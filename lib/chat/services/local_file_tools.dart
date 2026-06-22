import 'dart:convert';
import 'dart:io';

import 'package:nt_helper/mcp/tool_registry.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:path/path.dart' as path;

const localFileToolNames = {
  'local_list_files',
  'local_read_file',
  'local_search_files',
  'list_workspace_files',
  'read_workspace_file',
  'write_workspace_file',
  'list_uploaded_files',
  'read_uploaded_file',
};

void registerLocalFileTools(List<ToolRegistryEntry> entries) {
  final tools = _LocalFileTools(SettingsService());

  entries.addAll([
    ToolRegistryEntry(
      name: 'list_workspace_files',
      description:
          'List files under the user-selected chat workspace directory. Paths are relative to that workspace.',
      inputSchema: {
        'properties': {
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
      },
      handler: tools.listFiles,
      timeout: const Duration(seconds: 5),
    ),
    ToolRegistryEntry(
      name: 'read_workspace_file',
      description:
          'Read a file from the user-selected chat workspace. Text is returned as UTF-8; binary files are returned as base64. Paths are relative to that workspace.',
      inputSchema: {
        'properties': {
          'path': {
            'type': 'string',
            'description': 'Relative path of the text file to read.',
          },
          'max_bytes': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 200000,
            'description':
                'Maximum bytes to read. Default: 100000. Larger files return an error.',
          },
        },
        'required': ['path'],
      },
      handler: tools.readFile,
      timeout: const Duration(seconds: 5),
    ),
    ToolRegistryEntry(
      name: 'write_workspace_file',
      description:
          'Write a UTF-8 text file under the user-selected chat workspace. Paths are relative to that workspace.',
      inputSchema: {
        'properties': {
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
            'description': 'Create missing parent directories. Default: true.',
          },
        },
        'required': ['path', 'content'],
      },
      handler: tools.writeFile,
      timeout: const Duration(seconds: 5),
    ),
    ToolRegistryEntry(
      name: 'list_uploaded_files',
      description:
          'List files under the uploads/ folder inside the selected chat workspace.',
      inputSchema: {
        'properties': {
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
      },
      handler: tools.listUploadedFiles,
      timeout: const Duration(seconds: 5),
    ),
    ToolRegistryEntry(
      name: 'read_uploaded_file',
      description:
          'Read a file from uploads/ inside the selected chat workspace. Text is returned as UTF-8; binary files are returned as base64.',
      inputSchema: {
        'properties': {
          'filename': {
            'type': 'string',
            'description': 'Filename or relative path under uploads/.',
          },
          'max_bytes': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 200000,
            'description':
                'Maximum bytes to read. Default: 100000. Larger files return an error.',
          },
        },
        'required': ['filename'],
      },
      handler: tools.readUploadedFile,
      timeout: const Duration(seconds: 5),
    ),
    ToolRegistryEntry(
      name: 'local_list_files',
      description:
          'List files under the user-selected local chat directory. Paths are relative to that directory.',
      inputSchema: {
        'properties': {
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
      },
      handler: tools.listFiles,
      timeout: const Duration(seconds: 5),
    ),
    ToolRegistryEntry(
      name: 'local_read_file',
      description:
          'Read a file from the user-selected local chat directory. Text is returned as UTF-8; binary files are returned as base64. Paths are relative to that directory.',
      inputSchema: {
        'properties': {
          'path': {
            'type': 'string',
            'description': 'Relative path of the text file to read.',
          },
          'max_bytes': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 200000,
            'description':
                'Maximum bytes to read. Default: 100000. Larger files return an error.',
          },
        },
        'required': ['path'],
      },
      handler: tools.readFile,
      timeout: const Duration(seconds: 5),
    ),
    ToolRegistryEntry(
      name: 'local_search_files',
      description:
          'Search UTF-8 text files under the user-selected local chat directory. Paths are relative to that directory.',
      inputSchema: {
        'properties': {
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
        'required': ['query'],
      },
      handler: tools.searchFiles,
      timeout: const Duration(seconds: 10),
    ),
  ]);
}

class _LocalFileTools {
  final SettingsService _settings;

  _LocalFileTools(this._settings);

  Future<String> listFiles(Map<String, dynamic> args) async {
    final root = await _rootDirectory();
    if (root == null) return _notConfigured();

    final target = await _resolveUnderRoot(root, args['path'] as String?);
    if (target == null) return _outsideRoot();
    if (!await target.exists()) {
      return _json({'success': false, 'error': 'path_not_found'});
    }
    if (target is! Directory) {
      return _json({'success': false, 'error': 'not_a_directory'});
    }

    final recursive = args['recursive'] == true;
    final limit = _intArg(args['limit'], fallback: 50, min: 1, max: 200);
    final entries = <Map<String, dynamic>>[];

    await for (final entity in target.list(recursive: recursive)) {
      final stat = await entity.stat();
      entries.add({
        'path': _relative(root, entity.path),
        'type': entity is Directory ? 'directory' : 'file',
        'size': stat.type == FileSystemEntityType.file ? stat.size : null,
        'modified': stat.modified.toIso8601String(),
      });
      if (entries.length >= limit) break;
    }

    return _json({
      'success': true,
      'root': root.path,
      'path': _relative(root, target.path),
      'entries': entries,
      'truncated': entries.length >= limit,
    });
  }

