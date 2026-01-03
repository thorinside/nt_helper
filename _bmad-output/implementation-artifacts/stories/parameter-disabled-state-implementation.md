# Story: Implement Parameter Disabled/Grayed-Out State in UI

**Status:** TODO
**Priority:** Medium
**Epic:** UX Improvements
**Assignee:** TBD

---

## Summary

Implement visual disabled/grayed-out state for parameters in the UI based on the parameter flag (bits 16-20) in SysEx 0x44/0x45 responses. This provides users with immediate visual feedback about which parameters are active in the current configuration.

**Problem It Solves:**
- Users cannot tell which parameters are relevant to their current configuration
- Users may try to edit parameters that have no effect (e.g., Clock Input when using Internal source)
- No visual indication that certain outputs are disabled or that mode-dependent parameters are inactive
- Confusion about why changing a parameter value has no audible effect

**Solution:**
- Extract disabled flag from parameter value messages (bits 16-20 of 21-bit encoding)
- Add `isDisabled` field to `ParameterValue` model
- Update UI to show disabled parameters with reduced opacity and optional read-only state
- **Online mode only** - flag is only available when connected to hardware

---

## Acceptance Criteria

### AC-1: Data Model Updates

1. **AC-1.1:** Add `isDisabled` field to `ParameterValue` class
   ```dart
   class ParameterValue {
     final int algorithmIndex;
     final int parameterNumber;
     final int value;
     final bool isDisabled;  // NEW

     ParameterValue({
       required this.algorithmIndex,
       required this.parameterNumber,
       required this.value,
       this.isDisabled = false,  // Default for backward compatibility
     });
   }
   ```

2. **AC-1.2:** Update equality and hashCode methods to include `isDisabled`

3. **AC-1.3:** Update `toString()` to include disabled state for debugging

### AC-2: SysEx Response Parsing

1. **AC-2.1:** Extract flag from 0x44 (All Parameter Values) response
   ```dart
   // lib/domain/sysex/responses/all_parameter_values_response.dart
   AllParameterValues parse() {
     var algorithmIndex = decode8(data.sublist(0, 1));
     return AllParameterValues(
       algorithmIndex: algorithmIndex,
       values: [
         for (int offset = 1; offset < data.length; offset += 3)
           ParameterValue(
             algorithmIndex: algorithmIndex,
             parameterNumber: offset ~/ 3,
             value: decode16(data, offset),
             isDisabled: _extractDisabledFlag(data[offset]),  // NEW
           ),
       ],
     );
   }

   bool _extractDisabledFlag(int byte0) {
     final flag = (byte0 >> 2) & 0x1F;
     return flag == 1;
   }
   ```

2. **AC-2.2:** Extract flag from 0x45 (Single Parameter Value) response
   ```dart
   // lib/domain/sysex/responses/parameter_value_response.dart
   ParameterValue parse() {
     return ParameterValue(
       algorithmIndex: decode8(data.sublist(0, 1)),
       parameterNumber: decode16(data, 1),
       value: decode16(data, 4),
       isDisabled: _extractDisabledFlag(data[4]),  // NEW
     );
   }
   ```

3. **AC-2.3:** Offline/Demo mode defaults to `isDisabled = false` for all parameters
   - MockDistingMIDIManager returns parameters with isDisabled always false
   - OfflineDistingMIDIManager returns parameters with isDisabled always false
   - Only live hardware connection provides accurate disabled state

### AC-3: UI Visual Feedback

1. **AC-3.1:** Parameter editor widgets show disabled state
   - Disabled parameters have 0.5 opacity (50% transparency)
   - Optional: Disabled parameters show a "disabled" icon or badge
   - Disabled parameters can still be viewed but with visual indication they won't take effect

2. **AC-3.2:** Parameter controls behavior for disabled parameters
   - **Option A (Read-only):** Disabled parameters cannot be edited
   - **Option B (Editable with warning):** Disabled parameters can be edited but with visual warning
   - **Recommendation:** Start with Option A (read-only) for clearer UX

3. **AC-3.3:** Parameter list/grid view shows disabled state
   - Grayed out text for disabled parameters
   - Reduced opacity for the entire parameter row/card
   - Tooltip explains why parameter is disabled (if determinable)

4. **AC-3.4:** Synchronized screen parameter display
   - Main parameter list shows disabled state
   - Parameter pages respect disabled state
   - MCP parameter queries include disabled flag in JSON response

### AC-4: State Management Integration

1. **AC-4.1:** DistingCubit propagates disabled state
   - Slot model includes disabled state for each parameter
   - State updates when parameter values are refreshed
   - Disabled state changes trigger UI rebuild

2. **AC-4.2:** Parameter update logic respects disabled state
   - Optional: Warn or prevent parameter updates for disabled parameters
   - Log warning if attempting to set disabled parameter value

### AC-5: MCP Integration

