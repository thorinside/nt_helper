# Story E3.6 Context: Verify Cross-Platform Compatibility

**Epic:** 3 - Drag-and-Drop Preset Package Installation
**Story ID:** e3-6-verify-cross-platform-compatibility
**Generated:** 2025-10-28

---

## Overview

This story verifies that the drag-and-drop feature works correctly on all platforms. The platform check was implemented in Story E3.1, so this is **verification-only** - no new code is expected unless issues are discovered.

---

## Platform Architecture

### Platform Check Pattern (From E3.1)

The drag-and-drop functionality is conditionally wrapped based on platform:

```dart
import 'package:flutter/foundation.dart';
import 'package:desktop_drop/desktop_drop.dart';

// In PresetBrowserDialog build method:
Widget content = AlertDialog(...);

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
```

### Why This Works Cross-Platform

1. **No Conditional Imports**: `desktop_drop` package can be imported on all platforms
2. **Runtime Check**: Platform detection happens at runtime, not compile-time
3. **Widget Wrapper**: Non-desktop platforms simply return the unwrapped `content` widget
4. **Zero Impact**: Mobile/web builds include the library but never instantiate `DropTarget`

---

## Testing Matrix

### Desktop Platforms (Drag-Drop Enabled)

#### macOS Testing
**Primary Test Platform**

```bash
# Build release version
flutter build macos --release

# Run debug version for testing
flutter run -d macos
```

**Checklist:**
- [ ] Build succeeds without warnings
- [ ] App launches successfully
- [ ] Browse Presets dialog opens
- [ ] Drag-drop zone visible (blue overlay on hover)
- [ ] Can drag .zip file over dialog
- [ ] Visual feedback appears (blue overlay)
- [ ] Drop triggers package analysis
- [ ] PackageInstallDialog appears
- [ ] Installation completes successfully
- [ ] No console errors or warnings

#### Windows Testing (If Available)

```bash
# Build release version
flutter build windows --release

# Run debug version for testing
flutter run -d windows
```

**Checklist:**
- [ ] Build succeeds without warnings
- [ ] App launches successfully
- [ ] Browse Presets dialog opens
- [ ] Drag-drop functionality works
- [ ] Visual feedback appears
- [ ] Installation completes successfully

#### Linux Testing (If Available)

```bash
# Build release version
flutter build linux --release

# Run debug version for testing
flutter run -d linux
```

**Checklist:**
- [ ] Build succeeds without warnings
- [ ] App launches successfully
- [ ] Browse Presets dialog opens
- [ ] Drag-drop functionality works
- [ ] Visual feedback appears
- [ ] Installation completes successfully

---

### Mobile Platforms (Drag-Drop Disabled)

#### Android Testing

```bash
# Build release APK
flutter build apk --release

# Run debug version on emulator/device
flutter run -d <device-id>
```

**Checklist:**
- [ ] Build succeeds without warnings
- [ ] App installs on device/emulator
- [ ] App launches successfully
- [ ] Navigate to Browse Presets dialog
- [ ] Dialog opens without errors
- [ ] **No drag-drop UI elements visible**
- [ ] Dialog functions normally (preset browsing)
- [ ] No runtime exceptions
- [ ] No console errors related to drag-drop

#### iOS Testing (If Available)

```bash
# Build for iOS
flutter build ios --release

# Run on simulator/device
flutter run -d <device-id>
```

**Checklist:**
- [ ] Build succeeds without warnings
- [ ] App launches successfully
- [ ] Browse Presets dialog opens
- [ ] **No drag-drop UI elements visible**
- [ ] Dialog functions normally
- [ ] No runtime exceptions

---

### Web Platform (Drag-Drop Disabled)

```bash
# Build for web
flutter build web --release

# Run web version
flutter run -d chrome
```

**Checklist:**
- [ ] Build succeeds without warnings
- [ ] App loads in browser
- [ ] Browse Presets dialog opens
- [ ] **No drag-drop UI elements visible**
- [ ] Dialog functions normally
- [ ] No console errors
- [ ] No JavaScript exceptions

---

## Build Commands Reference

### All Platform Builds

