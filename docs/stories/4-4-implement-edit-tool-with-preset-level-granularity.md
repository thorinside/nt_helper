# Story 4.4: Implement edit tool with preset-level granularity

Status: drafted

## Story

As an LLM client modifying a preset,
I want to send a complete desired preset state and have the backend calculate minimal changes,
So that I don't need to understand NT hardware slot reordering and algorithm movement.

## Acceptance Criteria

1. Create `edit` tool accepting: `target` ("preset"), `data` (object with preset JSON)
2. Preset JSON format: `{ "name": "...", "slots": [ { "algorithm": {...}, "parameters": [...] } ] }`
3. Parameter structure: `{ "parameter_number": N, "value": V, "mapping": {...} }` where mapping is optional
4. Mapping structure (all fields optional): `{ "cv": {...}, "midi": {...}, "i2c": {...}, "performance_page": N }`
5. Use snake_case for all JSON field names: `cv_input`, `midi_channel`, `is_midi_enabled`, etc.
6. When mapping omitted entirely from parameter JSON, existing mapping is preserved unchanged
7. When creating new parameters (new algorithm), all mapping types default to disabled (cv/midi/i2c enabled=false, performance_page=0)
8. When mapping included, only specified mapping types are updated, others preserved
9. Backend diff engine compares desired state vs current device state (reads from SynchronizedState)
10. Diff engine determines: algorithms to add, algorithms to remove, algorithms to move, parameters to change, mappings to update
11. Diff validates all changes before applying (fail fast on first validation error)
12. Mapping validation: MIDI channel 0-15, MIDI CC 0-128 (128=aftertouch), CV input 0-12, i2c CC 0-255, performance_page 0-15, etc.
13. If validation succeeds, apply changes and auto-save preset
14. Return updated preset state after successful application
15. Return detailed error message if validation or application fails (no partial changes)
16. Tool works only in connected mode (clear error if offline/demo)
17. JSON schema documents complete preset structure with mapping examples
18. Unit tests verify diff logic: add algorithm, remove algorithm, reorder algorithms, change parameters, update mappings, combined changes
19. `flutter analyze` passes with zero warnings
20. All tests pass

## Tasks / Subtasks

- [ ] Define edit tool schema for preset target (AC: 1, 5, 17)
  - [ ] Create tool definition with `target` and `data` parameters
  - [ ] Document preset JSON structure with snake_case fields
  - [ ] Document mapping structure with all optional fields
  - [ ] Create JSON schema with mapping examples
  - [ ] Add examples: rename preset, add algorithm, change parameters, update mappings

- [ ] Implement diff engine for preset comparison (AC: 9-10)
  - [ ] Read current preset state from DistingCubit (SynchronizedState)
  - [ ] Compare desired slots vs current slots
  - [ ] Identify algorithms to add (in desired, not in current)
  - [ ] Identify algorithms to remove (in current, not in desired)
  - [ ] Identify algorithms to move (different slot positions)
  - [ ] Identify parameter value changes
  - [ ] Identify mapping changes (CV, MIDI, i2c, performance_page)

- [ ] Implement validation logic (AC: 11-12, 15)
  - [ ] Validate preset name (non-empty string)
  - [ ] Validate algorithm GUIDs exist in metadata
  - [ ] Validate parameter numbers within algorithm range
  - [ ] Validate parameter values within min/max bounds
  - [ ] Validate MIDI channel 0-15
  - [ ] Validate MIDI CC 0-128 (128=aftertouch)
  - [ ] Validate MIDI type enum values
  - [ ] Validate CV input 0-12
  - [ ] Validate i2c CC 0-255
  - [ ] Validate performance_page 0-15
  - [ ] Return detailed error on validation failure (no partial changes)

- [ ] Implement mapping preservation logic (AC: 6-8)
  - [ ] When mapping omitted: preserve existing mapping
  - [ ] When creating new algorithm: default all mappings to disabled
  - [ ] When mapping included: update only specified types (partial updates)
  - [ ] CV mapping disabled: `enabled=false` or `cv_input=0`
  - [ ] MIDI mapping disabled: `is_midi_enabled=false`
  - [ ] i2c mapping disabled: `is_i2c_enabled=false`
  - [ ] Performance page not assigned: `performance_page=0`

