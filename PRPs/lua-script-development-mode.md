# PRP: Lua Script Development Mode

## Feature Overview
Implement a development mode for the Lua Script algorithm that allows drag-and-drop of `.lua` files onto the Program parameter editor, monitors the file for changes, automatically uploads modifications, and reloads the script on the Disting NT hardware.

## Context and Background

### Current State
- The Plugin Gallery already supports drag-and-drop upload of `.lua` files via `gallery_screen.dart`
- **Parameter Editor Registry**: The `ParameterEditorRegistry` already has a rule for the Lua Script algorithm's Program parameter that returns a `FileParameterEditor` widget
- The `FileParameterEditor` is used by `synchronized_screen.dart` when rendering parameters
- Scripts are uploaded to `/programs/lua/` on SD card and selected via Program parameter (0-999)

### Key Technical Details
1. **Lua Script Algorithm GUID**: `'lua '` (note the trailing space)
2. **Program Parameter**: Maps to file index in `/programs/lua/` directory
3. **Parameter Editor Rule**: Lines 162-172 in `parameter_editor_registry.dart` define the rule
4. **Upload Methods**: 
   - `installPlugin()` - uploads to SD card (persistent)
   - `installLua()` - direct SysEx installation (temporary)
5. **Parameter Reload**: Setting same Program value triggers script reload on hardware

## Implementation Blueprint

### Phase 1: Enhance FileParameterEditor for Lua Script

Since the `FileParameterEditor` is already used for the Lua Script Program parameter via the registry, we'll enhance it rather than creating a new algorithm view.

```dart
// lib/ui/widgets/file_parameter_editor.dart modifications

class _FileParameterEditorState extends State<FileParameterEditor> {
  // Add development mode state
  Timer? _fileWatchTimer;
  String? _developmentFilePath;
  DateTime? _lastModified;
  bool _isDragOver = false;
  _DevelopmentState _devState = _DevelopmentState.inactive;
  
  enum _DevelopmentState {
    inactive,
    monitoring,
    changeDetected,
    uploading,
    reloading,
    error
  }
  
  // Check if this is Lua Script Program parameter
  bool get _isLuaScriptProgram => 
    widget.slot.algorithm.guid == 'lua ' && 
    widget.parameterInfo.name == 'Program';
}
```

### Phase 2: Implement Drag-Drop on FileParameterEditor

```dart
// Inside file_parameter_editor.dart build method
@override
Widget build(BuildContext context) {
  // Existing build logic...
  
  // Wrap with DropTarget if it's Lua Script Program on desktop
  if (_isLuaScriptProgram && 
      !kIsWeb && 
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    return DropTarget(
      onDragDone: _handleScriptDrop,
      onDragEntered: (_) => setState(() => _isDragOver = true),
      onDragExited: (_) => setState(() => _isDragOver = false),
      child: Stack([
        _buildExistingContent(), // Current FileParameterEditor content
        if (_isDragOver) _buildDragOverlay(),
        if (_devState != _DevelopmentState.inactive) _buildDevModeIndicator(),
      ]),
    );
  }
  
  return _buildExistingContent();
}
```

### Phase 3: File Monitoring Implementation

```dart
void _startFileMonitoring(String filePath) {
  _developmentFilePath = filePath;
  _lastModified = File(filePath).lastModifiedSync();
  _devState = _DevelopmentState.monitoring;
  
  // Use Timer.periodic since watcher package adds dependency
  _fileWatchTimer = Timer.periodic(Duration(seconds: 1), (_) async {
    if (_developmentFilePath == null) return;
    
    try {
      final file = File(_developmentFilePath!);
      final currentModified = await file.lastModified();
      
      if (currentModified != _lastModified) {
        setState(() => _devState = _DevelopmentState.changeDetected);
        _lastModified = currentModified;
        await _uploadAndReloadScript();
      }
    } catch (e) {
      setState(() => _devState = _DevelopmentState.error);
    }
  });
}
```

### Phase 4: Upload and Reload Mechanism

```dart
Future<void> _uploadAndReloadScript() async {
  setState(() => _devState = _DevelopmentState.uploading);
  
  try {
    // Read the modified script
    final file = File(_developmentFilePath!);
    final contents = await file.readAsBytes();
    final fileName = path.basename(_developmentFilePath!);
    
    // Upload to hardware
    await widget.distingCubit.installPlugin(
      fileName,
      contents,
      onProgress: (progress) {
        // Update UI if needed
      },
    );
    
    // Get current Program parameter value
    final programParam = _getProgramParameter();
    final currentValue = programParam?.value ?? 0;
    
    setState(() => _devState = _DevelopmentState.reloading);
    
    // Force reload by setting parameter to same value
    await widget.distingCubit.setParameterValue(
      algorithmIndex: widget.algorithmInfo.index,
      parameterIndex: 0, // Program is first parameter
      value: currentValue,
    );
    
    setState(() => _devState = _DevelopmentState.monitoring);
  } catch (e) {
    setState(() => _devState = _DevelopmentState.error);
    debugPrint('Failed to upload/reload script: $e');
  }
}
```

### Phase 5: Animated Status Indicator

```dart
Widget _buildDevModeIndicator() {
  return Positioned(
    top: 8,
    right: 8,
    child: GestureDetector(
      onTap: _toggleDevelopmentMode,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getStateColor().withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getStateColor()),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStateIcon(),
            SizedBox(width: 4),
            Text(
              _getStateText(),
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildStateIcon() {
  switch (_devState) {
    case _DevelopmentState.monitoring:
      return Icon(Icons.visibility, size: 16);
    case _DevelopmentState.changeDetected:
      return Icon(Icons.edit_note, size: 16);
    case _DevelopmentState.uploading:
    case _DevelopmentState.reloading:
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    case _DevelopmentState.error:
      return Icon(Icons.error_outline, size: 16);
    default:
      return Icon(Icons.code, size: 16);
  }
}
```

