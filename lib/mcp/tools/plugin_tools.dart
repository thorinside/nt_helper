import 'dart:convert';

import 'package:nt_helper/chat/models/allowed_file_root.dart';
import 'package:nt_helper/chat/services/local_file_tools.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/mcp/tool_registry.dart';
import 'package:nt_helper/models/plugin_cleanup_outcome.dart';
import 'package:nt_helper/models/plugin_install_report.dart';
import 'package:path/path.dart' as path;

/// Registers `install_plugin` for [actor]. Local reads are limited to the
/// allowed roots that grant [actor] read permission, exactly as `read_file`.
void registerPluginTools(
  List<ToolRegistryEntry> entries,
  DistingCubit cubit, {
  required FileRootActor actor,
}) {
  final tools = PluginTools(cubit, actor: actor);
  entries.add(
    ToolRegistryEntry(
      name: 'install_plugin',
      description:
          'Install a C++ plug-in (.o) or Lua script (.lua) from this computer '
          'onto the connected Disting NT SD card, then verify it. .o files go '
          'to /programs/plug-ins/ and trigger a plug-in rescan; the result lists '
          'the algorithms the device reports for the file (matched by the GUIDs '
          'inside it) and whether every expected GUID appeared. .lua files go to '
          '/programs/lua/ and are verified by SD listing only. Requires a live, '
          'synchronized device; refused in offline and demo mode. The file must '
          'be inside an allowed root with MCP read permission (see '
          'list_allowed_roots) and at most 2 MiB. Upload runs at roughly '
          '5-10 KB/s. If the .o is in use by the current preset, the preset is '
          'cleared for the upload and reloaded from its last saved copy, so call '
          'save first to keep unsaved edits. An existing file with the same '
          'name is overwritten.',
      inputSchema: {
        'properties': {
          'path': {
            'type': 'string',
            'description':
                'Absolute local path of the file to install, ending in .o or '
                '.lua, for example /Users/me/plugins/build/myfilter.o. The file '
                'name is kept on the SD card.',
          },
          'load': {
            'type': 'boolean',
            'default': false,
            'description':
                'For .o files only: after the rescan, load every algorithm '
                'found for the file so it is ready to add without a delay. '
                'Default: false. Rejected for .lua files.',
          },
        },
        'required': ['path'],
        'additionalProperties': false,
      },
      handler: tools.installPlugin,
      timeout: const Duration(minutes: 10),
    ),
  );
}

/// Handlers behind the plugin MCP tools.
final class PluginTools {
  /// Creates handlers that read local files as [actor] and install them
  /// through [_cubit]. [maxRescanAttempts] and [rescanPollInterval] bound the
  /// wait for a rescanned `.o` to appear.
  PluginTools(
    this._cubit, {
    required this.actor,
    this.maxRescanAttempts = 5,
    this.rescanPollInterval = const Duration(seconds: 1),
  });

  final DistingCubit _cubit;

  /// Caller whose allowed-root read permission governs local file access.
  final FileRootActor actor;

  /// Maximum algorithm-list reads while waiting for a rescan.
  final int maxRescanAttempts;

  /// Delay between algorithm-list reads while waiting for a rescan.
  final Duration rescanPollInterval;

  /// Largest file `install_plugin` accepts, in bytes.
  static const maxFileBytes = 2 * 1024 * 1024;

  /// Lower-case extensions `install_plugin` accepts.
  static const supportedExtensions = {'.o', '.lua'};

  /// Handles `install_plugin`. Always returns a JSON object with `success`;
  /// failures carry a snake_case `error` code and a readable `message`.
  Future<String> installPlugin(Map<String, dynamic> args) async {
    final unknown = args.keys.where((k) => k != 'path' && k != 'load');
    if (unknown.isNotEmpty) {
      return _failure(
        'unknown_argument',
        'Unknown argument(s): ${unknown.join(', ')}. Accepted: path, load.',
      );
    }
    final rawPath = args['path'];
    if (rawPath is! String || rawPath.trim().isEmpty) {
      return _failure(
        'missing_path',
        'path is required: the absolute local path of a .o or .lua file.',
      );
    }
    final load = args['load'] ?? false;
    if (load is! bool) {
      return _failure('invalid_load', 'load must be true or false.');
    }
    final localPath = rawPath.trim();
    final extension = path.extension(localPath).toLowerCase();
    if (!supportedExtensions.contains(extension)) {
      return _failure(
        'unsupported_extension',
        'Only .o (C++ plug-in) and .lua (Lua script) files can be installed; '
            'got "${extension.isEmpty ? '(none)' : extension}".',
      );
    }
    if (load && extension == '.lua') {
      return _failure(
        'load_not_supported',
        'load applies only to .o plug-ins. Lua scripts are chosen with the '
            'Program parameter of a Lua Script slot.',
      );
    }

    final resolved = await resolveAllowedLocalFile(localPath, actor: actor);
    final file = resolved.file;
    if (file == null) {
      return _failure(resolved.error!, switch (resolved.error) {
        'absolute_path_required' => 'path must be an absolute path.',
        'file_not_found' => 'No file exists at $localPath.',
        _ =>
          '$localPath is not inside an allowed root with ${actor.storageKey} '
              'read permission. Call list_allowed_roots to see readable roots; '
              'roots are configured in nt_helper Settings.',
      });
    }

    final size = await file.length();
    if (size == 0) {
      return _failure('empty_file', '$localPath is empty.');
    }
    if (size > maxFileBytes) {
      return _failure(
        'file_too_large',
        '$localPath is $size bytes; the limit is $maxFileBytes bytes.',
        {'size': size, 'max_bytes': maxFileBytes},
      );
    }

    final PluginInstallReport report;
    try {
      report = await _cubit.installPluginAndVerify(
        path.basename(file.path),
        await file.readAsBytes(),
        load: load,
        maxRescanAttempts: maxRescanAttempts,
        rescanPollInterval: rescanPollInterval,
      );
    } on PluginInstallRefused catch (e) {
      return _failure(e.reason.code, e.message);
    } on FormatException catch (e) {
      return _failure('invalid_file_name', e.message);
    } catch (e) {
      return _failure('install_failed', 'Upload did not complete: $e');
    }
    return jsonEncode(_reportJson(file.path, extension, report, load));
  }

