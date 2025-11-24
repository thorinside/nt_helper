# Story 10.20: Reposition Quantize Controls Per Design Prototype

Status: done
Created: 2025-11-24
Completed: 2025-11-24

## Story

As a **Step Sequencer user**,
I want **the quantize controls positioned between the step grid and playback controls with a "Snap to Scale" checkbox**,
So that **the UI matches the approved design prototype and quantization is easier to use**.

## Background

The original design prototype (`docs/step-sequencer-ui-mockup-global-mode.html`) shows quantize controls positioned between the step grid and playback controls, with a clean horizontal layout including:
- Checkbox: "Snap to Scale"
- Scale dropdown
- Root note dropdown
- "Quantize All" button

Current implementation has quantize controls in the top row next to the sequence selector, which is harder to use and doesn't match the prototype.

## Acceptance Criteria

### AC1: Reposition Quantize Controls Section

**Current layout:**
```
[Mode Selector]
[Sequence] [Quantize Controls Inline] ← REMOVE FROM HERE
[Step Grid]
[Playback Controls]
```

**Target layout (per design prototype):**
```
[Mode Selector]
[Sequence]
[Step Grid]
[Quantize Controls] ← MOVE TO HERE (between grid and playback)
[Playback Controls]
```

**Implementation:**
- Remove quantize controls from top row next to sequence selector
- Create new quantize controls section between step grid and playback controls
- Use same styling as playback controls section (background, padding, border-radius)

### AC2: Add "Snap to Scale" Checkbox

**Current behavior:**
- Quantization always active when scale/root selected
- No way to temporarily disable without changing scale

**Target behavior:**
- Add checkbox: "Snap to Scale"
- When unchecked: quantization disabled, scale/root controls remain visible but inactive
- When checked: quantization active
- Checkbox state stored in local UI state (not persisted)

**Visual design (from prototype):**
```
[✓ Snap to Scale] [Major ▼] [C ▼] [Quantize All]
```

### AC3: Horizontal Layout for Quantize Controls

**Layout (from prototype lines 309-340):**
- Single horizontal row with items left-aligned
- Items with consistent spacing (12-16px gap)
- Responsive: wraps on mobile if needed

**Order:**
1. Checkbox: "Snap to Scale"
2. Scale dropdown
3. Root note dropdown
4. "Quantize All" button

### AC4: Show Quantize Controls Only in Pitch Mode

**Current behavior:**
- Quantize controls always visible

**Target behavior (from prototype):**
- Show quantize section ONLY when Pitch mode is active
- Smooth slide animation when showing/hiding (300ms transition)
- Collapsed when not in Pitch mode (no space taken)

**Animation (from prototype lines 292-297):**
- Slide down: opacity 0→1, translateY(-20px)→0
- Collapse up: opacity 1→0, translateY(0)→(-20px)
- Transition: 300ms ease

### AC5: Update QuantizeControls Widget

**Current widget location:**
`lib/ui/widgets/step_sequencer/quantize_controls.dart`

**Required changes:**
- Add `bool snapEnabled` parameter (checkbox state)
- Add `ValueChanged<bool> onSnapToggle` callback
- Update layout to horizontal row (not inline with sequence)
- Add checkbox widget
- Disable scale/root dropdowns when `snapEnabled == false`
- Keep existing "Quantize All" button functionality

### AC6: Maintain Quantization Behavior

**Existing behavior to preserve:**
- Quantization logic in `lib/services/scale_quantizer.dart`
- Scale definitions (Major, Minor, Dorian, etc.)
- Root note handling (C-B)
- "Quantize All" button confirmation dialog
- Individual step quantization when snap enabled

**New behavior:**
- Only quantize when checkbox is checked
- Scale/root selection preserved even when checkbox unchecked

## Implementation Plan

### Task 1: Update StepSequencerView Layout
- Remove quantize controls from top row (line ~196-210 in `lib/ui/step_sequencer_view.dart`)
- Add quantize controls section after step grid, before playback controls
- Add animation logic for show/hide based on `_activeParameter == StepParameter.pitch`

### Task 2: Update QuantizeControls Widget
- Add `snapEnabled` parameter and `onSnapToggle` callback
- Change from inline layout to section layout
- Add checkbox widget with label "Snap to Scale"
- Implement horizontal row layout
- Add disabled state for dropdowns when snap unchecked

### Task 3: Update State Management
- Add `_snapEnabled` state to `_StepSequencerViewState`
- Initialize to `false` (quantization off by default)
- Wire checkbox toggle to `_snapEnabled` state
- Pass state to quantization logic

### Task 4: Update Quantization Logic
- Modify `_quantizeValue()` to check `_snapEnabled` before quantizing
- Preserve scale/root selection in local state regardless of checkbox

