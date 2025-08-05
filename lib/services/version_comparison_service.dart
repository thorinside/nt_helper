// lib/services/version_comparison_service.dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pub_semver/pub_semver.dart';
import 'package:nt_helper/models/gallery_models.dart';

/// Service for comparing plugin versions using semantic versioning
/// and fallback strategies for non-standard version formats
class VersionComparisonService {
  /// Compare two version strings
  /// Returns: -1 if version1 < version2, 0 if equal, 1 if version1 > version2
  static int compareVersions(String version1, String version2) {
    try {
      // Try semantic version comparison first
      final v1 = _parseVersion(version1);
      final v2 = _parseVersion(version2);

      if (v1 != null && v2 != null) {
        return v1.compareTo(v2);
      }
    } catch (e) {
      debugPrint('SemanticVersion comparison failed: $e');
    }

    // Fallback to custom comparison logic
    return _fallbackVersionComparison(version1, version2);
  }

  /// Check if a newer version is available
  static bool hasUpdate(String installedVersion, String availableVersion) {
    return compareVersions(installedVersion, availableVersion) < 0;
  }

  /// Get the best available version from plugin releases
  /// Priority: stable > latest > beta
  static String getBestAvailableVersion(PluginReleases releases) {
    // Prefer stable if available
    if (releases.stable != null && releases.stable!.isNotEmpty) {
      return releases.stable!;
    }

    // Fall back to latest
    if (releases.latest.isNotEmpty) {
      return releases.latest;
    }

    // Last resort: beta
    if (releases.beta != null && releases.beta!.isNotEmpty) {
      return releases.beta!;
    }

    // Should not happen, but return latest as fallback
    return releases.latest;
  }

  /// Get all available versions sorted by preference
  static List<String> getAvailableVersions(PluginReleases releases) {
    final versions = <String>[];

    // Add in order of preference
    if (releases.stable != null && releases.stable!.isNotEmpty) {
      versions.add(releases.stable!);
    }

    if (releases.latest.isNotEmpty && !versions.contains(releases.latest)) {
      versions.add(releases.latest);
    }

    if (releases.beta != null &&
        releases.beta!.isNotEmpty &&
        !versions.contains(releases.beta!)) {
      versions.add(releases.beta!);
    }

    return versions;
  }

