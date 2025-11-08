# Story 4.7: Implement show tool for state inspection

Status: drafted

## Story

As an LLM client inspecting current state,
I want a flexible show tool that displays preset, slot, parameter, screen, or routing information with mappings included,
So that I can understand the current configuration before making changes.

## Acceptance Criteria

1. Create `show` tool accepting: `target` ("preset"|"slot"|"parameter"|"screen"|"routing", required), `identifier` (string or int, optional)
2. When `target: "preset"`, return complete preset with all slots, parameters, and mappings (rendered from SynchronizedState)
3. Parameter structure includes: `parameter_number`, `parameter_name`, `value`, `min`, `max`, `unit`, `mapping` (optional - only if enabled)
4. Mapping structure uses snake_case: `cv_input`, `midi_channel`, `is_midi_enabled`, etc.
5. Disabled mappings omitted from output (only include mapping object if at least one type is enabled)
6. CV mapping included if: `cv_input > 0` OR `source > 0`
7. CV mapping fields: `source`, `cv_input`, `is_unipolar`, `is_gate`, `volts`, `delta`
8. MIDI mapping included if: `is_midi_enabled == true`
9. MIDI mapping fields: `is_midi_enabled`, `midi_channel`, `midi_type` ("cc"|"note_momentary"|"note_toggle"|"cc_14bit_low"|"cc_14bit_high"), `midi_cc`, `is_midi_symmetric`, `is_midi_relative`, `midi_min`, `midi_max`
10. i2c mapping included if: `is_i2c_enabled == true`
11. i2c mapping fields: `is_i2c_enabled`, `i2c_cc`, `is_i2c_symmetric`, `i2c_min`, `i2c_max`
12. Performance page included if: `performance_page > 0` (value 1-15)
13. When `target: "slot"`, require `identifier` (int slot_index), return single slot with all parameters and enabled mappings
14. When `target: "parameter"`, require `identifier` (format: "slot_index:parameter_number"), return single parameter with mapping (if enabled)
15. When `target: "screen"`, return current device screen as base64 JPEG image (reuse existing screenshot logic)
16. When `target: "routing"`, return routing state in same format as current `get_routing` tool
17. Routing returns physical names (Input N, Output N, Aux N, None) not internal bus numbers
18. Routing works in both online and offline modes (uses routing editor state)
19. Validate identifier format and ranges for each target type
20. Return clear error if identifier missing when required or invalid
21. JSON schema documents all target types with complete mapping field descriptions and examples
22. `flutter analyze` passes with zero warnings
23. All tests pass

## Tasks / Subtasks

- [ ] Define show tool schema (AC: 1, 4, 21)
  - [ ] Create tool definition with `target` and `identifier` parameters
  - [ ] Document all five target types: preset, slot, parameter, screen, routing
  - [ ] Document identifier requirements for each target
  - [ ] Document mapping structure with snake_case fields
  - [ ] Document complete mapping field descriptions
  - [ ] Create examples for each target type

- [ ] Implement preset target (AC: 2-3, 5)
  - [ ] Read complete preset state from DistingCubit (SynchronizedState)
  - [ ] Extract preset name
  - [ ] Extract all slots with algorithms
  - [ ] For each slot: include all parameters with name, number, value, min, max, unit
  - [ ] Include mapping object only if at least one type is enabled
  - [ ] Format as JSON response

- [ ] Implement mapping inclusion logic (AC: 5-12)
  - [ ] CV mapping included if: `cv_input > 0` OR `source > 0`
  - [ ] CV fields: source, cv_input, is_unipolar, is_gate, volts, delta
  - [ ] MIDI mapping included if: `is_midi_enabled == true`
  - [ ] MIDI fields: is_midi_enabled, midi_channel, midi_type, midi_cc, is_midi_symmetric, is_midi_relative, midi_min, midi_max
  - [ ] i2c mapping included if: `is_i2c_enabled == true`
  - [ ] i2c fields: is_i2c_enabled, i2c_cc, is_i2c_symmetric, i2c_min, i2c_max
  - [ ] Performance page included if: `performance_page > 0` (values 1-15)
  - [ ] Omit mapping object entirely if all types disabled

- [ ] Implement slot target (AC: 13)
  - [ ] Require `identifier` parameter (int slot_index)
  - [ ] Validate slot_index in range 0-31
  - [ ] Read slot state from DistingCubit at specified index
  - [ ] Return slot with algorithm, all parameters, and enabled mappings
  - [ ] Format as JSON response

- [ ] Implement parameter target (AC: 14)
  - [ ] Require `identifier` parameter (format: "slot_index:parameter_number")
  - [ ] Parse identifier into slot_index and parameter_number
  - [ ] Validate slot_index in range 0-31
  - [ ] Validate parameter_number within slot's parameter count
  - [ ] Read parameter state from DistingCubit
  - [ ] Return parameter with: number, name, value, min, max, unit, mapping (if enabled)
  - [ ] Format as JSON response

- [ ] Implement screen target (AC: 15)
  - [ ] Reuse existing screenshot logic from DistingCubit
  - [ ] Call `takeScreenshot()` method
  - [ ] Return base64-encoded JPEG image
  - [ ] Return error if screenshot not supported (offline/demo mode)

