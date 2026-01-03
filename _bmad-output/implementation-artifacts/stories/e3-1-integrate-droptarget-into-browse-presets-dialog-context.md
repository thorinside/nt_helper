# Story E3.1 Context: Integrate DropTarget into Browse Presets Dialog

**Generated:** 2025-10-28
**Story:** e3-1-integrate-droptarget-into-browse-presets-dialog
**Epic:** 3 - Drag-and-Drop Preset Package Installation

---

## Story Objective

Add drag-and-drop visual feedback to the Browse Presets dialog by integrating the `DropTarget` widget. This story focuses solely on the UI scaffolding and visual feedback - no actual file processing. When users drag a .zip file over the dialog, they should see a blue overlay with a drop icon indicating the drop zone is active.

**Key Deliverables:**
1. Visual feedback when dragging files over the dialog
2. Platform-conditional wrapping (desktop only)
3. State management for drag events
4. Stub handlers for future functionality

---

## Current State Analysis

### Target File: `preset_browser_dialog.dart`

**Location:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/preset_browser_dialog.dart`

**Current Structure:**
- StatefulWidget with `_PresetBrowserDialogState`
- Build method returns `AlertDialog` directly (line 33)
- Already has access to `DistingCubit` via `widget.distingCubit`
- Already has access to `PresetBrowserCubit` via context

**Current Build Method Pattern:**
```dart
@override
Widget build(BuildContext context) {
  final isMobile = Responsive.isMobile(context);

  return AlertDialog(
    title: Row(...),
    content: SizedBox(...),
    actions: [
      TextButton(...),
      BlocBuilder<PresetBrowserCubit, PresetBrowserState>(...),
    ],
  );
}
```

**Imports Present:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/preset_browser_cubit.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/interfaces/impl/preset_file_system_impl.dart';
import 'package:nt_helper/ui/widgets/load_preset_dialog.dart';
import 'package:nt_helper/ui/widgets/preset_package_dialog.dart';
import 'package:nt_helper/ui/widgets/mobile_drill_down_navigator.dart';
import 'package:nt_helper/utils/responsive.dart';
```

---

## Reference Implementation: LoadPresetDialog

**File:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/load_preset_dialog.dart`

### Complete Drag-Drop Implementation

**State Variables (lines 44-46):**
```dart
// Drag and drop state
bool _isDragOver = false;
bool _isInstallingPackage = false;
```

**Build Method Pattern (lines 221-277):**
```dart
@override
Widget build(BuildContext context) {
  Widget content = AlertDialog(
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(_isManagingHistory ? 'Manage History' : 'Load Preset'),
        if (!_isManagingHistory)
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Manage Preset History',
            onPressed: () {
              setState(() {
                _isManagingHistory = true;
              });
            },
          ),
      ],
    ),
    content: SizedBox(
      width: 400, // Wider dialog
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _isManagingHistory
                ? _buildManagementView()
                : _buildPresetSelectionView(),
            SizedBox(height: 4), // 4px spacing before progress bar
            // Fixed height container to prevent layout shift
            SizedBox(
              height: 8, // Height to accommodate the progress bar
              child: _isLoading || _isInstallingPackage
                  ? LinearProgressIndicator()
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: _isManagingHistory ? [_buildDoneButton()] : _buildLoadActions(),
  );

  // Only add drag and drop on desktop platforms
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    return DropTarget(
      onDragDone: _handleDragDone,
      onDragEntered: _handleDragEntered,
      onDragExited: _handleDragExited,
      child: Stack(children: [content, if (_isDragOver) _buildDragOverlay()]),
    );
  }

  return content;
}
```

**Handler Methods (lines 523-576):**
```dart
// Drag and drop handlers
void _handleDragEntered(DropEventDetails details) {
  setState(() {
    _isDragOver = true;
  });
}

void _handleDragExited(DropEventDetails details) {
  setState(() {
    _isDragOver = false;
  });
}

