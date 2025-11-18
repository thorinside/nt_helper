# Story 7.4: Synchronize Output Mode Usage Data

Status: pending

## Story

As a developer maintaining the nt_helper routing system,
I want output mode usage relationships synchronized from the hardware via SysEx 0x55 messages,
So that the routing editor can determine which parameters control output mode and which parameters are affected by those controls using hardware data instead of pattern matching.

## Context

The distingNT firmware now provides output mode usage data via SysEx 0x55 messages (commit 39b5376). When a parameter has the `isOutputMode` flag set (bit 3 of I/O flags), the firmware can respond with a list of parameters whose output routing is controlled by that mode parameter.

This story implements:
1. The SysEx 0x55 request/response handling
2. Automatic querying when parameters with `isOutputMode` flag are detected
3. Storage of output mode relationships in synchronized state
4. MCP exposure of output mode data

Story 7.3 provides the `isOutputMode` flag that triggers these queries. Story 7.5 will consume this data to replace pattern matching in the routing editor.

## Acceptance Criteria

### AC-1: SysEx Message Type Definition

1. Add `respOutputModeUsage(0x55)` to `DistingNTRespMessageType` enum
2. Add corresponding enum value with proper documentation

### AC-2: Request Message Implementation

3. Create `RequestOutputModeUsage` class in `lib/domain/sysex/requests/`
4. Constructor accepts `slotIndex` and `parameterNumber`
5. Generates SysEx message: `[0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x55, slot, (p>>14)&3, (p>>7)&0x7f, p&0x7f, 0xF7]`
6. Parameter number encoded as 16-bit value split into three 7-bit bytes
7. Follows existing SysEx request patterns in codebase

### AC-3: Response Message Implementation

8. Create `OutputModeUsageResponse` class in `lib/domain/sysex/responses/`
9. Parses response payload:
   - Bytes 0-2: Source parameter number (16-bit, 7-bit encoded)
   - Byte 3: Number of affected parameters
   - Bytes 4+: List of affected parameter numbers (each 3 bytes, 7-bit encoded)
10. Returns structured data: `OutputModeUsage` class with:
    - `int sourceParameterNumber` - The mode control parameter
    - `List<int> affectedParameterNumbers` - Parameters controlled by this mode
11. Follows existing SysEx response patterns in codebase

### AC-4: Response Factory Integration

12. Update `ResponseFactory` to handle `respOutputModeUsage` message type
13. Return `OutputModeUsageResponse` instance for 0x55 messages
14. Follow existing factory pattern for message type dispatch

### AC-5: Automatic Query Mechanism

15. When `ParameterInfo` with `isOutputMode=true` is received, automatically queue request for output mode usage
16. `DistingCubit` or MIDI manager schedules `RequestOutputModeUsage` for that parameter
17. Debounce mechanism ensures only one query per parameter during sync operations
18. Queries triggered during initial algorithm load and parameter info refresh

### AC-6: State Management

19. Add `OutputModeUsage` data structure to store relationships:
    - `Map<int, List<int>> outputModeMap` - Maps mode parameter number to affected parameter numbers
20. `DistingCubit` stores output mode relationships per slot
21. State updates when `OutputModeUsageResponse` is received
22. Output mode data persists across parameter value updates
23. Clear output mode data when algorithm changes or slot is cleared

### AC-7: Offline/Mock Mode Behavior

24. `MockDistingMidiManager` returns empty output mode relationships (no data in mock mode)
25. `OfflineDistingMidiManager` returns empty output mode relationships (no data in offline mode)
26. Offline behavior does not trigger 0x55 queries (no hardware available)
27. Offline behavior documented in code comments

### AC-8: MCP Integration

28. Add `get_output_mode_usage` MCP tool accepting `slot` and `parameter_number`
29. Returns JSON with:
    - `source_parameter_number: int`
    - `affected_parameters: array of int`
30. Update `show` tool to include output mode relationships in slot details
31. Parameter search results include `controls_output_mode: boolean` flag

### AC-9: Unit Testing

32. Unit test verifies 0x55 request message generation with correct encoding
33. Unit test verifies response parsing for single affected parameter
34. Unit test verifies response parsing for multiple affected parameters
35. Unit test verifies empty response (no affected parameters)
36. Unit test verifies state updates when response received
37. Unit test verifies offline/mock managers don't trigger queries

### AC-10: Integration Testing

38. Integration test with real hardware verifies automatic querying
39. Test algorithm with output mode parameters triggers 0x55 requests
40. Test output mode relationships stored correctly in state
41. Manual testing confirms data matches hardware behavior

### AC-11: Documentation

42. Add inline code comments explaining 0x55 message format
43. Document output mode usage concept: "mode parameter controls routing for affected parameters"
44. Update MCP API documentation with `get_output_mode_usage` tool
45. Document that output mode data is only available in online mode

### AC-12: Code Quality

46. `flutter analyze` passes with zero warnings
47. All existing tests pass with no regressions
48. New code follows existing SysEx patterns

