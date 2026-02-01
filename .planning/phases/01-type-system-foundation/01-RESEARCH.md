# Phase 1: Type System Foundation - Research

**Researched:** 2026-01-31
**Domain:** Flutter Freezed state management with enum extensions
**Confidence:** HIGH

## Summary

Phase 1 extends the type system to support 14-bit MIDI events without breaking existing 7-bit and note detection. The core work involves adding new enum variants to `MidiEventType`, ensuring `MidiListenerState` can emit 14-bit detection results, and regenerating Freezed code. This is a non-breaking change - existing detection logic continues working unchanged while new types lay the groundwork for Phase 2's detection logic.

The existing architecture already has most infrastructure in place:
- `MidiMappingType` enum already defines `cc14BitLow(3)` and `cc14BitHigh(4)` variants
- `PackedMappingData` already handles 14-bit encoding/decoding in SysEx
- `MidiListenerCubit` threshold pattern (10 hits) can be extended for pairs
- `onMidiEventFound` callback signature already supports arbitrary `MidiEventType` variants

Key challenge: Choosing enum naming that clearly encodes byte order without breaking the callback contract or confusing consumers.

**Primary recommendation:** Add `cc14BitLowFirst` and `cc14BitHighFirst` enum variants where "low" and "high" refer to the CC number (0-31 vs 32-63), and "first" indicates which is the MSB. Reuse existing `lastDetectedCc` field to store the lower CC number.

## Standard Stack

No new dependencies needed - this is a pure Dart/Flutter type system extension using existing tools.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| freezed | ^3.2.3 | Immutable state classes with copyWith, union types | Official Dart code generation tool for immutable states |
| freezed_annotation | ^3.1.0 | Annotations for freezed | Required for @freezed decorator |
| build_runner | ^2.10.4 | Code generation runner | Standard Dart build tool |
| flutter_bloc | ^9.1.1 | Cubit state management | Project standard for state management |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| bloc | ^9.1.0 | Core bloc pattern primitives | Indirect dependency, already in pubspec |
| equatable | ^2.0.7 | Value equality for state classes | Used by some Freezed classes, optional |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Freezed | Manual copyWith implementation | More code, error-prone, harder to maintain |
| Enum variants for byte order | Separate boolean field | Requires new state field, more complex pattern matching |
| build_runner | Manual code generation | Unrealistic for production code |

**Installation:**
No installation needed - all dependencies already in `pubspec.yaml`.

**Build command:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Architecture Patterns

### Pattern 1: Freezed Sealed Classes with Part Files

**What:** Freezed generates immutable state classes with copyWith methods. State is defined in a `.dart` file with a `part` directive, and generated code goes in `.freezed.dart`.

**When to use:** All state classes in this codebase use Freezed (existing pattern).

**Example:**
```dart
// Source: lib/ui/midi_listener/midi_listener_state.dart (existing)
part of 'midi_listener_cubit.dart';

enum MidiEventType { cc, noteOn, noteOff }

@freezed
sealed class MidiListenerState with _$MidiListenerState {
  const factory MidiListenerState.initial() = Initial;

  const factory MidiListenerState.data({
    @Default([]) List<MidiDevice> devices,
    MidiDevice? selectedDevice,
    @Default(false) bool isConnected,
    MidiEventType? lastDetectedType,
    int? lastDetectedChannel,
    int? lastDetectedCc,
    int? lastDetectedNote,
    DateTime? lastDetectedTime,
  }) = Data;
}
```

**After extending for 14-bit:**
```dart
part of 'midi_listener_cubit.dart';

enum MidiEventType {
  cc,               // 7-bit CC
  noteOn,
  noteOff,
  cc14BitLowFirst,  // 14-bit CC where lower CC number (0-31) is MSB
  cc14BitHighFirst, // 14-bit CC where higher CC number (32-63) is MSB
}

@freezed
sealed class MidiListenerState with _$MidiListenerState {
  // Same factory constructors, no state field changes needed
  const factory MidiListenerState.initial() = Initial;

  const factory MidiListenerState.data({
    @Default([]) List<MidiDevice> devices,
    MidiDevice? selectedDevice,
    @Default(false) bool isConnected,
    MidiEventType? lastDetectedType,        // Now includes 14-bit variants
    int? lastDetectedChannel,               // 0-15, same as before
    int? lastDetectedCc,                    // For 14-bit: stores lower CC (0-31)
    int? lastDetectedNote,                  // Notes unchanged
    DateTime? lastDetectedTime,
  }) = Data;
}
```

