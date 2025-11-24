# Sprint Change Proposal - Epic 10 Bit Pattern Interaction Model

**Date:** 2025-11-23
**Created By:** PM Agent (John)
**Change Scope:** Minor (Direct implementation by dev team)
**Status:** ✅ APPROVED & EXECUTED (2025-11-23)

---

## Section 1: Issue Summary

### Triggering Story
**Story ID:** e10-10 (Implement Bit Pattern Editor for Pattern)
**Discovery Context:** Post-implementation review revealed a fundamental UX mismatch

### Core Problem Statement

**Issue Type:** Misunderstanding of original requirements

**Problem:** Multiple Epic 10 stories (e10-3, e10-9, e10-10) specify opening **dialog boxes** for editing step parameters and bit patterns. However, the original design intent was for users to **directly click on value bar segments** to toggle bits and edit values inline—similar to a DAW piano roll or step sequencer interface.

**Current Implementation (Story 10.10, line 154):**
> "Changed tap handler to show editor dialog for bit pattern modes **(instead of direct bit toggling)**"

This represents a move AWAY from the intuitive direct-click interaction toward a more cumbersome dialog-based approach.

**Additional Issue:** There's a bug in the direct segment-clicking mechanism that needs to be fixed as part of this correction.

### Supporting Evidence

