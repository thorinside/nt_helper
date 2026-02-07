# File Parameter Editor Navigation Buttons Lack Labels

**Severity: High**

## Files Affected
- `lib/ui/widgets/file_parameter_editor.dart` (lines 817-917)

## Description

The `FileParameterEditor` in file selection mode shows a row with:
1. **Previous button** (lines 821-836): An `InkWell` containing a `Container` with `Icons.navigate_before`
2. **Current selection display** (lines 841-861): A `Container` with icon and text
3. **Next button** (lines 866-881): An `InkWell` containing a `Container` with `Icons.navigate_next`
4. **Browse button** (lines 891-915): An `InkWell` with icon and "Browse" text

Issues:
- Previous/Next buttons use `InkWell` wrapping `Container > Icon` with no semantic label - screen reader will only announce the icon name or nothing
- The current selection display has no semantic role - it's a plain `Container` with text
- The Browse button text helps, but has no semantic role as a button
- The text input editor (lines 733-815) uses `GestureDetector` on the non-editing state with no semantic label
- Dev mode indicator (lines 968-993) is a `GestureDetector` with `AnimatedContainer` - no semantic information about dev mode state

## Impact on Blind Users

- Previous/Next navigation for files is very difficult to use - no labels like "Previous file" or "Next file"
- Current file name is readable but has no context ("Kick.wav" with no indication it's the selected sample)
- Browse button works somewhat but is not announced as a button
- Text input mode: the tap-to-edit area is not announced as editable
- Development mode status and toggle are invisible to screen readers

## Recommended Fix

```dart
// Previous button
Semantics(
  button: true,
  label: 'Previous ${widget.rule.mode == FileSelectionMode.folderOnly ? "folder" : "file"}',
  enabled: widget.currentValue > widget.parameterInfo.min,
  child: InkWell(onTap: _decrementValue, ...),
)

// Current selection
Semantics(
  label: 'Selected: ${_currentDisplayValue ?? "No selection"}',
  child: Container(...),
)

// Next button
Semantics(
  button: true,
  label: 'Next ${widget.rule.mode == FileSelectionMode.folderOnly ? "folder" : "file"}',
  enabled: widget.currentValue < widget.parameterInfo.max,
  child: InkWell(onTap: _incrementValue, ...),
)

// Browse button
Semantics(
  button: true,
  label: 'Browse files',
  child: InkWell(onTap: _showFileSelectionDialog, ...),
)
```