```bash
# Desktop
flutter build macos --release
flutter build windows --release
flutter build linux --release

# Mobile
flutter build apk --release
flutter build ios --release

# Web
flutter build web --release
```

### Quick Verification (All Platforms)

```bash
# Analyze code (must pass)
flutter analyze

# Run tests
flutter test

# Check for platform-specific issues
flutter doctor -v
```

---

## Platform Detection Code Review

### Verify Implementation in PresetBrowserDialog

**File:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/preset_browser_dialog.dart`

**Required Imports:**
```dart
import 'package:flutter/foundation.dart'; // for kIsWeb, defaultTargetPlatform
import 'package:desktop_drop/desktop_drop.dart'; // for DropTarget
```

**State Variables:**
```dart
class _PresetBrowserDialogState extends State<PresetBrowserDialog> {
  bool _isDragOver = false;
  bool _isInstallingPackage = false;
  // ...
}
```

**Build Method Structure:**
```dart
@override
Widget build(BuildContext context) {
  // Build content first (works on all platforms)
  Widget content = AlertDialog(
    title: ...,
    content: ...,
    actions: ...,
  );

  // Conditionally wrap with drag-drop (desktop only)
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

---

## Expected Behavior by Platform

### Desktop (Windows, macOS, Linux)
- ✅ Drag-drop enabled
- ✅ Visual feedback on hover
- ✅ Full package installation flow
- ✅ All overlays visible
- ✅ Complete feature set

### Mobile (Android, iOS)
- ❌ No drag-drop UI
- ✅ Dialog works normally
- ✅ Preset browsing functional
- ✅ No runtime errors
- ℹ️ Users must transfer packages via other means

### Web
- ❌ No drag-drop UI
- ✅ Dialog works normally
- ✅ Preset browsing functional
- ✅ No runtime errors
- ℹ️ Users must transfer packages via other means

---

## Common Issues and Solutions

### Issue 1: Build Fails on Mobile

**Symptom:** Build errors mentioning `desktop_drop` on Android/iOS

**Diagnosis:**
```bash
flutter clean
flutter pub get
flutter build apk
```

**Solution:** Should not occur - `desktop_drop` supports all platforms. If it does:
1. Check `pubspec.yaml` for correct version: `desktop_drop: ^0.4.4`
2. Ensure no conditional imports are used
3. Verify platform check is correct

### Issue 2: Runtime Error on Mobile

**Symptom:** App crashes when opening Browse Presets dialog on mobile

**Diagnosis:** Check if platform check is missing or incorrect

**Solution:** Ensure platform check returns unwrapped `content` on mobile:
```dart
if (!kIsWeb && (defaultTargetPlatform == ...)) {
  return DropTarget(...);
}
return content; // <-- Must return unwrapped content
```

### Issue 3: Drag-Drop Not Working on Desktop

**Symptom:** No visual feedback when dragging files on macOS/Windows/Linux

**Diagnosis:** Platform check may be excluding desktop platforms

**Solution:** Verify platform check includes desktop platforms:
```dart
if (!kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux)) {
  // ...
}
```

### Issue 4: `flutter analyze` Warnings

**Symptom:** Warnings about unused imports or unreachable code

**Diagnosis:** Check for conditional imports (should not exist)

**Solution:** Use runtime checks only, no conditional imports:
```dart
// ✅ Correct - import unconditionally
import 'package:desktop_drop/desktop_drop.dart';

// ❌ Wrong - don't use conditional imports
// import 'package:desktop_drop/desktop_drop.dart' if (dart.library.io) '...';
```

---

## Verification Checklist

### Code Quality
- [ ] `flutter analyze` passes with zero warnings
- [ ] No conditional imports used
- [ ] Platform check uses `defaultTargetPlatform` from `foundation.dart`
- [ ] State variables (`_isDragOver`, `_isInstallingPackage`) properly initialized

### Desktop Functionality
- [ ] macOS build succeeds
- [ ] Drag-drop works on macOS
- [ ] Visual feedback appears
- [ ] Installation completes
- [ ] Windows build succeeds (if tested)
- [ ] Linux build succeeds (if tested)

### Mobile Compatibility
- [ ] Android APK build succeeds
- [ ] App runs on Android without errors
- [ ] Browse Presets dialog opens
- [ ] No drag-drop UI elements visible
- [ ] iOS build succeeds (if tested)

### Web Compatibility
- [ ] Web build succeeds
- [ ] App loads in browser
- [ ] Browse Presets dialog opens
- [ ] No drag-drop UI elements visible
- [ ] No JavaScript errors

---

## Testing Strategy

### Minimum Required Tests

**Mandatory:**
1. ✅ macOS build and functional test (primary platform)
2. ✅ Android APK build and runtime test (verify no errors)
3. ✅ `flutter analyze` passes

**Recommended if Available:**
4. Windows build and test
5. Linux build and test
6. iOS build and test
7. Web build and test

### Test Execution Order

1. **Code Analysis First:**
   ```bash
   flutter analyze
   ```
   Must pass before proceeding.

2. **Primary Platform (macOS):**
   ```bash
   flutter run -d macos
   ```
   Test complete drag-drop flow.

3. **Mobile Platform (Android):**
   ```bash
   flutter run -d <android-device>
   ```
   Verify dialog works without drag-drop.

4. **Additional Platforms (Optional):**
   Test Windows, Linux, iOS, Web if available.

---

## Documentation

### End-to-End Test Report Template

```markdown
## Cross-Platform Verification Report

**Date:** YYYY-MM-DD
**Tester:** [Name]
**Branch:** [Branch name]
**Commit:** [Commit hash]

### Code Quality
- [ ] `flutter analyze`: PASS/FAIL
- [ ] `flutter test`: PASS/FAIL

### Desktop Platforms
#### macOS
- [ ] Build: PASS/FAIL
- [ ] Drag-drop: WORKS/BROKEN
- [ ] Installation: SUCCESS/FAILED
- [ ] Notes: [Any issues or observations]

#### Windows (if tested)
- [ ] Build: PASS/FAIL
- [ ] Drag-drop: WORKS/BROKEN
- [ ] Notes: [Any issues or observations]

#### Linux (if tested)
- [ ] Build: PASS/FAIL
- [ ] Drag-drop: WORKS/BROKEN
- [ ] Notes: [Any issues or observations]

### Mobile Platforms
#### Android
- [ ] Build: PASS/FAIL
- [ ] Runtime: NO ERRORS/ERRORS FOUND
- [ ] Dialog: WORKS/BROKEN
- [ ] Notes: [Any issues or observations]

#### iOS (if tested)
- [ ] Build: PASS/FAIL
- [ ] Runtime: NO ERRORS/ERRORS FOUND
- [ ] Notes: [Any issues or observations]

### Web Platform (if tested)
- [ ] Build: PASS/FAIL
- [ ] Runtime: NO ERRORS/ERRORS FOUND
- [ ] Notes: [Any issues or observations]

### Overall Result
- [ ] PASS: All platforms work as expected
- [ ] FAIL: Issues found (describe below)

### Issues Found
[Describe any issues]

### Recommendations
[Any recommendations for improvements]
```

---

## Definition of Done

- [ ] Desktop builds succeed (macOS confirmed)
- [ ] Mobile builds succeed (Android confirmed)
- [ ] Drag-drop UI only appears on desktop
- [ ] No runtime errors on any tested platform
- [ ] Browse Presets dialog works on all tested platforms
- [ ] `flutter analyze` passes with zero warnings
- [ ] End-to-end manual test on macOS completed successfully
- [ ] Test report documented

---

## References

- **Story File:** `/Users/nealsanche/nosuch/nt_helper/docs/stories/e3-6-verify-cross-platform-compatibility.md`
- **Epic Context:** `/Users/nealsanche/nosuch/nt_helper/docs/epic-3-context.md`
- **PresetBrowserDialog:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/preset_browser_dialog.dart`
- **Reference Implementations:**
  - GalleryScreen: `/Users/nealsanche/nosuch/nt_helper/lib/ui/gallery_screen.dart`
  - FileParameterEditor: `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/file_parameter_editor.dart`
  - LoadPresetDialog: `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/load_preset_dialog.dart`
- **Previous Story:** E3.5 - Execute Package Installation
- **Next Story:** E3.7 - Remove Obsolete LoadPresetDialog