1. **AC-5.1:** MCP `get_parameter_value` response includes disabled flag
   ```json
   {
     "slot_index": 1,
     "algorithm_name": "Clock",
     "parameter_number": 6,
     "parameter_name": "Clock input",
     "value": 0,
     "is_disabled": true,
     "min": 0,
     "max": 28
   }
   ```

2. **AC-5.2:** MCP `get_multiple_parameters` includes disabled flag for each parameter

3. **AC-5.3:** MCP `search` tool (parameter search) includes disabled flag

### AC-6: Testing

1. **AC-6.1:** Unit tests for flag extraction
   - Test byte0 = 0x00 → isDisabled = false
   - Test byte0 = 0x04 → isDisabled = true (flag = 1)
   - Test byte0 = 0x08 → isDisabled = false (different flag value)
   - Test all response parsers

2. **AC-6.2:** Integration tests with hardware
   - Clock algorithm with Internal source: Clock input should be disabled
   - Clock algorithm with External source: Clock input should be enabled
   - Disabled outputs: Routing parameters should be disabled

3. **AC-6.3:** UI tests
   - Disabled parameters show reduced opacity
   - Disabled parameters cannot be edited (if read-only option chosen)
   - Offline mode: all parameters appear enabled

4. **AC-6.4:** All tests pass, zero warnings, no regressions

### AC-7: Documentation

1. **AC-7.1:** Update parameter flag analysis report with implementation status
2. **AC-7.2:** Document UI behavior in user-facing documentation
3. **AC-7.3:** Add code comments explaining flag extraction logic

---

## Technical Details

### Flag Extraction

**Location in 21-bit encoding:**
```
Bits:  [20 19 18 17 16] [15 14 13 12 11 10 9 8 7] [6 5 4 3 2 1 0]
Bytes:    byte0 (7 bits)    byte1 (7 bits)         byte2 (7 bits)

byte0 structure: [b6 b5 b4 b3 b2] [b1 b0]
                 ↑  flag bits     ↑ value bits 14-15

Flag = (byte0 >> 2) & 0x1F
isDisabled = (flag == 1)
```

### Files to Modify

**Core Data Model:**
- `lib/domain/disting_nt_sysex.dart` - Update ParameterValue class
- `lib/domain/sysex/responses/all_parameter_values_response.dart` - Extract flag
- `lib/domain/sysex/responses/parameter_value_response.dart` - Extract flag

**Mock/Offline Implementations:**
- `lib/domain/mock_disting_midi_manager.dart` - Return isDisabled=false
- `lib/domain/offline_disting_midi_manager.dart` - Return isDisabled=false

**State Management:**
- `lib/cubit/disting_cubit.dart` - Propagate disabled state
- `lib/models/slot.dart` - Include disabled state in parameter info

**UI Widgets:**
- `lib/ui/widgets/parameter_editor_widget.dart` - Show disabled state
- `lib/ui/widgets/parameter_list_widget.dart` - Gray out disabled params
- `lib/ui/synchronized_screen.dart` - Display disabled state in parameter pages

**MCP Tools:**
- `lib/mcp/tools/disting_tools.dart` - Include is_disabled in JSON responses
- `lib/util/case_converter.dart` - Handle isDisabled → is_disabled conversion

**Tests:**
- `test/domain/sysex/responses/parameter_value_response_test.dart` - Flag extraction tests
- `test/domain/sysex/responses/all_parameter_values_response_test.dart` - Flag extraction tests
- `test/integration/parameter_disabled_state_test.dart` - Integration tests (NEW)

### Implementation Phases

**Phase 1: Data Model (Foundation)**
1. Update ParameterValue class
2. Update response parsers to extract flag
3. Unit tests for flag extraction

**Phase 2: State Propagation**
1. Ensure disabled state flows through DistingCubit
2. Update Slot model if needed
3. Integration tests

**Phase 3: UI Visual Feedback**
1. Update parameter editor widgets
2. Add opacity/disabled styling
3. Implement read-only behavior for disabled params

**Phase 4: MCP Integration**
1. Update MCP tool responses
2. Test with LLM clients

---

## UI Design Mockup (Text Description)

