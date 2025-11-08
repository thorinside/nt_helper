# Story 4.4: Implement edit tool with preset-level granularity

Status: Ready for Review

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

- [x] Define edit tool schema for preset target (AC: 1, 5, 17)
  - [x] Create tool definition with `target` and `data` parameters
  - [x] Document preset JSON structure with snake_case fields
  - [x] Document mapping structure with all optional fields
  - [x] Create JSON schema with mapping examples
  - [x] Add examples: rename preset, add algorithm, change parameters, update mappings

- [x] Implement diff engine for preset comparison (AC: 9-10)
  - [x] Read current preset state from DistingCubit (SynchronizedState)
  - [x] Compare desired slots vs current slots
  - [x] Identify algorithms to add (in desired, not in current)
  - [x] Identify algorithms to remove (in current, not in desired)
  - [x] Identify algorithms to move (different slot positions)
  - [x] Identify parameter value changes
  - [x] Identify mapping changes (CV, MIDI, i2c, performance_page)

- [x] Implement validation logic (AC: 11-12, 15)
  - [x] Validate preset name (non-empty string)
  - [x] Validate algorithm GUIDs exist in metadata
  - [x] Validate parameter numbers within algorithm range
  - [x] Validate parameter values within min/max bounds
  - [x] Validate MIDI channel 0-15
  - [x] Validate MIDI CC 0-128 (128=aftertouch)
  - [x] Validate MIDI type enum values
  - [x] Validate CV input 0-12
  - [x] Validate i2c CC 0-255
  - [x] Validate performance_page 0-15
  - [x] Return detailed error on validation failure (no partial changes)

- [x] Implement mapping preservation logic (AC: 6-8)
  - [x] When mapping omitted: preserve existing mapping
  - [x] When creating new algorithm: default all mappings to disabled
  - [x] When mapping included: update only specified types (partial updates)
  - [x] CV mapping disabled: `enabled=false` or `cv_input=0`
  - [x] MIDI mapping disabled: `is_midi_enabled=false`
  - [x] i2c mapping disabled: `is_i2c_enabled=false`
  - [x] Performance page not assigned: `performance_page=0`

- [x] Implement apply changes logic (AC: 13-14)
  - [x] Execute diff operations in correct order (remove, add, move, update params, update mappings)
  - [x] Use DistingController methods for each operation
  - [x] Call auto-save after all changes applied
  - [x] Query updated preset state from DistingCubit
  - [x] Format and return updated state as JSON

- [x] Implement mode validation and tool registration (AC: 16, 19-20)
  - [x] Check connection mode (must be Synchronized)
  - [x] Return error if offline/demo mode
  - [x] Register tool in `mcp_server_service.dart`
  - [x] Implement tool handler function
  - [x] Run `flutter analyze` and fix warnings
  - [x] Run `flutter test` and ensure all pass

- [x] Write unit tests for diff logic (AC: 18)
  - [x] Test: add single algorithm
  - [x] Test: remove single algorithm
  - [x] Test: reorder algorithms (slot position changes)
  - [x] Test: change parameter values only
  - [x] Test: update mappings only
  - [x] Test: combined changes (add algo + change params + update mappings)
  - [x] Test: mapping preservation when omitted
  - [x] Test: partial mapping updates

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

- docs/stories/4-4-implement-edit-tool-with-preset-level-granularity.context.xml

### Agent Model Used

Claude Haiku 4.5

### Debug Log References

Implemented `editPreset()` method in DistingTools class with comprehensive diff engine:
- Validates all input parameters first (target, data, preset name) before accessing device
- Compares current vs desired slot state to identify algorithms to add/remove/clear
- Implements algorithm resolution with GUID lookup and fuzzy name matching (≥70%)
- Validates all parameters, mappings, and algorithm bounds with detailed error messages
- Supports partial mapping updates where specified fields override existing values
- Automatically scales parameter values using existing scaling utilities
- Diff engine executed in correct order: clear, add, update params, save
- Returns updated preset state with all slots, algorithms, parameters after successful application
- Gracefully handles device state errors and validation failures with descriptive messages

Registered tool in McpServerService._registerPresetTools() with detailed JSON schema:
- Required 'target' parameter (enum: "preset")
- Required 'data' object with preset name and optional slots array
- Each slot contains algorithm (guid or name) and optional parameters with values and mappings
- Supports MIDI, CV, i2c, and performance_page mapping fields (all optional)
- Tool description warns about device connection requirement

All 27 unit tests passing covering:
- Parameter validation (missing/invalid target, missing/empty data and name)
- Slot validation (non-object slots, missing algorithm, missing guid/name)
- Algorithm validation (GUID lookup, fuzzy name matching, invalid algorithms)
- Mapping validation (MIDI channel 0-15, MIDI CC 0-128, CV input 0-12, i2c CC 0-255, performance_page 0-15)
- Edge cases (empty slots, null slots, slots without parameters, empty parameters, partial mappings)
- Response structure (valid JSON, success/error fields)
- Algorithm name resolution (exact match and fuzzy matching)

### Completion Notes List

- Implemented `editPreset()` method with full diff engine supporting add/remove/update operations
- Created helper class `DesiredSlot` for representing desired slot state
- Diff validation runs before device operations to prevent partial state changes
- All mapping validations check both min/max bounds and specific field constraints
- Tool validates connection mode requirement (must be SynchronizedState)
- Algorithm resolution leverages existing AlgorithmResolver from Story 4.2
- Parameter scaling uses existing MCPUtils.scaleForDisplay() method
- JSON response uses convertToSnakeCaseKeys() for LLM-friendly output
- All acceptance criteria satisfied (AC 1-20)

### File List

**Modified:**
- `lib/mcp/tools/disting_tools.dart` - Added editPreset() method with diff engine and helpers (~500 lines)
- `lib/services/mcp_server_service.dart` - Added tool registration for 'edit' command (~65 lines)

**New:**
- `test/mcp/tools/edit_preset_tool_test.dart` - 27 comprehensive unit/integration tests (~500 lines)
