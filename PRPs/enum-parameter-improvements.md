# PRP: Enhanced Enum Parameter Support for MCP Server

## Executive Summary

The MCP server currently provides insufficient information about enum parameters to LLMs. When parameters are enumerations, the server only returns integer values without exposing the available enum strings or their mappings. This PRP details the implementation of comprehensive enum support across all parameter-related MCP tools.

## Problem Statement

Current limitations:
- `get_current_preset` returns only integer values for enum parameters
- `set_parameter_value` requires integer values, cannot accept enum strings
- `get_parameter_value` returns only integers without enum context
- `set_multiple_parameters` lacks enum string support
- No way to retrieve available enum options for a parameter

## Solution Overview

Enhance the MCP server to:
1. Include enum metadata in all parameter responses
2. Accept both integer indices and enum strings for parameter setting
3. Provide dedicated enum retrieval functionality
4. Maintain backward compatibility with existing integer-only clients

## Technical Research

### Current Implementation Details

**Key Files:**
- `/Users/nealsanche/nosuch/nt_helper/lib/mcp/tools/disting_tools.dart` - MCP tool implementations
- `/Users/nealsanche/nosuch/nt_helper/lib/services/mcp_server_service.dart` - Server registration
- `/Users/nealsanche/nosuch/nt_helper/lib/db/daos/metadata_dao.dart` - Enum data retrieval
- `/Users/nealsanche/nosuch/nt_helper/lib/domain/disting_nt_sysex.dart` - Core data structures

**Enum Identification:**
```dart
// lib/cubit/disting_cubit.dart:2351
bool isEnum(int i) => parameters[i].unit == 1;
```

**Database Schema:**
```sql
-- lib/db/tables.dart:63-77
CREATE TABLE parameter_enums (
  algorithm_guid TEXT,
  parameter_number INTEGER,
  enum_index INTEGER,     -- Integer value
  enum_string TEXT,       -- Display string
  PRIMARY KEY (algorithm_guid, parameter_number, enum_index)
);
```

**Current Parameter Structure (lib/mcp/tools/disting_tools.dart:57-71):**
```dart
{
  'parameter_number': paramIndex,
  'name': pInfo.name,
  'min_value': _scaleForDisplay(pInfo.min, pInfo.powerOfTen),
  'max_value': _scaleForDisplay(pInfo.max, pInfo.powerOfTen),
  'default_value': _scaleForDisplay(pInfo.defaultValue, pInfo.powerOfTen),
  'unit': pInfo.unit,  // unit == 1 indicates enum
  'value': liveRawValue != null ? _scaleForDisplay(liveRawValue, pInfo.powerOfTen) : null,
}
```

### Existing Enum Infrastructure

**Data Available But Not Exposed:**
- `MetadataDao.getFullAlgorithmDetails()` (lines 268-326) retrieves enum data
- `ParameterEnumStrings` class holds enum values list
- UI already uses enum strings for dropdowns (lib/ui/synchronized_screen.dart:1709-1736)

**Mock Implementation Example (lib/services/mock_disting_midi_manager.dart):**
```dart
// IO routing parameters with 28 enum values
final routingEnums = [
  "None", "Input 1", "Input 2", ..., "Output 8", "Aux 1", ..., "Aux 8"
];
```

## Implementation Blueprint

### Phase 1: Add Enum Helper Methods

**Location:** `/Users/nealsanche/nosuch/nt_helper/lib/mcp/tools/disting_tools.dart`

```dart
class DistingTools {
  // ... existing code ...
  
  /// Retrieves enum values for a parameter if it's an enum type
  Future<List<String>?> _getParameterEnumValues(
      int slotIndex, int parameterNumber) async {
    try {
      // Get algorithm from slot
      final algorithm = await _controller.getAlgorithmInSlot(slotIndex);
      if (algorithm == null) return null;
      
      // Get enum strings from controller
      final enumStrings = await _controller.getParameterEnumStrings(
          slotIndex, parameterNumber);
      return enumStrings?.values;
    } catch (e) {
      debugPrint('Error fetching enum values: $e');
      return null;
    }
  }
  
  /// Checks if a parameter is an enum type
  bool _isEnumParameter(ParameterInfo paramInfo) {
    return paramInfo.unit == 1;
  }
  
  /// Converts enum string to integer index
  int? _enumStringToIndex(List<String> enumValues, String value) {
    final index = enumValues.indexOf(value);
    return index >= 0 ? index : null;
  }
  
  /// Converts integer index to enum string
  String? _enumIndexToString(List<String> enumValues, int index) {
    if (index >= 0 && index < enumValues.length) {
      return enumValues[index];
    }
    return null;
  }
}
```

