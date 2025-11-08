# Story 4.3: Implement new tool for preset initialization

Status: drafted

## Story

As an LLM client starting preset creation,
I want a tool that creates a new blank preset or preset with initial algorithms,
So that I have a clean starting point for building my configuration.

## Acceptance Criteria

1. Create `new` tool accepting: `name` (string, required), `algorithms` (array, optional)
2. When `algorithms` not provided, create blank preset with specified name
3. When `algorithms` provided, accept array of: `{ "guid": "...", "name": "...", "specifications": [...] }`
4. Support algorithm identification by GUID or name (fuzzy matching ≥70%)
5. `specifications` array provides values for algorithm creation (required for some algorithms, optional for others)
6. Tool validates algorithm existence before creation
7. Tool validates specification values against algorithm requirements
8. Tool clears current preset on device (unsaved changes lost - warn in description)
9. Tool adds algorithms sequentially to slots 0, 1, 2, etc.
10. New algorithms have default parameter values and all mappings disabled (CV/MIDI/i2c enabled=false, performance_page=0)
11. Return created preset state with all slots, default parameter values, and disabled mappings
12. Tool fails with clear error if in offline/demo mode
13. JSON schema includes examples: blank preset, preset with 1 algorithm, preset with 3 algorithms
14. `flutter analyze` passes with zero warnings
15. All tests pass

## Tasks / Subtasks

- [ ] Define new tool schema (AC: 1, 13)
  - [ ] Create tool definition with `name` and `algorithms` parameters
  - [ ] Document `algorithms` array structure with guid/name/specifications
  - [ ] Add warning about clearing current preset (unsaved changes lost)
  - [ ] Create JSON schema with three examples (blank, 1 algo, 3 algos)
  - [ ] Document specification value format and requirements

- [ ] Implement algorithm validation (AC: 4, 6-7)
  - [ ] Implement GUID lookup in AlgorithmMetadataService
  - [ ] Implement fuzzy name matching (≥70% similarity, reuse from Story 4.2)
  - [ ] Validate algorithm existence before preset creation
  - [ ] Validate specification values against algorithm requirements
  - [ ] Return clear error messages for validation failures

- [ ] Implement preset initialization logic (AC: 2, 8-10)
  - [ ] Call `DistingCubit.requestNewPreset()` to clear current preset
  - [ ] Set preset name via DistingController
  - [ ] When algorithms array empty: leave preset blank
  - [ ] When algorithms provided: add sequentially via `DistingController.addAlgorithm()`
  - [ ] Assign to slots 0, 1, 2, ... in order
  - [ ] Ensure default parameter values for each algorithm
  - [ ] Ensure all mappings disabled (CV/MIDI/i2c enabled=false, performance_page=0)

- [ ] Implement state return (AC: 11)
  - [ ] Query current preset state from DistingCubit
  - [ ] Extract all slots with algorithms
  - [ ] Include default parameter values for each slot
  - [ ] Include disabled mapping state for each parameter
  - [ ] Format as JSON response

- [ ] Implement mode validation (AC: 12)
  - [ ] Check current connection mode via DistingCubit state
  - [ ] Throw error if in offline mode: "Cannot create preset in offline mode"
  - [ ] Throw error if in demo mode: "Cannot create preset in demo mode"
  - [ ] Only allow in connected mode (synchronized state)

- [ ] Register tool and test (AC: 14-15)
  - [ ] Add tool registration in `mcp_server_service.dart`
  - [ ] Implement tool handler function
  - [ ] Write unit tests for validation logic
  - [ ] Write integration tests for preset creation
  - [ ] Test blank preset creation
  - [ ] Test preset with algorithms
  - [ ] Test specification validation
  - [ ] Test mode validation (offline/demo rejection)
  - [ ] Run `flutter analyze` and fix warnings
  - [ ] Run `flutter test` and ensure all pass

## Dev Notes

### Architecture Context

- Preset management: `lib/cubit/disting_cubit.dart` (`requestNewPreset()`, `requestSavePreset()`)
- Controller interface: `lib/services/disting_controller.dart`
- Controller implementation: `lib/services/disting_controller_impl.dart`
- Algorithm metadata: `lib/services/algorithm_metadata_service.dart`
- State model: `lib/cubit/disting_state.dart` (Synchronized state)

### Preset Initialization Flow

1. Check connection mode (must be Synchronized state)
2. Call `requestNewPreset()` - clears current preset on device
3. Set preset name
4. For each algorithm in array:
   - Validate algorithm exists (GUID or fuzzy name match)
   - Validate specifications if provided
   - Call `addAlgorithm()` with algorithm + specifications
5. Algorithms auto-assigned to slots 0, 1, 2, etc.
6. Parameters get default values from algorithm metadata
7. All mappings default to disabled

### Default Mapping State

- CV mapping: `enabled=false`, all fields zero/null
- MIDI mapping: `is_midi_enabled=false`, all fields default
- i2c mapping: `is_i2c_enabled=false`, all fields default
- Performance page: `performance_page=0` (not assigned)

### Specification Handling

- Specifications are algorithm-specific configuration values
- Some algorithms require specifications (e.g., polyphonic algorithms need voice count)
- Others have optional specifications or none at all
- Validate against algorithm metadata requirements

### Testing Strategy

- Mock DistingCubit for unit tests
- Test blank preset creation (no algorithms)
- Test single algorithm preset
- Test multi-algorithm preset
- Test GUID-based algorithm selection
- Test fuzzy name matching for algorithm selection
- Test specification validation
- Test mode validation (reject offline/demo)

### Project Structure Notes

- Tool implementation: `lib/mcp/tools/disting_tools.dart`
- Tool registration: `lib/services/mcp_server_service.dart`
- Test file: `test/mcp/tools/new_tool_test.dart`
- Reuse fuzzy matching from Story 4.2

### References

- [Source: docs/architecture.md#Critical Architecture: MCP Server]
- [Source: docs/architecture.md#State Management]
- [Source: docs/epics.md#Story E4.3]
- [Source: lib/cubit/disting_cubit.dart - requestNewPreset method]

## Dev Agent Record

### Context Reference

- docs/stories/4-3-implement-new-tool-for-preset-initialization.context.xml

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
