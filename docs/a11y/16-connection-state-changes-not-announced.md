# Connection State Changes Are Never Announced to Screen Readers

**Severity: High**

## Files Affected

- `lib/ui/widgets/routing/routing_editor_widget.dart` (lines 1231-1260 - connection creation, 292-308 - deletion animation completion)
- `lib/cubit/routing_editor_cubit.dart` (connection create/delete methods)

## Description

When connections are created, deleted, or modified in the routing editor, the only feedback is visual:

1. **Connection created**: A new bezier curve appears on the canvas, potentially with a bus label. No announcement.

2. **Connection deleted via label click**: The connection line and label disappear instantly (with a brief fading label overlay for visual continuity). No announcement.

3. **Connection deleted via port long-press**: A color animation plays (red -> orange -> white -> fade out) for ~900ms, then connections disappear. No announcement.

4. **Connection error**: An error display appears in the top-right corner (`_buildErrorDisplay()`) with auto-dismiss after 5 seconds. The error text is visually rendered but has no `liveRegion` semantics to trigger automatic announcement.

5. **Cascade operations**: When bus reassignment cascades (deleting one connection triggers bus changes on others), these cascading changes happen silently.

6. **Feedback messages**: `_showFeedback()` uses `ScaffoldMessenger.showSnackBar()` which has some basic accessibility support, but `_showError()` uses a custom positioned overlay that doesn't.

## Impact on Blind Users

A blind user performing routing operations (once accessible alternatives are implemented) will receive no confirmation that their actions succeeded or failed. They won't know:
- Whether a connection was actually created
- Whether a connection was deleted
- What bus was assigned to a new connection
- Whether a cascade of changes occurred
- Whether an error prevents the operation

## Recommended Fix

### 1. Announce connection creation

```dart
Future<void> _createConnectionWithErrorHandling(
  RoutingEditorCubit cubit,
  String sourcePortId,
  String targetPortId,
) async {
  try {
    await cubit.createConnection(
      sourcePortId: sourcePortId,
      targetPortId: targetPortId,
    );

    // Announce success
    final sourceName = _getPortDisplayName(sourcePortId);
    final destName = _getPortDisplayName(targetPortId);
    SemanticsService.announce(
      'Connection created from $sourceName to $destName',
      TextDirection.ltr,
    );
  } on ArgumentError catch (e) {
    SemanticsService.announce(
      'Connection failed: ${e.message}',
      TextDirection.ltr,
    );
    _showError('Invalid connection: ${e.message}');
  }
  // ... etc
}
```

### 2. Announce connection deletion

```dart
void _onFadeOutAnimationStatus(AnimationStatus status) {
  if (status == AnimationStatus.completed && _deletingPort != null) {
    final portName = _deletingPort!.name;
    cubit.deleteConnectionsForPort(_deletingPort!.id);

    SemanticsService.announce(
      'All connections on $portName deleted',
      TextDirection.ltr,
    );
    // ... existing cleanup code
  }
}
```

### 3. Make error display a live region

```dart
Widget _buildErrorDisplay() {
  return Positioned(
    top: 8,
    right: 8,
    child: Semantics(
      liveRegion: true,  // Auto-announces when content changes
      child: Container(
        // ... existing error display
      ),
    ),
  );
}
```

### 4. Announce cascade effects

```dart
// In routing_editor_cubit.dart after cascade operations
void _announceCascadeResults(int affectedCount) {
  if (affectedCount > 0) {
    SemanticsService.announce(
      '$affectedCount additional connections updated due to bus reassignment',
      TextDirection.ltr,
    );
  }
}
```