### Phase 2: Enhance getCurrentPreset

**Modify parameter structure (lib/mcp/tools/disting_tools.dart:57-71):**

```dart
// In getCurrentPreset method, around line 57
for (int paramIndex = 0; paramIndex < parameterInfos.length; paramIndex++) {
  final pInfo = parameterInfos[paramIndex];
  final int? liveRawValue = await _controller.getParameterValue(i, paramIndex);
  
  // Build base parameter object
  final paramData = {
    'parameter_number': paramIndex,
    'name': pInfo.name,
    'min_value': _scaleForDisplay(pInfo.min, pInfo.powerOfTen),
    'max_value': _scaleForDisplay(pInfo.max, pInfo.powerOfTen),
    'default_value': _scaleForDisplay(pInfo.defaultValue, pInfo.powerOfTen),
    'unit': pInfo.unit,
    'value': liveRawValue != null
        ? _scaleForDisplay(liveRawValue, pInfo.powerOfTen)
        : null,
  };
  
  // Add enum metadata if this is an enum parameter
  if (_isEnumParameter(pInfo)) {
    final enumValues = await _getParameterEnumValues(i, paramIndex);
    if (enumValues != null) {
      paramData['is_enum'] = true;
      paramData['enum_values'] = enumValues;
      if (liveRawValue != null) {
        paramData['enum_value'] = _enumIndexToString(enumValues, liveRawValue);
      }
    }
  }
  
  parametersJsonList.add(paramData);
}
```

### Phase 3: Enhance setParameterValue

**Support enum string values (lib/mcp/tools/disting_tools.dart:161-253):**

```dart
Future<String> setParameterValue(Map<String, dynamic> params) async {
  final int? slotIndex = params['slot_index'] as int?;
  final int? parameterNumberParam = params['parameter_number'] as int?;
  final String? parameterNameParam = params['parameter_name'] as String?;
  final dynamic value = params['value'];  // Can be num or String for enums
  
  // ... existing validation ...
  
  try {
    // ... existing parameter lookup code ...
    
    // Handle enum parameter value conversion
    int rawValue;
    if (_isEnumParameter(paramInfo!)) {
      if (value is String) {
        // Convert enum string to index
        final enumValues = await _getParameterEnumValues(slotIndex!, targetParameterNumber!);
        if (enumValues == null) {
          return jsonEncode(convertToSnakeCaseKeys(MCPUtils.buildError(
              'Could not retrieve enum values for parameter ${paramInfo.name}')));
        }
        
        final enumIndex = _enumStringToIndex(enumValues, value);
        if (enumIndex == null) {
          return jsonEncode(convertToSnakeCaseKeys(MCPUtils.buildError(
              'Invalid enum value "$value" for parameter ${paramInfo.name}. Valid values: ${enumValues.join(", ")}')));
        }
        rawValue = enumIndex;
      } else if (value is num) {
        // Use numeric value directly
        rawValue = value.round();
      } else {
        return jsonEncode(convertToSnakeCaseKeys(MCPUtils.buildError(
            'Enum parameter ${paramInfo.name} requires either a string enum value or numeric index')));
      }
    } else {
      // Handle non-enum parameters as before
      if (value is! num) {
        return jsonEncode(convertToSnakeCaseKeys(MCPUtils.buildError(
            'Non-enum parameter ${paramInfo.name} requires a numeric value')));
      }
      
      if (paramInfo.powerOfTen > 0) {
        rawValue = (value * pow(10, paramInfo.powerOfTen)).round();
      } else {
        rawValue = value.round();
      }
    }
    
    // ... existing range validation and update code ...
  } catch (e) {
    // ... existing error handling ...
  }
}
```

### Phase 4: Enhance getParameterValue

**Include enum context (lib/mcp/tools/disting_tools.dart:261-308):**

```dart
Future<String> getParameterValue(Map<String, dynamic> params) async {
  // ... existing validation and retrieval ...
  
  try {
    // ... existing code to get liveRawValue and paramInfo ...
    
    final responseData = {
      'slot_index': slotIndex,
      'parameter_number': parameterNumber,
      'parameter_name': paramInfo.name,
      'value': _scaleForDisplay(liveRawValue!, paramInfo.powerOfTen),
    };
    
    // Add enum metadata if applicable
    if (_isEnumParameter(paramInfo)) {
      final enumValues = await _getParameterEnumValues(slotIndex, parameterNumber);
      if (enumValues != null) {
        responseData['is_enum'] = true;
        responseData['enum_values'] = enumValues;
        responseData['enum_value'] = _enumIndexToString(enumValues, liveRawValue);
      }
    }
    
    return jsonEncode(convertToSnakeCaseKeys(MCPUtils.buildSuccess(
        'Parameter value retrieved successfully',
        data: responseData)));
  } catch (e) {
    // ... existing error handling ...
  }
}
```