- [ ] Implement apply changes logic (AC: 13-14)
  - [ ] Execute diff operations in correct order (remove, add, move, update params, update mappings)
  - [ ] Use DistingController methods for each operation
  - [ ] Call auto-save after all changes applied
  - [ ] Query updated preset state from DistingCubit
  - [ ] Format and return updated state as JSON

- [ ] Implement mode validation and tool registration (AC: 16, 19-20)
  - [ ] Check connection mode (must be Synchronized)
  - [ ] Return error if offline/demo mode
  - [ ] Register tool in `mcp_server_service.dart`
  - [ ] Implement tool handler function
  - [ ] Run `flutter analyze` and fix warnings
  - [ ] Run `flutter test` and ensure all pass

- [ ] Write unit tests for diff logic (AC: 18)
  - [ ] Test: add single algorithm
  - [ ] Test: remove single algorithm
  - [ ] Test: reorder algorithms (slot position changes)
  - [ ] Test: change parameter values only
  - [ ] Test: update mappings only
  - [ ] Test: combined changes (add algo + change params + update mappings)
  - [ ] Test: mapping preservation when omitted
  - [ ] Test: partial mapping updates

## Dev Notes

### Architecture Context

- State management: `lib/cubit/disting_cubit.dart` (SynchronizedState)
- Controller: `lib/services/disting_controller.dart` and `disting_controller_impl.dart`
- Algorithm operations: `addAlgorithm()`, `clearSlot()`, `moveAlgorithm()`
- Parameter operations: `updateParameterValue()`, mapping updates
- State model: `lib/cubit/disting_state.dart` (Slot, ParameterInfo, RoutingInfo)

### Diff Engine Strategy

**Algorithm Changes**:
1. Remove algorithms: Clear slots for algorithms in current but not in desired
2. Add algorithms: Add new algorithms to empty slots
3. Move algorithms: Reorder to match desired slot positions

**Parameter Changes**:
1. Compare parameter values (current vs desired)
2. Update only changed values via `updateParameterValue()`

**Mapping Changes**:
1. Compare mapping state (current vs desired)
2. Update only changed mappings
3. Partial updates: only specified types updated, others preserved

### Snake Case Convention

All JSON field names use snake_case for better LLM parsing:
- `parameter_number` (not parameterNumber)
- `cv_input` (not cvInput)
- `midi_channel` (not midiChannel)
- `is_midi_enabled` (not isMidiEnabled)
- `performance_page` (not performancePage)

### Mapping Structure

```json
{
  "cv": {
    "source": 0,
    "cv_input": 1,
    "is_unipolar": false,
    "is_gate": false,
    "volts": 10.0,
    "delta": 1.0
  },
  "midi": {
    "is_midi_enabled": true,
    "midi_channel": 0,
    "midi_type": "cc",
    "midi_cc": 74,
    "is_midi_symmetric": false,
    "is_midi_relative": false,
    "midi_min": 0,
    "midi_max": 127
  },
  "i2c": {
    "is_i2c_enabled": true,
    "i2c_cc": 20,
    "is_i2c_symmetric": false,
    "i2c_min": 0,
    "i2c_max": 255
  },
  "performance_page": 1
}
```

### Validation Error Messages

- Clear and actionable error messages
- Include which field failed and why
- Example: "MIDI channel must be 0-15, got 16"
- Example: "Parameter 5 value 150 exceeds maximum 100"

### Testing Strategy

- Unit tests with mock DistingCubit and controller
- Test each diff operation type separately
- Test combined operations
- Test validation failures
- Test mapping preservation and partial updates
- Integration tests with mock hardware state

### Project Structure Notes

- Tool implementation: `lib/mcp/tools/disting_tools.dart`
- Diff engine: Create new file `lib/services/preset_diff_engine.dart` (or inline in tool handler)
- Validation: Create new file `lib/services/preset_validator.dart` (or inline)
- Test file: `test/mcp/tools/edit_preset_tool_test.dart`

### References

- [Source: docs/architecture.md#State Management]
- [Source: docs/architecture.md#Critical Architecture: MCP Server]
- [Source: docs/epics.md#Story E4.4]
- [Source: lib/cubit/disting_state.dart - Slot model]
- [Source: lib/models/packed_mapping_data.dart - Mapping structure]

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
