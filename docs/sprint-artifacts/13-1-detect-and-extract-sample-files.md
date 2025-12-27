# Story 13.1: Detect and Extract Sample Files from Plugin Zip Archives

Status: Ready for Review

## Story

As a developer maintaining plugin installation,
I want `_extractArchive()` to also extract files from the `samples/` directory in plugin zips,
so that sample dependencies are available for installation alongside plugin files.

## Acceptance Criteria

1. `_extractArchive()` detects files under `samples/` path in zip archive (case-insensitive check)
2. Sample files are extracted with their full relative path preserved (e.g., `samples/drums/kick.wav`)
3. Sample files are returned as separate list or tagged entries distinguishable from plugin files
4. Existing plugin file filtering (`.o`, `.lua`, `.3pot`) continues to work unchanged
5. Sample files of any extension are included (`.wav`, `.raw`, `.bin`, etc.)
6. Empty `samples/` directories are ignored (only files extracted)
7. Nested sample directories are supported (e.g., `samples/category/subcategory/file.wav`)
8. Unit test verifies sample extraction from test zip with `samples/` directory
9. Unit test verifies plugin-only zips continue to work (no samples directory)
10. `flutter analyze` passes with zero warnings

## Tasks / Subtasks

- [x] Task 1: Modify `_extractArchive()` return type (AC: #3)
  - [x] Create a new class or record to hold both plugin files and sample files
  - [x] Options: `ExtractedArchiveContents` class with `pluginFiles` and `sampleFiles` lists
  - [x] Update method signature to return new type

- [x] Task 2: Add sample detection logic to `_extractArchive()` (AC: #1, #5, #6, #7)
  - [x] Add case-insensitive check for files starting with `samples/` or `Samples/`
  - [x] Filter sample files separately from plugin files
  - [x] Preserve full relative path for sample files
  - [x] Skip directory entries (only extract actual files)

- [x] Task 3: Update callers of `_extractArchive()` (AC: #4)
  - [x] Update `_installSinglePluginViaDisting()` to handle new return type
  - [x] Initially just use the pluginFiles list to preserve existing behavior
  - [x] Sample files will be used in Story 13.2

- [x] Task 4: Write unit tests (AC: #8, #9)
  - [x] Create test fixture zip with plugin + samples
  - [x] Create test fixture zip with plugin only
  - [x] Test sample path preservation
  - [x] Test case-insensitive detection
  - [x] Test nested sample directories

- [x] Task 5: Verify `flutter analyze` passes (AC: #10)

## Dev Notes

### Primary File to Modify
`lib/services/gallery_service.dart`

### Current `_extractArchive()` Behavior (lines 964-1047)
The method currently:
1. Decodes zip using `ZipDecoder().decodeBytes(archiveBytes)`
2. Iterates through files in archive
3. Applies `sourceDirectoryPath` filtering if configured
4. Applies `extractPattern` regex filtering if configured
5. Filters by `queuedPlugin.selectedPlugins` if collection
6. Returns `List<MapEntry<String, List<int>>>` of extracted files

### Proposed Design

Create a simple class to hold extraction results:

```dart
class ExtractedArchiveContents {
  final List<MapEntry<String, List<int>>> pluginFiles;
  final List<MapEntry<String, List<int>>> sampleFiles;

  const ExtractedArchiveContents({
    required this.pluginFiles,
    required this.sampleFiles,
  });

  bool get hasSamples => sampleFiles.isNotEmpty;
}
```

### Sample Detection Logic

```dart
// Case-insensitive check for samples directory
bool _isSampleFile(String filePath) {
  final lowerPath = filePath.toLowerCase();
  return lowerPath.startsWith('samples/') || lowerPath.startsWith('/samples/');
}
```

### Testing Strategy
- Create test zips programmatically using `archive` package
- Test in `test/services/gallery_service_samples_test.dart`
- Mock zip contents to verify extraction logic

### Project Structure Notes
- Aligns with existing service patterns in `lib/services/`
- Uses existing `archive` package dependency
- No new dependencies required

### References
- [Source: lib/services/gallery_service.dart#_extractArchive (lines 964-1047)]
- [Source: docs/epics.md#Epic 13]

## Dev Agent Record

### Context Reference
Epic 13: Plugin Sample Dependency Installation

### Agent Model Used
Claude Opus 4.5

### Debug Log References
N/A - All tests passed on first run

### Completion Notes List
- Created `ExtractedArchiveContents` class with `pluginFiles`, `sampleFiles` lists, `hasSamples` getter, and `totalFileCount` getter
- Added `_isSampleFile()` helper method for case-insensitive samples/ prefix detection
- Modified `_extractArchive()` to detect and separate sample files before applying other filters
- Sample files preserve their full relative path (e.g., `samples/drums/kick.wav`)
- Updated caller in `_installSinglePluginViaDisting()` to use `extractedContents.pluginFiles`
- Added `@visibleForTesting` methods for testability: `extractArchiveForTesting()` and `isSampleFileForTesting()`
- Created comprehensive test suite with 31 tests covering all acceptance criteria (expanded during code review)
- All tests pass, `flutter analyze` passes with zero warnings
- **Code Review Fixes (2025-12-27):** Added path normalization for case-insensitive filesystems, retry logic for transient failures, directory conflict detection

### File List
- lib/services/gallery_service.dart (modified)
- test/services/gallery_service_sample_extraction_test.dart (new)

## Change Log
- 2025-12-26: Implemented sample file detection and extraction in `_extractArchive()` method
