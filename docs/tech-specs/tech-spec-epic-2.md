# Epic Technical Specification: 14-bit MIDI CC Support

Date: 2025-10-27
Author: Neal
Epic ID: 2
Status: Draft

---

## Overview

This epic extends the existing MIDI mapping system to support 14-bit MIDI Continuous Controller (CC) messages, matching functionality added to the Expert Sleepers reference implementation. 14-bit MIDI CC uses paired controller numbers (MSB controller N and LSB controller N+32) to achieve 16,384 discrete values instead of the standard 128 values provided by 7-bit CC, eliminating zipper noise and enabling smooth, high-resolution parameter control for critical synthesis parameters.

The implementation follows the pattern established in the Expert Sleepers reference commit (3e52e54), which simplified the MIDI type encoding from complex boolean flag logic to direct type value encoding using bit shifts. This change naturally accommodates the new 14-bit CC modes (type values 3 and 4) alongside existing CC (0), Note Momentary (1), and Note Toggle (2) modes.

## Objectives and Scope

**In Scope:**
- Extend `MidiMappingType` enum to include `cc14BitLow` (value=3) and `cc14BitHigh` (value=4)
- Refactor `PackedMappingData` encoding/decoding to use bit-shift operations for type values
- Update mapping editor UI dropdown to expose 14-bit CC options
- Ensure SysEx encoding/decoding preserves 14-bit types in hardware communication
- Maintain compatibility with reference HTML preset editor for preset exchange
- Disable "MIDI Relative" switch for 14-bit CC types (same behavior as note types)

**Out of Scope:**
- Runtime MIDI message interpretation/handling (hardware handles pairing MSB/LSB)
- UI for manually pairing CC numbers (hardware automatically uses N and N+32)
- Migration of existing 7-bit CC mappings to 14-bit (user must manually reconfigure)
- Documentation of MIDI 14-bit CC protocol itself (standard MIDI specification)

## System Architecture Alignment

This epic works within the existing MIDI mapping infrastructure without introducing new services or architectural components:

**Affected Components:**
- `lib/models/packed_mapping_data.dart` - Data model for MIDI mapping encoding/decoding
- `lib/ui/widgets/packed_mapping_data_editor.dart` - UI for configuring MIDI mappings in parameter property editor
- `lib/domain/sysex/requests/set_midi_mapping.dart` - SysEx command for writing mappings to hardware
- `lib/domain/sysex/responses/mapping_response.dart` - SysEx response parser for reading mappings from hardware

**Architectural Constraints:**
- Must maintain SysEx message format compatibility with Disting NT firmware 1.10+
- Must maintain preset file format compatibility with reference HTML editor
- UI changes must follow existing property editor patterns (no new screens)
- Type encoding must remain 7-bit safe for MIDI SysEx transmission

## Detailed Design

### Services and Modules

No new services or modules required. Changes confined to existing components:

| Component | Responsibility | Changes Required |
|-----------|---------------|------------------|
| `PackedMappingData` model | MIDI mapping data encoding/decoding | Add enum values, refactor bit-shift logic |
| `packed_mapping_data_editor.dart` | UI for mapping configuration | Add dropdown options, disable relative for 14-bit |
| `set_midi_mapping.dart` | SysEx request encoding | Verify type encoding compatibility |
| `mapping_response.dart` | SysEx response parsing | Verify type decoding compatibility |

### Data Models and Contracts

**MidiMappingType Enum** (`lib/models/packed_mapping_data.dart`):

```dart
enum MidiMappingType {
  cc(0),              // Existing: Standard 7-bit CC
  noteMomentary(1),   // Existing: MIDI note on/off
  noteToggle(2),      // Existing: MIDI note toggle
  cc14BitLow(3),      // NEW: 14-bit CC low byte (MSB)
  cc14BitHigh(4);     // NEW: 14-bit CC high byte (LSB)

  final int value;
  const MidiMappingType(this.value);
}
```

**PackedMappingData Structure**:

```dart
class PackedMappingData {
  final MidiMappingType midiMappingType;
  final bool midiRelative;  // Disabled for 14-bit types
  final int midiControllerNumber;
  final int i2cAddress;
  // ... other fields

  // Encoding: midiFlags2 = rel | (type << 2)
  // Decoding: type = flags2 >> 2
}
```

**Bit Layout in midiFlags2 byte:**
- Bit 0: `midiRelative` flag
- Bit 1: Reserved (was toggle flag, now unused)
- Bits 2-6: `midiMappingType` value (supports 0-31)

**Reference Implementation Pattern** (from commit 3e52e54):
```javascript
// Before (complex boolean logic):
let type = ( flags2 & 4 ) ? ( ( flags2 & 2 ) ? 2 : 1 ) : 0;

// After (direct bit-shift):
let type = flags2 >> 2;

// Encoding before:
let flags2 = rel | ( toggle << 1 ) | ( mtype << 2 );

// Encoding after:
let flags2 = rel | ( 0 << 1 ) | ( type << 2 );
```

