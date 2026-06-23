import 'dart:convert';
import 'dart:io';

import 'package:nt_helper/chat/models/allowed_file_root.dart';
import 'package:nt_helper/mcp/tool_registry.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:path/path.dart' as path;

const localFileToolNames = {
  'list_allowed_roots',
  'list_files',
  'read_file',
  'write_file',
  'search_files',
};

void registerLocalFileTools(
  List<ToolRegistryEntry> entries, {
  required FileRootActor actor,
}) {
  final tools = _LocalFileTools(SettingsService(), actor);

  entries.addAll([
    ToolRegistryEntry(
      name: 'list_allowed_roots',
      description:
          'List named filesystem roots available to this caller and their permissions.',
      inputSchema: {'properties': {}},
      handler: tools.listAllowedRoots,
      timeout: const Duration(seconds: 5),
    ),
    ToolRegistryEntry(
      name: 'list_files',
      description:
          'List files under an allowed root. Paths are relative to the selected root.',
      inputSchema: {
        'properties': {
          'root_id': {
            'type': 'string',
            'description': 'ID from list_allowed_roots.',
          },
          'path': {
            'type': 'string',
            'description': 'Optional relative subdirectory to list.',
          },
          'recursive': {
            'type': 'boolean',
            'description': 'Whether to include nested files. Default: false.',
          },
          'limit': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 200,
            'description': 'Maximum number of entries to return. Default: 50.',
          },
        },
        'required': ['root_id'],
      },
      handler: tools.listFiles,
      timeout: const Duration(seconds: 5),
    ),
    ToolRegistryEntry(
      name: 'read_file',
      description:
          'Read a UTF-8 text or binary file under an allowed root. Binary files are returned as base64.',
      inputSchema: {
        'properties': {
          'root_id': {
            'type': 'string',
            'description': 'ID from list_allowed_roots.',
          },
          'path': {
            'type': 'string',
            'description': 'Relative path of the file to read.',
          },
          'max_bytes': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 200000,
            'description':
                'Maximum bytes to read. Default: 100000. Larger files return an error.',
          },
        },
        'required': ['root_id', 'path'],
      },
      handler: tools.readFile,
      timeout: const Duration(seconds: 5),
    ),
    ToolRegistryEntry(
      name: 'write_file',
      description:
          'Write UTF-8 text to a file under an allowed root. No delete or rename support.',
      inputSchema: {
        'properties': {
          'root_id': {
            'type': 'string',
            'description': 'ID from list_allowed_roots.',
          },
          'path': {
            'type': 'string',
            'description': 'Relative path of the file to write.',
          },
          'content': {
            'type': 'string',
            'description': 'UTF-8 text content to write.',
          },
          'create_parents': {
            'type': 'boolean',
            'description':
                'Create missing parent directories under the root. Default: false.',
          },
          'overwrite': {
            'type': 'boolean',
            'description': 'Allow replacing an existing file. Default: false.',
          },
        },
        'required': ['root_id', 'path', 'content'],
      },
      handler: tools.writeFile,
      timeout: const Duration(seconds: 5),
    ),
    ToolRegistryEntry(
      name: 'search_files',
      description:
          'Search UTF-8 text files under an allowed root. Paths are relative to that root.',
      inputSchema: {
        'properties': {
          'root_id': {
            'type': 'string',
            'description': 'ID from list_allowed_roots.',
          },
          'query': {
            'type': 'string',
            'description': 'Case-insensitive text to search for.',
          },
          'path': {
            'type': 'string',
            'description': 'Optional relative subdirectory to search.',
          },
          'limit': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 100,
            'description': 'Maximum number of matches to return. Default: 25.',
          },
          'max_file_bytes': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 500000,
            'description':
                'Skip files larger than this many bytes. Default: 200000.',
          },
        },
        'required': ['root_id', 'query'],
      },
      handler: tools.searchFiles,
      timeout: const Duration(seconds: 10),
    ),
  ]);
}

