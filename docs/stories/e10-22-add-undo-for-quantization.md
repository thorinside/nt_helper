# Story 10.22: Add Undo for Quantization Operations

Status: done
Created: 2025-11-24
Completed: 2025-11-24

## Story

As a **Step Sequencer user**,
I want **to undo quantization operations**,
So that **I can experiment freely without fear of losing my pitch data**.

## Background

Previously, "Quantize All" showed a scary confirmation dialog warning "This action cannot be undone." But there's no technical reason why quantization can't be undone - we can store the old values and restore them.

## Acceptance Criteria

### AC1: Add Undo History Stack

**Implementation:**
- Create undo history data structure with `_UndoHistoryEntry` and `_ParameterChange`
- Store list of parameter changes (parameter number, old value, new value)
- Limit history to 10 entries (FIFO when full)
- Track timestamp for each entry

### AC2: Store State Before Quantize Operations

**When "Quantize All" is executed:**
- Capture current pitch values before quantization
- Store list of changes (only steps that actually changed)
- Add entry to undo history
- Skip storing if no values changed

### AC3: Add Undo Button to Quantize Controls

**UI placement:**
- Add undo icon button next to "Quantize All" button
- Show tooltip: "Undo last quantize"
- Theme-aware colors (adapts to dark/light mode)
- Enabled state indicated by color (teal when enabled, grey when disabled)

### AC4: Implement Undo Functionality

**Undo behavior:**
- Pop most recent entry from undo history
- Restore all old values from that entry
- Update hardware parameters
- Show progress indicator during undo
- Show success snackbar with number of changes undone

### AC5: Remove Confirmation Dialog

**Before:** "Quantize All" showed scary dialog about action being undone
**After:** "Quantize All" executes immediately, user can undo if needed

**Better UX:** Encourages experimentation, reduces friction

### AC6: Keep Scale/Root Selectors Always Enabled

**Independent controls:**
- Scale dropdown always enabled
- Root note dropdown always enabled
- "Quantize All" button always enabled
- "Snap to Scale" checkbox only controls automatic snapping during editing
- All controls work independently

## Implementation Summary

**Data Structures:**
```dart
class _UndoHistoryEntry {
  final List<_ParameterChange> changes;
  final DateTime timestamp;
}

class _ParameterChange {
  final int parameterNumber;
  final int oldValue;
  final int newValue;
}
```

**Undo History Management:**
- Maximum 10 entries in history
- FIFO when limit exceeded
- Only stores actual changes (not no-ops)

**UI Changes:**
- Added undo icon button to quantize controls
- Removed confirmation dialog
- Theme-aware disabled/enabled colors
- Tooltip for discoverability

**Files Modified:**
- `lib/ui/step_sequencer_view.dart` - Added undo stack, undo logic, removed dialog
- `lib/ui/widgets/step_sequencer/quantize_controls.dart` - Added undo button, removed confirmation dialog, made controls always enabled

## Testing

**Manual testing:**
- ✅ Click "Quantize All" - executes immediately without dialog
- ✅ Undo button enabled after quantize
- ✅ Click undo - restores old pitch values
- ✅ Undo button disabled when history empty
- ✅ Scale/root selectors work with checkbox unchecked
- ✅ Theme colors adapt to dark/light mode
- ✅ No snackbar notifications
- ✅ No spinner during undo
- ✅ No runtime errors

## Benefits

**Better UX:**
- No scary confirmation dialog
- Encourages experimentation
- Easy to try different scales and undo
- Standard undo pattern familiar to users

**More Flexible:**
- Scale/root controls always available
- Can set up scale, work chromatic, then manually quantize
- Checkbox only controls real-time snapping

## References

- Epic: [docs/epics/epic-10.md](../epics/epic-10.md)
- Related: [e10-20-reposition-quantize-controls-per-design.md](e10-20-reposition-quantize-controls-per-design.md)
- Related: [e10-4-scale-quantization.md](e10-4-scale-quantization.md)

---

## Change Log

**2025-11-24:** Story created and completed
- Implemented undo stack for quantization operations (max 10 entries)
- Removed confirmation dialog
- Added undo button with theme-aware colors
- Made scale/root controls independent of snap checkbox
- Removed all snackbar notifications per user request
- Removed spinner dialog during undo per user request
- All acceptance criteria met
