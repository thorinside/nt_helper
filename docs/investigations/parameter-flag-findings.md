# Parameter Flag Findings - Grayed Out/Disabled Parameters

**Date:** 2025-11-14
**Tested On:** Clock algorithm (disting NT hardware)
**Source:** Expert Sleepers (Andrew from OS) - "refactored code to query whether parameters are grayed out/disabled"

## Summary

Expert Sleepers added a flag to parameter value messages (0x44/0x45) to indicate:

**The flag indicates parameters that are GRAYED OUT/DISABLED in the UI.**

## Flag Location

```
21-bit encoding: [bits 16-20: flag] [bits 0-15: value]

Extraction:
  flag = (byte0 >> 2) & 0x1F
```

## Flag Meaning

| Flag Value | Parameter State | UI Display |
|------------|-----------------|------------|
| 1 | Disabled/Grayed out | Show parameter grayed out, possibly read-only |
| 0 | Enabled/Active | Normal editable parameter |

## Test Results - Clock Algorithm

**Total parameters:** 72
**Disabled parameters (flag=1):** 17
**Enabled parameters (flag=0):** 55

### Disabled Parameters by Section

**Global Settings (params 0-11):**
- Param 6: Clock input (disabled - likely using Internal clock source)
- Param 7: Run/stop input (disabled - likely using Internal clock source)

**Output 1 (params 12-23):**
- Param 13: 1:Output (disabled)
- Param 14: 1:Output mode (disabled)
- Param 21: (disabled)

**Output 2 (params 24-35):**
- Param 25, 26, 33 (disabled)

**Output 3 (params 36-47):**
- Param 37, 38, 45 (disabled)

**Output 4 (params 48-59):**
- Param 57, 59 (disabled)

**Output 5 (params 60-71):**
- Param 69, 71 (disabled)

### Pattern Analysis

The disabled parameters likely depend on:
1. **Output Enable state** - When an output is disabled, its parameters are grayed out
2. **Clock source** - External clock disables internal clock parameters
3. **Mode dependencies** - Certain modes disable incompatible parameters
4. **ES-5 Expander setting** - Affects which routing parameters are available

## Implementation in nt_helper

### Implementation Status
The flag is **fully implemented** as of Story 7.1. Disabled parameters are visually indicated and read-only.

### Implementation Details

1. **ParameterValue class includes isDisabled field:**
```dart
class ParameterValue {
  final int algorithmIndex;
  final int parameterNumber;
  final int value;
  final bool isDisabled;  // IMPLEMENTED: extracted from flag bit

  ParameterValue({
    required this.algorithmIndex,
    required this.parameterNumber,
    required this.value,
    this.isDisabled = false,  // Default for backward compatibility
  });
}
```

2. **Response parsers extract and use the flag:**
```dart
// lib/domain/sysex/responses/parameter_value_response.dart
// lib/domain/sysex/responses/all_parameter_values_response.dart
bool _extractDisabledFlag(int byte0) {
  final flag = (byte0 >> 2) & 0x1F;  // Extract bits 16-20
  return flag == 1;  // flag=1 means disabled
}

int _extractValue(int byte0, int byte1, int byte2) {
  // Mask out flag bits before decoding
  final maskedByte0 = byte0 & 0x03;
  return decode16([maskedByte0, byte1, byte2], 0);
}

ParameterValue parse() {
  final byte0 = data[4];
  return ParameterValue(
    algorithmIndex: decode8(data.sublist(0, 1)),
    parameterNumber: decode16(data, 1),
    value: _extractValue(data[4], data[5], data[6]),
    isDisabled: _extractDisabledFlag(byte0),
  );
}
```

3. **UI shows disabled parameters with reduced opacity:**
```dart
// lib/ui/widgets/parameter_view_row.dart
if (isDisabled) {
  return Opacity(
    opacity: 0.5,
    child: IgnorePointer(
      child: Tooltip(
        message: 'This parameter is disabled',
        child: parameterWidget,
      ),
    ),
  );
}
```

4. **MCP tools expose isDisabled state:**
- `get_parameter_value` includes `is_disabled` field
- `get_multiple_parameters` (show) includes `is_disabled` for each parameter
- Parameter search results include `is_disabled` field

### Query Method

Per Andrew's question "How is convenient for you to query that?":

**Option 1: Include in existing 0x44/0x45 messages (CURRENT)**
- ✅ Already implemented
- ✅ No additional SysEx overhead
- ✅ Flag is in bits 16-20 of each parameter value

**Option 2: Separate query message**
- Would require new SysEx command
- Not needed - current approach is optimal

**Recommendation:** Continue using the current approach with flag in parameter value messages.

## Benefits

1. **Better UX:** Users see which parameters are available in current configuration
2. **Prevents errors:** Disabled parameters can be made read-only
3. **Guidance:** Visual feedback about parameter dependencies
4. **Efficiency:** No additional SysEx messages needed

## Files

- **Detailed Report:** `docs/parameter-flag-analysis-report.md`
- **Test Tool:** `tools/parameter_flag_analyzer.dart` (hex dump analyzer with real Clock data)
- **Capture Guide:** `tools/capture_parameter_flags.md`

---

**Status:** ✅ Complete - Flag meaning confirmed
**Next Step:** Implement in nt_helper UI to gray out disabled parameters