class _ResolvedRoot {
  const _ResolvedRoot(this.config, this.directory);

  final AllowedFileRoot config;
  final Directory directory;
}

class _LocalFileTools {
  _LocalFileTools(this._settings, this._actor);

  final SettingsService _settings;
  final FileRootActor _actor;

  Future<String> listAllowedRoots(Map<String, dynamic> args) async {
    final roots = <Map<String, dynamic>>[];
    for (final root in _settings.allowedFileRoots) {
      final permissions = root.permissionsFor(_actor);
      if (permissions.isEmpty) continue;
      roots.add({
        'id': root.id,
        'label': root.label,
        'path': root.path,
        'permissions':
            permissions.map((permission) => permission.storageKey).toList()
              ..sort(),
      });
    }

    return _json({'success': true, 'roots': roots});
  }

  Future<String> listFiles(Map<String, dynamic> args) async {
    final rootResult = await _resolveRoot(args, FileRootPermission.read);
    if (rootResult.error != null) return rootResult.error!;
    final root = rootResult.root!;

    final target = await _resolveUnderRoot(root.directory, args['path']);
    if (target.error != null) return target.error!;
    final entity = target.entity!;
    if (!await entity.exists()) {
      return _json({'success': false, 'error': 'path_not_found'});
    }
    if (entity is! Directory) {
      return _json({'success': false, 'error': 'not_a_directory'});
    }

    final recursive = args['recursive'] == true;
    final limit = _intArg(args['limit'], fallback: 50, min: 1, max: 200);
    final entries = <Map<String, dynamic>>[];

    await for (final child in entity.list(
      recursive: recursive,
      followLinks: false,
    )) {
      if (child is Link) continue;
      if (!await _pathResolvesInsideRoot(root.directory, child.path)) continue;
      final stat = await child.stat();
      entries.add({
        'path': _relative(root.directory, child.path),
        'type': child is Directory ? 'directory' : 'file',
        'size': stat.type == FileSystemEntityType.file ? stat.size : null,
        'modified': stat.modified.toIso8601String(),
      });
      if (entries.length >= limit) break;
    }

    return _json({
      'success': true,
      'root_id': root.config.id,
      'root_label': root.config.label,
      'path': _relative(root.directory, entity.path),
      'entries': entries,
      'truncated': entries.length >= limit,
    });
  }

  Future<String> readFile(Map<String, dynamic> args) async {
    final rootResult = await _resolveRoot(args, FileRootPermission.read);
    if (rootResult.error != null) return rootResult.error!;
    final root = rootResult.root!;

    final target = await _resolveUnderRoot(root.directory, args['path']);
    if (target.error != null) return target.error!;
    final entity = target.entity!;
    if (entity is! File || !await entity.exists()) {
      return _json({'success': false, 'error': 'file_not_found'});
    }

    final maxBytes = _intArg(
      args['max_bytes'],
      fallback: 100000,
      min: 1,
      max: 200000,
    );
    final stat = await entity.stat();
    if (stat.size > maxBytes) {
      return _json({
        'success': false,
        'error': 'file_too_large',
        'size': stat.size,
        'max_bytes': maxBytes,
      });
    }

    try {
      final content = await entity.readAsString();
      return _json({
        'success': true,
        'root_id': root.config.id,
        'path': _relative(root.directory, entity.path),
        'size': stat.size,
        'encoding': 'utf8',
        'content': content,
      });
    } on FormatException {
      final bytes = await entity.readAsBytes();
      return _json({
        'success': true,
        'root_id': root.config.id,
        'path': _relative(root.directory, entity.path),
        'size': stat.size,
        'encoding': 'base64',
        'content_base64': base64Encode(bytes),
      });
    }
  }

