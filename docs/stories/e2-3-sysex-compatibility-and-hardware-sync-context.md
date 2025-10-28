# Story Context: E2.3 - SysEx compatibility and hardware sync

**Generated:** 2025-10-27
**Epic:** E2 - 14-bit MIDI CC Support
**Story:** E2.3 - SysEx compatibility and hardware sync

---

## Story Summary

Verify that 14-bit MIDI CC types correctly encode in SysEx messages sent to hardware and correctly decode from hardware responses. Implement integration tests for round-trip verification and validate preset exchange compatibility with the reference HTML editor.

---

## Technical Context

### Architecture Alignment

**From `docs/architecture.md`:**

**SysEx Command System:**
- All hardware communication uses MIDI SysEx messages
- Message definitions in `lib/domain/disting_nt_sysex.dart`
- Request implementations in `lib/domain/sysex/requests/` (47 command types)
- Response parsers in `lib/domain/sysex/responses/`
- Scheduler in `lib/domain/disting_message_scheduler.dart` (queuing, retry, timeout)

**MIDI Manager Hierarchy:**
- `IDistingMidiManager` - Abstract interface
- `DistingMidiManager` - Live hardware communication
- `MockDistingMidiManager` - Demo mode for testing
- `OfflineDistingMidiManager` - Offline mode with cached data

**Testing Infrastructure:**
- Use `MockDistingMidiManager` for integration tests (no hardware required)
- Bloc/Cubit testing with `bloc_test` package
- Test files in `test/` directory mirror `lib/` structure

### SysEx Message Structure

**General Format:**
```
[0xF0] [0x00, 0x21, 0x27] [0x6D] [SysExId] [MessageType] [Payload...] [0xF7]
 Start  Expert Sleepers    NT    Device ID  Command      Data         End
```

**Set MIDI Mapping Command:**
- MessageType: `DistingNTRequestMessageType.setMidiMapping`
- Payload includes slot index, parameter index, and packed mapping data
- Packed data encoded using `PackedMappingData.encodeMIDIPackedData()`

**Mapping Response:**
- MessageType: `DistingNTRespMessageType.mappingResponse`
- Payload contains packed mapping data bytes
- Decoded using `PackedMappingData.fromBytes()`

---

## Code Locations

### Files to Verify/Update

| File | Purpose | Expected Status |
|------|---------|----------------|
| `lib/domain/sysex/requests/set_midi_mapping.dart` | Encoding | Should work with E2.1 changes |
| `lib/domain/sysex/responses/mapping_response.dart` | Decoding | Should work with E2.1 changes |

### Related Files (for Integration Tests)

| File | Purpose |
|------|---------|
| `lib/cubit/disting_cubit.dart` | State management for hardware operations |
| `lib/domain/mock_disting_midi_manager.dart` | Mock for testing without hardware |
| `test/models/packed_mapping_data_test.dart` | Existing unit tests |

---

## Implementation Details

### SysEx Encoding Verification

**In `set_midi_mapping.dart`:**
- Already uses `PackedMappingData.encodeMIDIPackedData()` from E2.1
- No code changes expected
- Verification: Inspect encoded SysEx message, confirm flags2 byte correct

**Expected Encoding:**
```dart
// User creates mapping with MidiMappingType.cc14BitLow
final mapping = PackedMappingData(
  midiMappingType: MidiMappingType.cc14BitLow,  // value = 3
  midiControllerNumber: 1,
  midiRelative: false,
  // ... other fields
);

final encoded = mapping.encodeMIDIPackedData();
// flags2 byte should be: 0 | (3 << 2) = 0x0C
```

### SysEx Decoding Verification

**In `mapping_response.dart`:**
- Already uses `PackedMappingData.fromBytes()` from E2.1
- No code changes expected
- Verification: Parse response with flags2=0x0C, confirm MidiMappingType.cc14BitLow

**Expected Decoding:**
```dart
// Hardware returns response with flags2 = 0x0C
final responseBytes = Uint8List.fromList([..., 0x0C, ...]);
final mapping = PackedMappingData.fromBytes(responseBytes);

// Should decode to:
// midiMappingType = MidiMappingType.cc14BitLow (value 3)
// midiRelative = false
```

---

## Testing Strategy

### Integration Tests

**Create `test/integration/midi_mapping_14bit_round_trip_test.dart`:**

1. **Round-trip with Mock Manager:**
   ```dart
   test('14-bit CC low mapping survives round-trip', () async {
     final cubit = DistingCubit(mockDatabase);
     await cubit.connectToDevice(mockInput, mockOutput, useMock: true);

     // Create mapping
     final original = PackedMappingData(
       midiMappingType: MidiMappingType.cc14BitLow,
       midiControllerNumber: 1,
       midiRelative: false,
       // ... other fields
     );

     // Save to mock hardware
     await cubit.setMidiMapping(slotIndex: 0, paramIndex: 0, mapping: original);

     // Read back from mock hardware
     final retrieved = await cubit.getMidiMapping(slotIndex: 0, paramIndex: 0);

     // Verify preserved
     expect(retrieved.midiMappingType, equals(MidiMappingType.cc14BitLow));
     expect(retrieved.midiControllerNumber, equals(1));
   });
   ```