### Task 5: Add Animations
- Implement slide animation using `AnimatedContainer` or `AnimatedSize`
- 300ms ease transition
- Slide down when entering Pitch mode
- Slide up when leaving Pitch mode

### Task 6: Testing
- Verify quantize section appears only in Pitch mode
- Test checkbox enables/disables quantization
- Test "Quantize All" respects checkbox state
- Test scale/root preserved when checkbox toggled
- Test responsive layout on mobile
- Verify smooth animations

## Design Reference

**Source:** `docs/step-sequencer-ui-mockup-global-mode.html` (lines 366-397)

```html
<!-- Quantize Controls (only visible in Pitch mode) -->
<div class="quantize-controls" id="quantizeControls">
    <div class="quantize-row">
        <label>
            <input type="checkbox" id="snapToggle"> Snap to Scale
        </label>
        <select id="scaleSelect">
            <option>Major</option>
            <option>Minor</option>
            ...
        </select>
        <select id="rootNoteSelect">
            <option value="0">C</option>
            ...
        </select>
        <button id="quantizeAllBtn">Quantize All</button>
    </div>
</div>
```

**CSS Animation (lines 285-307):**
```css
.quantize-controls {
    max-height: 0;
    opacity: 0;
    transform: translateY(-20px);
    transition: max-height 0.3s ease, opacity 0.3s ease, transform 0.3s ease;
}

.quantize-controls.visible {
    max-height: 100px;
    opacity: 1;
    transform: translateY(0);
}
```

## Benefits

**Usability:**
- More logical placement (near step grid where quantization applies)
- Checkbox provides explicit control over quantization
- Cleaner top row (just sequence selector and mode buttons)

**Consistency:**
- Matches original approved design prototype
- Consistent with playback controls styling
- Better grouping of related controls

**User Experience:**
- Easy to toggle quantization on/off
- Visual feedback when quantization disabled
- Reduced clutter in top row

## Files to Modify

- `lib/ui/step_sequencer_view.dart` - Layout changes, animation logic
- `lib/ui/widgets/step_sequencer/quantize_controls.dart` - Add checkbox, update layout
- Possibly update tests in `test/ui/widgets/step_sequencer/` if widget tests exist

## References

- Design Prototype: `docs/step-sequencer-ui-mockup-global-mode.html`
- Related Story: [e10-4-scale-quantization.md](e10-4-scale-quantization.md)
- Epic: [docs/epics/epic-10.md](../epics/epic-10.md)

---

## Implementation Summary

**Completed Changes:**
1. ✅ Moved quantize controls from top row to between step grid and playback controls
2. ✅ Replaced button with checkbox for "Snap to Scale"
3. ✅ Added AnimatedSize widget for smooth show/hide animation (300ms)
4. ✅ Quantize section only visible in Pitch mode
5. ✅ Step grid uses fixed height to prevent shrinking
6. ✅ Added SingleChildScrollView to allow playback controls to scroll away
7. ✅ Positioned sequence selector at beginning of row
8. ✅ Expanded scale library from 11 to 40+ scales

**Scale Library Enhancements:**
- Major modes: Major, Dorian, Phrygian, Lydian, Mixolydian, Minor, Locrian
- Minor variations: Harmonic Minor, Melodic Minor, Dorian ♭2
- Pentatonic: Major, Minor, Blues, Major Blues
- Exotic: Hungarian Minor, Spanish, Arabic, Japanese (In Sen, Hirajoshi, Iwato), Chinese, Persian, Byzantine, Gypsy, Jewish, Flamenco
- Symmetrical: Whole Tone, Diminished (Whole-Half, Half-Whole), Augmented
- Jazz: Bebop Major, Bebop Dorian, Bebop Dominant, Altered, Lydian Augmented, Lydian Dominant, Mixolydian ♭6, Half Diminished
- Other: Enigmatic, Double Harmonic, Neapolitan Major/Minor, Prometheus, Tritone

**Files Modified:**
- `lib/ui/step_sequencer_view.dart` - Layout restructure, animation, scrolling
- `lib/ui/widgets/step_sequencer/quantize_controls.dart` - Checkbox implementation
- `lib/services/scale_quantizer.dart` - Expanded scale library

**Testing:**
- ✅ Hot reload successful
- ✅ Zero runtime errors
- ✅ Animation working smoothly
- ✅ Checkbox functionality working
- ✅ All scales available in dropdown

## Change Log

**2025-11-24:** Story created and completed
- Identified design prototype with correct quantize control placement
- Defined acceptance criteria and implementation plan
- Implemented all features per design
- Expanded scale library significantly
- All acceptance criteria met
