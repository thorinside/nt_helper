# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-09-06-interactive-connection-labels/spec.md

> Created: 2025-09-06  
> Updated: 2025-09-06
> Status: Ready for Implementation
> Approach: TDD with minimal invasive changes (~60 lines total)

## Task Breakdown

### Task 1: Add Hover Callbacks to ConnectionData (~5 lines)
- [ ] 1.1 Write unit test for ConnectionData with hover callbacks
- [ ] 1.2 Add `onLabelHover` and `onLabelTap` optional callbacks to ConnectionData class (2 fields)
- [ ] 1.3 Verify test passes

### Task 2: Store Label Bounds in ConnectionPainter (~10 lines)  
- [ ] 2.1 Write test for label bounds storage and hit testing
- [ ] 2.2 Add `Map<String, Rect> _labelBounds = {}` field to ConnectionPainter
- [ ] 2.3 Modify `_drawConnectionLabel()` to store label bounds in map (5 lines)
- [ ] 2.4 Add simple hit test method `_hitTestLabel(Offset point)` (5 lines)
- [ ] 2.5 Verify test passes

### Task 3: Add Hover State to RoutingEditorWidget (~15 lines)
- [ ] 3.1 Write widget test for hover state management
- [ ] 3.2 Add `String? _hoveredConnectionId` field to widget state (1 field)
- [ ] 3.3 Wrap connection canvas with MouseRegion using GhostConnectionTooltip pattern (5 lines)
- [ ] 3.4 Add hover callbacks that update state and call ConnectionData callbacks (5 lines)
- [ ] 3.5 Pass `hoveredConnectionId` to ConnectionPainter constructor (2 lines)
- [ ] 3.6 Verify test passes and hover events work with mouse and stylus

### Task 4: Implement Simple Hover Visual Feedback (~10 lines)
- [ ] 4.1 Write test for hover visual styling changes
- [ ] 4.2 Add `hoveredConnectionId` parameter to ConnectionPainter constructor (1 line)
- [ ] 4.3 Modify `_drawConnectionLabel()` to check hover state and apply styling (5 lines)
- [ ] 4.4 Use existing Paint patterns for border width and color changes (3 lines)
- [ ] 4.5 Verify test passes and visual feedback appears correctly

### Task 5: Add Tap-to-Toggle Using Existing Method (~15 lines)
- [ ] 5.1 Write test for connection label tap and output mode toggle
- [ ] 5.2 Add GestureDetector around connection canvas using existing patterns (5 lines)
- [ ] 5.3 Add connection lookup method to find connection by label tap point (5 lines)
- [ ] 5.4 Call existing `RoutingEditorCubit.setPortOutputMode()` to toggle mode (3 lines)
- [ ] 5.5 Toggle between OutputMode.add (0) and OutputMode.replace (1) (2 lines)
- [ ] 5.6 Verify test passes and mode changes immediately update labels

### Task 6: Integration Testing (~5 lines)
- [ ] 6.1 Write integration test covering hover → tap → mode change flow
- [ ] 6.2 Verify mouse hover, stylus hover, and tap all work correctly
- [ ] 6.3 Run `flutter analyze` to ensure zero warnings
- [ ] 6.4 Verify total code changes stay within ~60 line estimate

## Dependencies

- **Task 1** → Task 2 (ConnectionData callbacks needed for bounds storage)
- **Task 2** → Task 3 (bounds storage needed for hit testing)  
- **Task 3** → Task 4 (hover state needed for visual feedback)
- **Task 4** → Task 5 (visual feedback should work before adding tap functionality)
- **All tasks** → Task 6 (integration testing requires all components)

## Implementation Notes

- **Reuse Patterns**: Copy exact MouseRegion pattern from `ghost_connection_tooltip.dart:151-153`
- **Existing Methods**: Use `RoutingEditorCubit.setPortOutputMode()` - already implemented
- **Simple Styling**: Modify existing Paint objects with `isHovered ? newValue : defaultValue`
- **Test Strategy**: Start with unit tests, build to integration tests
- **Code Estimate**: Each task should add roughly 5-15 lines, totaling ~60 lines