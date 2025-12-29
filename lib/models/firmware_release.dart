import 'package:freezed_annotation/freezed_annotation.dart';

part 'firmware_release.freezed.dart';
part 'firmware_release.g.dart';

/// Represents a firmware release available for download
/// Named FirmwareRelease to avoid collision with existing FirmwareVersion class
@freezed
sealed class FirmwareRelease with _$FirmwareRelease {
  const factory FirmwareRelease({
    /// Version string (e.g., "1.12.0")
    required String version,

    /// Release date
    required DateTime releaseDate,

    /// List of changelog entries for this release
    required List<String> changelog,

    /// Download URL for the firmware package
    required String downloadUrl,
  }) = _FirmwareRelease;

  factory FirmwareRelease.fromJson(Map<String, dynamic> json) =>
      _$FirmwareReleaseFromJson(json);
}

/// Extension methods for FirmwareRelease
extension FirmwareReleaseExtension on FirmwareRelease {
  /// Gets the version as a display string with 'v' prefix (e.g., "v1.12.0")
  String get displayVersion => 'v$version';

  /// Parses version into comparable components [major, minor, patch]
  List<int> get versionParts {
    final parts = version.split('.');
    return parts.map((p) => int.tryParse(p) ?? 0).toList();
  }

  /// Compares this version to another version string
  /// Returns positive if this version is newer, negative if older, 0 if equal
  int compareToVersion(String other) {
    final thisParts = versionParts;
    final otherParts = other.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final thisVal = i < thisParts.length ? thisParts[i] : 0;
      final otherVal = i < otherParts.length ? otherParts[i] : 0;
      if (thisVal != otherVal) {
        return thisVal - otherVal;
      }
    }
    return 0;
  }
}
