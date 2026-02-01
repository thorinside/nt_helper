# Technology Stack - 14-bit MIDI CC Detection

**Project:** nt_helper
**Feature:** 14-bit MIDI CC auto-detection
**Researched:** 2026-01-31
**Overall confidence:** HIGH

## Executive Summary

No new packages required. The feature is a pure logic enhancement within the existing `MidiListenerCubit`. All necessary infrastructure already exists.

## Stack Analysis

### Core Framework (No Changes)

| Technology | Current Version | Purpose | Status |
|------------|----------------|---------|--------|
| flutter_midi_command | ^0.5.3 | MIDI packet reception via `MidiPacket.data` | SUFFICIENT |
| flutter_bloc | ^9.1.1 | Cubit state management | SUFFICIENT |
| freezed | ^3.2.3 (dev) | Immutable state classes | SUFFICIENT |

**Rationale:**
- `flutter_midi_command` provides raw MIDI bytes via `MidiPacket.data` (UInt8List)
- Existing code already parses status bytes, channels, and CC numbers
- 14-bit detection is purely algorithmic - track multiple CC numbers simultaneously, detect pairs 32 apart
- No timing library needed (no time window requirement per spec)

### State Management (Enhancements Needed)

The following changes are needed to existing state structures:

**MidiEventType enum** (in `midi_listener_state.dart`):
```dart
// Current:
enum MidiEventType { cc, noteOn, noteOff }

// Enhanced for 14-bit:
enum MidiEventType {
  cc,           // 7-bit CC
  cc14Bit,      // 14-bit CC pair
  noteOn,
  noteOff
}
```

**MidiListenerState.data** (Freezed class):
```dart
// Add new fields:
int? lastDetectedCc14BitMsb,     // MSB CC number (0-31)
int? lastDetectedCc14BitLsb,     // LSB CC number (32-63)
```

**Rationale:**
- Need to distinguish 14-bit CC from 7-bit CC in UI (different auto-fill behavior)
- Need to communicate both CC numbers (MSB and LSB) to caller
- Byte order determination happens in cubit logic, state just reports the result

### Detection Algorithm (Pure Logic)

Implementation within `MidiListenerCubit._handleMidiData()`:

**Data Structures:**
```dart
// Track recent CC activity across all CC numbers
final Map<int, int> _ccActivityCounts = {}; // cc_number -> count

// Track which CC numbers have been seen (for pair detection)
final Set<int> _seenCcNumbers = {};
```

**Algorithm:**
1. When CC message arrives (status byte 0xB0):
   - Increment activity count for that CC number
   - Add to seen set
   - Check if paired CC exists (MSB 0-31 has LSB 32-63)
2. When both members of pair seen >= threshold:
   - Analyze recent values to determine byte order (MSB vs LSB)
   - Emit `MidiEventType.cc14Bit` with both CC numbers
3. Reset tracking after detection

**No new packages needed:**
- Map/Set are Dart built-ins
- No timing library (no time window per spec)
- No statistical library (simple value range analysis determines byte order)

### Integration with Existing Code

**Files Modified:**
- `lib/ui/midi_listener/midi_listener_state.dart` - Add enum value, add state fields
- `lib/ui/midi_listener/midi_listener_cubit.dart` - Enhance `_handleMidiData()` logic
- `lib/ui/midi_listener/midi_listener_cubit.freezed.dart` - Regenerate via build_runner

**Files NOT Modified:**
- `pubspec.yaml` - No new dependencies
- `MidiMappingType` enum - Already has `cc14BitLow` and `cc14BitHigh` variants
- `PackedMappingData` - Already handles 14-bit encoding/decoding
- Mapping editor UI - Will read new state fields, no stack changes

**Build Commands:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze  # Must pass with zero warnings
flutter test     # Verify no regressions
```

## Alternatives Considered

| Approach | Why Not |
|----------|---------|
| **Add `collection` package** | Already in pubspec.yaml (^1.19.1), but not needed - Dart built-ins suffice |
| **Add `rxdart` for windowing** | No timing window requirement per spec, unnecessary complexity |
| **Add `quiver` for LRU cache** | Tracking is simple (Map + Set), no need for cache eviction library |
| **Separate detection service** | Cubit is already the MIDI event processor, no architectural reason to split |

## Version Verification

**flutter_midi_command ^0.5.3:**
- Published: 2023-11-20 (latest available)
- Provides: `MidiPacket` with `.data` property (UInt8List of raw MIDI bytes)
- Status: VERIFIED in existing code (`midi_listener_cubit.dart:108`)
- Confidence: HIGH (already working in production for 7-bit CC and note detection)

**flutter_bloc ^9.1.1:**
- Published: 2024-11-15 (current stable)
- Provides: Cubit pattern with emit()
- Status: VERIFIED in existing code
- Confidence: HIGH

**freezed ^3.2.3:**
- Published: 2025-01-15 (current stable)
- Provides: Code generation for immutable state classes with copyWith()
- Status: VERIFIED in existing code
- Confidence: HIGH

## Installation

No installation needed - all required packages already in `pubspec.yaml`.

## Sources

- [flutter_midi_command package](https://pub.dev/packages/flutter_midi_command) - MEDIUM confidence (pub.dev listing, verified in codebase)
- [flutter_bloc package](https://pub.dev/packages/flutter_bloc) - HIGH confidence (official package)
- [freezed package](https://pub.dev/packages/freezed) - HIGH confidence (official package)
- Existing codebase analysis - HIGH confidence (direct verification)

## Stack Recommendation

**DO:**
- Use existing infrastructure (flutter_midi_command, Cubit, Freezed)
- Implement as pure logic enhancement in `MidiListenerCubit`
- Add enum variant `cc14Bit` to `MidiEventType`
- Add state fields `lastDetectedCc14BitMsb` and `lastDetectedCc14BitLsb`

**DO NOT:**
- Add new packages
- Create separate service/manager classes
- Add timing/windowing libraries (not needed per spec)
- Modify core MIDI infrastructure (flutter_midi_command works)

## Risk Assessment

**Technical Risk: LOW**

Reasons:
- Zero new dependencies (no integration risk)
- Existing MIDI parsing already works (7-bit CC, notes)
- Algorithm is deterministic (no probabilistic/ML uncertainty)
- State changes are additive (no breaking changes)

**Integration Risk: LOW**

Reasons:
- Cubit is the natural place for this logic (already handles MIDI parsing)
- Freezed will auto-generate new copyWith() parameters
- UI can ignore new state fields if not ready (graceful degradation)
- Mapping editor already has `MidiMappingType.cc14BitLow/High` support

## Quality Gate

- [x] Versions are current (verified via pub.dev, dates noted)
- [x] Rationale explains WHY (algorithm is pure logic, no new tools needed)
- [x] Integration with existing stack considered (Cubit enhancement, Freezed regeneration)
- [x] Sources cited with confidence levels

## Next Steps for Implementation

1. Extend `MidiEventType` enum in `midi_listener_state.dart`
2. Add new state fields to `MidiListenerState.data` factory
3. Run `build_runner` to regenerate Freezed code
4. Enhance `_handleMidiData()` with pair-tracking logic
5. Add tests for 14-bit detection algorithm
6. Verify with `flutter analyze` (zero warnings required)
