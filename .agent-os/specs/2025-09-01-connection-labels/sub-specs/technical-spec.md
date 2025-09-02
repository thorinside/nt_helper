# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-01-connection-labels/spec.md

> Created: 2025-09-01
> Version: 1.0.0

## Technical Requirements

- **Label Rendering System**: Implement text rendering on Flutter CustomPaint canvas at the midpoint of each connection path
- **Bus Identifier Formatting**: Create a bus-to-label converter that maps bus numbers to display strings:
  - Buses 1-12 → "I1" through "I12" (physical inputs)
  - Buses 13-20 → "O1" through "O8" (physical outputs)
  - Buses 21-28 → "A1" through "A8" (auxiliary buses)
  
- **Path Midpoint Calculation**: Implement algorithm to find the center point of curved Bezier paths used for connection rendering
- **Text Styling**: Define consistent text style for labels (size, color, font weight) that ensures readability against various backgrounds
- **State Integration**: Extract bus information from existing Connection model in RoutingEditorState
- **Rendering Performance**: Ensure label painting doesn't impact routing editor performance with many connections

## Approach

### 1. Connection Model Enhancement
Leverage existing `Connection` model in `lib/core/routing/models/connection.dart` to extract bus information. No new data structure needed - bus numbers are already available.

### 2. Label Formatter Utility
Create `BusLabelFormatter` utility class in `lib/core/routing/utils/` with static methods:
```dart
class BusLabelFormatter {
  static String formatBusLabel(int busNumber) {
    if (busNumber >= 1 && busNumber <= 12) {
      return 'I${busNumber}';
    } else if (busNumber >= 13 && busNumber <= 20) {
      return 'O${busNumber - 12}';
    } else if (busNumber >= 21 && busNumber <= 28) {
      return 'A${busNumber - 20}';
    }
    return 'B$busNumber'; // fallback
  }
}
```

### 3. Midpoint Calculation Algorithm
Implement Bezier curve midpoint calculation for curved connection paths:
- For cubic Bezier curves: use parametric equation at t=0.5
- Calculate tangent angle for text rotation alignment
- Handle both straight lines and curved paths

### 4. Custom Painter Enhancement
Modify existing connection painter in `RoutingEditorWidget` to:
- Render connection paths first
- Calculate midpoints for each path
- Paint labels with appropriate styling and rotation
- Use `TextPainter` for precise text rendering

### 5. Text Styling Specification
Define consistent `TextStyle` for connection labels:
- Font size: 10-12pt for readability without clutter
- Font weight: Medium/SemiBold for visibility
- Color: High contrast against background (consider theme-aware colors)
- Optional: Semi-transparent background rectangle for improved readability

## Implementation Files

- `lib/core/routing/utils/bus_label_formatter.dart` - New utility for bus-to-label conversion
- `lib/ui/widgets/routing/routing_editor_widget.dart` - Enhanced CustomPaint implementation
- `lib/ui/painters/connection_painter.dart` - Modified to include label rendering (if separate painter exists)

## External Dependencies

No new external dependencies required. Implementation uses existing Flutter framework capabilities:
- `CustomPaint` and `CustomPainter` for canvas rendering
- `TextPainter` for text rendering
- Existing routing framework models and state management