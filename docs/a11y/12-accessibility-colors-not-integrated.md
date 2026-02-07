# accessibility_colors.dart Exists But Is Not Used for Screen Reader Support

**Severity: Medium**

## Files Affected

- `lib/ui/widgets/routing/accessibility_colors.dart` (entire file)
- `lib/ui/widgets/routing/connection_painter.dart` (color logic at lines 374-458)
- `lib/ui/widgets/routing/port_widget.dart` (color logic at lines 362-405)

## Description

The codebase includes an `AccessibilityColors` helper class that provides:
- WCAG contrast ratio calculation
- Methods to check AA/AAA compliance
- Automatic color adjustment to meet contrast requirements
- A factory method `fromColorScheme()` that produces `AccessibleRoutingColors`

This is a **good foundation** for visual accessibility (color blindness, low vision). However, reviewing the codebase reveals:

1. **Not imported by any widget**: Searching for usage of `AccessibilityColors` or `AccessibleRoutingColors` shows the class exists but is not referenced by `ConnectionPainter`, `PortWidget`, or any other rendering code. Colors are hard-coded or derived directly from the theme.

2. **ConnectionPainter uses inline colors**: Port type colors are determined by string matching in `_getPortColor()` (line 987-996) with hard-coded `Colors.blue`, `Colors.orange`, `Colors.red`, `Colors.purple`, `Colors.grey`. These are not contrast-checked.

3. **Connection labels use hard-coded black text on white**: The label rendering (lines 715-718) uses `Colors.black` for text and `Colors.white` for background, which is good contrast but doesn't adapt to themes.

4. **No non-color differentiators**: The routing editor relies heavily on color to distinguish between:
   - Audio (blue) vs CV (orange) vs Gate (red) vs Clock (purple) ports
   - Regular (solid) vs Ghost (dashed) vs Invalid (dashed red) vs Partial (dashed) connections
   - Connected (filled) vs Disconnected (outlined) ports
   - Replace mode (blue) vs Add mode (default) connections

   Of these, only Regular vs Ghost/Invalid uses non-color differentiators (dashed lines). Port types are distinguished **only** by color with no shape, pattern, or icon variation.

## Impact on Blind Users

For fully blind users, color distinctions are irrelevant -- they need text-based or semantic information (covered in other findings). However, for **low-vision** users who may use screen magnification with a screen reader:

- Port type colors may be indistinguishable
- Connection states may be hard to differentiate
- Shadow dot indicators on ports may be too small
- The delete animation color progression (red -> orange -> white) won't be perceivable

## Recommended Fix

### 1. Actually use AccessibilityColors in the rendering pipeline

```dart
// In ConnectionPainter constructor or initialization
final accessibleColors = AccessibilityColors.fromColorScheme(theme.colorScheme);

// Use these colors instead of hard-coded values
Color _getPortColor(String portId) {
  if (portId.contains('audio')) return accessibleColors.audioPortColor;
  if (portId.contains('cv')) return accessibleColors.cvPortColor;
  // etc.
}
```

### 2. Add non-color differentiators for port types

```dart
// Different shapes for different port types
Widget _buildPortDotByType(PortType type) {
  switch (type) {
    case PortType.audio:
      return _CirclePort(color: audioColor);    // Circle for audio
    case PortType.cv:
      return _DiamondPort(color: cvColor);      // Diamond for CV
    case PortType.gate:
      return _SquarePort(color: gateColor);     // Square for gate
    case PortType.clock:
      return _TrianglePort(color: clockColor);  // Triangle for clock
  }
}
```

### 3. Add pattern/shape variation to connection lines

Use different dash patterns for different connection states:
- Regular: solid line
- Ghost: long dashes
- Invalid: short dashes (already different)
- Replace mode: dot-dash pattern (not just blue color)
