# Story 4.6: Implement edit tool with parameter-level granularity

Status: drafted

## Story

As an LLM client adjusting specific parameters,
I want to set parameter values and mappings by name or number without sending full preset/slot data,
So that I can make quick parameter tweaks efficiently.

## Acceptance Criteria

1. Extend `edit` tool to accept: `target` ("parameter"), `slot_index` (int, required), `parameter` (string or int, required), `value` (number, optional), `mapping` (object, optional)
2. Support parameter identification by: `parameter_name` (string) OR `parameter_number` (int, 0-based)
3. When using `parameter_name`, search slot parameters for matching name (exact match required)
4. When `value` provided: validate and update parameter value
5. When `mapping` provided: validate and update parameter mapping
6. When both `value` and `mapping` omitted: return error "Must provide value or mapping"
7. Mapping object structure (all fields optional, snake_case): `cv`, `midi`, `i2c`, `performance_page`
8. Partial mapping updates supported - only specified mapping types are updated, others preserved. Example: `{ "midi": {...} }` updates only MIDI, preserves CV/i2c/performance_page
9. Empty mapping object `{}` is valid and preserves all existing mappings
10. Validate slot_index in range 0-31
11. Validate parameter exists in slot
12. Validate value within parameter min/max range (if provided)
13. Validate mapping fields strictly: MIDI channel 0-15, MIDI CC 0-128, MIDI type enum values, CV input 0-12, CV source (algorithm output index), i2c CC 0-255, performance_page 0-15
14. Apply changes and auto-save preset
15. Return updated parameter state: `{ "slot_index": N, "parameter_number": N, "parameter_name": "...", "value": N, "mapping": {...} }`
16. Disabled mappings omitted from return value (only enabled mappings included)
17. Return error if parameter not found, value out of range, or mapping validation fails
18. JSON schema includes complete mapping field documentation with valid ranges and examples
19. `flutter analyze` passes with zero warnings
20. All tests pass

## Tasks / Subtasks

- [ ] Extend edit tool schema for parameter target (AC: 1-2, 7, 18)
  - [ ] Add "parameter" target option to edit tool
  - [ ] Add `slot_index` parameter (required)
  - [ ] Add `parameter` parameter (string or int, required)
  - [ ] Add `value` parameter (number, optional)
  - [ ] Add `mapping` parameter (object, optional)
  - [ ] Document mapping structure with all optional fields (snake_case)
  - [ ] Document complete mapping field valid ranges
  - [ ] Create examples: update value, update mapping, update both, partial mapping update

- [ ] Implement parameter lookup logic (AC: 2-3, 11)
  - [ ] Read slot state from DistingCubit at specified index
  - [ ] If `parameter` is int: use as parameter_number directly
  - [ ] If `parameter` is string: search slot parameters for exact name match
  - [ ] If parameter not found by name: return error with available parameter names
  - [ ] Validate parameter exists in slot

- [ ] Implement validation logic (AC: 4-6, 10, 12-13, 17)
  - [ ] Validate slot_index in range 0-31
  - [ ] Validate at least one of `value` or `mapping` is provided
  - [ ] If value provided: validate within parameter min/max range
  - [ ] If mapping provided: validate all mapping fields
  - [ ] Validate MIDI channel 0-15
  - [ ] Validate MIDI CC 0-128 (128=aftertouch)
  - [ ] Validate MIDI type enum values
  - [ ] Validate CV input 0-12
  - [ ] Validate CV source (algorithm output index)
  - [ ] Validate i2c CC 0-255
  - [ ] Validate performance_page 0-15
  - [ ] Return detailed error messages for validation failures

- [ ] Implement partial mapping updates (AC: 8-9)
  - [ ] When mapping is empty object `{}`: preserve all existing mappings
  - [ ] When mapping contains only `midi`: update MIDI only, preserve CV/i2c/performance_page
  - [ ] When mapping contains only `cv`: update CV only, preserve MIDI/i2c/performance_page
  - [ ] When mapping contains only `i2c`: update i2c only, preserve CV/MIDI/performance_page
  - [ ] When mapping contains only `performance_page`: update page only, preserve CV/MIDI/i2c
  - [ ] Support combinations: e.g., `{ "midi": {...}, "performance_page": 1 }`

- [ ] Implement apply changes and return state (AC: 14-16)
  - [ ] If value provided: call `updateParameterValue(slot_index, parameter_number, value)`
  - [ ] If mapping provided: update mapping via appropriate controller methods
  - [ ] Call auto-save after changes
  - [ ] Query updated parameter state from DistingCubit
  - [ ] Format return value with: slot_index, parameter_number, parameter_name, value
  - [ ] Include mapping object only if at least one type is enabled
  - [ ] Omit disabled mappings from return value

