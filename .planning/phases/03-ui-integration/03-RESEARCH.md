# Phase 3: UI Integration - Research

**Researched:** 2026-01-31
**Domain:** Flutter UI state management and BLoC pattern integration
**Confidence:** HIGH

## Summary

Phase 3 integrates the completed 14-bit MIDI detection engine (Phase 2) into the existing mapping editor UI. The implementation requires minimal changes to existing widgets, leveraging the established BLoC pattern already in place. The `MidiDetectorWidget` already listens to `MidiListenerCubit` state via `BlocConsumer`, and the `onMidiEventFound` callback pattern is fully functional for 7-bit CC detection.

The existing architecture provides clear integration points: (1) `MidiDetectorWidget` already receives `MidiEventType` enum values including the new 14-bit variants (`cc14BitLowFirst`, `cc14BitHighFirst`), (2) the mapping editor's `onMidiEventFound` callback already handles type-to-MidiMappingType conversion, and (3) the status message display logic uses pattern matching that will automatically handle 14-bit types. The primary work involves extending the existing callback logic to map 14-bit event types to the correct `MidiMappingType` enum variants and updating the status message format for brevity.

**Primary recommendation:** Extend the existing `onMidiEventFound` callback in `PackedMappingDataEditor._buildMidiEditor()` to handle `cc14BitLowFirst` → `cc14BitLow` and `cc14BitHighFirst` → `cc14BitHigh` mappings. Update status message generation in `MidiDetectorWidget` to display "14-bit CC X Ch Y" format (4-5 words). No new dependencies or architectural changes required.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_bloc | 9.1.1 | BLoC state management | Already integrated; provides `BlocConsumer`, `BlocBuilder` for reactive UI |
| bloc | 9.1.0 | Core BLoC library | State management foundation; Cubit pattern in use |
| freezed | 3.2.3 | Immutable state classes | Generates copyWith methods; existing `MidiListenerState` uses it |
| Flutter SDK | 3.x+ | Material Design widgets | Native UI framework; `RangeSlider`, `DropdownMenu`, `Switch` already in use |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| equatable | 2.0.7 | Value equality | State comparison in BLoC (already integrated) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| BlocConsumer | BlocListener + BlocBuilder | More verbose; no benefit for this use case |
| Callback pattern | Direct Cubit access | Violates separation of concerns; callback is established pattern |
| Manual state tracking | StreamBuilder | Reinvents BLoC wheel; less maintainable |

**Installation:**
No additional packages required — all tools available in current stack.

## Architecture Patterns

### Recommended Integration Structure
```
MidiListenerCubit (state source)
    ↓ (BlocConsumer listens)
MidiDetectorWidget (displays status, fires callback)
    ↓ (onMidiEventFound callback)
PackedMappingDataEditor._buildMidiEditor (consumes detection)
    ↓ (setState updates local _data)
widget.onSave(_data) → DistingCubit (persists mapping)
```

### Pattern 1: BlocConsumer for Side Effects + UI Updates
**What:** Listen to Cubit state changes, trigger callbacks AND rebuild UI simultaneously.

**When to use:** Widget needs both visual feedback (status message) and programmatic action (form auto-fill).

**Example:**
```dart
// Source: lib/ui/midi_listener/midi_detector_widget.dart lines 157-206
BlocConsumer<MidiListenerCubit, MidiListenerState>(
  listener: (context, state) {
    // Side effect: fire callback for form auto-fill
    if (state.lastDetectedType != null && state.lastDetectedChannel != null) {
      widget.onMidiEventFound?.call(
        type: state.lastDetectedType,
        channel: state.lastDetectedChannel,
        number: state.lastDetectedCc ?? state.lastDetectedNote ?? 0,
      );
    }
  },
  builder: (context, state) {
    // UI update: show status message
    return _buildAnimatedStatus(theme);
  },
)
```

### Pattern 2: Enum-to-Enum Mapping in Callbacks
**What:** Convert detection event type (`MidiEventType`) to mapping configuration type (`MidiMappingType`).

**When to use:** Domain types differ between detection layer and configuration layer.

