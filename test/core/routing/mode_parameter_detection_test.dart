import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('Mode Parameter Detection Tests', () {
    test('should detect output parameters with matching mode parameters', () {
      // Create a Lua Script-like slot with output parameters that have mode parameters
      final slot = _createLuaScriptSlot();

      // Extract IO parameters
      final ioParams = AlgorithmRouting.extractIOParameters(slot);

      // Verify that outputs with mode parameters are detected
      expect(ioParams.containsKey('Gate Out'), isTrue,
          reason: 'Gate Out should be detected as IO parameter (has Gate Out mode)');
      expect(ioParams.containsKey('Pitch CV'), isTrue,
          reason: 'Pitch CV should be detected as IO parameter (has Pitch CV mode)');

      // Verify that inputs without mode parameters are also detected if they match bus criteria
      expect(ioParams.containsKey('Clock In'), isTrue,
          reason: 'Clock In should be detected as IO parameter (bus parameter)');
      expect(ioParams.containsKey('Reset'), isTrue,
          reason: 'Reset should be detected as IO parameter (bus parameter)');
    });

    test('should correctly identify mode parameters', () {
      final slot = _createLuaScriptSlot();

      // Extract mode parameters
      final modeParams = AlgorithmRouting.extractModeParameters(slot);
      final modeParamsWithNumbers = AlgorithmRouting.extractModeParametersWithNumbers(slot);

      // Verify mode parameters are detected
      expect(modeParams.containsKey('Gate Out mode'), isTrue);
      expect(modeParams.containsKey('Pitch CV mode'), isTrue);

      // Verify mode parameters have correct structure
      expect(modeParamsWithNumbers['Gate Out mode'], isNotNull);
      expect(modeParamsWithNumbers['Gate Out mode']?.parameterNumber, equals(4));
      expect(modeParamsWithNumbers['Pitch CV mode'], isNotNull);
      expect(modeParamsWithNumbers['Pitch CV mode']?.parameterNumber, equals(6));
    });

    test('should handle algorithms without mode parameters', () {
      // Create a simple algorithm without mode parameters
      final slot = _createSimpleAlgorithmSlot();

      // Extract IO parameters
      final ioParams = AlgorithmRouting.extractIOParameters(slot);

      // Should still detect bus parameters
      expect(ioParams.containsKey('Input'), isTrue);
      expect(ioParams.containsKey('Output'), isTrue);

      // Extract mode parameters
      final modeParams = AlgorithmRouting.extractModeParameters(slot);
      expect(modeParams, isEmpty);
    });

    test('should handle mixed parameter scenarios', () {
      // Create an algorithm with some outputs having modes and some not
      final slot = _createMixedAlgorithmSlot();

      // Extract IO parameters
      final ioParams = AlgorithmRouting.extractIOParameters(slot);

      // Outputs with mode parameters should be detected
      expect(ioParams.containsKey('Main Out'), isTrue,
          reason: 'Main Out should be detected (has Main Out mode)');

      // Regular bus parameters should also be detected
      expect(ioParams.containsKey('Aux Out'), isTrue,
          reason: 'Aux Out should be detected as regular bus parameter');
      expect(ioParams.containsKey('Input 1'), isTrue,
          reason: 'Input 1 should be detected as regular bus parameter');
    });

    test('should create proper routing from Lua Script slot', () {
      final slot = _createLuaScriptSlot();

      // Create routing from slot
      final routing = AlgorithmRouting.fromSlot(
        slot,
        algorithmUuid: 'test_lua_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Should have both inputs and outputs
      expect(routing.inputPorts, isNotEmpty,
          reason: 'Lua Script should have input ports');
      expect(routing.outputPorts, isNotEmpty,
          reason: 'Lua Script should have output ports');

      // Check for specific output ports
      final outputNames = routing.outputPorts.map((p) => p.name).toSet();
      expect(outputNames.any((name) => name.contains('Gate')), isTrue,
          reason: 'Should have a Gate output port');
      expect(outputNames.any((name) => name.contains('Pitch')), isTrue,
          reason: 'Should have a Pitch output port');
    });
  });
}