### Pattern 2: Type-Encoded Information (Enum Variants)

**What:** Rather than adding separate fields for byte order, encode it in the event type itself. This avoids state explosion and makes pattern matching simpler.

**When to use:** When a property of the data is categorical and mutually exclusive (MSB-first vs LSB-first).

**Example:**
```dart
// BAD: Separate fields
enum MidiEventType { cc, cc14Bit, noteOn, noteOff }

@freezed
sealed class MidiListenerState with _$MidiListenerState {
  const factory MidiListenerState.data({
    MidiEventType? lastDetectedType,
    bool? lastDetectedByteOrderLowFirst,  // Extra field = more complexity
    int? lastDetectedCc,
    int? lastDetectedCcPair,              // Extra field = more complexity
  }) = Data;
}

// GOOD: Type-encoded
enum MidiEventType {
  cc,
  cc14BitLowFirst,   // Byte order is part of the type
  cc14BitHighFirst,
  noteOn,
  noteOff,
}

@freezed
sealed class MidiListenerState with _$MidiListenerState {
  const factory MidiListenerState.data({
    MidiEventType? lastDetectedType,  // Type tells you everything
    int? lastDetectedCc,              // Stores lower CC number for 14-bit
  }) = Data;
}
```

**Consumer pattern matching:**
```dart
// In MidiDetectorWidget
final (String, int?) eventInfo = switch (lastDetectedType) {
  MidiEventType.cc => ('CC', lastDetectedCc),
  MidiEventType.cc14BitLowFirst => ('14-bit CC (low=MSB)', lastDetectedCc),
  MidiEventType.cc14BitHighFirst => ('14-bit CC (high=MSB)', lastDetectedCc),
  MidiEventType.noteOn => ('Note On', lastDetectedNote),
  MidiEventType.noteOff => ('Note Off', lastDetectedNote),
};
```

### Pattern 3: Callback Contract Stability

**What:** The existing `onMidiEventFound` callback uses `MidiEventType` as a parameter. Adding enum variants doesn't break the signature - consumers just need to handle new cases.

**When to use:** When extending behavior without breaking existing integrations.

**Example:**
```dart
// Callback signature (unchanged):
onMidiEventFound?.call(
  type: lastDetectedType,  // Can now be cc14BitLowFirst or cc14BitHighFirst
  channel: lastDetectedChannel,
  number: eventNumber,     // For 14-bit: the lower CC number (0-31)
);

// Consumer in PackedMappingDataEditor (new cases):
onMidiEventFound: ({required type, required channel, required number}) {
  MidiMappingType detectedMappingType = MidiMappingType.cc;

  if (type == MidiEventType.noteOn || type == MidiEventType.noteOff) {
    detectedMappingType = MidiMappingType.noteMomentary;
  } else if (type == MidiEventType.cc14BitLowFirst) {
    detectedMappingType = MidiMappingType.cc14BitLow;  // Lower CC is MSB
  } else if (type == MidiEventType.cc14BitHighFirst) {
    detectedMappingType = MidiMappingType.cc14BitHigh; // Higher CC is MSB
  }

  _data = _data.copyWith(
    midiMappingType: detectedMappingType,
    midiCC: number,  // Store lower CC number (0-31)
    midiChannel: channel,
    isMidiEnabled: true,
  );
}
```

### Anti-Patterns to Avoid

- **Anti-pattern 1: Skipping Freezed regeneration** - Adding enum variants without running `build_runner` causes compile errors. Always regenerate after state changes.
- **Anti-pattern 2: Breaking callback semantics** - Don't change what `number` means (e.g., storing 14-bit value instead of CC number). Keep it as CC number; type indicates interpretation.
- **Anti-pattern 3: State field explosion** - Don't add `lastDetectedCc14BitMsb`, `lastDetectedCc14BitLsb`, `lastDetectedByteOrder`, etc. Encode in type, reuse existing fields.
- **Anti-pattern 4: Incomplete pattern matching** - After adding enum variants, all `switch` statements on `MidiEventType` must handle new cases or use `_` default.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Immutable state with copyWith | Manual copyWith implementation | Freezed `@freezed` annotation | Handles nested copyWith, equality, toString, serialization |
| Enum serialization | Custom toJson/fromJson | Built-in enum `.name` and `values` | Dart enums have built-in serialization since Dart 2.17 |
| Pattern matching on types | if/else chains | `switch` expressions (Dart 3) | Exhaustiveness checking, cleaner syntax |
| State equality | Manual `==` override | Freezed or Equatable | Handles deep equality, hashCode consistency |