**Example:**
```dart
// Source: lib/ui/widgets/packed_mapping_data_editor.dart lines 683-721
onMidiEventFound: ({required MidiEventType type, required channel, required number}) {
  MidiMappingType detectedMappingType = MidiMappingType.cc;

  if (type == MidiEventType.noteOn || type == MidiEventType.noteOff) {
    detectedMappingType = MidiMappingType.noteMomentary;
  } else if (type == MidiEventType.cc14BitLowFirst) {
    detectedMappingType = MidiMappingType.cc14BitLow;
  } else if (type == MidiEventType.cc14BitHighFirst) {
    detectedMappingType = MidiMappingType.cc14BitHigh;
  }

  _data = _data.copyWith(
    midiMappingType: detectedMappingType,
    midiCC: number,
    midiChannel: channel,
    isMidiEnabled: true,
  );
}
```

### Pattern 3: Pattern Matching for Display Text
**What:** Use Dart switch expressions to generate UI strings based on enum values.

**When to use:** Multiple enum variants need different display representations.

**Example:**
```dart
// Source: lib/ui/midi_listener/midi_detector_widget.dart lines 107-113
final eventInfo = switch (type) {
  MidiEventType.cc => ('CC', s.lastDetectedCc),
  MidiEventType.noteOn => ('Note On', s.lastDetectedNote),
  MidiEventType.noteOff => ('Note Off', s.lastDetectedNote),
  MidiEventType.cc14BitLowFirst => ('14-bit CC', s.lastDetectedCc),
  MidiEventType.cc14BitHighFirst => ('14-bit CC', s.lastDetectedCc),
};
```

### Pattern 4: Optimistic UI with Debounced Saves
**What:** Update local state immediately, trigger debounced save to backend.

**When to use:** Form fields need instant visual feedback but expensive backend updates.

**Example:**
```dart
// Source: lib/ui/widgets/packed_mapping_data_editor.dart lines 202-218
void _triggerOptimisticSave({bool force = false}) {
  setState(() {
    _isDirty = true;
    _isSaving = force;
  });
  _debounceTimer?.cancel();
  if (force) {
    _attemptSave();
  } else {
    _debounceTimer = Timer(_debounceDuration, () {
      setState(() { _isSaving = true; });
      _attemptSave();
    });
  }
}
```

### Anti-Patterns to Avoid
- **Direct Cubit manipulation in callbacks:** Callbacks should update local widget state, not bypass the widget's setState flow.
- **Hardcoded status messages:** Use switch expressions for enum-to-string conversions; supports exhaustiveness checking.
- **Ignoring existing callback signature:** `onMidiEventFound` already has named parameters; match the pattern.
- **Skipping force save on detection:** Detection-triggered updates should persist immediately (force: true) to ensure mapping saved before user closes editor.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Status message fading | Custom animation state machine | AnimatedSwitcher with Timer | Already implemented; handles fade transitions automatically |
| Range slider with labels | Custom gesture handling | Flutter's RangeSlider widget | Material Design compliance; touch target sizing; accessibility |
| Dropdown menus | Custom overlay widgets | DropdownMenu (Material 3) | Keyboard navigation; screen reader support; consistent styling |
| Debounced saves | Manual Timer management | Existing `_triggerOptimisticSave` pattern | Already handles edge cases (disposal, retry logic, dirty state) |

**Key insight:** The mapping editor already handles all UI complexity (dropdowns, sliders, switches, debounced saves). The integration only adds enum mapping logic to the existing callback—no new UI primitives required.

## Common Pitfalls

### Pitfall 1: Incomplete Enum Mapping
**What goes wrong:** New 14-bit event types not handled in switch expressions; compiler doesn't catch missing cases.

**Why it happens:** Dart switch expressions on enums require exhaustive matching only in expression context, not statement context.

**How to avoid:** Use switch expressions (returns value) instead of switch statements; compiler enforces exhaustiveness.

**Warning signs:** Status message shows "Detected null" or callback doesn't fire for 14-bit CCs.

### Pitfall 2: CC Number vs Base CC Confusion
**What goes wrong:** 14-bit detection returns lower CC number (0-31), but user sees CC32+ on controller.

**Why it happens:** 14-bit pairs use CC X and CC X+32; detection always returns base CC (lower number).