### Phase 5: Enhance setMultipleParameters

**Support mixed enum/numeric values (lib/mcp/tools/disting_tools.dart:857-963):**

```dart
// In setMultipleParameters, modify the individual parameter processing loop
for (int i = 0; i < parameters.length; i++) {
  final param = parameters[i];
  // ... existing validation ...
  
  final dynamic value = paramMap['value'];  // Can be num or String
  
  // ... existing parameter number/name validation ...
  
  // Create individual parameter update request
  final Map<String, dynamic> individualParams = {
    'slot_index': slotIndex,
    'value': value,  // Pass value as-is (String or num)
  };
  
  // ... rest of existing code ...
}
```

### Phase 6: Add getParameterEnumValues Tool

**New dedicated enum retrieval tool:**

```dart
/// MCP Tool: Gets available enum values for a parameter
/// Parameters:
///   - slot_index (int, required): The 0-based index of the slot
///   - parameter_number (int, optional): The parameter number
///   - parameter_name (String, optional): The parameter name
/// Returns:
///   A JSON string with enum values or an error
Future<String> getParameterEnumValues(Map<String, dynamic> params) async {
  final int? slotIndex = params['slot_index'] as int?;
  final int? parameterNumber = params['parameter_number'] as int?;
  final String? parameterName = params['parameter_name'] as String?;
  
  // Validate slot index
  final slotError = MCPUtils.validateSlotIndex(slotIndex);
  if (slotError != null) {
    return jsonEncode(convertToSnakeCaseKeys(slotError));
  }
  
  // Validate exactly one of parameter_number or parameter_name
  final paramError = MCPUtils.validateExactlyOne(
      params, ['parameter_number', 'parameter_name']);
  if (paramError != null) {
    return jsonEncode(convertToSnakeCaseKeys(paramError));
  }
  
  try {
    // Get parameter info to validate it's an enum
    final List<ParameterInfo> paramInfos = 
        await _controller.getParametersForSlot(slotIndex!);
    
    // Find target parameter
    int? targetParamNumber;
    ParameterInfo? paramInfo;
    
    if (parameterNumber != null) {
      if (parameterNumber >= 0 && parameterNumber < paramInfos.length) {
        targetParamNumber = parameterNumber;
        paramInfo = paramInfos[parameterNumber];
      }
    } else if (parameterName != null) {
      // Find by name
      for (int i = 0; i < paramInfos.length; i++) {
        if (paramInfos[i].name.toLowerCase() == parameterName.toLowerCase()) {
          targetParamNumber = i;
          paramInfo = paramInfos[i];
          break;
        }
      }
    }
    
    if (paramInfo == null || targetParamNumber == null) {
      return jsonEncode(convertToSnakeCaseKeys(MCPUtils.buildError(
          'Parameter not found in slot $slotIndex')));
    }
    
    if (!_isEnumParameter(paramInfo)) {
      return jsonEncode(convertToSnakeCaseKeys(MCPUtils.buildError(
          'Parameter ${paramInfo.name} is not an enum type')));
    }
    
    final enumValues = await _getParameterEnumValues(slotIndex, targetParamNumber);
    
    if (enumValues == null || enumValues.isEmpty) {
      return jsonEncode(convertToSnakeCaseKeys(MCPUtils.buildError(
          'Could not retrieve enum values for parameter ${paramInfo.name}')));
    }
    
    return jsonEncode(convertToSnakeCaseKeys(MCPUtils.buildSuccess(
        'Enum values retrieved successfully',
        data: {
          'slot_index': slotIndex,
          'parameter_number': targetParamNumber,
          'parameter_name': paramInfo.name,
          'enum_values': enumValues,
          'current_value_index': await _controller.getParameterValue(
              slotIndex, targetParamNumber),
        })));
  } catch (e) {
    return jsonEncode(convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())));
  }
}
```

### Phase 7: Register New Tool

**Add to MCP server (lib/services/mcp_server_service.dart:511-650):**

