# Floating Overlay Widgets (Screenshot, Video, Draggable) Are Inaccessible

**Severity: High**

## Files Affected

- `lib/ui/widgets/floating_screenshot_overlay.dart` (lines 71-155)
- `lib/ui/widgets/floating_video_overlay.dart` (lines 89-277)
- `lib/ui/widgets/draggable_resizable_overlay.dart` (lines 178-283)

## Description

The app has floating overlay widgets for viewing the Disting NT's screen (screenshot) and video feed. These overlays are implemented using `OverlayEntry` and wrapped in `DraggableResizableOverlay` which provides drag-to-move and drag-to-resize functionality.

### Issues:

#### 1. No semantic container or role for overlays
The `DraggableResizableOverlay` renders as a `Positioned` widget inside a `Stack` with no `Semantics` wrapper. A screen reader user won't know an overlay is present, what it shows, or how to interact with it.

#### 2. Close button has no semantic label
The close button (lines 221-246 in `draggable_resizable_overlay.dart`) is a `GestureDetector` wrapping a `Container` with an `Icon`. It has no `Semantics`, tooltip, or accessible label:

```dart
GestureDetector(
  onTap: () { widget.overlayEntry.remove(); },
  child: Container(
    width: 24,
    height: 24,
    // ... decoration
    child: const Icon(Icons.close, size: 16, color: Colors.white),
  ),
)
```

#### 3. Resize handle has no semantic label
The resize handle (lines 249-277) is similarly a `GestureDetector` with no semantic information. Resizing is drag-only with no keyboard alternative.

#### 4. Screenshot image not described
The screenshot `Image.memory` widget (line 115-119) has no semantic label describing what it shows. The `FloatingVideoOverlay` does use `excludeFromSemantics: true` on its `Image.memory` (line 177), which correctly excludes a rapidly-updating video frame, but provides no alternative description.

#### 5. Copy-to-clipboard via long press is undiscoverable
Both overlays support long-press to copy the current frame to clipboard, but this gesture is not announced or discoverable via screen reader.

#### 6. Controls auto-hide after 10 seconds
The `DraggableResizableOverlay` hides its close and resize controls after `controlsHideDelay` (10 seconds). When hidden, the `AnimatedOpacity` makes them visually invisible but they remain in the widget tree. A screen reader user might still encounter invisible controls, or might lose access when controls hide.

## Impact on Blind Users

A blind user:
- Won't know an overlay is present on screen
- Can't close an overlay they accidentally opened
- Can't copy screenshot/video content to clipboard
- May encounter unlabeled interactive regions
- Can't resize or reposition overlays

## Recommended Fix

### 1. Add semantic wrapper to DraggableResizableOverlay

```dart
return Positioned(
  left: _x,
  top: _y,
  child: Semantics(
    label: 'Floating overlay',
    container: true,
    child: SizedBox(
      width: _width,
      height: _height,
      child: // ... existing Stack
    ),
  ),
);
```

### 2. Make close button accessible

```dart
Semantics(
  label: 'Close overlay',
  button: true,
  child: GestureDetector(
    onTap: () { widget.overlayEntry.remove(); },
    child: // ... existing Container with Icon
  ),
)
```

Or better, use an `IconButton` with tooltip:

```dart
IconButton(
  icon: const Icon(Icons.close, size: 16, color: Colors.white),
  tooltip: 'Close overlay',
  onPressed: () { widget.overlayEntry.remove(); },
)
```

### 3. Add semantic description for screenshot

```dart
Semantics(
  label: 'Disting NT screen capture. Long press to copy to clipboard.',
  image: true,
  child: Image.memory(screenshot!, fit: BoxFit.cover, gaplessPlayback: true),
)
```

### 4. Add custom semantic action for copy

```dart
Semantics(
  customSemanticsActions: {
    CustomSemanticsAction(label: 'Copy to clipboard'): _copyToClipboard,
  },
  child: // image widget
)
```

### 5. Don't hide controls for screen reader users

```dart
final showControls = _controlsVisible ||
    _isResizing ||
    _isDragging ||
    MediaQuery.of(context).accessibleNavigation;  // Always show for screen readers
```
