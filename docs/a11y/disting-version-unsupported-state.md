# Disting Version Unsupported State Not Communicated

**Severity: Low**

## Files Affected
- `lib/ui/widgets/disting_version.dart` (lines 21-65)

## Description

The `DistingVersion` widget shows the firmware version number. When the firmware is below the required version, the text color changes to `colorScheme.error` (red). There's a `Tooltip` with "nt_helper requires at least $requiredVersion" but only when contextual help is unavailable.

The tap action (to manage firmware) uses `InkWell` which is accessible, and the `MouseRegion` for contextual help is hover-only (same issue as ContextualHelpBar).

## Impact on Blind Users

- The unsupported firmware state is communicated only via red text color
- Tooltip is present and works with VoiceOver's "read hint" gesture
- Tap to manage firmware works via InkWell
- Minor issue overall since the version text is readable

## Recommended Fix

Add a semantic label that includes the supported status:

```dart
Semantics(
  label: isNotSupported
      ? 'Firmware version $distingVersion - update required (minimum $requiredVersion)'
      : 'Firmware version $distingVersion',
  button: onTap != null,
  hint: onTap != null ? 'Tap to manage firmware updates' : null,
  child: content,
)
```
