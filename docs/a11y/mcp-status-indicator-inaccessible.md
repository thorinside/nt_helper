# MCP Status Indicator Completely Inaccessible

**Severity: Critical**

## Files Affected

- `lib/ui/widgets/mcp_status_indicator.dart` (lines 52-134)

## Description

The `McpStatusIndicator` is a small colored circle (16x16 pixels) that uses `GestureDetector` for tap handling instead of a proper button widget. It conveys server status purely through color (green=running, red=error, grey=disabled). While it has a `Tooltip`, this has several accessibility problems:

1. **No semantic role**: `GestureDetector` does not expose itself as a button to the accessibility tree. Screen readers will not announce it as an interactive element.

2. **No accessible label**: The colored circle and inner specular highlight `Container` widgets have no `Semantics` wrapper. VoiceOver will either skip this widget entirely or announce it as "Image" or similar.

3. **Color-only status communication**: Status is conveyed solely through green/red/grey colors with no text alternative beyond the tooltip (which is not reliably announced by screen readers on tap).

4. **Tiny touch target**: The 16x16 pixel size is well below the minimum 48x48 recommended touch target for accessibility.

## Impact on Blind Users

- VoiceOver users will likely not be able to find or interact with this control at all
- Even if found, there is no semantic role or label to indicate it is a toggle button for the MCP server
- TalkBack users on Android would need to explore the screen to find this very small target
- Status changes (running/error/stopped) are not announced

## Recommended Fix

Replace `GestureDetector` + `Container` with a semantic button:

```dart
Semantics(
  button: true,
  label: isRunning
      ? 'MCP server running. Double tap to disable'
      : hasError
          ? 'MCP server error. Double tap to retry'
          : 'MCP server disabled. Double tap to enable',
  child: IconButton(
    iconSize: 16,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    tooltip: tooltip,
    onPressed: () async { /* existing tap handler */ },
    icon: Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(/* existing gradient */),
      ),
    ),
  ),
)
```

Or at minimum, wrap the existing `GestureDetector` in `Semantics`:

```dart
Semantics(
  button: true,
  label: tooltip, // reuse the tooltip text
  child: GestureDetector(/* existing code */),
)
```
