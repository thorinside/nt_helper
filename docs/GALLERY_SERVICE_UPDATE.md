# Gallery Service Update - downloadUrl Support

## Overview

The nt_helper Flutter app has been updated to support the new `downloadUrl` functionality from the NT Gallery backend. This allows for direct downloads from URLs specified in the plugin installation configuration, while maintaining backward compatibility with the existing GitHub API fallback.

## Changes Made

### 1. Updated PluginInstallation Model

Added `downloadUrl` field to the `PluginInstallation` class in `gallery_models.dart`:

```dart
@freezed
sealed class PluginInstallation with _$PluginInstallation {
  const factory PluginInstallation({
    required String targetPath,
    String? subdirectory,
    String? assetPattern,
    String? extractPattern,
    String? downloadUrl,  // <-- New field
    @Default(false) bool preserveDirectoryStructure,
    String? sourceDirectoryPath,
  }) = _PluginInstallation;
}
```

### 2. Enhanced _getDownloadUrl Method

Updated `_getDownloadUrl()` method in `gallery_service.dart` to:

- **Priority 1**: Use `downloadUrl` from plugin installation config if available
- **Priority 2**: Fall back to GitHub API release asset discovery

```dart
Future<String> _getDownloadUrl(GalleryPlugin plugin, String version) async {
  // Priority 1: Use direct download URL from installation config if available
  if (plugin.installation.downloadUrl != null && 
      plugin.installation.downloadUrl!.isNotEmpty) {
    return plugin.installation.downloadUrl!;
  }

  // Priority 2: Fall back to GitHub API release asset discovery
  // ... existing GitHub API logic
}
```

### 3. Improved Zip Extraction with extractPattern

Enhanced `_extractArchive()` method to use `extractPattern` for file filtering:

- Compiles regex from `plugin.installation.extractPattern`
- Filters files in zip archives based on the pattern
- Supports patterns like `.*\.lua$`, `.*\.cpp$`, `.*\.o$`, etc.
- Maintains backward compatibility when no pattern is specified

## Supported Download Scenarios

### 1. Direct Single File Downloads

```json
{
  "installation": {
    "targetPath": "/lua/",
    "downloadUrl": "https://raw.githubusercontent.com/user/repo/main/plugin.lua",
    "extractPattern": ".*\\.lua$"
  }
}
```

### 2. Zip File with Single Plugin

```json
{
  "installation": {
    "targetPath": "/lua/",
    "downloadUrl": "https://github.com/user/repo/releases/download/v1.0.0/plugin.zip",
    "extractPattern": ".*\\.lua$"
  }
}
```

### 3. Zip File with Multiple Plugins (Collections)

```json
{
  "installation": {
    "targetPath": "/programs/plug-ins/user/",
    "downloadUrl": "https://github.com/user/repo/releases/download/v1.0.0/collection.zip",
    "extractPattern": ".*\\.o$"
  }
}
```

### 4. Backward Compatibility (GitHub API Fallback)

```json
{
  "installation": {
    "targetPath": "/lua/",
    "assetPattern": ".*\\.zip$",
    "extractPattern": ".*\\.lua$"
    // No downloadUrl - will use GitHub API
  }
}
```

## Key Benefits

1. **Performance**: Direct downloads avoid GitHub API rate limits and are faster
2. **Flexibility**: Supports any URL source, not just GitHub releases
3. **Precision**: `extractPattern` allows exact file filtering from archives
4. **Compatibility**: Existing plugins continue to work without changes

## Required Build Steps

After making these changes, you need to regenerate the Dart code:

```bash
cd nt_helper
dart pub get
dart pub run build_runner build
```

This regenerates the freezed model files (`gallery_models.freezed.dart` and `gallery_models.g.dart`) to include the new `downloadUrl` field.

## Testing

Created `test/gallery_service_test.dart` with tests covering:

- downloadUrl priority over GitHub API
- extractPattern usage for different plugin types
- Fallback behavior when downloadUrl is null
- Collection plugin support

## Error Handling

The updated service includes enhanced error messages that indicate:
- Whether downloadUrl or GitHub API was used
- What extractPattern was applied
- Number of files extracted from archives

## Live Gallery Compatibility

The implementation is compatible with the current live gallery at:
https://nt-gallery-frontend.fly.dev/api/gallery.json

Which includes examples of both downloadUrl-enabled plugins and traditional GitHub API-based plugins.