- [ ] Implement routing target (AC: 16-18)
  - [ ] Read routing state from RoutingEditorCubit
  - [ ] Reuse format from existing `get_routing` MCP tool
  - [ ] Return physical names: "Input N", "Output N", "Aux N", "None"
  - [ ] Do NOT return internal bus numbers
  - [ ] Support both online and offline modes
  - [ ] Format as JSON response

- [ ] Implement validation and error handling (AC: 19-20)
  - [ ] Validate identifier present when required (slot, parameter)
  - [ ] Validate identifier format for parameter target (slot_index:parameter_number)
  - [ ] Validate slot_index ranges
  - [ ] Validate parameter_number ranges
  - [ ] Return clear error messages for validation failures
  - [ ] Include guidance in error messages (e.g., "slot_index must be 0-31, got 42")

- [ ] Register tool and test (AC: 22-23)
  - [ ] Add tool registration in `mcp_server_service.dart`
  - [ ] Implement tool handler function with target dispatch
  - [ ] Write unit tests for each target type
  - [ ] Test mapping inclusion logic
  - [ ] Test identifier validation
  - [ ] Test in all connection modes (demo, offline, connected)
  - [ ] Test error cases (missing identifier, invalid ranges)
  - [ ] Run `flutter analyze` and fix warnings
  - [ ] Run `flutter test` and ensure all pass

## Dev Notes

### Architecture Context

- State management: `lib/cubit/disting_cubit.dart` (SynchronizedState)
- Routing state: `lib/cubit/routing_editor_cubit.dart`
- Screenshot: `lib/cubit/disting_cubit.dart` (`takeScreenshot()` method)
- Existing routing tool: `lib/mcp/tools/disting_tools.dart` (`get_routing`)
- Parameter model: `lib/cubit/disting_state.dart` (ParameterInfo)
- Mapping model: `lib/models/packed_mapping_data.dart`

### Mapping Inclusion Rules

**CV Mapping** - Include if enabled:
- Condition: `cv_input > 0` OR `source > 0`
- Fields: source, cv_input, is_unipolar, is_gate, volts, delta

**MIDI Mapping** - Include if enabled:
- Condition: `is_midi_enabled == true`
- Fields: is_midi_enabled, midi_channel, midi_type, midi_cc, is_midi_symmetric, is_midi_relative, midi_min, midi_max

**i2c Mapping** - Include if enabled:
- Condition: `is_i2c_enabled == true`
- Fields: is_i2c_enabled, i2c_cc, is_i2c_symmetric, i2c_min, i2c_max

**Performance Page** - Include if assigned:
- Condition: `performance_page > 0`
- Values: 1-15 (0 means not assigned)

**Omit entire mapping object** if all types disabled.

### Target Examples

**Preset target**:
```json
{
  "target": "preset"
}
```

**Slot target**:
```json
{
  "target": "slot",
  "identifier": 0
}
```

**Parameter target**:
```json
{
  "target": "parameter",
  "identifier": "0:5"
}
```

**Screen target**:
```json
{
  "target": "screen"
}
```

**Routing target**:
```json
{
  "target": "routing"
}
```

### Response Format Examples

**Preset response** (partial):
```json
{
  "name": "My Preset",
  "slots": [
    {
      "slot_index": 0,
      "algorithm": { "guid": "...", "name": "VCO" },
      "parameters": [
        {
          "parameter_number": 0,
          "parameter_name": "Pitch",
          "value": 64,
          "min": 0,
          "max": 127,
          "unit": "semitones",
          "mapping": {
            "midi": {
              "is_midi_enabled": true,
              "midi_channel": 0,
              "midi_type": "cc",
              "midi_cc": 74
            },
            "performance_page": 1
          }
        }
      ]
    }
  ]
}
```

**Parameter response**:
```json
{
  "slot_index": 0,
  "parameter_number": 5,
  "parameter_name": "Cutoff Frequency",
  "value": 64,
  "min": 0,
  "max": 127,
  "unit": "Hz",
  "mapping": {
    "cv": {
      "cv_input": 1,
      "is_unipolar": false
    }
  }
}
```

### Routing Response Format

Reuse existing `get_routing` tool format:
- Physical names: "Input 1", "Input 2", "Output 1", "Output 2", "Aux 1", "Aux 2", "None"
- NOT internal bus numbers (1-42)
- Works in both online and offline modes

### Testing Strategy

- Unit tests for each target type
- Test mapping inclusion logic for all combinations
- Test identifier validation and parsing
- Test in all connection modes
- Test error cases
- Integration tests verifying state accuracy

### Project Structure Notes

- Tool implementation: `lib/mcp/tools/disting_tools.dart` (new `show` tool)
- Reuse existing routing tool logic
- Test file: `test/mcp/tools/show_tool_test.dart`

### References

- [Source: docs/architecture.md#State Management]
- [Source: docs/architecture.md#Critical Architecture: MCP Server]
- [Source: docs/epics.md#Story E4.7]
- [Source: lib/cubit/disting_state.dart - ParameterInfo]
- [Source: lib/models/packed_mapping_data.dart - mapping structure]

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