1. **Story e10-3** (AC3.1): "Tap step → opens modal with all per-step parameters"
2. **Story e10-9** (AC #4): "Tapping a step bar in Ties mode opens bit pattern editor overlay"
3. **Story e10-10** (AC #3): "Tapping a step bar in Pattern mode opens the bit pattern editor overlay"
4. **User feedback:** "The bits can be toggled by hand by clicking on the individual segments in the value bar"
5. **Bug report:** Direct clicking mechanism has a defect preventing proper bit toggling

**Impact:** Users experience unnecessary friction when editing bit patterns. The dialog-based approach requires:
- Tap bar → Wait for dialog animation → Edit bits → Dismiss dialog → Repeat for next step

Direct clicking would be:
- Tap segment → Bit toggles immediately → Continue editing

---

## Section 2: Epic Impact Assessment

### Current Epic Status

**Epic 10:** Visual Step Sequencer UI Widget
**Completion:** ~85% complete (stories 1, 2, 3, 4, 5, 6, 8, 10 done; story 7 in progress)

### Epic-Level Changes Required

**Modify existing epic scope:** ✅ YES
- Epic 10 acceptance criteria remain valid
- Implementation approach for bit pattern editing needs correction
- No change to overall epic goals or deliverables

**Add new epic:** ❌ NO
**Remove/defer epic:** ❌ NO
**Redefine epic:** ❌ NO

### Specific Epic Changes

**Story Updates Required:**
1. **e10-3** (Step Selection and Editing) - MINOR UPDATE
   - Remove "modal dialog" references for bit pattern parameters
   - Clarify that bit pattern modes (Pattern, Ties) use direct segment clicking
   - Keep modal dialog for *non-bit-pattern* parameters (Pitch slider, Velocity, Division, etc.)

2. **e10-9** (Bit Pattern Visualization for Ties) - MINOR UPDATE
   - Update AC #4: Change "opens bit pattern editor overlay" to "supports direct segment clicking"
   - Remove BitPatternEditorDialog usage for Ties mode
   - Enhance `_handleBarInteraction()` to detect segment clicks and toggle bits

3. **e10-10** (Bit Pattern Editor for Pattern) - MINOR UPDATE
   - Update AC #3: Change "opens bit pattern editor overlay" to "supports direct segment clicking"
   - Remove BitPatternEditorDialog usage for Pattern mode
   - Fix the bug in segment click detection

**New Story Required:**
- **e10.10.1** - Fix Bit Pattern Direct Clicking (BUG FIX + UX CORRECTION)

### Impact on Remaining Epics

**Future Epic Review:** ✅ CHECKED
- No future epics depend on the dialog-based interaction model
- All remaining Epic 10 stories (Story 7: Auto-sync debouncing) are unaffected
- No sequencing or priority changes needed

---

## Section 3: Artifact Conflict and Impact Analysis

### PRD Impact

**Conflicts with PRD:** ❌ NO
**Requirements changes needed:** ❌ NO
**MVP scope impact:** ❌ NO

**Analysis:** The PRD defines the Step Sequencer UI as a visual, intuitive interface for editing sequences. Direct segment clicking *better* aligns with the PRD goal of "effortless and musical" editing than dialog boxes.

### Architecture Impact

**System components:** ❌ NO CHANGES
**Architectural patterns:** ❌ NO CHANGES
**Technology stack:** ❌ NO CHANGES
**Data models:** ❌ NO CHANGES
**API designs:** ❌ NO CHANGES
**Integration points:** ❌ NO CHANGES

**Analysis:** This is a UI interaction change only. The underlying cubit state management (`DistingCubit.updateParameterValue`), MIDI write debouncing, and parameter discovery architecture remain unchanged.

### UI/UX Specification Impact

**User interface components:** ✅ MINOR UPDATE
- Remove `BitPatternEditorDialog` widget (or keep for future non-sequencer use)
- Enhance `StepColumnWidget` tap gesture detection for 8-segment grid
- No changes to visual design (8-segment bit pattern bars remain)

**User flows:** ✅ MINOR UPDATE
- Simplified flow: Tap segment → Bit toggles (vs. Tap → Dialog → Edit → Close)

**Wireframes/mockups:** ❌ NO CHANGES
**Interaction patterns:** ✅ CORRECTION
**Accessibility:** ❌ NO CHANGES

### Other Artifacts

**Deployment:** ❌ NO CHANGES
**Infrastructure:** ❌ NO CHANGES
**Monitoring:** ❌ NO CHANGES
**Testing:** ✅ MINOR UPDATE (update widget tests for direct clicking)
**Documentation:** ✅ MINOR UPDATE (update story docs)
**CI/CD:** ❌ NO CHANGES

---

## Section 4: Path Forward Evaluation

### Option 1: Direct Adjustment ✅ RECOMMENDED

**Can issue be addressed by modifying existing stories?** YES
**Can new stories be added within current epic?** YES
**Maintains timeline and scope?** YES

**Approach:**
- Create story **e10.10.1** to fix direct clicking and remove dialog dependency
- Update documentation for stories e10-3, e10-9, e10-10 to reflect correct interaction model
- Remove or deprecate `BitPatternEditorDialog` widget

**Effort Estimate:** LOW
- 2-4 hours implementation (enhance `_handleBarInteraction`, detect segment clicks, toggle bits)
- 1 hour testing (widget tests + manual verification)
- Total: ~4-6 hours (0.5-1 day)

**Risk Level:** LOW
- Well-understood problem domain
- No external dependencies
- Easily reversible if needed
- Clear acceptance criteria

**Status:** ✅ VIABLE (RECOMMENDED)

---

### Option 2: Potential Rollback ❌ NOT VIABLE

**Would reverting simplify the issue?** NO
**Stories to roll back:** e10-9, e10-10 (bit pattern visualization)
**Rollback effort justified?** NO

**Analysis:** Rolling back would lose valuable work (8-segment visualization, parameter discovery, global mode selector). The issue is NOT with the implementation quality—it's simply choosing direct clicking over dialogs. Forward fix is cleaner.

**Effort Estimate:** HIGH (revert + reimplement = 2-3 days)
**Risk Level:** MEDIUM (code churn, potential regressions)

**Status:** ❌ NOT VIABLE

---

### Option 3: MVP Review ❌ NOT APPLICABLE

**Is MVP still achievable?** YES
**Scope reduction needed?** NO
**Goals need modification?** NO

**Analysis:** This is a minor UX refinement, not a fundamental constraint. MVP is unaffected.

**Status:** ❌ NOT APPLICABLE

---

### Option 4: Hybrid Approach ❌ NOT NECESSARY

Keep both dialog AND direct clicking? **Not recommended.**
- Adds complexity without clear value
- Two interaction models for same feature confuses users
- Direct clicking is superior for this use case (fast, visual, in-context)

**Status:** ❌ NOT NECESSARY

---

## Section 5: Recommended Approach

### Selected Path: **Option 1 - Direct Adjustment**

### Rationale

1. **Implementation Effort:** Minimal (0.5-1 day)
2. **Technical Risk:** Low (well-scoped change, no architecture impact)
3. **Team Momentum:** Maintains forward progress, avoids demoralizing rollback
4. **Maintainability:** Simplifies codebase (removes dialog widget, one interaction model)
5. **User Experience:** Direct clicking is faster, more intuitive, aligns with DAW patterns
6. **Business Value:** Improves UX without scope changes or delays

### Trade-offs Considered

**Dialog approach pros:**
- More screen space for bit labels/explanations
- Could show additional controls (presets, randomize, clear)

**Direct clicking pros (WINNER):**
- Faster editing workflow (no dialog overhead)
- Visual: see bit pattern change in real-time on the bar
- Matches established DAW/sequencer interaction patterns
- Reduces code complexity (fewer widgets)

**Decision:** Direct clicking wins for core editing. If advanced features (presets, randomize) are needed later, they can be added to a context menu or toolbar.

---

## Section 6: Detailed Change Proposals

### Proposal 1: Create Story e10.10.1

**Story ID:** e10.10.1
**Title:** Fix Bit Pattern Direct Clicking (Remove Dialog, Fix Segment Detection Bug)
**Type:** Bug Fix + UX Correction
**Priority:** HIGH (blocks intuitive UX)

**User Story:**
> As a **Step Sequencer user**,
> I want **to toggle bit pattern segments by clicking directly on the 8-segment value bar**,
> So that **I can edit Pattern and Ties parameters quickly without opening dialog boxes**.

**Acceptance Criteria:**

1. **AC1:** When global parameter mode = Pattern or Ties, tapping a specific segment in the step value bar toggles that bit (0→1 or 1→0)
2. **AC2:** Segment detection correctly maps tap position to bits 0-7 (bit 0 at bottom, bit 7 at top)
3. **AC3:** Bit toggle calls `updateParameterValue(slotIndex, paramNumber, newValue)` with debouncing (50ms)
4. **AC4:** Visual feedback: tapped segment immediately updates fill color (set=filled, unset=empty)
5. **AC5:** Works for both Pattern (blue color scheme) and Ties (yellow color scheme) modes
6. **AC6:** `BitPatternEditorDialog` widget is no longer called for Pattern/Ties modes (remove tap handler)
7. **AC7:** Bug fix: Tap position correctly detects which of the 8 segments was clicked (verify with edge cases)
8. **AC8:** Offline mode: bit toggles persist in dirty params and sync on reconnect
9. **AC9:** All existing tests pass + new tests for direct segment clicking
10. **AC10:** `flutter analyze` passes with zero warnings

**Technical Implementation:**

```dart
// In step_column_widget.dart
void _handleBarInteraction(double dy, double barHeight) {
  if (_isBitPatternMode()) {
    // NEW: Direct bit toggling for Pattern/Ties modes
    final bitIndex = _calculateBitIndexFromTapPosition(dy, barHeight);
    if (bitIndex >= 0 && bitIndex < 8) {
      _toggleBit(bitIndex);
    }
  } else if (widget.activeParameter == StepParameter.division) {
    // Division mode: discrete 0-14 selection
    final divisionValue = ((barHeight - dy) / barHeight * 15).floor().clamp(0, 14);
    _updateParameter(divisionValue);
  } else {
    // Continuous parameters (Pitch, Velocity, Mod, etc.)
    final value = ((barHeight - dy) / barHeight * 127).round().clamp(0, 127);
    _updateParameter(value);
  }
}

int _calculateBitIndexFromTapPosition(double dy, double barHeight) {
  // Divide bar into 8 equal segments
  // Bit 0 at bottom (dy near barHeight), Bit 7 at top (dy near 0)
  final segmentHeight = barHeight / 8.0;
  final bitIndex = ((barHeight - dy) / segmentHeight).floor();
  return bitIndex.clamp(0, 7);
}

void _toggleBit(int bitIndex) {
  final currentValue = _getCurrentParameterValue();
  final newValue = currentValue ^ (1 << bitIndex); // XOR to toggle bit
  _updateParameter(newValue);
}

bool _isBitPatternMode() {
  return widget.activeParameter == StepParameter.pattern ||
         widget.activeParameter == StepParameter.ties;
}
```

**Test Requirements:**

```dart
testWidgets('Tapping bottom segment toggles bit 0', (tester) async {
  // Setup: Pattern mode, value = 0b00000000 (all bits off)
  await tester.pumpWidget(createStepColumn(
    activeParameter: StepParameter.pattern,
    parameterValue: 0,
  ));

  // Tap bottom segment (bit 0)
  await tester.tapAt(Offset(30, 270)); // Near bottom of 280px bar
  await tester.pumpAndSettle();

  // Verify: value changed to 0b00000001 (bit 0 set)
  expect(find.byWidgetPredicate((w) =>
    w is CustomPaint &&
    (w.painter as PitchBarPainter).value == 1
  ), findsOneWidget);
});

testWidgets('Tapping top segment toggles bit 7', (tester) async {
  // Setup: Ties mode, value = 0b00000000
  await tester.pumpWidget(createStepColumn(
    activeParameter: StepParameter.ties,
    parameterValue: 0,
  ));

  // Tap top segment (bit 7)
  await tester.tapAt(Offset(30, 10)); // Near top of 280px bar
  await tester.pumpAndSettle();

  // Verify: value changed to 0b10000000 (bit 7 set)
  expect(find.byWidgetPredicate((w) =>
    w is CustomPaint &&
    (w.painter as PitchBarPainter).value == 128
  ), findsOneWidget);
});

testWidgets('Toggling already-set bit turns it off', (tester) async {
  // Setup: Pattern mode, value = 0b00001010 (bits 1 and 3 set)
  await tester.pumpWidget(createStepColumn(
    activeParameter: StepParameter.pattern,
    parameterValue: 10, // 0b00001010
  ));

  // Tap bit 1 segment (currently set)
  await tester.tapAt(Offset(30, 245)); // Bit 1 position
  await tester.pumpAndSettle();

  // Verify: value changed to 0b00001000 (bit 1 cleared, bit 3 still set)
  expect(find.byWidgetPredicate((w) =>
    w is CustomPaint &&
    (w.painter as PitchBarPainter).value == 8
  ), findsOneWidget);
});
```

**Files Modified:**
- `lib/ui/widgets/step_sequencer/step_column_widget.dart` - Enhance tap handler, add bit detection logic
- `test/ui/widgets/step_sequencer/step_column_widget_test.dart` - Add direct clicking tests

**Files Removed/Deprecated:**
- `lib/ui/widgets/step_sequencer/bit_pattern_editor_dialog.dart` - Remove tap handler calls (widget can remain for potential future use)

**Effort:** 0.5-1 day
**Risk:** Low

---

### Proposal 2: Update Story e10-3 Documentation

**Story:** e10-3-step-selection-and-editing.md
**Section:** Acceptance Criteria

**OLD (AC3.1):**
> Tap step → opens modal with all per-step parameters

**NEW (AC3.1):**
> **For continuous/discrete parameters (Pitch, Velocity, Mod, Division):** Tap step → opens modal with all per-step parameters
> **For bit pattern parameters (Pattern, Ties):** Tap directly on value bar segments to toggle individual bits (no modal)

**Rationale:** Clarifies that the modal is for *non-bit-pattern* parameters only. Bit patterns use direct segment clicking for faster editing.

---

### Proposal 3: Update Story e10-9 Documentation

**Story:** e10-9-implement-bit-pattern-editor-for-ties.md
**Section:** Acceptance Criteria

**OLD (AC #4):**
> Tapping a step bar in Ties mode opens bit pattern editor overlay

**NEW (AC #4):**
> Tapping a specific segment of the step bar in Ties mode toggles that bit directly (0→1 or 1→0) without opening a dialog

**OLD (AC #5):**
> Bit pattern editor shows 8 toggle buttons (horizontal layout)

**NEW (AC #5):**
> ~~Bit pattern editor shows 8 toggle buttons~~ Step bar 8-segment visualization allows direct bit toggling via tap

**Rationale:** Removes dialog/overlay references, clarifies direct interaction model.

---

### Proposal 4: Update Story e10-10 Documentation

**Story:** e10-10-implement-bit-pattern-editor-for-pattern.md
**Section:** Acceptance Criteria

**OLD (AC #3):**
> Tapping a step bar in Pattern mode opens the bit pattern editor overlay

**NEW (AC #3):**
> Tapping a specific segment of the step bar in Pattern mode toggles that bit directly (0→1 or 1→0) without opening a dialog

**OLD (AC #4):**
> Bit pattern editor shows 8 toggle buttons in horizontal layout with blue color scheme (Pattern color)

**NEW (AC #4):**
> ~~Bit pattern editor shows 8 toggle buttons~~ Step bar 8-segment visualization allows direct bit toggling via tap, using blue color scheme (Pattern color)

**Rationale:** Aligns with Ties mode interaction, removes dialog dependency.

---

## Section 7: Implementation Handoff

### Change Scope Classification

**Scope:** MINOR (Direct implementation by development team)

**Justification:**
- Localized to Epic 10 step sequencer UI
- No PRD, architecture, or cross-epic dependencies
- Clear technical approach with low risk
- Well-defined acceptance criteria and test requirements

### Handoff Recipients

**Primary:** Development Team (Dev Agent)
**Responsibilities:**
1. Create story e10.10.1 markdown file in `docs/stories/`
2. Implement bit segment click detection in `step_column_widget.dart`
3. Fix segment-to-bit index mapping bug
4. Remove BitPatternEditorDialog tap handler calls for Pattern/Ties modes
5. Add widget tests for direct clicking behavior
6. Verify `flutter analyze` passes with zero warnings
7. Test on hardware (if available) or offline mode
8. Commit changes and update story status to "done"

**Secondary:** Product Manager (PM Agent - John)
**Responsibilities:**
1. Update story documentation for e10-3, e10-9, e10-10 with corrected acceptance criteria
2. Review implementation against corrected UX spec
3. Approve completion of story e10.10.1

**Tertiary:** None (no PO/SM or Architect involvement needed)

### Success Criteria

1. ✅ Story e10.10.1 created and completed
2. ✅ Tapping bit pattern segments toggles bits directly (no dialog)
3. ✅ Segment detection correctly maps to bits 0-7
4. ✅ Visual feedback: segments update immediately on tap
5. ✅ Works for both Pattern (blue) and Ties (yellow) modes
6. ✅ Debounced parameter writes (50ms)
7. ✅ All tests pass (existing + new direct clicking tests)
8. ✅ `flutter analyze` zero warnings
9. ✅ Story docs updated for e10-3, e10-9, e10-10
10. ✅ User can edit bit patterns faster than dialog-based approach

### Timeline Impact

**Estimated Implementation Time:** 0.5-1 day
**Epic 10 Delay:** None (this is a refinement within existing scope)
**MVP Delivery Impact:** None

---

## Section 8: Approval and Next Steps

### Approval Required

**Decision Maker:** Neal (Product Owner / Developer)
**Approval Status:** ✅ APPROVED (2025-11-23)

**Decisions by Neal (Product Owner):**
1. ✅ **APPROVED** - Create story e10.10.1 to implement direct bit clicking
2. ✅ **APPROVED** - Remove BitPatternEditorDialog tap handler calls for Pattern/Ties modes
3. ✅ **DELETE ENTIRELY** - Do not keep BitPatternEditorDialog widget code
4. ✅ **NO ADDITIONAL CHANGES** - Proceed as specified in proposal

### Next Steps (Upon Approval) - ✅ COMPLETED

1. **PM Agent (John):** ✅ DONE
   - ✅ Created story file: `docs/stories/e10-10-1-fix-bit-pattern-direct-clicking.md`
   - ✅ Updated story docs: e10-3, e10-9, e10-10 with corrected acceptance criteria
   - ✅ Marked this Sprint Change Proposal as APPROVED

2. **Dev Agent:** ⏳ PENDING
   - ⏳ Implement story e10.10.1 (enhance tap handler, fix bug, delete BitPatternEditorDialog, add tests)
   - ⏳ Verify all acceptance criteria met
   - ⏳ Run `flutter analyze` and `flutter test`
   - ⏳ Commit changes with reference to this proposal

3. **PM Agent (John):** ⏳ PENDING
   - ⏳ Review implementation
   - ⏳ Test UX improvement (tapping segments toggles bits)
   - ⏳ Mark story e10.10.1 as DONE
   - ⏳ Close this Sprint Change Proposal

---

## Appendix: Comparison of Interaction Models

### Dialog-Based Approach (OLD)

**User Flow:**
1. User taps step bar
2. Wait for dialog animation (~300ms)
3. Dialog opens with 8 toggle buttons
4. User taps bit 3 to toggle it
5. User taps "Apply" button
6. Dialog closes
7. Repeat for next step

**Total Time Per Bit:** ~2-3 seconds
**Friction Points:** Dialog load, apply button, context switch

---

### Direct Clicking Approach (NEW)

**User Flow:**
1. User taps segment 3 of step bar
2. Bit 3 toggles immediately
3. Visual feedback: segment fill changes
4. Continue to next bit or next step

**Total Time Per Bit:** ~0.5 seconds
**Friction Points:** None

**Efficiency Gain:** 4-6× faster editing
**UX Improvement:** In-context editing, visual feedback, DAW-familiar pattern

---

## Document End

**Prepared By:** PM Agent (John)
**Date:** 2025-11-23
**Project:** nt_helper - Disting NT MIDI Helper
**Epic:** Epic 10 - Visual Step Sequencer UI Widget
**Change Type:** Sprint Course Correction (Minor)
**Status:** PENDING APPROVAL

---

*This Sprint Change Proposal follows the BMAD Method Correct Course workflow (bmad/bmm/workflows/4-implementation/correct-course).*