/// Helper function to create a Lua Script-like slot with mode parameters
Slot _createLuaScriptSlot() {
  final algorithm = Algorithm(
    algorithmIndex: 0,
    guid: 'lua ',
    name: 'Lua Script',
  );

  final routing = RoutingInfo(
    algorithmIndex: 0,
    routingInfo: List.filled(6, 0),
  );

  final pages = ParameterPages(algorithmIndex: 0, pages: []);

  // Define parameters like in a typical Lua Script
  final parameters = [
    // Input parameters (no mode)
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 0,
      min: 0,
      max: 28,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Clock In',
      powerOfTen: 0,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 1,
      min: 0,
      max: 28,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Reset',
      powerOfTen: 0,
    ),
    // Output parameters with mode
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 2,
      min: 0,
      max: 28,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Gate Out',
      powerOfTen: 0,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 3,
      min: 0,
      max: 28,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Pitch CV',
      powerOfTen: 0,
    ),
    // Mode parameters
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 4,
      min: 0,
      max: 1,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Gate Out mode',
      powerOfTen: 0,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 6,
      min: 0,
      max: 1,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Pitch CV mode',
      powerOfTen: 0,
    ),
  ];

  // Create values (all defaults)
  final values = parameters.map((p) => ParameterValue(
    algorithmIndex: 0,
    parameterNumber: p.parameterNumber,
    value: p.defaultValue,
  )).toList();

  // Create enums for mode parameters
  final enums = [
    ParameterEnumStrings(
      algorithmIndex: 0,
      parameterNumber: 4,
      values: ['Add', 'Replace'],
    ),
    ParameterEnumStrings(
      algorithmIndex: 0,
      parameterNumber: 6,
      values: ['Add', 'Replace'],
    ),
  ];

  return Slot(
    algorithm: algorithm,
    routing: routing,
    pages: pages,
    parameters: parameters,
    values: values,
    enums: enums,
    mappings: [],
    valueStrings: [],
  );
}

/// Helper function to create a simple algorithm slot without mode parameters
Slot _createSimpleAlgorithmSlot() {
  final algorithm = Algorithm(
    algorithmIndex: 0,
    guid: 'simp',
    name: 'Simple Algorithm',
  );

  final routing = RoutingInfo(
    algorithmIndex: 0,
    routingInfo: List.filled(6, 0),
  );

  final pages = ParameterPages(algorithmIndex: 0, pages: []);

  final parameters = [
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 0,
      min: 0,
      max: 28,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Input',
      powerOfTen: 0,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 1,
      min: 0,
      max: 28,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Output',
      powerOfTen: 0,
    ),
  ];

  final values = parameters.map((p) => ParameterValue(
    algorithmIndex: 0,
    parameterNumber: p.parameterNumber,
    value: p.defaultValue,
  )).toList();

  return Slot(
    algorithm: algorithm,
    routing: routing,
    pages: pages,
    parameters: parameters,
    values: values,
    enums: [],
    mappings: [],
    valueStrings: [],
  );
}

/// Helper function to create a mixed algorithm slot with some outputs having modes
Slot _createMixedAlgorithmSlot() {
  final algorithm = Algorithm(
    algorithmIndex: 0,
    guid: 'mixd',
    name: 'Mixed Algorithm',
  );

  final routing = RoutingInfo(
    algorithmIndex: 0,
    routingInfo: List.filled(6, 0),
  );

  final pages = ParameterPages(algorithmIndex: 0, pages: []);

  final parameters = [
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 0,
      min: 0,
      max: 28,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Input 1',
      powerOfTen: 0,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 1,
      min: 0,
      max: 28,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Main Out',
      powerOfTen: 0,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 2,
      min: 0,
      max: 1,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Main Out mode',
      powerOfTen: 0,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 3,
      min: 0,
      max: 28,
      defaultValue: 0,
      unit: 1, // enum
      name: 'Aux Out',
      powerOfTen: 0,
    ),
  ];

  final values = parameters.map((p) => ParameterValue(
    algorithmIndex: 0,
    parameterNumber: p.parameterNumber,
    value: p.defaultValue,
  )).toList();

  final enums = [
    ParameterEnumStrings(
      algorithmIndex: 0,
      parameterNumber: 2,
      values: ['Add', 'Replace'],
    ),
  ];

  return Slot(
    algorithm: algorithm,
    routing: routing,
    pages: pages,
    parameters: parameters,
    values: values,
    enums: enums,
    mappings: [],
    valueStrings: [],
  );
}