**Key insight:** Freezed eliminates boilerplate for immutable state classes. Adding a field or enum variant requires only updating the factory constructor and regenerating - no manual copyWith, equality, or serialization code.

## Common Pitfalls

### Pitfall 1: Forgetting to Regenerate Freezed Code

**What goes wrong:** You add a new enum variant or state field, save the file, and immediately see IDE errors like "Missing required parameter" or "The getter 'lastDetectedType' isn't defined". Flutter analyze fails. Tests break.

**Why it happens:** Freezed generates code in `.freezed.dart` files. Changes to the source `.dart` file don't automatically update generated code. You must explicitly run `build_runner`.

**How to avoid:**
1. After ANY change to a `@freezed` class or its enums, run: `flutter pub run build_runner build --delete-conflicting-outputs`
2. Check that `.freezed.dart` file has updated timestamp
3. Verify `flutter analyze` passes with zero warnings before committing

**Warning signs:**
- IDE shows red underlines on previously working code
- Error: "The method 'copyWith' isn't defined for the type 'Data'"
- Error: "The getter 'lastDetectedType' isn't defined"
- Git diff shows changes in `.dart` but not `.freezed.dart`

**Phase to address:** Phase 1 - must regenerate after extending enum

---

### Pitfall 2: Incomplete Pattern Matching After Enum Extension

**What goes wrong:** You add `cc14BitLowFirst` and `cc14BitHighFirst` to the enum, but forget to update a `switch` statement in `MidiDetectorWidget`. The switch doesn't handle new cases, so they fall through to default or cause runtime errors.

**Why it happens:** Dart doesn't enforce exhaustive enum matching unless you use `switch` expressions (Dart 3). The existing code uses `switch` statements with explicit cases, so the compiler doesn't warn about missing cases.

**How to avoid:**
1. Search codebase for all `switch (.*MidiEventType)` patterns before/after extending enum
2. Update each switch to handle new cases or add `_` default
3. Prefer `switch` expressions over `switch` statements for exhaustiveness checking
4. Run tests to verify all code paths execute without errors

**Warning signs:**
- Detection fires but UI shows wrong event type string
- `onMidiEventFound` callback receives new type but consumer doesn't handle it
- Runtime error: "Unhandled case in switch"
- Tests fail with "No matching case for MidiEventType.cc14BitLowFirst"

**Phase to address:** Phase 1 - update all pattern matching after enum extension

---

### Pitfall 3: Callback Contract Ambiguity (What Does `number` Mean?)

**What goes wrong:** The `onMidiEventFound` callback passes `number` parameter. For 7-bit CC, `number` is the CC number (0-127). For 14-bit CC, it's ambiguous: is it the MSB CC, LSB CC, or the combined 14-bit value? Consumers make different assumptions, causing bugs.

**Why it happens:** The callback was designed for 7-bit events. Adding 14-bit extends the contract without documenting the semantic change. Different developers interpret `number` differently.

**How to avoid:**
1. **Document semantic:** `number` ALWAYS means the CC number, never the value. For 14-bit, it's the **lower** CC number (0-31).
2. **Consistent interpretation:** In Phase 2, always pass the lower CC when emitting 14-bit detection.
3. **Update consumer contracts:** Document in `PackedMappingDataEditor` that `number` is the CC to store in `midiCC` field.
4. **Consider renaming:** If ambiguity persists, rename to `ccNumber` (breaking change, avoid if possible).

**Warning signs:**
- Consumer stores 14-bit value (0-16383) in `midiCC` field which expects 0-127
- Different consumers interpret `number` differently for same event type
- Tests pass but integration fails because values are misinterpreted

**Phase to address:** Phase 1 - document semantics before implementation begins

---

### Pitfall 4: State Machine Corruption During Type Transition

**What goes wrong:** The detector identifies CC 1 as 7-bit, emits `MidiEventType.cc`, then later detects CC 1 + CC 33 as a pair and tries to emit `MidiEventType.cc14BitLowFirst`. The transition corrupts state:
- `_lastEventSignature` references the wrong type
- `_consecutiveCount` doesn't reset between modes
- Consumer receives conflicting signals (first 7-bit, then 14-bit)

**Why it happens:** Phase 1 doesn't implement detection logic, but it sets the stage. If state model allows type transitions without explicit reset, Phase 2 implementation will have bugs.