- [ ] Testing and validation (AC: 19-20)
  - [ ] Write unit tests for parameter lookup (by number and by name)
  - [ ] Test value update only
  - [ ] Test mapping update only
  - [ ] Test value + mapping update combined
  - [ ] Test partial mapping updates (each type separately)
  - [ ] Test empty mapping object `{}`
  - [ ] Test validation failures (slot_index, parameter not found, value out of range, invalid mapping fields)
  - [ ] Test error when both value and mapping omitted
  - [ ] Run `flutter analyze` and fix warnings
  - [ ] Run `flutter test` and ensure all pass

## Dev Notes

### Architecture Context

- State management: `lib/cubit/disting_cubit.dart` (SynchronizedState)
- Controller: `lib/services/disting_controller.dart` and `disting_controller_impl.dart`
- Parameter operations: `updateParameterValue()`, mapping update methods
- Parameter model: `lib/cubit/disting_state.dart` (ParameterInfo class)
- Mapping model: `lib/models/packed_mapping_data.dart`

### Parameter Identification

**By number (0-based)**:
```json
{
  "target": "parameter",
  "slot_index": 0,
  "parameter": 5,
  "value": 64
}
```

**By name (exact match)**:
```json
{
  "target": "parameter",
  "slot_index": 0,
  "parameter": "Cutoff Frequency",
  "value": 64
}
```

If name not found, error should list available parameter names for that slot.

### Mapping Update Examples

**Update value only**:
```json
{
  "target": "parameter",
  "slot_index": 0,
  "parameter": 5,
  "value": 64
}
```

**Update MIDI mapping only**:
```json
{
  "target": "parameter",
  "slot_index": 0,
  "parameter": "Cutoff Frequency",
  "mapping": {
    "midi": {
      "is_midi_enabled": true,
      "midi_channel": 0,
      "midi_cc": 74,
      "midi_type": "cc"
    }
  }
}
```

**Update value and mapping**:
```json
{
  "target": "parameter",
  "slot_index": 0,
  "parameter": 5,
  "value": 64,
  "mapping": {
    "midi": { "is_midi_enabled": true, "midi_channel": 0, "midi_cc": 74 },
    "performance_page": 1
  }
}
```

**Preserve all mappings (empty object)**:
```json
{
  "target": "parameter",
  "slot_index": 0,
  "parameter": 5,
  "value": 64,
  "mapping": {}
}
```

### Mapping Fields Documentation

**CV Mapping**:
- `source` (int): Algorithm output index for observing other algorithm outputs (advanced)
- `cv_input` (int, 0-12): Physical CV input number
- `is_unipolar` (bool): Unipolar vs bipolar mode
- `is_gate` (bool): Gate mode
- `volts` (float): Voltage scaling
- `delta` (float): Sensitivity

**MIDI Mapping**:
- `is_midi_enabled` (bool): Enable/disable MIDI control
- `midi_channel` (int, 0-15): MIDI channel
- `midi_type` (enum): "cc", "note_momentary", "note_toggle", "cc_14bit_low", "cc_14bit_high"
- `midi_cc` (int, 0-128): MIDI CC number (128=aftertouch)
- `is_midi_symmetric` (bool): Symmetric scaling
- `is_midi_relative` (bool): Relative mode
- `midi_min` (int): Minimum value for scaling
- `midi_max` (int): Maximum value for scaling

**i2c Mapping**:
- `is_i2c_enabled` (bool): Enable/disable i2c control
- `i2c_cc` (int, 0-255): i2c CC number
- `is_i2c_symmetric` (bool): Symmetric scaling
- `i2c_min` (int): Minimum value
- `i2c_max` (int): Maximum value

**Performance Page**:
- `performance_page` (int, 0-15): Performance page assignment (0=not assigned, 1-15=page number)

### Return Value Format

**Value only updated**:
```json
{
  "slot_index": 0,
  "parameter_number": 5,
  "parameter_name": "Cutoff Frequency",
  "value": 64
}
```

**Value and MIDI mapping enabled**:
```json
{
  "slot_index": 0,
  "parameter_number": 5,
  "parameter_name": "Cutoff Frequency",
  "value": 64,
  "mapping": {
    "midi": {
      "is_midi_enabled": true,
      "midi_channel": 0,
      "midi_type": "cc",
      "midi_cc": 74
    }
  }
}
```

Disabled mappings are omitted from return value.

### Testing Strategy

- Unit tests for all parameter lookup scenarios
- Test all mapping type combinations
- Test partial updates
- Test validation edge cases (boundaries: channel 15, CC 128, etc.)
- Test error messages are clear and actionable
- Integration tests with mock hardware state

### Project Structure Notes

- Tool implementation: `lib/mcp/tools/disting_tools.dart` (extend edit tool)
- Test file: `test/mcp/tools/edit_parameter_tool_test.dart`

### References

- [Source: docs/architecture.md#State Management]
- [Source: docs/epics.md#Story E4.6]
- [Source: lib/cubit/disting_state.dart - ParameterInfo class]
- [Source: lib/models/packed_mapping_data.dart - mapping structure]

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