## Tasks / Subtasks

- [ ] Task 1: Add SysEx message type (AC-1)
  - [ ] Add `respOutputModeUsage(0x55)` to `DistingNTRespMessageType` enum
  - [ ] Add documentation comment for message type

- [ ] Task 2: Implement request message (AC-2)
  - [ ] Create `lib/domain/sysex/requests/request_output_mode_usage.dart`
  - [ ] Implement constructor accepting slot and parameter number
  - [ ] Implement 16-bit to three 7-bit byte encoding
  - [ ] Generate complete SysEx message with proper framing
  - [ ] Add unit tests for message generation

- [ ] Task 3: Implement response message (AC-3)
  - [ ] Create `lib/domain/sysex/responses/output_mode_usage_response.dart`
  - [ ] Create `OutputModeUsage` data class
  - [ ] Implement parsing of source parameter number
  - [ ] Implement parsing of affected parameter count
  - [ ] Implement parsing of affected parameter list
  - [ ] Add unit tests for response parsing

- [ ] Task 4: Update response factory (AC-4)
  - [ ] Add case for `respOutputModeUsage` in `ResponseFactory`
  - [ ] Return `OutputModeUsageResponse` instance
  - [ ] Verify factory dispatch works correctly

- [ ] Task 5: Implement automatic query mechanism (AC-5)
  - [ ] Detect when `ParameterInfo.isOutputMode == true`
  - [ ] Schedule `RequestOutputModeUsage` for that parameter
  - [ ] Implement debounce to prevent duplicate queries
  - [ ] Trigger queries during algorithm load and parameter sync
  - [ ] Add unit tests for query triggering logic

- [ ] Task 6: Update state management (AC-6)
  - [ ] Add `outputModeMap` to slot/cubit state
  - [ ] Store output mode relationships when response received
  - [ ] Preserve data across parameter value updates
  - [ ] Clear data when algorithm changes
  - [ ] Add unit tests for state updates

- [ ] Task 7: Verify offline/mock behavior (AC-7)
  - [ ] Confirm mock manager doesn't trigger 0x55 queries
  - [ ] Confirm offline manager doesn't trigger 0x55 queries
  - [ ] Return empty relationships in offline modes
  - [ ] Add code comments documenting offline behavior

- [ ] Task 8: Implement MCP tools (AC-8)
  - [ ] Create `get_output_mode_usage` tool
  - [ ] Update `show` tool to include output mode data
  - [ ] Update parameter search to include `controls_output_mode` flag
  - [ ] Add MCP tool tests

- [ ] Task 9: Write unit tests (AC-9)
  - [ ] Test request message encoding for various parameter numbers
  - [ ] Test response parsing with 0, 1, multiple affected parameters
  - [ ] Test state updates when responses received
  - [ ] Test offline/mock behavior
  - [ ] Test debounce mechanism prevents duplicate queries

- [ ] Task 10: Write integration tests (AC-10)
  - [ ] Create hardware integration test for output mode queries
  - [ ] Verify automatic querying when algorithm loads
  - [ ] Verify relationships stored correctly
  - [ ] Manual testing with various algorithms

- [ ] Task 11: Update documentation (AC-11)
  - [ ] Add inline comments explaining 0x55 format
  - [ ] Document output mode usage concept
  - [ ] Update MCP API guide with new tool
  - [ ] Document online-only availability

- [ ] Task 12: Code quality validation (AC-12)
  - [ ] Run `flutter analyze` and fix warnings
  - [ ] Run all tests and verify no regressions
  - [ ] Verify SysEx patterns match existing code

## Dev Notes

### Architecture Context

**SysEx 0x55 Message Format:**

**Request:**
```
[0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x55, slot, p_high, p_mid, p_low, 0xF7]
```
- `sysExId`: Module ID (from connection)
- `slot`: Slot index (0-based)
- `p_high`: `(parameterNumber >> 14) & 0x3` (bits 14-15)
- `p_mid`: `(parameterNumber >> 7) & 0x7F` (bits 7-13)
- `p_low`: `parameterNumber & 0x7F` (bits 0-6)

**Response:**
```
[0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x55, slot, source_high, source_mid, source_low, count, affected_1_high, affected_1_mid, affected_1_low, ..., 0xF7]
```
- First 3 bytes after slot: Source parameter number (the mode control)
- `count`: Number of affected parameters
- Following bytes: Affected parameter numbers (3 bytes each, 7-bit encoded)

**Example:**
- Request output mode usage for parameter 42 in slot 0
- Response: Parameter 42 controls parameters [100, 101, 102, 103]

### Output Mode Concept

An "output mode" parameter controls how other parameters' outputs are routed:
- **Add mode**: Output is mixed with other outputs on the same bus
- **Replace mode**: Output replaces previous outputs on the same bus

The 0x55 message tells us which parameters are affected by a given mode control. This allows the routing editor to:
1. Identify which parameters control output modes (via `isOutputMode` flag from Story 7.3)
2. Determine which output parameters are controlled by each mode parameter (via 0x55 response)
3. Assign appropriate `OutputMode.add` or `OutputMode.replace` based on mode parameter value