**How to avoid:**
1. **Design principle:** Once a CC number is detected as 7-bit OR 14-bit, don't switch modes unless explicitly reset.
2. **Phase 2 requirement:** Parallel detection paths - 7-bit and 14-bit track independently, first to threshold wins.
3. **State reset on disconnect:** When device disconnects, reset all detection state.
4. **Testing:** In Phase 1, write tests for state copyWith behavior to ensure fields preserve correctly.

**Warning signs:**
- Detection type flips between `cc` and `cc14BitLowFirst` within same session
- Threshold counter has impossible values
- Consumer receives multiple `onMidiEventFound` calls with different types for same CC

**Phase to address:** Phase 1 - design state model to prevent corruption

## Code Examples

Verified patterns from existing codebase:

### Extending Enum (Before/After)

**Before (existing):**
```dart
// Source: lib/ui/midi_listener/midi_listener_state.dart
enum MidiEventType { cc, noteOn, noteOff }
```

**After (Phase 1):**
```dart
// Source: lib/ui/midi_listener/midi_listener_state.dart
enum MidiEventType {
  cc,               // 7-bit CC (0-127)
  noteOn,           // MIDI Note On
  noteOff,          // MIDI Note Off
  cc14BitLowFirst,  // 14-bit CC: lower CC number (0-31) is MSB, higher (32-63) is LSB
  cc14BitHighFirst, // 14-bit CC: higher CC number (32-63) is MSB, lower (0-31) is LSB
}
```

**Naming rationale:**
- "Low" and "High" refer to CC number ranges (0-31 vs 32-63), not byte order terminology (MSB/LSB)
- "First" indicates which is the MSB (most significant byte)
- Clear mapping: `cc14BitLowFirst` → `MidiMappingType.cc14BitLow` (lower CC is MSB)
- Clear mapping: `cc14BitHighFirst` → `MidiMappingType.cc14BitHigh` (higher CC is MSB)

### Regenerating Freezed Code

```bash
# Source: Project standard (CLAUDE.md, docs/architecture/coding-standards.md)
# Run after ANY change to @freezed classes or enums
flutter pub run build_runner build --delete-conflicting-outputs

# Verify zero warnings (required per project CLAUDE.md)
flutter analyze

# Run tests to verify state integrity
flutter test
```

### Pattern Matching on Extended Enum

**In MidiDetectorWidget (existing pattern extended):**
```dart
// Source: lib/ui/midi_listener/midi_detector_widget.dart (lines 177-182)
// BEFORE:
final (String, int?) eventInfo = switch (lastDetectedType) {
  MidiEventType.cc => ('CC', lastDetectedCc),
  MidiEventType.noteOn => ('Note On', lastDetectedNote),
  MidiEventType.noteOff => ('Note Off', lastDetectedNote),
};

// AFTER (Phase 1):
final (String, int?) eventInfo = switch (lastDetectedType) {
  MidiEventType.cc => ('CC', lastDetectedCc),
  MidiEventType.cc14BitLowFirst => ('14-bit CC', lastDetectedCc),  // Display lower CC
  MidiEventType.cc14BitHighFirst => ('14-bit CC', lastDetectedCc), // Display lower CC
  MidiEventType.noteOn => ('Note On', lastDetectedNote),
  MidiEventType.noteOff => ('Note Off', lastDetectedNote),
};
```

**In PackedMappingDataEditor (new integration):**
```dart
// Source: lib/ui/widgets/packed_mapping_data_editor.dart (around line 700)
// NEW in Phase 3 (shown here for Phase 1 type design validation):
onMidiEventFound: ({required type, required channel, required number}) {
  MidiMappingType detectedMappingType = MidiMappingType.cc;

  switch (type) {
    case MidiEventType.cc:
      detectedMappingType = MidiMappingType.cc;
      break;
    case MidiEventType.cc14BitLowFirst:
      detectedMappingType = MidiMappingType.cc14BitLow;  // Lower CC (0-31) is MSB
      break;
    case MidiEventType.cc14BitHighFirst:
      detectedMappingType = MidiMappingType.cc14BitHigh; // Higher CC (32-63) is MSB
      break;
    case MidiEventType.noteOn:
    case MidiEventType.noteOff:
      detectedMappingType = MidiMappingType.noteMomentary;
      break;
  }

  _data = _data.copyWith(
    midiMappingType: detectedMappingType,
    midiCC: number,  // Store lower CC number (0-31) for 14-bit
    midiChannel: channel,
    isMidiEnabled: true,
  );
}
```