void _handleDragDone(DropDoneDetails details) {
  setState(() {
    _isDragOver = false;
  });

  // Filter for supported files (zip packages or json presets)
  final supportedFiles = details.files.where((file) {
    final lowerPath = file.path.toLowerCase();
    return lowerPath.endsWith('.zip') || lowerPath.endsWith('.json');
  }).toList();

  if (supportedFiles.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please drop a preset package (.zip) or preset file (.json)',
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  if (supportedFiles.length > 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please drop only one file at a time'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final file = supportedFiles.first;
  if (file.path.toLowerCase().endsWith('.zip')) {
    // Process as package
    _processPackageFile(file);
  } else if (file.path.toLowerCase().endsWith('.json')) {
    // Process as single preset
    _processPresetFile(file);
  }
}
```

**Drag Overlay (lines 777-833):**
```dart
Widget _buildDragOverlay() {
  return Container(
    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
    child: Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Drop files here to install',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Supports .zip packages and .json presets',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
```

---

## Reference Pattern: GalleryScreen

**File:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/gallery_screen.dart`

**State Variables (lines 64-66):**
```dart
// Drag and drop state
bool _isDragOver = false;
bool _isInstalling = false;
```

**Build Method Pattern (lines 138-179):**
```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<GalleryCubit, GalleryState>(
    builder: (context, state) {
      Widget content = Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Column(
          children: [
            _buildHeader(state),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildGalleryTab(state), _buildQueueTab()],
              ),
            ),
          ],
        ),
      );

      // Only add drag and drop on desktop platforms
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux)) {
        return DropTarget(
          onDragDone: _handleDragDone,
          onDragEntered: _handleDragEntered,
          onDragExited: _handleDragExited,
          child: Stack(
            children: [
              content,
              if (_isDragOver) _buildDragOverlay(),
              if (_isInstalling) _buildInstallOverlay(),
            ],
          ),
        );
      }

      return content;
    },
  );
}
```

---

## Step-by-Step Implementation Guide

### Step 1: Add Imports

Add these imports at the top of `preset_browser_dialog.dart`:

```dart
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
```

**Note:** These go with the existing imports. No conditional imports needed - `desktop_drop` works on all platforms, we just conditionally enable the UI.

### Step 2: Add State Variables

In `_PresetBrowserDialogState`, add these state variables after the class declaration:

```dart
class _PresetBrowserDialogState extends State<PresetBrowserDialog> {
  // Drag and drop state
  bool _isDragOver = false;
  bool _isInstallingPackage = false;

  @override
  void initState() {
    super.initState();
    // Load root directory when dialog opens
    context.read<PresetBrowserCubit>().loadRootDirectory();
  }

  // ... rest of the class
```

### Step 3: Restructure Build Method

Replace the current build method with this pattern:

```dart
@override
Widget build(BuildContext context) {
  final isMobile = Responsive.isMobile(context);

  // Build the main content first
  Widget content = AlertDialog(
    title: Row(
      children: [
        const Text('Browse Presets'),
        const Spacer(),
        // Navigation controls
        BlocBuilder<PresetBrowserCubit, PresetBrowserState>(
          builder: (context, state) {
            return Row(
              children: [
                // Back button
                state.maybeMap(
                  loaded: (loaded) => loaded.navigationHistory.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            context.read<PresetBrowserCubit>().navigateBack();
                          },
                          tooltip: 'Back',
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
                // Sort toggle
                state.maybeMap(
                  loaded: (loaded) => IconButton(
                    icon: Icon(
                      loaded.sortByDate
                          ? Icons.date_range
                          : Icons.sort_by_alpha,
                    ),
                    onPressed: () {
                      context.read<PresetBrowserCubit>().toggleSortMode();
                    },
                    tooltip: loaded.sortByDate
                        ? 'Sort by date'
                        : 'Sort alphabetically',
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ],
    ),
    content: SizedBox(
      width: isMobile
          ? MediaQuery.of(context).size.width * 0.95
          : MediaQuery.of(context).size.width * 0.8,
      height: isMobile
          ? MediaQuery.of(context).size.height * 0.7
          : MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          // Main content area
          Expanded(
            child: BlocBuilder<PresetBrowserCubit, PresetBrowserState>(
              builder: (context, state) {
                return state.map(
                  initial: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  loading: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  loaded: (loaded) => isMobile
                      ? MobileDrillDownNavigator(
                          items:
                              loaded.currentDrillItems ??
                              loaded.leftPanelItems,
                          selectedItem: loaded.selectedDrillItem,
                          breadcrumbs: loaded.breadcrumbs ?? [],
                          onItemTap: _handleMobileItemTap,
                          onBreadcrumbTap: _handleBreadcrumbTap,
                          onRefresh: _handleRefresh,
                        )
                      : ThreePanelNavigator(
                          leftPanelItems: loaded.leftPanelItems,
                          centerPanelItems: loaded.centerPanelItems,
                          rightPanelItems: loaded.rightPanelItems,
                          selectedLeftItem: loaded.selectedLeftItem,
                          selectedCenterItem: loaded.selectedCenterItem,
                          selectedRightItem: loaded.selectedRightItem,
                          onItemSelected: _handleItemSelected,
                        ),
                  error: (error) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(error.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<PresetBrowserCubit>()
                                .loadRootDirectory();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Progress indicator bar
          BlocBuilder<PresetBrowserCubit, PresetBrowserState>(
            builder: (context, state) {
              return state.maybeMap(
                loading: (_) => const SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(),
                ),
                orElse: () => const SizedBox(height: 8),
              );
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      BlocBuilder<PresetBrowserCubit, PresetBrowserState>(
        builder: (context, state) {
          final selectedPath = context
              .read<PresetBrowserCubit>()
              .getSelectedPath();
          final isPresetFile =
              selectedPath.isNotEmpty &&
              selectedPath.toLowerCase().endsWith('.json');
          final isMobile = Responsive.isMobile(context);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPresetFile && !isMobile) ...[
                OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) => PresetPackageDialog(
                        presetFilePath: selectedPath,
                        fileSystem: PresetFileSystemImpl(
                          widget.distingCubit.requireDisting(),
                        ),
                        database: widget.distingCubit.database,
                      ),
                    );
                  },
                  child: const Text('Export'),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton(
                onPressed: isPresetFile
                    ? () {
                        Navigator.of(context).pop({
                          'sdCardPath': selectedPath,
                          'action': PresetAction.load,
                          'displayName': selectedPath.split('/').last,
                        });
                      }
                    : null,
                child: const Text('Load'),
              ),
            ],
          );
        },
      ),
    ],
  );

  // Only add drag and drop on desktop platforms
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    return DropTarget(
      onDragDone: _handleDragDone,
      onDragEntered: _handleDragEntered,
      onDragExited: _handleDragExited,
      child: Stack(
        children: [
          content,
          if (_isDragOver) _buildDragOverlay(),
          if (_isInstallingPackage) _buildInstallOverlay(),
        ],
      ),
    );
  }

  return content;
}
```

### Step 4: Add Handler Methods

Add these methods at the end of `_PresetBrowserDialogState` class (after existing helper methods):

```dart
// Drag and drop handlers
void _handleDragEntered(DropEventDetails details) {
  setState(() {
    _isDragOver = true;
  });
}

void _handleDragExited(DropEventDetails details) {
  setState(() {
    _isDragOver = false;
  });
}

void _handleDragDone(DropDoneDetails details) {
  setState(() {
    _isDragOver = false;
  });
  // Story E3.2 will implement full functionality
}
```

### Step 5: Add Overlay Builder Methods

Add these methods at the end of `_PresetBrowserDialogState` class:

```dart
Widget _buildDragOverlay() {
  return Positioned.fill(
    child: Container(
      color: Colors.blue.withValues(alpha: 0.1),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.upload_file,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Drop preset package here',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildInstallOverlay() {
  return Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    ),
  );
}
```

---

## Platform Check Details

**Why This Pattern:**
- `desktop_drop` package already in `pubspec.yaml` - no changes needed
- Package works on all platforms - no build errors on mobile/web
- Runtime check prevents UI from showing on unsupported platforms
- No conditional imports needed

**Platform Constants:**
- `kIsWeb` - true when running in browser
- `defaultTargetPlatform` - current platform enum
- Use from `package:flutter/foundation.dart`

---

## Testing Verification Steps

### Manual Testing

1. **Desktop Testing (macOS, Windows, or Linux):**
   ```bash
   flutter run -d macos
   ```
   - Open Browse Presets dialog
   - Drag any .zip file over the dialog window
   - Verify blue overlay appears with "Drop preset package here" message
   - Drag file outside dialog bounds
   - Verify overlay disappears
   - Drop file on dialog
   - Verify overlay disappears (nothing else happens - this is correct for this story)

2. **Mobile Testing (verify no errors):**
   ```bash
   flutter run -d ios
   # or
   flutter run -d android
   ```
   - Open Browse Presets dialog
   - Verify no visual changes (drag-drop UI should not appear)
   - Verify no runtime errors or warnings

### Code Quality

Run before committing:
```bash
flutter analyze
```

Must show: `No issues found!`

### Build Verification

Verify both platforms can build:
```bash
# Desktop
flutter build macos --debug

# Mobile
flutter build ios --debug --no-codesign
# or
flutter build apk --debug
```

Both should complete without errors.

---

## DropTarget Widget Behavior

**Widget Properties:**
- `onDragEntered` - Called when drag enters widget bounds
- `onDragExited` - Called when drag leaves widget bounds
- `onDragDone` - Called when files are dropped
- `child` - The widget to wrap (our Stack with content + overlays)

**DropEventDetails:**
- No file information (used for enter/exit events)

**DropDoneDetails:**
- `files` - List of `XFile` objects representing dropped files
- Each `XFile` has `.path`, `.name`, `.readAsBytes()` methods

**Important Notes:**
- Handler must call `setState()` to update UI
- Always reset `_isDragOver` to false in `onDragDone`
- Overlay is conditionally rendered via `if (_isDragOver)` in Stack

---

## Integration with PresetBrowserCubit

**Access in Dialog:**
```dart
context.read<PresetBrowserCubit>()
```

**Key Method for Future Stories:**
```dart
// After package installation completes (Story E3.4)
context.read<PresetBrowserCubit>().loadRootDirectory();
```

This refreshes the preset listing to show newly installed files.

---

## Code Organization Tips

1. **State Variables** - Keep at top of class for visibility
2. **Handler Methods** - Group together near end of class
3. **Overlay Builders** - Keep together after handlers
4. **Consistent Naming** - Use `_build` prefix for widget methods
5. **Comments** - Mark stub methods with future story reference

---

## Common Pitfalls

1. **Forgetting setState()** - UI won't update without it
2. **Not resetting _isDragOver** - Overlay will stick after drop
3. **Wrong import** - Use `package:flutter/foundation.dart` not `dart:io`
4. **Stack overflow** - Don't return DropTarget inside content, wrap content
5. **Color alpha syntax** - Use `withValues(alpha: 0.1)` not `withOpacity(0.1)`

---

## What This Story Does NOT Do

- File validation (Story E3.2)
- Package analysis (Story E3.2)
- Conflict detection (Story E3.3)
- Installation logic (Story E3.4)
- Error handling (Story E3.4)

This story is purely visual scaffolding. The `_handleDragDone` method is intentionally stubbed out.

---

## Definition of Done Checklist

- [ ] Imports added: `desktop_drop`, `cross_file`, `foundation`
- [ ] State variables added: `_isDragOver`, `_isInstallingPackage`
- [ ] Build method restructured with `content` variable
- [ ] Platform check wraps DropTarget correctly
- [ ] Handler methods implemented with setState calls
- [ ] Overlay builder methods return correct widgets
- [ ] Manual testing passed on desktop
- [ ] Mobile build succeeds with no errors
- [ ] `flutter analyze` passes with zero warnings
- [ ] All existing preset browser functionality still works

---

## Next Story Preview

**E3.2: Drop Handling & Package Analysis**

Will implement the `_handleDragDone` method to:
1. Filter dropped files for .zip extension
2. Read file bytes via `XFile.readAsBytes()`
3. Call `PresetPackageAnalyzer.analyzePackage(bytes)`
4. Store analysis results in state
5. Show error messages for invalid packages

The scaffolding from this story makes E3.2 straightforward - just implement the stub method and add error handling.