```dart
// In _buildServer method, add new tool registration
CallToolRequestHandler(
  name: 'get_parameter_enum_values',
  description: 'Get available enum values for an enum parameter',
  inputSchema: {
    'type': 'object',
    'properties': {
      'slot_index': {
        'type': 'integer',
        'description': '0-based slot index',
      },
      'parameter_number': {
        'type': 'integer',
        'description': 'Parameter number (0-based)',
      },
      'parameter_name': {
        'type': 'string',
        'description': 'Parameter name (alternative to number)',
      },
    },
    'required': ['slot_index'],
  },
  handler: (CallToolRequest request) async {
    final result = await _distingTools.getParameterEnumValues(
        request.params.arguments);
    return CallToolResult.fromContent(content: [
      TextContent(text: result),
    ]);
  },
),
```

### Phase 8: Update Controller Interface

**Add enum retrieval to DistingController:**

```dart
// In lib/services/disting_controller.dart
abstract class DistingController {
  // ... existing methods ...
  
  /// Get enum strings for a parameter if it's an enum type
  Future<ParameterEnumStrings?> getParameterEnumStrings(
      int slotIndex, int parameterNumber);
}

// In lib/services/disting_controller_impl.dart
class DistingControllerImpl implements DistingController {
  @override
  Future<ParameterEnumStrings?> getParameterEnumStrings(
      int slotIndex, int parameterNumber) async {
    try {
      final algorithm = await getAlgorithmInSlot(slotIndex);
      if (algorithm == null) return null;
      
      // Get from cubit state
      final slot = _cubit.state.slots[slotIndex];
      if (slot == null) return null;
      
      final enums = slot.enums.where((e) => 
          e.parameterNumber == parameterNumber).firstOrNull;
      return enums;
    } catch (e) {
      debugPrint('Error getting parameter enum strings: $e');
      return null;
    }
  }
}
```

## Testing Strategy

### Unit Tests

Create `/Users/nealsanche/nosuch/nt_helper/test/mcp_enum_support_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';

@GenerateMocks([DistingController])
void main() {
  group('MCP Enum Parameter Support', () {
    late MockDistingController mockController;
    late DistingTools tools;
    
    setUp(() {
      mockController = MockDistingController();
      tools = DistingTools(mockController);
    });
    
    test('getCurrentPreset includes enum metadata', () async {
      // Setup mock responses
      when(mockController.getParametersForSlot(0))
          .thenAnswer((_) async => [
            ParameterInfo(unit: 1, name: 'Source', min: 0, max: 2),
          ]);
      when(mockController.getParameterEnumStrings(0, 0))
          .thenAnswer((_) async => ParameterEnumStrings(
            algorithmIndex: 0,
            parameterNumber: 0,
            values: ['Internal', 'External', 'MIDI'],
          ));
      when(mockController.getParameterValue(0, 0))
          .thenAnswer((_) async => 1);
      
      final result = await tools.getCurrentPreset({});
      final json = jsonDecode(result);
      
      expect(json['slots'][0]['parameters'][0]['is_enum'], true);
      expect(json['slots'][0]['parameters'][0]['enum_values'], 
          ['Internal', 'External', 'MIDI']);
      expect(json['slots'][0]['parameters'][0]['enum_value'], 'External');
    });
    
    test('setParameterValue accepts enum string', () async {
      // Test setting by enum string value
      when(mockController.getParametersForSlot(0))
          .thenAnswer((_) async => [
            ParameterInfo(unit: 1, name: 'Source', min: 0, max: 2),
          ]);
      when(mockController.getParameterEnumStrings(0, 0))
          .thenAnswer((_) async => ParameterEnumStrings(
            algorithmIndex: 0,
            parameterNumber: 0,
            values: ['Internal', 'External', 'MIDI'],
          ));
      
      final result = await tools.setParameterValue({
        'slot_index': 0,
        'parameter_number': 0,
        'value': 'MIDI',
      });
      
      verify(mockController.updateParameterValue(0, 0, 2)).called(1);
      
      final json = jsonDecode(result);
      expect(json['success'], true);
    });
    
    test('setParameterValue rejects invalid enum string', () async {
      // Test invalid enum value
      when(mockController.getParametersForSlot(0))
          .thenAnswer((_) async => [
            ParameterInfo(unit: 1, name: 'Source', min: 0, max: 2),
          ]);
      when(mockController.getParameterEnumStrings(0, 0))
          .thenAnswer((_) async => ParameterEnumStrings(
            algorithmIndex: 0,
            parameterNumber: 0,
            values: ['Internal', 'External', 'MIDI'],
          ));
      
      final result = await tools.setParameterValue({
        'slot_index': 0,
        'parameter_number': 0,
        'value': 'InvalidValue',
      });
      
      final json = jsonDecode(result);
      expect(json['success'], false);
      expect(json['error'], contains('Invalid enum value'));
      expect(json['error'], contains('Valid values: Internal, External, MIDI'));
    });
    
    test('getParameterEnumValues returns enum options', () async {
      when(mockController.getParametersForSlot(0))
          .thenAnswer((_) async => [
            ParameterInfo(unit: 1, name: 'Source', min: 0, max: 2),
          ]);
      when(mockController.getParameterEnumStrings(0, 0))
          .thenAnswer((_) async => ParameterEnumStrings(
            algorithmIndex: 0,
            parameterNumber: 0,
            values: ['Internal', 'External', 'MIDI'],
          ));
      when(mockController.getParameterValue(0, 0))
          .thenAnswer((_) async => 1);
      
      final result = await tools.getParameterEnumValues({
        'slot_index': 0,
        'parameter_number': 0,
      });
      
      final json = jsonDecode(result);
      expect(json['success'], true);
      expect(json['data']['enum_values'], ['Internal', 'External', 'MIDI']);
      expect(json['data']['current_value_index'], 1);
    });
  });
}
```

