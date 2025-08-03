# Semantic Version Implementation Guide

## Adding pub_semver to Flutter

### 1. Add Dependency
```yaml
# pubspec.yaml
dependencies:
  pub_semver: ^2.1.4
```

### 2. Basic Usage
```dart
import 'package:pub_semver/pub_semver.dart';

// Parse versions
final installed = Version.parse('1.2.3');
final available = Version.parse('1.3.0');

// Compare versions
if (available > installed) {
  print('Update available!');
}

// Handle pre-release versions
final beta = Version.parse('2.0.0-beta.1');
final stable = Version.parse('2.0.0');
print(beta < stable); // true
```

### 3. Version Comparison Service

```dart
class VersionComparisonService {
  /// Compare two version strings
  static int compareVersions(String v1, String v2) {
    try {
      final version1 = Version.parse(v1);
      final version2 = Version.parse(v2);
      return version1.compareTo(version2);
    } catch (e) {
      // Fallback to string comparison for non-semver versions
      return v1.compareTo(v2);
    }
  }
  
  /// Check if update is available
  static bool isUpdateAvailable(String installed, String available) {
    try {
      return Version.parse(available) > Version.parse(installed);
    } catch (e) {
      return false;
    }
  }
  
  /// Get version priority (stable > latest > beta)
  static String selectBestVersion(PluginReleases releases) {
    final versions = <String, Version>{};
    
    // Parse available versions
    if (releases.stable != null) {
      try {
        versions['stable'] = Version.parse(releases.stable!);
      } catch (_) {}
    }
    
    try {
      versions['latest'] = Version.parse(releases.latest);
    } catch (_) {}
    
    if (releases.beta != null) {
      try {
        versions['beta'] = Version.parse(releases.beta!);
      } catch (_) {}
    }
    
    // Return highest stable version, or latest if no stable
    if (versions.containsKey('stable')) {
      return releases.stable!;
    }
    return releases.latest;
  }
}
```

### 4. GitHub Version Tags

GitHub release tags often include 'v' prefix:
```dart
String normalizeVersion(String gitTag) {
  // Remove 'v' prefix if present
  if (gitTag.startsWith('v') || gitTag.startsWith('V')) {
    return gitTag.substring(1);
  }
  return gitTag;
}
```

### 5. Handling Non-Semver Versions

Some plugins might use date-based or custom versioning:
```dart
class FlexibleVersionComparator {
  static bool isNewer(String installed, String available) {
    // Try semantic version first
    try {
      return Version.parse(available) > Version.parse(installed);
    } catch (_) {
      // Try date-based (YYYY.MM.DD)
      final datePattern = RegExp(r'^\d{4}\.\d{1,2}\.\d{1,2}$');
      if (datePattern.hasMatch(installed) && datePattern.hasMatch(available)) {
        return available.compareTo(installed) > 0;
      }
      
      // Fallback to string comparison
      return available.compareTo(installed) > 0;
    }
  }
}
```