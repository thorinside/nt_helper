# Story 4.5: Implement edit tool with slot-level granularity

Status: drafted

## Story

As an LLM client modifying a single slot,
I want to send desired slot state without affecting other slots,
So that I can make targeted changes efficiently.

## Acceptance Criteria

1. Extend `edit` tool to accept: `target` ("slot"), `slot_index` (int, required), `data` (object with slot JSON)
2. Slot JSON format: `{ "algorithm": { "guid": "...", "specifications": [...] }, "name": "...", "parameters": [...] }`
3. Parameter structure: `{ "parameter_number": N, "value": V, "mapping": {...} }` where mapping is optional
4. Mapping fields (all optional): `cv`, `midi`, `i2c`, `performance_page` using snake_case naming
5. When mapping omitted, existing mapping is preserved
6. When mapping included, only specified types are updated (partial updates supported)
7. Backend compares desired slot vs current slot at specified index (reads from SynchronizedState)
8. If algorithm changes: backend handles parameter/mapping reset automatically (tools just render SynchronizedState)
9. If algorithm stays same: update only changed parameters and mappings
10. If slot name provided: update custom slot name
11. Validate slot_index in range 0-31
12. Validate algorithm exists and specifications are valid
13. Validate parameter values against algorithm constraints
14. Validate mapping fields: MIDI channel 0-15, CC 0-128, type enum valid, CV input 0-12, i2c CC 0-255, performance_page 0-15
15. Apply changes and auto-save preset
16. Return updated slot state after successful application
17. Return error if validation fails (no partial changes)
18. JSON schema includes mapping examples: MIDI CC, CV input, i2c, performance page, combined mappings
19. `flutter analyze` passes with zero warnings
20. All tests pass

## Tasks / Subtasks

- [ ] Extend edit tool schema for slot target (AC: 1, 4, 18)
  - [ ] Add "slot" target option to edit tool
  - [ ] Add `slot_index` parameter (required for slot target)
  - [ ] Document slot JSON structure with snake_case fields
  - [ ] Document optional algorithm change with guid/specifications
  - [ ] Document optional slot name
  - [ ] Create mapping examples: MIDI CC, CV input, i2c, performance page, combined

- [ ] Implement slot-level diff logic (AC: 7-10)
  - [ ] Read current slot state from DistingCubit at specified index
  - [ ] Compare desired algorithm vs current algorithm (GUID match)
  - [ ] If algorithm changes: clear slot and add new algorithm with specifications
  - [ ] If algorithm same: compare parameters and mappings
  - [ ] Identify parameter value changes
  - [ ] Identify mapping changes (CV, MIDI, i2c, performance_page)
  - [ ] If slot name provided: update custom slot name

- [ ] Implement validation logic (AC: 11-14, 17)
  - [ ] Validate slot_index in range 0-31
  - [ ] Validate algorithm GUID exists in metadata
  - [ ] Validate specifications against algorithm requirements
  - [ ] Validate parameter numbers within algorithm range
  - [ ] Validate parameter values within min/max bounds
  - [ ] Validate MIDI channel 0-15
  - [ ] Validate MIDI CC 0-128
  - [ ] Validate MIDI type enum values (cc, note_momentary, note_toggle, cc_14bit_low, cc_14bit_high)
  - [ ] Validate CV input 0-12
  - [ ] Validate i2c CC 0-255
  - [ ] Validate performance_page 0-15
  - [ ] Return detailed error on validation failure

- [ ] Implement mapping preservation and partial updates (AC: 5-6)
  - [ ] When mapping omitted: preserve all existing mappings
  - [ ] When mapping included: update only specified types
  - [ ] Example: `{ "midi": {...} }` updates MIDI, preserves CV/i2c/performance_page
  - [ ] Empty mapping object `{}` is valid and preserves all mappings
  - [ ] Partial MIDI mapping: update only provided MIDI fields, preserve others

- [ ] Implement apply changes and return state (AC: 15-16)
  - [ ] If algorithm changed: call `clearSlot()` then `addAlgorithm()` with specifications
  - [ ] If algorithm same: call `updateParameterValue()` for each changed parameter
  - [ ] Update mappings via appropriate controller methods
  - [ ] If slot name provided: update custom slot name
  - [ ] Call auto-save after changes
  - [ ] Query updated slot state from DistingCubit
  - [ ] Return slot state as JSON with parameters and enabled mappings

- [ ] Testing and validation (AC: 19-20)
  - [ ] Write unit tests for slot-level diff logic
  - [ ] Test algorithm change (clear + add)
  - [ ] Test parameter value changes only
  - [ ] Test mapping updates only
  - [ ] Test custom slot name update
  - [ ] Test mapping preservation when omitted
  - [ ] Test partial mapping updates (e.g., MIDI only)
  - [ ] Test validation failures (slot_index out of range, invalid mappings)
  - [ ] Run `flutter analyze` and fix warnings
  - [ ] Run `flutter test` and ensure all pass

## Dev Notes

### Architecture Context

- State management: `lib/cubit/disting_cubit.dart` (SynchronizedState with 32 slots)
- Controller: `lib/services/disting_controller.dart` and `disting_controller_impl.dart`
- Slot operations: `getAlgorithmInSlot()`, `clearSlot()`, `addAlgorithm()`, `updateParameterValue()`
- Slot model: `lib/cubit/disting_state.dart` (Slot class with index, algorithm, parameters, routing, customName)

### Slot-Level vs Preset-Level Editing

**Slot-level (this story)**:
- Targeted changes to single slot
- More efficient for small edits
- Preserves other slots unchanged
- Simpler diff logic (compare one slot)

**Preset-level (Story 4.4)**:
- Complete preset restructuring
- Can reorder algorithms across slots
- Handles complex multi-slot changes
- More complex diff logic (compare all slots)

### Algorithm Change Handling

When algorithm GUID changes:
1. Backend automatically resets parameters to defaults
2. Backend automatically resets all mappings to disabled
3. Tool just needs to specify new algorithm + specifications
4. Tools render resulting SynchronizedState, don't need to manually reset

When algorithm stays same:
1. Parameters retain current values unless explicitly changed
2. Mappings retain current state unless explicitly changed
3. Partial updates supported

### Custom Slot Names

- Disting NT supports custom slot names
- Optional field in slot JSON: `"name": "My Filter"`
- If provided: update custom name
- If omitted: preserve existing custom name

### Mapping Partial Updates

Full mapping update:
```json
{
  "mapping": {
    "midi": { "is_midi_enabled": true, "midi_channel": 0, "midi_cc": 74 },
    "cv": { "cv_input": 1 },
    "performance_page": 1
  }
}
```

Partial mapping update (MIDI only):
```json
{
  "mapping": {
    "midi": { "is_midi_enabled": true, "midi_channel": 0, "midi_cc": 74 }
  }
}
```
Result: MIDI updated, CV and performance_page preserved

### Testing Strategy

- Unit tests with mock DistingCubit
- Test each change type separately
- Test combined changes
- Test validation failures
- Test mapping preservation and partial updates
- Integration tests verifying state after changes

### Project Structure Notes

- Tool implementation: `lib/mcp/tools/disting_tools.dart` (extend edit tool)
- Diff logic: May reuse from Story 4.4 or create slot-specific diff
- Test file: `test/mcp/tools/edit_slot_tool_test.dart`

### References

- [Source: docs/architecture.md#State Management]
- [Source: docs/epics.md#Story E4.5]
- [Source: lib/cubit/disting_state.dart - Slot class]
- [Source: lib/services/disting_controller.dart - slot operations]

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