  Future<String> writeFile(Map<String, dynamic> args) async {
    final rootResult = await _resolveRoot(args, FileRootPermission.write);
    if (rootResult.error != null) return rootResult.error!;
    final root = rootResult.root!;

    final content = args['content'];
    if (content is! String) {
      return _json({'success': false, 'error': 'missing_content'});
    }
    final contentBytes = utf8.encode(content);
    if (contentBytes.length > 500000) {
      return _json({
        'success': false,
        'error': 'content_too_large',
        'size': contentBytes.length,
        'max_bytes': 500000,
      });
    }

    final target = await _resolveUnderRoot(root.directory, args['path']);
    if (target.error != null) return target.error!;
    final entity = target.entity!;
    final file = File(entity.path);
    final parent = Directory(path.dirname(file.path));
    if (!await parent.exists()) {
      if (args['create_parents'] == true) {
        await parent.create(recursive: true);
      } else {
        return _json({'success': false, 'error': 'parent_not_found'});
      }
    }

    if (await file.exists() && args['overwrite'] != true) {
      return _json({'success': false, 'error': 'file_exists'});
    }

    await file.writeAsString(content);
    final stat = await file.stat();
    return _json({
      'success': true,
      'root_id': root.config.id,
      'path': _relative(root.directory, file.path),
      'size': stat.size,
      'encoding': 'utf8',
    });
  }