  Future<String> readFile(Map<String, dynamic> args) async {
    final root = await _rootDirectory();
    if (root == null) return _notConfigured();

    final requestedPath = args['path'];
    if (requestedPath is! String || requestedPath.trim().isEmpty) {
      return _json({'success': false, 'error': 'missing_path'});
    }

    final target = await _resolveUnderRoot(root, requestedPath);
    if (target == null) return _outsideRoot();
    if (target is! File || !await target.exists()) {
      return _json({'success': false, 'error': 'file_not_found'});
    }

    final maxBytes = _intArg(
      args['max_bytes'],
      fallback: 100000,
      min: 1,
      max: 200000,
    );
    final stat = await target.stat();
    if (stat.size > maxBytes) {
      return _json({
        'success': false,
        'error': 'file_too_large',
        'size': stat.size,
        'max_bytes': maxBytes,
      });
    }

    try {
      final content = await target.readAsString();
      return _json({
        'success': true,
        'path': _relative(root, target.path),
        'size': stat.size,
        'encoding': 'utf8',
        'content': content,
      });
    } on FormatException {
      final bytes = await target.readAsBytes();
      return _json({
        'success': true,
        'path': _relative(root, target.path),
        'size': stat.size,
        'encoding': 'base64',
        'content_base64': base64Encode(bytes),
      });
    }
  }

  Future<String> writeFile(Map<String, dynamic> args) async {
    final root = await _rootDirectory();
    if (root == null) return _notConfigured();

    final requestedPath = args['path'];
    final content = args['content'];
    if (requestedPath is! String || requestedPath.trim().isEmpty) {
      return _json({'success': false, 'error': 'missing_path'});
    }
    if (content is! String) {
      return _json({'success': false, 'error': 'missing_content'});
    }
    if (content.length > 500000) {
      return _json({
        'success': false,
        'error': 'content_too_large',
        'max_chars': 500000,
      });
    }

    final target = await _resolveUnderRoot(root, requestedPath);
    if (target == null) return _outsideRoot();
    if (target is Directory) {
      return _json({'success': false, 'error': 'path_is_directory'});
    }

    final createParents = args['create_parents'] != false;
    final parent = Directory(path.dirname(target.path));
    if (!await parent.exists()) {
      if (!createParents) {
        return _json({'success': false, 'error': 'parent_not_found'});
      }
      await parent.create(recursive: true);
    }

    await File(target.path).writeAsString(content);
    final stat = await File(target.path).stat();
    return _json({
      'success': true,
      'path': _relative(root, target.path),
      'size': stat.size,
    });
  }

  Future<String> listUploadedFiles(Map<String, dynamic> args) {
    return listFiles({...args, 'path': 'uploads'});
  }

  Future<String> readUploadedFile(Map<String, dynamic> args) {
    final filename = args['filename'];
    if (filename is! String || filename.trim().isEmpty) {
      return Future.value(_json({'success': false, 'error': 'missing_filename'}));
    }
    return readFile({
      ...args,
      'path': path.join('uploads', filename),
    });
  }

  Future<String> searchFiles(Map<String, dynamic> args) async {
    final root = await _rootDirectory();
    if (root == null) return _notConfigured();

    final query = args['query'];
    if (query is! String || query.trim().isEmpty) {
      return _json({'success': false, 'error': 'missing_query'});
    }

    final target = await _resolveUnderRoot(root, args['path'] as String?);
    if (target == null) return _outsideRoot();
    if (target is! Directory || !await target.exists()) {
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

    await for (final entity in target.list(recursive: true)) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      if (stat.size > maxFileBytes) continue;

      String content;
      try {
        content = await entity.readAsString();
      } on FormatException {
        continue;
      }

      final lines = const LineSplitter().convert(content);
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final matchIndex = line.toLowerCase().indexOf(needle);
        if (matchIndex == -1) continue;
        matches.add({
          'path': _relative(root, entity.path),
          'line': i + 1,
          'preview': line.trim(),
        });
        if (matches.length >= limit) {
          return _json({
            'success': true,
            'root': root.path,
            'query': query,
            'matches': matches,
            'truncated': true,
          });
        }
      }
    }

    return _json({
      'success': true,
      'root': root.path,
      'query': query,
      'matches': matches,
      'truncated': false,
    });
  }

  Future<Directory?> _rootDirectory() async {
    final configured = _settings.chatLocalDirectory?.trim();
    if (configured == null || configured.isEmpty) return null;
    final root = Directory(configured);
    if (!await root.exists()) return null;
    return Directory(await root.resolveSymbolicLinks());
  }

  Future<FileSystemEntity?> _resolveUnderRoot(
    Directory root,
    String? relativePath,
  ) async {
    final rawPath = relativePath?.trim();
    final combined = rawPath == null || rawPath.isEmpty
        ? root.path
        : path.join(root.path, rawPath);
    final normalized = path.normalize(combined);
    final parent = Directory(path.dirname(normalized));
    final resolvedParent = await parent.exists()
        ? await parent.resolveSymbolicLinks()
        : path.normalize(parent.path);
    final resolvedPath = path.normalize(path.join(resolvedParent, path.basename(normalized)));
    if (!path.isWithin(root.path, resolvedPath) && resolvedPath != root.path) {
      return null;
    }

    final type = await FileSystemEntity.type(resolvedPath);
    return type == FileSystemEntityType.directory
        ? Directory(resolvedPath)
        : File(resolvedPath);
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

  String _notConfigured() => _json({
    'success': false,
    'error': 'local_directory_not_configured',
  });

  String _outsideRoot() => _json({
    'success': false,
    'error': 'path_outside_local_directory',
  });

  String _json(Map<String, dynamic> value) => jsonEncode(value);
}