  Map<String, dynamic> _reportJson(
    String sourcePath,
    String extension,
    PluginInstallReport report,
    bool load,
  ) {
    final isObject = extension == '.o';
    final missing = report.missingGuids;
    final verified = isObject
        ? report.algorithms.isNotEmpty && missing.isEmpty
        : report.filePresent == true;
    final loadFailures = report.loadResults.where((r) => !r.loaded).length;
    return {
      'success': true,
      'plugin_type': isObject ? 'cpp' : 'lua',
      'source_path': sourcePath,
      'destination_path': report.destinationPath,
      'bytes_written': report.bytesWritten,
      'file_present': report.filePresent,
      'verified': verified,
      'preset_reloaded': report.presetReloaded,
      'root_duplicate': _cleanupJson(report.cleanup),
      if (isObject) ...{
        'rescan_attempts': report.rescanAttempts,
        'expected_guids': report.expectedGuids,
        'missing_guids': missing,
        'algorithms': [
          for (final a in report.algorithms)
            {'guid': a.guid, 'name': a.name, 'is_loaded': a.isLoaded},
        ],
      },
      if (load)
        'load_results': [
          for (final r in report.loadResults)
            {'guid': r.guid, 'loaded': r.loaded},
        ],
      'message': _summary(report, isObject, verified, load, loadFailures),
    };
  }

  String _summary(
    PluginInstallReport report,
    bool isObject,
    bool verified,
    bool load,
    int loadFailures,
  ) {
    final buffer = StringBuffer(
      'Uploaded ${report.bytesWritten} bytes to ${report.destinationPath}.',
    );
    if (!isObject) {
      buffer.write(
        verified
            ? ' The file is listed on the SD card.'
            : ' The SD listing did not confirm the file.',
      );
    } else if (verified) {
      final names = report.algorithms.map((a) => '${a.name} (${a.guid})');
      buffer.write(' Rescan found: ${names.join(', ')}.');
    } else if (report.algorithms.isEmpty) {
      buffer.write(
        ' No algorithm for this file appeared after '
        '${report.rescanAttempts} rescan check(s). Check the device screen '
        'for a load error, or call search_algorithms later.',
      );
    } else {
      buffer.write(
        ' Rescan is missing GUID(s): ${report.missingGuids.join(', ')}.',
      );
    }
    if (load) {
      buffer.write(
        report.loadResults.isEmpty
            ? ' Nothing was loaded because no algorithm was found.'
            : loadFailures == 0
            ? ' Loaded ${report.loadResults.length} algorithm(s).'
            : ' $loadFailures of ${report.loadResults.length} algorithm(s) '
                  'did not report loaded.',
      );
    }
    if (report.presetReloaded) {
      buffer.write(' The preset was reloaded from its saved copy.');
    }
    return buffer.toString();
  }

  Map<String, dynamic> _cleanupJson(PluginCleanupOutcome outcome) =>
      switch (outcome) {
        PluginCleanupSkipped() => {'status': 'not_applicable'},
        PluginCleanupRemoved(:final path) => {
          'status': 'removed',
          'path': path,
        },
        PluginCleanupDeletionFailed(:final path) => {
          'status': 'deletion_failed',
          'path': path,
        },
        PluginCleanupCouldNotBeVerified(:final path) => {
          'status': 'kept_unverified',
          'path': path,
        },
      };

  String _failure(
    String code,
    String message, [
    Map<String, dynamic> extra = const {},
  ]) => jsonEncode({
    'success': false,
    'error': code,
    'message': message,
    ...extra,
  });
}
