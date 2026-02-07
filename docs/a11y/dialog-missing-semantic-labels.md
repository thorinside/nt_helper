# Dialogs Missing Semantic Labels and Announcements

**Severity: High**

**Status: Addressed (2026-02-06)** — Dialog titles wrapped in Semantics with header: true

## Files Affected

- `lib/ui/widgets/rename_preset_dialog.dart` (lines 39-50)
- `lib/ui/widgets/rename_slot_dialog.dart` (lines 39-50)
- `lib/ui/widgets/plugin_selection_dialog.dart` (lines 86-244)
- `lib/ui/widgets/template_preview_dialog.dart` (lines 82-183, 185-209, 225-254)
- `lib/ui/widgets/preset_browser_dialog.dart` (lines 52-253)
- `lib/ui/widgets/preset_package_dialog.dart` (lines 138-188)
- `lib/ui/widgets/package_install_dialog.dart` (lines 74-128)
- `lib/ui/widgets/algorithm_export_dialog.dart` (lines 111-308)
- `lib/ui/widgets/debug_metadata_export_dialog.dart` (lines 122-382)
- `lib/ui/reset_outputs_dialog.dart` (lines 14-65)
- `lib/ui/metadata_sync/metadata_sync_page.dart` (lines 627-687, various confirmation dialogs)

## Description

Most `AlertDialog` widgets across the app lack a `semanticsLabel` property. While `AlertDialog.title` provides a visual title, the `semanticsLabel` property is specifically used by screen readers to announce the dialog's purpose when it opens. Without it, VoiceOver/TalkBack may announce the dialog generically or read the title text without proper dialog context.

Additionally, none of the dialogs use `Semantics` wrappers to group the dialog content into a coherent accessible unit.

## Impact on Blind Users

- When a dialog opens, VoiceOver/TalkBack may not clearly announce what the dialog is for
- Users may not understand they have entered a modal context
- The `AlertDialog` title is read, but without the "alert" or "dialog" role announcement that `semanticsLabel` ensures on some platforms
- Multi-state dialogs (like TemplatePreviewDialog which switches between preview/loading/error states) provide no announcement when transitioning between states

## Recommended Fix

Add `semanticsLabel` to all `AlertDialog` instances:

```dart
AlertDialog(
  semanticsLabel: 'Rename Preset Dialog',
  title: const Text('Rename Preset'),
  // ...
)
```

For multi-state dialogs like `TemplatePreviewDialog`, wrap state transitions with `Semantics` and use `SemanticsService.announce()`:

```dart
import 'package:flutter/semantics.dart';

// When transitioning to loading state:
SemanticsService.announce(
  'Injecting template, please wait',
  TextDirection.ltr,
);

// When transitioning to error state:
SemanticsService.announce(
  'Injection failed: $_errorMessage',
  TextDirection.ltr,
);
```