2. **All MIDI Types Round-trip:**
   ```dart
   test('All 5 MIDI types preserve through round-trip', () async {
     for (final type in MidiMappingType.values) {
       final mapping = PackedMappingData(midiMappingType: type, ...);
       await cubit.setMidiMapping(..., mapping: mapping);
       final retrieved = await cubit.getMidiMapping(...);
       expect(retrieved.midiMappingType, equals(type));
     }
   });
   ```

3. **SysEx Message Inspection:**
   ```dart
   test('set_midi_mapping encodes 14-bit types correctly in SysEx', () {
     final message = SetMidiMappingMessage(
       sysExId: 0,
       mapping: PackedMappingData(midiMappingType: MidiMappingType.cc14BitHigh, ...),
     );

     final sysex = message.encode();

     // Find flags2 byte in payload (position depends on message structure)
     final flags2 = sysex[/* calculate offset */];

     // Verify type 4 encoded: (4 << 2) = 0x10
     expect(flags2 >> 2, equals(4));
   });
   ```

### Preset Exchange Tests (Manual)

**Test 1: nt_helper → HTML Editor**
1. Create preset in nt_helper with 14-bit CC mappings
   - Add algorithm to slot
   - Configure parameter with "14 bit CC - low" mapping, controller 1
   - Configure another parameter with "14 bit CC - high" mapping, controller 2
2. Save preset to file
3. Load preset in reference HTML editor (https://tools.disting.expert/)
4. Verify mappings show "14 bit CC - low" and "14 bit CC - high"
5. Verify controller numbers correct
6. Save from HTML editor, reload in nt_helper
7. Verify mappings still correct

**Test 2: HTML Editor → nt_helper**
1. Create preset in reference HTML editor with 14-bit CC mappings
2. Export preset file
3. Load in nt_helper
4. Verify dropdown shows correct 14-bit CC types
5. Verify controller numbers correct
6. Save to hardware (if available) and verify persistence

### Hardware Tests (Optional, if hardware available)

**With Real Disting NT (firmware 1.10+):**
1. Connect nt_helper to Disting NT via MIDI
2. Create 14-bit CC mapping for filter cutoff
3. Save to hardware
4. Power cycle module
5. Reconnect and verify mapping persists
6. Connect MIDI controller
7. Verify 14-bit resolution (16,384 values vs 128)
8. Compare behavior with reference HTML editor

---

## Dependencies

### Prerequisites
- **Story E2.1** - Encoding/decoding logic implemented
- **Story E2.2** - UI functional for creating 14-bit mappings

### External Dependencies
- Disting NT firmware 1.10+ (for hardware testing)
- Reference HTML editor at https://tools.disting.expert/ (for compatibility testing)
- Expert Sleepers reference commit 3e52e54+ deployed

---

## Implementation Notes

### If Code Changes Needed

**Scenario:** If set_midi_mapping.dart or mapping_response.dart don't use PackedMappingData methods:

**Fix set_midi_mapping.dart:**
```dart
// Ensure using PackedMappingData.encodeMIDIPackedData()
final payload = mapping.encodeMIDIPackedData();
// Include in SysEx message
```

**Fix mapping_response.dart:**
```dart
// Ensure using PackedMappingData.fromBytes()
final mapping = PackedMappingData.fromBytes(responseData);
// Return to caller
```

### Debugging Tips

**Enable SysEx Message Logging:**
- Enable debug prints in `DistingMessageScheduler`
- Shows all sent/received messages with timestamps
- Inspect flags2 byte in logged payloads

**Verify Encoding:**
```dart
debugPrint('Encoded flags2: 0x${flags2.toRadixString(16)}');
debugPrint('Type value: ${flags2 >> 2}');
```

**Verify Decoding:**
```dart
debugPrint('Received flags2: 0x${flags2.toRadixString(16)}');
debugPrint('Decoded type: ${mapping.midiMappingType}');
```

---

## Definition of Done Checklist

- [ ] `set_midi_mapping.dart` verified/updated for 14-bit encoding
- [ ] `mapping_response.dart` verified/updated for 14-bit decoding
- [ ] Round-trip integration test passes
- [ ] All 5 MIDI types tested in round-trip
- [ ] SysEx message inspection test passes
- [ ] Preset exchange with HTML editor verified (both directions)
- [ ] Hardware testing completed (if hardware available) or documented as skipped
- [ ] Integration tests written and passing
- [ ] `flutter analyze` passes with zero warnings
- [ ] Documentation updated with 14-bit CC support

---

## Success Criteria

**Epic E2 is complete when:**
1. Users can select 14-bit CC types in UI (E2.2)
2. Mappings encode correctly for hardware (E2.1 + E2.3)
3. Mappings decode correctly from hardware (E2.1 + E2.3)
4. Round-trip tests pass (create → save → read → verify)
5. Presets exchange correctly with HTML editor
6. All tests pass, zero analyzer warnings
7. Feature documented and ready for release

---

## Epic Context Reference

See `docs/tech-spec-epic-2.md` for full epic technical specification.
