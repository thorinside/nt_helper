# Story Context: E2.1 - Extend MidiMappingType enum and data model

**Generated:** 2025-10-27
**Epic:** E2 - 14-bit MIDI CC Support
**Story:** E2.1 - Extend MidiMappingType enum and data model

---

## Story Summary

Extend the `MidiMappingType` enum to support 14-bit MIDI CC by adding `cc14BitLow` (value=3) and `cc14BitHigh` (value=4) values. Refactor `PackedMappingData` encoding/decoding to use bit-shift operations (`flags2 >> 2` for decoding, `type << 2` for encoding) instead of conditional boolean logic, matching the pattern from Expert Sleepers reference commit 3e52e54.

---

## Technical Context

### Architecture Alignment

**From `docs/architecture.md`:**
- Data models use Freezed + json_serializable for immutable classes
- Models located in `lib/models/` directory
- Current pattern: `PackedMappingData` is a Freezed data class with encoding/decoding methods
- MIDI mapping data encoded in packed byte format for SysEx transmission

**Key Components:**
- `lib/models/packed_mapping_data.dart` - Core data model for MIDI mapping encoding/decoding
- `lib/domain/sysex/requests/set_midi_mapping.dart` - Uses encoded mapping data
- `lib/domain/sysex/responses/mapping_response.dart` - Parses mapping data from hardware

### Reference Implementation Pattern

From Expert Sleepers commit 3e52e54453eef243fe07e356718a97b081152209:

**Decoding Change:**
```javascript
// Before (complex conditional):
let type = ( flags2 & 4 ) ? ( ( flags2 & 2 ) ? 2 : 1 ) : 0;

// After (simple bit-shift):
let type = flags2 >> 2;
```

**Encoding Change:**
```javascript
// Before (boolean flags):
let toggle = ( type == 2 );
let mtype = ( type != 0 );
let flags2 = rel | ( toggle << 1 ) | ( mtype << 2 );

// After (direct type value):
let flags2 = rel | ( 0 << 1 ) | ( type << 2 );
```

### Current Implementation

`lib/models/packed_mapping_data.dart` currently has:
- 3 MIDI types: cc (0), noteMomentary (1), noteToggle (2)
- Conditional decoding logic for extracting type from flags2
- Boolean flag encoding for creating flags2

### Required Changes

1. **Enum Extension:**
   ```dart
   enum MidiMappingType {
     cc(0),
     noteMomentary(1),
     noteToggle(2),
     cc14BitLow(3),      // NEW
     cc14BitHigh(4);     // NEW

     final int value;
     const MidiMappingType(this.value);
   }
   ```

2. **Decoding Refactor (in fromBytes()):**
   - Replace conditional logic with: `final type = MidiMappingType.values[flags2 >> 2];`
   - Extract relative flag: `final relative = (flags2 & 0x01) != 0;`

3. **Encoding Refactor (in encodeMIDIPackedData()):**
   - Replace boolean logic with: `final midiFlags2 = (midiRelative ? 1 : 0) | (midiMappingType.value << 2);`

---

## Code Locations

### Files to Modify

| File | Lines | Changes Required |
|------|-------|------------------|
| `lib/models/packed_mapping_data.dart` | ~200-300 | Add enum values, refactor encoding/decoding methods |

### Related Files (Read Only - for context)

| File | Purpose |
|------|---------|
| `lib/domain/sysex/requests/set_midi_mapping.dart` | Uses `encodeMIDIPackedData()` - verify compatibility |
| `lib/domain/sysex/responses/mapping_response.dart` | Uses `fromBytes()` - verify compatibility |
| `test/models/packed_mapping_data_test.dart` | Existing tests - must continue to pass |

---

## Testing Strategy

### Unit Tests Required

In `test/models/packed_mapping_data_test.dart`:

1. **Enum value tests:**
   - Verify `cc14BitLow.value == 3`
   - Verify `cc14BitHigh.value == 4`

2. **Encoding tests:**
   - Create mapping with type 3, encode, verify flags2 byte
   - Create mapping with type 4, encode, verify flags2 byte
   - Verify relative flag preserved

3. **Decoding tests:**
   - Decode bytes with flags2 = 0x0C (type 3), verify MidiMappingType.cc14BitLow
   - Decode bytes with flags2 = 0x10 (type 4), verify MidiMappingType.cc14BitHigh
   - Verify relative flag extracted correctly

4. **Backward compatibility:**
   - Test existing types 0-2 still encode/decode correctly
   - Run all existing tests - must pass

### Quality Gates

- `flutter analyze` - zero warnings
- `flutter test` - all tests pass
- No breaking changes to existing API

---

## Dependencies

### Prerequisites
- None (foundational change)

### Blocks
- Story E2.2 (UI needs enum values)
- Story E2.3 (SysEx needs encoding/decoding)

---

## Implementation Notes

### Bit Layout in midiFlags2

```
Bit 7 | Bit 6 | Bit 5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0
------+-------+-------+-------+-------+-------+-------+-------
  0   | Type  | Type  | Type  | Type  | Type  |   0   |  Rel
```

- Bit 0: Relative flag (0 = absolute, 1 = relative)
- Bit 1: Reserved (always 0)
- Bits 2-6: Type value (0-31 supported, 0-4 used)
- Bit 7: Always 0 (7-bit MIDI safe)

### Type Value Mapping

| Type | Value | Flags2 (rel=0) | Flags2 (rel=1) |
|------|-------|----------------|----------------|
| cc | 0 | 0x00 | 0x01 |
| noteMomentary | 1 | 0x04 | 0x05 |
| noteToggle | 2 | 0x08 | 0x09 |
| cc14BitLow | 3 | 0x0C | 0x0D |
| cc14BitHigh | 4 | 0x10 | 0x11 |

### Code Style

- Use `debugPrint()` for logging, never `print()`
- Follow existing Freezed pattern for immutable data classes
- Maintain null-safety
- Use descriptive variable names
- Add comments explaining bit-shift operations

---

## Definition of Done Checklist

- [ ] Enum extended with cc14BitLow (3) and cc14BitHigh (4)
- [ ] fromBytes() uses bit-shift decoding
- [ ] encodeMIDIPackedData() uses bit-shift encoding
- [ ] Unit tests added for new enum values
- [ ] Unit tests added for encoding/decoding
- [ ] All existing tests pass
- [ ] `flutter analyze` passes with zero warnings
- [ ] Code review completed
- [ ] Changes match reference implementation pattern

---

## Epic Context Reference

See `docs/tech-spec-epic-2.md` for full epic technical specification including:
- Complete overview of 14-bit MIDI CC support
- Detailed design and architecture alignment
- Acceptance criteria and traceability mapping
- NFRs and test strategy