### Integration Tests

Create `/Users/nealsanche/nosuch/nt_helper/integration_test/enum_parameter_test.dart`:

```dart
void main() {
  testWidgets('Enum parameter full workflow', (WidgetTester tester) async {
    // 1. Start MCP server
    // 2. Call get_current_preset
    // 3. Verify enum metadata is present
    // 4. Set parameter using enum string
    // 5. Verify parameter was updated
    // 6. Get parameter value
    // 7. Verify enum context is included
  });
}
```

## Validation Gates

```bash
# 1. Flutter Analysis (MUST pass with zero issues)
flutter analyze

# 2. Run Unit Tests
flutter test test/mcp_enum_support_test.dart

# 3. Run All Tests
flutter test

# 4. Build Check
flutter build apk --debug

# 5. MCP Server Validation
# Start server and test with curl
curl -X POST http://localhost:3000/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "get_parameter_enum_values",
      "arguments": {
        "slot_index": 0,
        "parameter_number": 0
      }
    },
    "id": 1
  }'

# 6. Mock Mode Testing
# Launch app in demo mode and verify enum dropdowns work

# 7. Generate Test Coverage
flutter test --coverage
lcov --list coverage/lcov.info
```

## Implementation Tasks

1. **Add enum helper methods** to DistingTools class
2. **Enhance getCurrentPreset** to include enum metadata
3. **Update setParameterValue** to accept enum strings
4. **Enhance getParameterValue** with enum context
5. **Update setMultipleParameters** for mixed values
6. **Implement getParameterEnumValues** tool
7. **Register new tool** in MCP server
8. **Add getParameterEnumStrings** to controller
9. **Write comprehensive unit tests**
10. **Test with mock implementation**
11. **Validate all MCP tools** with enum parameters
12. **Update API documentation**

## Success Criteria

- [ ] All parameter tools expose enum metadata
- [ ] Enum strings accepted for parameter setting
- [ ] Backward compatibility maintained
- [ ] Zero flutter analyze warnings
- [ ] All tests passing
- [ ] Mock mode fully functional
- [ ] MCP server responds correctly

## References

### Internal Documentation
- Current MCP implementation: `/Users/nealsanche/nosuch/nt_helper/lib/mcp/tools/disting_tools.dart`
- Database schema: `/Users/nealsanche/nosuch/nt_helper/lib/db/tables.dart`
- Mock implementation: `/Users/nealsanche/nosuch/nt_helper/lib/services/mock_disting_midi_manager.dart`

### External Resources
- MCP Specification: https://modelcontextprotocol.io/specification
- JSON Schema Enums: https://json-schema.org/understanding-json-schema/reference/enum
- Flutter Enhanced Enums: https://dart.dev/language/enums
- JSON Serializable: https://pub.dev/packages/json_serializable

## Risk Mitigation

1. **Backward Compatibility**: All changes are additive; existing integer-only clients continue working
2. **Performance**: Enum lookups are cached in cubit state, minimal overhead
3. **Error Handling**: Comprehensive validation with helpful error messages
4. **Testing**: Multiple validation gates ensure correctness

## Confidence Score: 9/10

This PRP provides comprehensive context with:
- Complete code examples with file paths and line numbers
- Clear implementation phases
- Extensive testing strategy
- Multiple validation gates
- References to existing patterns
- Detailed error handling

The implementation should succeed in one pass with the provided information.