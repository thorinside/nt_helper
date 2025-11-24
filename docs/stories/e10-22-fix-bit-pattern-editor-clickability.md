# Story e10.22: Fix Bit Pattern Editor Clickability Regression

**Epic:** 10 - Visual Step Sequencer UI Widget
**Status:** done
**Created:** 2025-11-24
**Priority:** HIGH
**Sprint Change Proposal:** docs/sprint-change-proposal-2025-11-23.md

---

## Story

As a **Step Sequencer user**,
I want **to be able to click on individual bits in the bit pattern editor**,
So that **I can set the bit patterns and ties correctly**.

---

## Context

The bit pattern editor was previously working (Story e10.10.1), but has regressed. The user reports "I can't click on individual bits to make them turn on and off."
The editor should allow clicking on bits based on the number of divisions (up to 8).

**Problem:**
- Bit pattern editor is not responding to clicks, or clicks are not toggling the bits.
- This functionality was previously implemented but is now broken.
- User suspects regression from "drag to paint values" feature (e10-21).
- Paint values functionality is not needed/relevant for bit pattern editor.

**Solution:**
- Investigate why `BitPatternEditor` is not receiving or processing taps.
- Check if "drag to paint" logic in `StepColumnWidget` is intercepting gestures intended for `BitPatternEditor`.
- Disable "drag to paint" for Pattern and Ties modes.

---

## Acceptance Criteria

### AC1: Clickable Bits
- When in Pattern or Ties mode, individual bits in the editor must be clickable.
- Clicking a valid bit must toggle its state (on/off).
- Clicking an invalid bit (disabled due to division count) should do nothing.

### AC2: Division Dependency
- The number of active/clickable bits must match the number of subdivisions determined by the Division parameter.
- Division 7 (default) -> 1 bit.
- Division 0 or 14 -> 8 bits.

### AC3: Visual Feedback
- Toggling a bit must immediately update the visual state (filled/empty).

### AC4: No Regressions
- Other parameters (Pitch, Velocity, etc.) must still work correctly.

---

## Technical Implementation

- Verify `BitPatternEditor` implementation in `lib/ui/widgets/step_sequencer/bit_pattern_editor.dart`.
- Verify integration in `lib/ui/widgets/step_sequencer/step_column_widget.dart`.
- Check for any overlaying widgets or gesture conflicts in `StepSequencerView`.
- Add regression test to ensure this doesn't break again.
