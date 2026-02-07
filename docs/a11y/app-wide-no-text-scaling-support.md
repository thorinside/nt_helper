# No Text Scaling / Dynamic Type Support

**Severity: High**

**Status: Not yet addressed**

## Files Affected
- All UI files with hardcoded font sizes

## Description

The app contains no usage of `MediaQuery.textScaleFactor` or `TextScaler`, and uses hardcoded `fontSize` values throughout. When a user increases their device's text size setting (common for low-vision users), the app will either:

1. Not scale text at all (if overridden)
2. Scale text but break layouts (if not designed for it)

Flutter's Material widgets generally respect text scaling by default, but any layout that assumes fixed text dimensions will break.

## Impact on Low-Vision Users

- Users who rely on larger text sizes may find the UI unusable
- Parameter names and values may overflow or be clipped
- The routing canvas text will not scale
- Step sequencer step numbers and values are in small fixed-size text

## Recommended Fix

1. Test the app with system text scale set to 1.5x and 2.0x
2. Replace hardcoded `fontSize` values with theme-based text styles (`Theme.of(context).textTheme`)
3. Ensure layouts use flexible sizing that accommodates larger text
4. For constrained spaces (routing node labels, step sequencer), provide text truncation with full text in semantic labels