  /// Check if a version string follows semantic versioning
  static bool isSemanticVersion(String version) {
    try {
      final cleaned = _cleanVersionString(version);
      Version.parse(cleaned);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get version channel type based on version string
  static String getVersionChannel(String version, PluginReleases releases) {
    if (releases.stable == version) return 'stable';
    if (releases.beta == version) return 'beta';
    if (releases.latest == version) return 'latest';
    return 'unknown';
  }

  /// Parse version string to Version object, handling common prefixes
  static Version? _parseVersion(String versionString) {
    try {
      final cleaned = _cleanVersionString(versionString);
      return Version.parse(cleaned);
    } catch (e) {
      debugPrint('Failed to parse version "$versionString": $e');
      return null;
    }
  }

  /// Clean version string by removing common prefixes and suffixes
  static String _cleanVersionString(String version) {
    var cleaned = version.trim();

    // Remove common prefixes
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }

    if (cleaned.startsWith('release-')) {
      cleaned = cleaned.substring(8);
    }

    if (cleaned.startsWith('tag-')) {
      cleaned = cleaned.substring(4);
    }

    // Handle date-based versions (convert to semantic format)
    if (_isDateBasedVersion(cleaned)) {
      return _convertDateToSemver(cleaned);
    }

    return cleaned;
  }

  /// Check if version string is date-based (YYYY-MM-DD, YYYYMMDD, etc.)
  static bool _isDateBasedVersion(String version) {
    // Check for YYYY-MM-DD format
    final dateRegex1 = RegExp(r'^\d{4}-\d{2}-\d{2}');
    if (dateRegex1.hasMatch(version)) return true;

    // Check for YYYYMMDD format
    final dateRegex2 = RegExp(r'^\d{8}$');
    if (dateRegex2.hasMatch(version)) return true;

    // Check for YYYY.MM.DD format
    final dateRegex3 = RegExp(r'^\d{4}\.\d{2}\.\d{2}');
    if (dateRegex3.hasMatch(version)) return true;

    return false;
  }

  /// Convert date-based version to semantic version format
  static String _convertDateToSemver(String dateVersion) {
    // For date-based versions, we'll use YYYY.MM.DD format
    // which can be parsed as semantic version

    if (dateVersion.contains('-')) {
      // YYYY-MM-DD -> YYYY.MM.DD
      return dateVersion.replaceAll('-', '.');
    }

    if (dateVersion.length == 8 && RegExp(r'^\d{8}$').hasMatch(dateVersion)) {
      // YYYYMMDD -> YYYY.MM.DD
      return '${dateVersion.substring(0, 4)}.${dateVersion.substring(4, 6)}.${dateVersion.substring(6, 8)}';
    }

    return dateVersion;
  }

  /// Fallback comparison for non-semantic versions
  static int _fallbackVersionComparison(String version1, String version2) {
    debugPrint('Using fallback comparison for: $version1 vs $version2');

    // Try to extract numeric parts for comparison
    final nums1 = _extractNumbers(version1);
    final nums2 = _extractNumbers(version2);

    if (nums1.isNotEmpty && nums2.isNotEmpty) {
      for (int i = 0; i < nums1.length && i < nums2.length; i++) {
        final diff = nums1[i].compareTo(nums2[i]);
        if (diff != 0) return diff;
      }
      // If all compared numbers are equal, longer version is considered newer
      return nums1.length.compareTo(nums2.length);
    }

    // Final fallback: lexicographic comparison
    return version1.compareTo(version2);
  }

  /// Extract numeric components from version string
  static List<int> _extractNumbers(String version) {
    final numbers = <int>[];
    final regex = RegExp(r'\d+');
    final matches = regex.allMatches(version);

    for (final match in matches) {
      final num = int.tryParse(match.group(0)!);
      if (num != null) {
        numbers.add(num);
      }
    }

    return numbers;
  }

  /// Validate version string format
  static bool isValidVersionString(String version) {
    if (version.isEmpty) return false;

    // Check if it's a valid semantic version
    if (isSemanticVersion(version)) return true;

    // Check if it's a date-based version
    if (_isDateBasedVersion(version)) return true;

    // Check if it contains at least one number
    return RegExp(r'\d').hasMatch(version);
  }

  /// Get version comparison details for debugging
  static Map<String, dynamic> getVersionComparisonDetails(
    String version1,
    String version2,
  ) {
    final details = <String, dynamic>{
      'version1': version1,
      'version2': version2,
      'cleaned1': _cleanVersionString(version1),
      'cleaned2': _cleanVersionString(version2),
      'isSemanticV1': isSemanticVersion(version1),
      'isSemanticV2': isSemanticVersion(version2),
      'isDateV1': _isDateBasedVersion(_cleanVersionString(version1)),
      'isDateV2': _isDateBasedVersion(_cleanVersionString(version2)),
      'comparison': compareVersions(version1, version2),
    };

    return details;
  }
}

/// Extension methods for PluginReleases to add version comparison capabilities
extension PluginReleasesVersioning on PluginReleases {
  /// Get the best available version for updates
  String get bestVersion =>
      VersionComparisonService.getBestAvailableVersion(this);

  /// Get all available versions sorted by preference
  List<String> get allVersions =>
      VersionComparisonService.getAvailableVersions(this);

  /// Check if any version is newer than the installed version
  bool hasNewerVersionThan(String installedVersion) {
    final bestVersion = VersionComparisonService.getBestAvailableVersion(this);
    return VersionComparisonService.hasUpdate(installedVersion, bestVersion);
  }
}