**How to avoid:** Always use `result.number` from detection—it's the base CC by design (0-31 for 14-bit).

**Warning signs:** Mapping configured with CC32+ instead of CC0-31; hardware doesn't respond.

### Pitfall 3: Status Message Verbosity
**What goes wrong:** Status message exceeds 4-5 word requirement (e.g., "Detected 14-bit Control Change CC 1 on MIDI channel 1").

**Why it happens:** Copy-pasting existing 7-bit format without condensing.

**How to avoid:** Use format "14-bit CC X Ch Y" (exactly 5 tokens: type, CC keyword, number, Ch keyword, channel).

**Warning signs:** UI testing shows status text wrapping or truncating on mobile screens.

### Pitfall 4: RangeSlider Not Enabled for 14-bit
**What goes wrong:** User detects 14-bit CC but range slider remains at 7-bit limits (0-127).

**Why it happens:** Existing slider uses parameter min/max, not MIDI resolution.

**How to avoid:** Slider already uses `widget.parameterMin` and `widget.parameterMax`—no MIDI-specific limits. No change needed; this is a non-issue in current architecture.

**Warning signs:** N/A — slider range is parameter-driven, not MIDI-driven.

### Pitfall 5: Byte Order Display Confusion
**What goes wrong:** User unsure which 14-bit dropdown option matches detected hardware.

**Why it happens:** Labels "14 bit CC - low" and "14 bit CC - high" don't explain MSB/LSB byte order.

**How to avoid:** Detection auto-selects correct type; user doesn't need to understand byte order. UI labels unchanged.

**Warning signs:** User manually changes 14-bit type after detection; indicates confusion (but not a blocker).

## Code Examples

Verified patterns from codebase:

### Status Message Generation (14-bit Extension)
```dart
// Source: Extend lib/ui/midi_listener/midi_detector_widget.dart lines 107-113
final eventInfo = switch (type) {
  MidiEventType.cc => ('CC', s.lastDetectedCc),
  MidiEventType.noteOn => ('Note On', s.lastDetectedNote),
  MidiEventType.noteOff => ('Note Off', s.lastDetectedNote),
  MidiEventType.cc14BitLowFirst => ('14-bit CC', s.lastDetectedCc),
  MidiEventType.cc14BitHighFirst => ('14-bit CC', s.lastDetectedCc),
};

final eventNumber = eventInfo.$2;
if (eventNumber != null) {
  _statusMessage = 'Detected ${eventInfo.$1} $eventNumber on channel ${channel + 1}';
  // Result: "Detected 14-bit CC 1 on channel 1" (8 words - too long)
  // REVISED for UI-01 requirement:
  _statusMessage = '14-bit CC $eventNumber Ch ${channel + 1}';
  // Result: "14-bit CC 1 Ch 1" (5 words - compliant)
}
```

### Callback Extension for 14-bit Types
```dart
// Source: Extend lib/ui/widgets/packed_mapping_data_editor.dart lines 692-709
onMidiEventFound: ({required MidiEventType type, required channel, required number}) {
  MidiMappingType detectedMappingType = MidiMappingType.cc;

  if (type == MidiEventType.noteOn || type == MidiEventType.noteOff) {
    // Existing note logic...
    detectedMappingType = MidiMappingType.noteMomentary;
  } else if (type == MidiEventType.cc14BitLowFirst) {
    detectedMappingType = MidiMappingType.cc14BitLow;  // NEW
  } else if (type == MidiEventType.cc14BitHighFirst) {
    detectedMappingType = MidiMappingType.cc14BitHigh;  // NEW
  }

  setState(() {
    _data = _data.copyWith(
      midiMappingType: detectedMappingType,
      midiCC: number,  // Base CC (0-31 for 14-bit)
      midiChannel: channel,
      isMidiEnabled: true,
    );
  });
  _midiCcController.text = number.toString();
  _triggerOptimisticSave(force: true);  // Force immediate save
}
```