### Parameter Editor - Enabled Parameter
```
┌─────────────────────────────────────┐
│ Source                              │
│ ┌─────────────────────────────────┐ │
│ │ Internal           ▼            │ │  ← Normal opacity
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Parameter Editor - Disabled Parameter
```
┌─────────────────────────────────────┐
│ Clock input                    50%  │  ← Grayed out text
│ ┌─────────────────────────────────┐ │
│ │ None               ▼  [DISABLED]│ │  ← Reduced opacity, optional badge
│ └─────────────────────────────────┘ │
│ (Disabled - using Internal source)  │  ← Optional explanation
└─────────────────────────────────────┘
```

---

## Example Scenarios

### Scenario 1: Clock Algorithm with Internal Source

**Configuration:**
- Source = Internal
- Tempo = 120 BPM

**Expected Behavior:**
- Parameters 0-5: Enabled (Source, Tempo, Run, Time sig, etc.)
- Parameter 6 (Clock input): **DISABLED** - grayed out
- Parameter 7 (Run/stop input): **DISABLED** - grayed out
- Output parameters: Depend on output Enable state

**User sees:**
- Clock input dropdown grayed out, cannot select
- Tooltip: "Clock input is disabled when Source is set to Internal"

### Scenario 2: Clock Algorithm Output Disabled

**Configuration:**
- Output 1: Enable = Off

**Expected Behavior:**
- Output 1 Enable parameter: Enabled
- Output 1 routing parameters (Output, Output mode, Type, Divisor, etc.): **DISABLED**

**User sees:**
- All Output 1 parameters except Enable are grayed out
- Cannot edit disabled routing parameters
- Turning Enable=On makes routing parameters enabled again

### Scenario 3: Offline/Demo Mode

**Mode:** Offline (no hardware connected)

**Expected Behavior:**
- ALL parameters appear enabled (isDisabled = false)
- No grayed-out parameters
- User can experiment freely

**Rationale:**
- Offline mode doesn't receive 0x44/0x45 messages with flags
- Better UX to allow all parameter editing in demo mode

---

## Testing Plan

### Unit Tests

1. **Flag Extraction Tests:**
   ```dart
   test('Extract disabled flag when bit 16 is set', () {
     final data = Uint8List.fromList([
       0x01,      // algorithm index
       0x00, 0x00, 0x06,  // parameter number
       0x04, 0x00, 0x00,  // value with flag=1 (byte0=0x04 -> flag=(4>>2)&0x1F=1)
     ]);

     final response = ParameterValueResponse(data);
     final param = response.parse();

     expect(param.isDisabled, true);
   });

   test('No disabled flag when bit 16 is clear', () {
     final data = Uint8List.fromList([
       0x01,      // algorithm index
       0x00, 0x00, 0x06,  // parameter number
       0x00, 0x00, 0x00,  // value with flag=0
     ]);

     final response = ParameterValueResponse(data);
     final param = response.parse();

     expect(param.isDisabled, false);
   });
   ```

2. **ParameterValue Equality Tests:**
   - Test equality with same disabled state
   - Test inequality with different disabled state

### Integration Tests

1. **Hardware Connection Test:**
   - Connect to hardware
   - Query Clock algorithm parameters
   - Verify Clock input and Run/stop input have isDisabled=true when Source=Internal

2. **Mode Change Test:**
   - Change Source from Internal to External
   - Verify Clock input transitions from disabled to enabled
   - Verify UI updates to show enabled state

3. **Offline Mode Test:**
   - Disconnect from hardware
   - Verify all parameters show isDisabled=false
   - Verify UI shows all parameters as editable

### Manual Testing

1. Test with Clock algorithm (has known disabled parameters)
2. Test with Euclidean patterns (ES-5 mode disables some outputs)
3. Test mode transitions (Internal ↔ External)
4. Test output enable/disable toggling
5. Verify MCP responses include disabled flag

---

## Migration Notes

### Backward Compatibility

- ✅ Adding `isDisabled` field with default value maintains compatibility
- ✅ Existing code that doesn't check `isDisabled` continues to work
- ✅ Offline mode behavior unchanged (all params editable)

### Rollout Strategy

1. **Phase 1:** Deploy data model changes (non-breaking)
2. **Phase 2:** Deploy UI changes (users see new disabled state)
3. **Phase 3:** Deploy MCP updates (LLMs see disabled flag)

### User Communication

**Release Notes:**
> **New: Visual feedback for disabled parameters**
>
> Parameters that are disabled in the current configuration now appear grayed out in the UI. For example, when using the Clock algorithm with Internal source, the "Clock input" parameter is disabled and shown with reduced opacity. This helps you focus on the parameters that are relevant to your current setup.
>
> Note: This feature is only available when connected to hardware (online mode).

---

## Story Dependencies

- **Prerequisite:** Parameter flag analysis (completed)
- **Prerequisite:** Understanding of 0x44/0x45 message format
- **Follows:** All Epic 4 MCP stories (for MCP integration)

---

## User Value

- **Clarity:** Immediately see which parameters are active
- **Efficiency:** Don't waste time editing parameters that have no effect
- **Learning:** Understand parameter dependencies (e.g., Source mode affects Clock input)
- **Error Prevention:** Visual indication prevents confusion about why changes don't work
- **Professional UX:** Matches expectations from DAWs and hardware editors

---

## Reference Documents

- `docs/parameter-flag-findings.md` - Quick reference for flag meaning
- `docs/parameter-flag-analysis-report.md` - Detailed analysis with protocol details
- `test/parameter_flag_test.dart` - Flag extraction tool with real Clock data