  Future<String> searchFiles(Map<String, dynamic> args) async {
    final rootResult = await _resolveRoot(args, FileRootPermission.search);
    if (rootResult.error != null) return rootResult.error!;
    final root = rootResult.root!;

    final query = args['query'];
    if (query is! String || query.trim().isEmpty) {
      return _json({'success': false, 'error': 'missing_query'});
    }

    final target = await _resolveUnderRoot(root.directory, args['path']);
    if (target.error != null) return target.error!;
    final entity = target.entity!;
    if (entity is! Directory || !await entity.exists()) {
      return _json({'success': false, 'error': 'directory_not_found'});
    }

    final limit = _intArg(args['limit'], fallback: 25, min: 1, max: 100);
    final maxFileBytes = _intArg(
      args['max_file_bytes'],
      fallback: 200000,
      min: 1,
      max: 500000,
    );
    final needle = query.toLowerCase();
    final matches = <Map<String, dynamic>>[];

    await for (final child in entity.list(
      recursive: true,
      followLinks: false,
    )) {
      if (child is! File) continue;
      if (!await _pathResolvesInsideRoot(root.directory, child.path)) continue;
      final stat = await child.stat();
      if (stat.size > maxFileBytes) continue;

      String content;
      try {
        content = await child.readAsString();
      } on FormatException {
        continue;
      }

      final lines = const LineSplitter().convert(content);
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.toLowerCase().contains(needle)) continue;
        matches.add({
          'path': _relative(root.directory, child.path),
          'line': i + 1,
          'preview': line.trim(),
        });
        if (matches.length >= limit) {
          return _json({
            'success': true,
            'root_id': root.config.id,
            'query': query,
            'matches': matches,
            'truncated': true,
          });
        }
      }
    }

    return _json({
      'success': true,
      'root_id': root.config.id,
      'query': query,
      'matches': matches,
      'truncated': false,
    });
  }

  Future<({String? error, _ResolvedRoot? root})> _resolveRoot(
    Map<String, dynamic> args,
    FileRootPermission permission,
  ) async {
    final rootId = args['root_id'];
    if (rootId is! String || rootId.trim().isEmpty) {
      return (
        error: _json({'success': false, 'error': 'missing_root_id'}),
        root: null,
      );
    }

    AllowedFileRoot? root;
    for (final candidate in _settings.allowedFileRoots) {
      if (candidate.id == rootId) {
        root = candidate;
        break;
      }
    }
    if (root == null) {
      return (
        error: _json({'success': false, 'error': 'root_not_found'}),
        root: null,
      );
    }
    if (!root.allows(_actor, permission)) {
      return (
        error: _json({
          'success': false,
          'error': 'permission_denied',
          'permission': permission.storageKey,
        }),
        root: null,
      );
    }

    final directory = Directory(root.path);
    if (!await directory.exists()) {
      return (
        error: _json({'success': false, 'error': 'root_not_found_on_disk'}),
        root: null,
      );
    }

    return (
      error: null,
      root: _ResolvedRoot(
        root,
        Directory(await directory.resolveSymbolicLinks()),
      ),
    );
  }

  Future<({String? error, FileSystemEntity? entity})> _resolveUnderRoot(
    Directory root,
    dynamic relativePath,
  ) async {
    if (relativePath != null && relativePath is! String) {
      return (
        error: _json({'success': false, 'error': 'invalid_path'}),
        entity: null,
      );
    }

    final rawPath = (relativePath as String?)?.trim();
    if (rawPath != null && rawPath.isNotEmpty && path.isAbsolute(rawPath)) {
      return (
        error: _json({'success': false, 'error': 'absolute_path_not_allowed'}),
        entity: null,
      );
    }
    final normalizedRelative = path.normalize(rawPath ?? '');
    if (normalizedRelative == '..' ||
        normalizedRelative.startsWith('..${path.separator}') ||
        normalizedRelative.split(path.separator).contains('..')) {
      return (
        error: _json({'success': false, 'error': 'path_outside_allowed_root'}),
        entity: null,
      );
    }

    final combined = rawPath == null || rawPath.isEmpty
        ? root.path
        : path.join(root.path, normalizedRelative);
    final normalized = path.normalize(combined);
    final existingAncestor = await _nearestExistingAncestor(normalized);
    final resolvedAncestor = await existingAncestor.resolveSymbolicLinks();
    final suffix = path.relative(normalized, from: existingAncestor.path);
    final resolvedPath = suffix == '.'
        ? path.normalize(resolvedAncestor)
        : path.normalize(path.join(resolvedAncestor, suffix));

    if (!path.isWithin(root.path, resolvedPath) && resolvedPath != root.path) {
      return (
        error: _json({'success': false, 'error': 'path_outside_allowed_root'}),
        entity: null,
      );
    }

    final type = await FileSystemEntity.type(resolvedPath, followLinks: false);
    if (type == FileSystemEntityType.link) {
      return (
        error: _json({'success': false, 'error': 'path_outside_allowed_root'}),
        entity: null,
      );
    }
    return (
      error: null,
      entity: type == FileSystemEntityType.directory
          ? Directory(resolvedPath)
          : File(resolvedPath),
    );
  }

  Future<bool> _pathResolvesInsideRoot(
    Directory root,
    String entityPath,
  ) async {
    try {
      final isDirectory = await FileSystemEntity.isDirectory(entityPath);
      final resolved = isDirectory
          ? await Directory(entityPath).resolveSymbolicLinks()
          : await File(entityPath).resolveSymbolicLinks();
      return path.isWithin(root.path, resolved) || resolved == root.path;
    } on FileSystemException {
      return false;
    }
  }

  Future<Directory> _nearestExistingAncestor(String targetPath) async {
    var current = Directory(targetPath);
    while (!await current.exists()) {
      final parentPath = path.dirname(current.path);
      if (parentPath == current.path) break;
      current = Directory(parentPath);
    }
    return current;
  }

  String _relative(Directory root, String entityPath) {
    final rel = path.relative(entityPath, from: root.path);
    return rel == '.' ? '' : rel;
  }

  int _intArg(
    dynamic value, {
    required int fallback,
    required int min,
    required int max,
  }) {
    final parsed = value is int
        ? value
        : value is num
        ? value.toInt()
        : value is String
        ? int.tryParse(value) ?? fallback
        : fallback;
    return parsed.clamp(min, max).toInt();
  }

  String _json(Map<String, dynamic> value) => jsonEncode(value);
}