### Phase 6: Handle Drop Events

```dart
Future<void> _handleScriptDrop(DropDoneDetails details) async {
  // Filter for .lua files only
  final luaFiles = details.files.where((file) => 
    file.path.toLowerCase().endsWith('.lua')).toList();
  
  if (luaFiles.isEmpty) {
    _showError('Please drop a .lua file');
    return;
  }
  
  if (luaFiles.length > 1) {
    _showError('Please drop only one file at a time');
    return;
  }
  
  final file = luaFiles.first;
  
  // Ask user if they want to enable development mode
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Enable Development Mode?'),
      content: Text(
        'Monitor "${path.basename(file.path)}" for changes and '
        'automatically reload on the Disting NT?'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Enable'),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    await _startDevelopmentMode(file.path);
  }
}
```

## File References and Patterns to Follow

### Existing Patterns to Mimic:
1. **Drag-Drop**: `/lib/ui/gallery_screen.dart:1525-1636` - DropTarget implementation
2. **File Upload**: `/lib/ui/gallery_screen.dart:1607-1636` - installPlugin usage
3. **FileParameterEditor**: `/lib/ui/widgets/file_parameter_editor.dart` - Current implementation
4. **Registry Integration**: `/lib/ui/synchronized_screen.dart:1560` - How FileParameterEditor is used
5. **Timer Monitoring**: `/lib/cubit/disting_cubit.dart:2920-2922` - Timer.periodic pattern
6. **Progress Indicators**: `/lib/ui/cpu_monitor_widget.dart:97-105` - Loading states
7. **State Animation**: `/lib/ui/widgets/floating_screenshot_overlay.dart:276-285` - AnimatedContainer

### Key Dependencies:
- `desktop_drop: ^0.6.0` - Already in pubspec.yaml
- `cross_file: ^0.3.4` - For cross-platform file handling
- No need for watcher package - use Timer.periodic like existing code

### MIDI/SysEx Details:
- **Upload**: Use `DistingCubit.installPlugin()` method
- **Parameter Set**: Use `DistingCubit.setParameterValue()` 
- **File Location**: Scripts go to `/programs/lua/` on SD card
- **Program Parameter**: Index 0, maps to file index in directory

## Gotchas and Edge Cases

1. **Platform Detection**: Must check for desktop platforms (Windows, macOS, Linux)
2. **File Names**: Ensure valid filenames for SD card (no special chars)
3. **Chunk Size**: File uploads use 512-byte chunks - don't change
4. **Parameter Mapping**: Program value must match file index after upload
5. **Debouncing**: Rapid file changes need debouncing to avoid excessive uploads
6. **Error Recovery**: Handle file deletion, permission errors gracefully
7. **State Cleanup**: Cancel timer in dispose() to prevent memory leaks
8. **iOS Limitation**: File watching not supported - would need polling fallback

## Implementation Tasks

1. Modify `/lib/ui/widgets/file_parameter_editor.dart` to detect Lua Script Program parameter
2. Add development mode state variables and enum to `_FileParameterEditorState`
3. Wrap existing build output with `DropTarget` when on desktop and Lua Script
4. Implement drag-drop handler for `.lua` files only
5. Add file monitoring with 1-second Timer.periodic
6. Implement upload and reload sequence using existing `DistingCubit` methods
7. Create animated status indicator with all states
8. Add proper error handling and user feedback
9. Test with real hardware for parameter reload behavior

## Validation Gates

```bash
# Syntax and code quality
flutter analyze

# Ensure no dartfmt issues
dart format --set-exit-if-changed .

# Run existing tests
flutter test

# Manual testing checklist:
# 1. Drag .lua file onto Program parameter - should start dev mode
# 2. Edit file locally - should see status change and auto-upload
# 3. Click dev mode indicator - should stop monitoring
# 4. Test with invalid files - should show appropriate errors
# 5. Test rapid file changes - should debounce properly
# 6. Test on Windows, macOS, Linux - all should work
# 7. Test parameter reload - script should restart on hardware
```

## External Documentation

- **desktop_drop package**: https://pub.dev/packages/desktop_drop
- **Flutter drag outside docs**: https://docs.flutter.dev/ui/interactivity/gestures/drag-outside
- **Dart file watching**: https://api.flutter.dev/flutter/dart-io/File/lastModified.html
- **Timer.periodic**: https://api.dart.dev/stable/dart-async/Timer/Timer.periodic.html

## Success Criteria

- FileParameterEditor detects when it's rendering the Lua Script Program parameter
- Drop zone appears only for Lua Script Program parameter on desktop platforms
- Dropped `.lua` files enter development mode automatically after user confirmation
- File changes detected within 1-2 seconds
- Automatic upload and script reload works reliably
- Visual feedback clear for all states (monitoring, uploading, reloading, error)
- No memory leaks or dangling timers
- Integrates seamlessly with existing FileParameterEditor without affecting other uses

## Architecture Summary

The implementation leverages the existing parameter editor registry system:
1. `ParameterEditorRegistry` already maps Lua Script Program parameter to `FileParameterEditor`
2. `FileParameterEditor` will be enhanced to detect when it's being used for Lua Script
3. Drag-drop and development mode features will be conditionally added only for Lua Script
4. No changes needed to registry or synchronized_screen.dart

## Confidence Score: 9.5/10

The implementation path is very clear since we're enhancing an existing widget that's already properly integrated through the registry system. The approach is less invasive than creating a custom algorithm view and follows the established architecture perfectly.