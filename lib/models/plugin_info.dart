import 'package:freezed_annotation/freezed_annotation.dart';

part 'plugin_info.freezed.dart';
part 'plugin_info.g.dart';

/// Enum representing the different types of plugins supported by Disting NT
enum PluginType {
  lua(
    'Lua Script',
    '/programs/lua',
    '.lua',
    'Lua scripts for custom algorithms',
  ),
  threePot(
    '3pot',
    '/programs/three_pot',
    '.3pot',
    '3-potentiometer control plugins',
  ),
  cpp('C++ Plugin', '/programs/plug-ins', '.o', 'Compiled C++ plugin objects');

  const PluginType(
    this.displayName,
    this.directory,
    this.extension,
    this.description,
  );

  final String displayName;
  final String directory;
  final String extension;
  final String description;
}

/// Represents information about a plugin installed on the Disting NT
@freezed
sealed class PluginInfo with _$PluginInfo {
  const factory PluginInfo({
    required String name,
    required String path,
    required PluginType type,
    required int sizeBytes,
    String? description,
    DateTime? lastModified,
  }) = _PluginInfo;

  factory PluginInfo.fromJson(Map<String, dynamic> json) =>
      _$PluginInfoFromJson(json);
}

/// Extension methods for PluginInfo
extension PluginInfoExtension on PluginInfo {
  /// Gets the filename without the path
  String get filename {
    return path.split('/').last;
  }

  /// Gets the plugin name without the file extension
  String get nameWithoutExtension {
    final filename = this.filename;
    if (filename.endsWith(type.extension)) {
      return filename.substring(0, filename.length - type.extension.length);
    }
    return filename;
  }

  /// Gets a user-friendly display name for the plugin
  String get displayName {
    return nameWithoutExtension.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  /// Gets the size in a human-readable format
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