### APIs and Interfaces

**PackedMappingData Methods**:

```dart
// Factory constructor for decoding SysEx bytes
factory PackedMappingData.fromBytes(Uint8List data) {
  final flags2 = data[offsetIndex];
  final type = MidiMappingType.values[flags2 >> 2];  // Bit-shift decode
  final relative = (flags2 & 0x01) != 0;
  // ... decode remaining fields
}

// Encoding method for SysEx transmission
Uint8List encodeMIDIPackedData() {
  final midiFlags2 = (midiRelative ? 1 : 0) | (midiMappingType.value << 2);
  return Uint8List.fromList([
    // ... other bytes
    midiFlags2,
    // ... remaining bytes
  ]);
}
```

**UI Editor Interface** (`packed_mapping_data_editor.dart`):

```dart
DropdownButton<MidiMappingType>(
  value: _data.midiMappingType,
  items: [
    DropdownMenuItem(value: MidiMappingType.cc, child: Text('CC')),
    DropdownMenuItem(value: MidiMappingType.noteMomentary, child: Text('Note - momentary')),
    DropdownMenuItem(value: MidiMappingType.noteToggle, child: Text('Note - toggle')),
    DropdownMenuItem(value: MidiMappingType.cc14BitLow, child: Text('14 bit CC - low')),   // NEW
    DropdownMenuItem(value: MidiMappingType.cc14BitHigh, child: Text('14 bit CC - high')), // NEW
  ],
  onChanged: (newType) {
    setState(() {
      _data = _data.copyWith(midiMappingType: newType);
    });
  },
)

// Disable relative switch for 14-bit and note types
Switch(
  value: _data.midiRelative,
  onChanged: _canUseRelative() ? (value) { /* ... */ } : null,
)

bool _canUseRelative() {
  return _data.midiMappingType == MidiMappingType.cc;  // Only CC supports relative
}
```

### Workflows and Sequencing

**User Workflow: Creating 14-bit MIDI Mapping**

1. User opens parameter property editor for a parameter
2. User selects MIDI mapping tab
3. User selects "14 bit CC - low" or "14 bit CC - high" from type dropdown
4. "MIDI Relative" switch becomes disabled (greyed out)
5. User enters CC controller number (hardware will automatically pair with N+32)
6. User saves mapping
7. App encodes mapping with type value 3 or 4
8. App sends `set_midi_mapping` SysEx command to hardware
9. Hardware acknowledges and stores mapping

**Preset Exchange Workflow**

1. User creates preset with 14-bit mappings in nt_helper
2. User exports/saves preset
3. `PackedMappingData.encodeMIDIPackedData()` encodes type as `(type << 2)` in flags2
4. Preset file contains encoded mapping data
5. User loads preset in reference HTML editor
6. HTML editor decodes type as `flags2 >> 2`
7. Dropdown shows "14 bit CC - low" or "14 bit CC - high"
8. Mapping works identically in both editors

**Hardware Sync Workflow**

1. App requests existing mappings via SysEx
2. `mapping_response.dart` receives response bytes
3. Parser decodes type using `flags2 >> 2`
4. Creates `PackedMappingData` with correct `MidiMappingType`
5. UI displays mapping with correct type in dropdown
6. User can edit and resave mapping
7. Round-trip preserves type value

## Non-Functional Requirements

### Performance

- Enum value changes and bit-shift operations add negligible overhead (<1μs per operation)
- No impact on UI render performance (dropdown adds 2 items)
- SysEx message size unchanged (same byte count)
- No additional database queries or network calls required

### Security

- No security implications (local data model changes only)
- No new attack surface introduced
- Type value remains 7-bit safe (0-4 values, well within 0-127 MIDI range)

### Reliability/Availability

- Backward compatible: existing presets with types 0-2 load correctly
- Forward compatible: reference editor supports types 3-4
- Graceful handling of invalid type values (clamp to valid range)
- Existing tests continue to pass with enum extension

### Observability

- Use existing `debugPrint()` for type encoding/decoding
- Analyzer warnings must remain at zero
- Test coverage for new enum values and bit-shift logic

## Dependencies and Integrations

**Internal Dependencies:**
- `lib/models/packed_mapping_data.dart` - Core data model
- `lib/ui/widgets/packed_mapping_data_editor.dart` - UI component
- `lib/domain/sysex/requests/set_midi_mapping.dart` - SysEx encoding
- `lib/domain/sysex/responses/mapping_response.dart` - SysEx decoding

**External Dependencies:**
- Disting NT firmware 1.10+ (supports 14-bit CC types)
- Reference HTML preset editor (commit 3e52e54+)

**No New Dependencies Required:**
- Flutter SDK: 3.35.1 (existing)
- Dart SDK: 3.8.1+ (existing)
- All existing packages remain at current versions

## Acceptance Criteria (Authoritative)