### State Immutability Verification

**Test that copyWith preserves type information:**
```dart
// NEW test for Phase 1
test('MidiListenerState.data copyWith preserves 14-bit type', () {
  final state = MidiListenerState.data(
    lastDetectedType: MidiEventType.cc14BitLowFirst,
    lastDetectedChannel: 0,
    lastDetectedCc: 1,  // Lower CC number
  );

  final updated = state.copyWith(
    lastDetectedTime: DateTime.now(),
  );

  expect(updated.lastDetectedType, MidiEventType.cc14BitLowFirst);
  expect(updated.lastDetectedCc, 1);
  expect(updated.lastDetectedChannel, 0);
});

test('MidiListenerState supports all MidiEventType variants', () {
  // Verify enum can be assigned to state field without errors
  for (final type in MidiEventType.values) {
    final state = MidiListenerState.data(lastDetectedType: type);
    expect(state.lastDetectedType, type);
  }
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual copyWith methods | Freezed code generation | Freezed 1.0 (2021) | Less boilerplate, fewer bugs |
| if/else chains for type matching | switch expressions | Dart 3.0 (2023) | Exhaustiveness checking |
| @immutable with manual equality | @freezed annotation | Freezed 2.0 (2022) | Auto-generates equality, hashCode |
| Separate boolean flags for variants | Enum variants | Dart 2.17 enhanced enums (2022) | Type-safe, fewer fields |

**Deprecated/outdated:**
- Manual `==` and `hashCode` implementations - use Freezed or Equatable
- `const` constructor boilerplate - Freezed generates it
- Separate fields for mutually exclusive states - use enum variants or sealed classes

## Open Questions

Things that couldn't be fully resolved:

1. **Enum naming: "LowFirst" vs "MsbLow"**
   - What we know: "Low" and "High" refer to CC number ranges (0-31 vs 32-63). "First" indicates MSB position.
   - What's unclear: Does "LowFirst" clearly communicate "lower CC is MSB" or is "MsbLow" clearer?
   - Recommendation: Use "LowFirst" for consistency with existing `MidiMappingType.cc14BitLow` (maps naturally). Document in code comments.

2. **Should state have a paired CC field?**
   - What we know: Existing `lastDetectedCc` field stores the CC number. For 14-bit, we could store just the lower CC, or add `lastDetectedCcPair` for the higher CC.
   - What's unclear: Do consumers need both CC numbers explicitly, or can they compute higher = lower + 32?
   - Recommendation: Store only lower CC in `lastDetectedCc`. Consumers can compute paired CC if needed. Avoid state field explosion.

3. **Freezed regeneration timing: commit generated files?**
   - What we know: `.freezed.dart` files are generated code. Git tracks them in this project.
   - What's unclear: Should we commit after EVERY regeneration, or only when changing state schema?
   - Recommendation: Commit `.freezed.dart` files whenever `.dart` state files change. Project already tracks generated files in git (per .gitignore analysis).

## Sources

### Primary (HIGH confidence)
- Existing codebase analysis - `/Users/nealsanche/nosuch/nt_helper/lib/ui/midi_listener/` directory
- Freezed package documentation - pub.dev (version 3.2.3)
- Flutter/Dart 3.8.1 language spec - dart.dev (enhanced enums, switch expressions)
- Project CLAUDE.md - coding standards, build commands

### Secondary (MEDIUM confidence)
- Architecture research - `.planning/research/ARCHITECTURE.md` (lines 179-220)
- Stack research - `.planning/research/STACK.md` (lines 32-44, 86-97)
- Pitfalls research - `.planning/research/PITFALLS.md` (pitfalls 6, 8)

### Tertiary (LOW confidence)
- None - all findings verified with primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all tools already in pubspec.yaml, versions verified
- Architecture patterns: HIGH - extracted from existing working code
- Pitfalls: HIGH - based on Freezed documentation and existing project patterns
- Naming choices: MEDIUM - "LowFirst" vs alternatives is subjective

**Research date:** 2026-01-31
**Valid until:** 2026-03-31 (30 days for stable infrastructure)

**Phase 1 scope verification:**
- ✅ Type system extension (enum variants)
- ✅ State model compatibility (Freezed regeneration)
- ✅ Non-breaking change verification (callback contract)
- ✅ Pattern matching updates identified
- ❌ Detection logic (Phase 2 scope)
- ❌ UI integration (Phase 3 scope)