### RangeSlider Widget (No Changes Required)
```dart
// Source: lib/ui/widgets/packed_mapping_data_editor.dart lines 977-1056
// Existing implementation already supports full parameter range
Widget _buildRangeSlider({
  required int minValue,
  required int maxValue,
  required void Function(int rawMin, int rawMax) onChanged,
  void Function(int rawMin, int rawMax)? onChangeEnd,
}) {
  // Uses widget.parameterMin and widget.parameterMax (NOT MIDI-specific limits)
  // Already supports 14-bit ranges (0-16383) if parameter defines it
  // No modification needed for Phase 3
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual MIDI type selection | Auto-detection from hardware | Phase 2 (this release) | Reduced user friction; correct byte order guaranteed |
| Stateful widget state only | BLoC pattern (Cubit + state) | Pre-existing | Testable, reactive UI; state persists across widget rebuilds |
| Material 2 widgets | Material 3 DropdownMenu | Flutter 3.x migration | Improved accessibility, keyboard navigation |
| Immediate saves on every keystroke | Debounced optimistic saves | Pre-existing | Reduced backend load; better UX during rapid edits |

**Deprecated/outdated:**
- 7-bit-only MIDI mappings: Now auto-detects 14-bit when hardware sends paired CCs
- Manual dropdown for MIDI type: Detection auto-fills; user can still override if needed

## Open Questions

Things that couldn't be fully resolved:

1. **Status message fade timing**
   - What we know: Existing fade timer is 3 seconds (line 282: `Duration(seconds: 3)`)
   - What's unclear: Should 14-bit detection have longer fade (more complex message)?
   - Recommendation: Keep 3 seconds; message is concise (5 words); user reads quickly

2. **Auto-tab switching on detection**
   - What we know: Editor has 4 tabs (CV, MIDI, I2C, Performance); initialIndex logic exists (lines 119-136)
   - What's unclear: Should detection auto-switch to MIDI tab if user is on CV tab?
   - Recommendation: No auto-switch; could be jarring. Detection works regardless of active tab.

3. **14-bit range slider interpretation**
   - What we know: Slider uses parameter min/max (e.g., 0-16383 for 14-bit parameter)
   - What's unclear: Should UI show "14-bit" label when range is 0-16383?
   - Recommendation: No special labeling; slider is parameter-agnostic by design

4. **Byte order tooltip/help text**
   - What we know: Dropdown shows "14 bit CC - low" and "14 bit CC - high"
   - What's unclear: Do users need tooltip explaining MSB/LSB byte order?
   - Recommendation: Not for Phase 3; detection handles it. Defer to user feedback.

## Sources

### Primary (HIGH confidence)
- Codebase: `/Users/nealsanche/nosuch/nt_helper/lib/ui/midi_listener/midi_detector_widget.dart` — BlocConsumer pattern (lines 157-206), status message generation (lines 107-113, 179-193)
- Codebase: `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/packed_mapping_data_editor.dart` — onMidiEventFound callback (lines 683-721), _buildRangeSlider (lines 977-1056)
- Codebase: `/Users/nealsanche/nosuch/nt_helper/lib/ui/midi_listener/midi_listener_state.dart` — MidiEventType enum with cc14BitLowFirst/cc14BitHighFirst (lines 14-18)
- Codebase: `/Users/nealsanche/nosuch/nt_helper/lib/models/packed_mapping_data.dart` — MidiMappingType enum with cc14BitLow/cc14BitHigh (lines 5-14)
- Phase 2 Verification: `.planning/phases/02-14-bit-detection/02-VERIFICATION.md` — Confirmed detection engine emits correct event types (all 13 truths verified)

### Secondary (MEDIUM confidence)
- Flutter BLoC documentation: Pattern matching and BlocConsumer best practices (inferred from existing code patterns)
- Flutter Material Design: RangeSlider, DropdownMenu, Switch widgets (standard Flutter SDK)

### Tertiary (LOW confidence)
- None required — all research grounded in existing codebase patterns

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Flutter/BLoC versions pinned in pubspec.yaml; no new dependencies
- Architecture: HIGH — Integration points exist and are proven (7-bit CC detection works today)
- Pitfalls: MEDIUM — Based on code analysis; real-world testing may reveal edge cases

**Research date:** 2026-01-31
**Valid until:** 2026-04-30 (90 days; Flutter/BLoC patterns stable, codebase-specific research)