1. **Data Model**: `MidiMappingType` enum includes `cc14BitLow` (value=3) and `cc14BitHigh` (value=4)
2. **Encoding**: `PackedMappingData.encodeMIDIPackedData()` encodes type using `(type << 2)` bit-shift
3. **Decoding**: `PackedMappingData.fromBytes()` decodes type using `flags2 >> 2` bit-shift
4. **UI**: Mapping editor dropdown displays "14 bit CC - low" and "14 bit CC - high" options
5. **UI**: "MIDI Relative" switch is disabled when 14-bit CC type is selected
6. **SysEx**: `set_midi_mapping` command correctly encodes 14-bit types in hardware messages
7. **SysEx**: `mapping_response` parser correctly decodes 14-bit types from hardware responses
8. **Round-trip**: Create 14-bit mapping → save to hardware → read back → verify type preserved
9. **Preset Exchange**: Presets with 14-bit mappings load correctly in reference HTML editor
10. **Preset Exchange**: Presets created in HTML editor with 14-bit mappings load correctly in nt_helper
11. **Testing**: All existing tests pass with enum extension
12. **Testing**: New tests verify 14-bit type encoding/decoding
13. **Quality**: `flutter analyze` passes with zero warnings

## Traceability Mapping

| AC # | Spec Section | Component(s) | Test Idea |
|------|-------------|-------------|-----------|
| 1 | Data Models → MidiMappingType | `packed_mapping_data.dart` | Unit test enum values |
| 2 | APIs → encodeMIDIPackedData | `packed_mapping_data.dart` | Unit test bit-shift encoding |
| 3 | APIs → fromBytes | `packed_mapping_data.dart` | Unit test bit-shift decoding |
| 4 | APIs → UI Editor Interface | `packed_mapping_data_editor.dart` | Widget test dropdown items |
| 5 | APIs → UI Editor Interface | `packed_mapping_data_editor.dart` | Widget test switch state |
| 6 | Dependencies → set_midi_mapping | `set_midi_mapping.dart` | SysEx message inspection |
| 7 | Dependencies → mapping_response | `mapping_response.dart` | Response parser unit test |
| 8 | Workflows → Hardware Sync | Integration | Full round-trip test |
| 9 | Workflows → Preset Exchange | Integration | Export/import with HTML editor |
| 10 | Workflows → Preset Exchange | Integration | Import HTML preset into nt_helper |
| 11-12 | Test Strategy → Coverage | All components | Test suite execution |
| 13 | Observability | All components | Analyzer execution |

## Risks, Assumptions, Open Questions

**Assumptions:**
- Firmware 1.10+ correctly implements 14-bit CC type handling (verified via Expert Sleepers reference implementation)
- Reference HTML editor commit 3e52e54 is deployed and accessible to users
- Hardware automatically pairs CC N with CC N+32 for 14-bit resolution (no app-side pairing logic needed)
- Bit layout in midiFlags2 remains stable across firmware versions

**Risks:**
- **LOW**: Existing presets with custom flags2 values outside 0-2 range could decode incorrectly
  - *Mitigation*: Validate type value range during decoding, clamp to valid values
- **LOW**: Reference HTML editor version mismatch could cause preset incompatibility
  - *Mitigation*: Document minimum HTML editor version requirement
- **VERY LOW**: Bit-shift implementation differs between Dart and JavaScript
  - *Mitigation*: Reference commit 3e52e54 confirms JavaScript pattern, Dart bit-shift is identical

**Open Questions:**
- None (implementation pattern fully defined by reference commit)

## Test Strategy Summary

**Unit Tests:**
- `test/models/packed_mapping_data_test.dart`:
  - Test `cc14BitLow` and `cc14BitHigh` enum values
  - Test encoding with types 3 and 4 produces correct flags2 byte
  - Test decoding flags2 with types 3 and 4 produces correct enum
  - Test relative flag disabled for 14-bit types

**Widget Tests:**
- `test/ui/widgets/packed_mapping_data_editor_test.dart`:
  - Test dropdown displays all 5 type options
  - Test selecting 14-bit type updates data model
  - Test relative switch becomes disabled for 14-bit types
  - Test visual consistency with existing design

**Integration Tests:**
- `test/integration/midi_mapping_round_trip_test.dart`:
  - Create mapping with 14-bit type in UI
  - Encode to SysEx and simulate hardware save
  - Decode hardware response
  - Verify type preserved through round-trip

**Compatibility Tests:**
- Manual testing with reference HTML preset editor
- Export preset from nt_helper with 14-bit mappings
- Load in HTML editor, verify dropdown shows correct type
- Export from HTML editor with 14-bit mappings
- Load in nt_helper, verify correct type displayed

**Existing Test Impact:**
- All existing `packed_mapping_data_test.dart` tests must pass
- No changes required to tests for types 0-2 (backward compatible)

**Coverage Target:**
- Enum extension: 100% (simple value addition)
- Encoding/decoding logic: 100% (critical path)
- UI changes: 80%+ (widget test coverage)
- Integration: Manual verification + automated round-trip test