### Query Triggering Strategy

**When to query:**
1. Algorithm loaded into slot → Request parameter info for all parameters
2. Parameter info received with `isOutputMode=true` → Queue 0x55 request
3. Parameter refresh triggered → Re-query if needed

**Debounce logic:**
- Track which parameters have been queried in current sync session
- Don't re-query same parameter until algorithm changes
- Clear query cache when algorithm changes or slot cleared

### State Structure

```dart
class OutputModeUsage {
  final int sourceParameterNumber;
  final List<int> affectedParameterNumbers;

  OutputModeUsage({
    required this.sourceParameterNumber,
    required this.affectedParameterNumbers,
  });
}

// In Slot or DistingCubit state:
Map<int, OutputModeUsage> outputModeMap; // Key: source parameter number
```

### Files to Modify

**SysEx Messages:**
- `lib/domain/disting_nt_sysex.dart` - Add enum value, OutputModeUsage class
- `lib/domain/sysex/requests/request_output_mode_usage.dart` - New file
- `lib/domain/sysex/responses/output_mode_usage_response.dart` - New file
- `lib/domain/sysex/response_factory.dart` - Add 0x55 case

**State Management:**
- `lib/cubit/disting_cubit.dart` - Add output mode map, query triggering logic
- `lib/models/slot.dart` - Add output mode data (if needed)

**MIDI Managers:**
- `lib/domain/i_disting_midi_manager.dart` - Add requestOutputModeUsage method (if needed)
- `lib/domain/disting_midi_manager.dart` - Implement request sending
- `lib/domain/mock_disting_midi_manager.dart` - No-op implementation
- `lib/domain/offline_disting_midi_manager.dart` - No-op implementation

**MCP Tools:**
- `lib/services/disting_controller.dart` - Add getOutputModeUsage method
- `lib/services/disting_controller_impl.dart` - Implement method
- `lib/mcp/tools/disting_tools.dart` - Add get_output_mode_usage tool

**Tests:**
- `test/domain/sysex/requests/request_output_mode_usage_test.dart` - New file
- `test/domain/sysex/responses/output_mode_usage_response_test.dart` - New file
- `test/cubit/disting_cubit_output_mode_test.dart` - New file (or add to existing)

### Related Stories

- **Story 7.3** - Provides `isOutputMode` flag that triggers queries (prerequisite)
- **Story 7.5** - Will consume output mode data to replace pattern matching in routing
- **Story 7.1** - Similar pattern: SysEx flag extraction and state management

### Reference Documents

- distingNT repository commit 39b5376: "add output mode parsing"
- `docs/architecture.md` - SysEx patterns and state management
- `lib/domain/sysex/responses/parameter_info_response.dart` - Example response parser

### Testing Strategy

**Unit Tests:**
- Request message encoding for various parameter numbers (0, 1, 100, 1000, max)
- Response parsing with 0 affected parameters
- Response parsing with 1 affected parameter
- Response parsing with many affected parameters
- State updates when responses received
- Debounce prevents duplicate queries

**Integration Tests:**
- Real hardware querying (requires physical distingNT)
- Automatic triggering when algorithm loads
- State persistence across parameter updates
- Clear state when algorithm changes

**Manual Testing:**
- Load algorithms with known output mode parameters
- Inspect output mode data via MCP tools
- Verify relationships match hardware behavior
- Test offline mode returns empty data

### Implementation Notes

**16-bit Parameter Encoding:**
```dart
// Encode 16-bit parameter number to three 7-bit bytes
final p_high = (parameterNumber >> 14) & 0x3;   // Bits 14-15
final p_mid = (parameterNumber >> 7) & 0x7F;    // Bits 7-13
final p_low = parameterNumber & 0x7F;            // Bits 0-6
```

**16-bit Parameter Decoding:**
```dart
// Decode three 7-bit bytes to 16-bit parameter number
final parameterNumber = (data[0] << 14) | (data[1] << 7) | data[2];
```

**Response Parsing Pattern:**
```dart
@override
OutputModeUsage parse() {
  final sourceParam = (data[0] << 14) | (data[1] << 7) | data[2];
  final count = data[3];
  final affectedParams = <int>[];

  for (int i = 0; i < count; i++) {
    final offset = 4 + (i * 3);
    final param = (data[offset] << 14) |
                  (data[offset + 1] << 7) |
                  data[offset + 2];
    affectedParams.add(param);
  }

  return OutputModeUsage(
    sourceParameterNumber: sourceParam,
    affectedParameterNumbers: affectedParams,
  );
}
```

## Dev Agent Record

### Context Reference

- TBD: docs/stories/7-4-synchronize-output-mode-usage-data.context.xml

### Agent Model Used

TBD

### Completion Notes List

- TBD

### File List

**Modified:**
- TBD

**Added:**
- TBD

### Change Log

- **2025-11-18:** Story created by Business Analyst (Mary)
