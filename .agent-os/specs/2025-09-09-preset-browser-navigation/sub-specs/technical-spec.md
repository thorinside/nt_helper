# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-09-preset-browser-navigation/spec.md

> Created: 2025-09-09
> Version: 1.0.0

## Technical Requirements

- **Three-Panel Navigation Widget**: Implement a custom Flutter widget with three horizontally arranged panels using Row layout with flex sizing
- **Directory Traversal via SysEx**: Use existing `IDistingMidiManager.requestDirectoryListing(String path)` method that returns `DirectoryListing?`
- **State Management**: Create a new PresetBrowserCubit following existing patterns with Freezed immutable state objects
- **Progress Indicator**: Implement LinearProgressIndicator in `SizedBox(height: 8)` following existing patterns from LoadPresetDialog
- **Icon System**: Use Flutter's built-in Icons.folder for directories and Icons.insert_drive_file for files
- **Sorting Logic**: Implement dual sorting modes (alphabetic and date-based) with unified file/directory lists
- **Path Management**: Build full paths from root (/ or /presets) maintaining path state across navigation
- **Back Navigation**: Track navigation history stack for back button functionality
- **Recent Presets**: Integrate with existing SharedPreferences history (key: 'presetHistory') - no database table exists currently
- **Dialog Presentation**: Modal AlertDialog launched from SynchronizedScreen PopupMenuItem, returns Map with sdCardPath, action, displayName
- **Error Handling**: Check `FirmwareVersion.hasSdCardSupport` and `!state.offline` before operations
- **Responsive Design**: Ensure panels resize appropriately for different screen sizes
- **Visual Feedback**: Highlight selected items in each panel, show loading states per panel

## Approach

### Widget Architecture
- **PresetBrowserDialog**: Main dialog container with responsive sizing
- **ThreePanelNavigator**: Core navigation widget with three Column widgets in a Row
- **DirectoryPanel**: Reusable panel widget for displaying directory contents
- **PresetItem**: Individual list item widget with icon, name, and selection state

### State Management Layer
```dart
class PresetBrowserCubit extends Cubit<PresetBrowserState> {
  final IDistingMidiManager midiManager;
  final DatabaseService database;
  
  // Navigation state
  List<String> navigationHistory = [];
  String currentPath = '/';
  Map<String, List<FileSystemItem>> directoryCache = {};
  
  // Panel state
  List<FileSystemItem> leftPanelItems = [];
  List<FileSystemItem> centerPanelItems = [];
  List<FileSystemItem> rightPanelItems = [];
  
  // Selection state
  String? selectedLeftItem;
  String? selectedCenterItem;
  String? selectedRightItem;
}
```

### SysEx Integration
- Use existing `requestDirectoryListing(String path)` method from IDistingMidiManager
- Leverage `DistingCubit._scanDirectory()` pattern for recursive traversal
- Implement caching strategy to avoid repeated SysEx calls
- Handle timeout scenarios with fallback UI states
- Parse DirectoryListing responses into FileSystemItem objects

### Navigation Logic
- **Three-level traversal**: Root → Category → Specific presets/subdirectories
- **Path building**: Concatenate selections to build full file paths
- **History management**: Push/pop navigation states for back functionality
- **Deep linking**: Support direct navigation to specific paths

### UI/UX Implementation
- **Panel layout**: Flex(1) for each panel to ensure equal width distribution
- **Loading states**: Individual LinearProgressIndicator per panel during SysEx operations
- **Selection feedback**: ListTile with selected highlighting using Theme colors
- **Icons**: Consistent iconography (folders vs files) across all panels
- **Scrolling**: ListView.builder for efficient rendering of large directories

### Storage Integration
- Use SharedPreferences for preset history (key: 'presetHistory')
- Update preset history when user selects preset files
- Cache directory structures in memory for session persistence

## Integration with Existing Code

### Files to Modify/Extend
- **LoadPresetDialog** (`lib/ui/widgets/load_preset_dialog.dart`): Create complementary three-panel browser dialog
- **DistingCubit** (`lib/cubit/disting_cubit.dart`): Reuse `fetchSdCardPresets()` and `_scanDirectory()` methods
- **SynchronizedScreen**: Add new menu option for three-panel browser alongside existing preset loader

### Existing Methods to Leverage
- `IDistingMidiManager.requestDirectoryListing(String path)` - Returns DirectoryListing with files/folders
- `DistingCubit._scanDirectory(String path)` - Recursive directory traversal pattern
- `DistingCubit.fetchSdCardPresets()` - Starting point for SD card scanning
- SharedPreferences for preset history management

### Return Value Format
Must return Map with keys:
- `'sdCardPath'`: Full path to selected preset
- `'action'`: PresetAction enum (load/append/export)
- `'displayName'`: User-friendly name for display

### Compatibility Requirements
- Maintain drag-and-drop support for .zip and .json files
- Preserve existing preset loading workflow  
- Check firmware version for SD card support
- Handle offline state gracefully