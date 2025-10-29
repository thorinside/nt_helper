import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

void main() {
  // Check if the required JSON file exists before defining tests
  final file = File('docs/nt_algorithm_details_1757556475.json');
  final fileExists = file.existsSync();

  group('AlgorithmRouting Loading Tests', skip: !fileExists, () {
    late Map<String, dynamic> algorithmData;

    setUpAll(() async {
      // Load the JSON file with all algorithm data
      final jsonString = await file.readAsString();
      algorithmData = json.decode(jsonString);
    });

    test('should load all algorithms from JSON without errors', () {
      final algorithms = algorithmData['algorithms'] as List;

      // Track successful and failed algorithms
      final successfulAlgorithms = <String>[];
      final failedAlgorithms = <String, String>{};

      for (final algorithmJson in algorithms) {
        final guid = algorithmJson['guid'] as String;
        final name = algorithmJson['name'] as String;

        try {
          // Create a Slot from the JSON data
          final slot = _createSlotFromJson(algorithmJson);

          // Try to create an AlgorithmRouting from the slot
          final routing = AlgorithmRouting.fromSlot(
            slot,
            algorithmUuid:
                'test_${guid}_${DateTime.now().millisecondsSinceEpoch}',
          );

          // Verify basic properties
          expect(routing, isNotNull);
          expect(routing.inputPorts, isNotNull);
          expect(routing.outputPorts, isNotNull);
          expect(routing.connections, isNotNull);

          successfulAlgorithms.add('$name ($guid)');
        } catch (e, stackTrace) {
          failedAlgorithms['$name ($guid)'] = '$e\n$stackTrace';
        }
      }

      // Report results
      debugPrint('\nAlgorithm Loading Results:');
      debugPrint(
        'Successfully loaded: ${successfulAlgorithms.length} algorithms',
      );
      debugPrint('Failed to load: ${failedAlgorithms.length} algorithms');

      if (failedAlgorithms.isNotEmpty) {
        debugPrint('\nFailed algorithms:');
        failedAlgorithms.forEach((name, error) {
          debugPrint('  - $name');
          debugPrint('    Error: ${error.split('\n').first}');
        });
      }

      // The test passes if all algorithms load successfully
      expect(
        failedAlgorithms,
        isEmpty,
        reason: 'All algorithms should load without errors',
      );
    });

    test(
      'should ensure all factory algorithms have at least one input or output port (except special cases)',
      () {
        final algorithms = algorithmData['algorithms'] as List;
        final algorithmsWithNoIO = <String>[];

        // Known special cases that legitimately have no I/O
        final specialCases = {
          'note': 'Notes display algorithm',
          'stpw': 'Stopwatch utility (no audio/CV I/O)',
          'es5e': 'ES-5 Encoder (Expert Sleepers output encoder)',
        };

        for (final algorithmJson in algorithms) {
          final guid = algorithmJson['guid'] as String;
          final name = algorithmJson['name'] as String;

          // Skip community algorithms (those with uppercase letters in GUID)
          // They may not load properly in metadata collector
          if (guid.contains(RegExp(r'[A-Z]'))) {
            debugPrint('Skipping $name ($guid) - Community algorithm');
            continue;
          }

          // Skip known special cases
          if (specialCases.containsKey(guid)) {
            debugPrint('Skipping $name ($guid) - ${specialCases[guid]}');
            continue;
          }

          try {
            // Create a Slot from the JSON data
            final slot = _createSlotFromJson(algorithmJson);

            // Create an AlgorithmRouting from the slot
            final routing = AlgorithmRouting.fromSlot(
              slot,
              algorithmUuid:
                  'test_${guid}_${DateTime.now().millisecondsSinceEpoch}',
            );

            // Check if algorithm has at least one input or output
            final hasInputs = routing.inputPorts.isNotEmpty;
            final hasOutputs = routing.outputPorts.isNotEmpty;

            if (!hasInputs && !hasOutputs) {
              algorithmsWithNoIO.add(
                '$name ($guid) - inputs: ${routing.inputPorts.length}, outputs: ${routing.outputPorts.length}',
              );
              debugPrint(
                'WARNING: Algorithm $name ($guid) has no inputs or outputs!',
              );
            } else {
              debugPrint(
                '✓ $name ($guid) - inputs: ${routing.inputPorts.length}, outputs: ${routing.outputPorts.length}',
              );
            }
          } catch (e) {
            // If we can't load the algorithm, that's a different problem
            // that should be caught by the first test
            debugPrint('ERROR: Failed to load $name ($guid): $e');
          }
        }

        // Report any algorithms with no I/O
        if (algorithmsWithNoIO.isNotEmpty) {
          debugPrint('\nAlgorithms with NO inputs or outputs:');
          for (final algo in algorithmsWithNoIO) {
            debugPrint('  - $algo');
          }
        }

        // The test fails if any factory algorithm (except special cases) has no I/O
        expect(
          algorithmsWithNoIO,
          isEmpty,
          reason:
              'All factory algorithms (except documented special cases) should have at least one input or output port',
        );
      },
    );

    test('should handle algorithms with various parameter configurations', () {
      final algorithms = algorithmData['algorithms'] as List;

      // Test a variety of algorithm types
      final testCases = <String, void Function(dynamic)>{
        'Th14': (json) {
          // 14-bit CC to CV - should have CV output parameters
          final slot = _createSlotFromJson(json);
          final routing = AlgorithmRouting.fromSlot(slot);

          // Should have at least one output
          expect(routing.outputPorts, isNotEmpty);
        },
        'arpg': (json) {
          // Arpeggiator - complex polyphonic algorithm
          final slot = _createSlotFromJson(json);
          final routing = AlgorithmRouting.fromSlot(slot);

          // Arpeggiator may not have traditional I/O ports as it works via MIDI/I2C
          // Just verify it loads without error
          expect(routing, isNotNull);
          expect(routing.inputPorts, isNotNull);
          expect(routing.outputPorts, isNotNull);
        },
        'attn': (json) {
          // Attenuverter - multi-channel algorithm
          final slot = _createSlotFromJson(json);
          final routing = AlgorithmRouting.fromSlot(slot);

          // Attenuverter may have variable channels - just verify it loads
          expect(routing, isNotNull);
          expect(routing.inputPorts, isNotNull);
          expect(routing.outputPorts, isNotNull);
        },
        'note': (json) {
          // Notes algorithm - special case with no I/O
          final slot = _createSlotFromJson(json);
          final routing = AlgorithmRouting.fromSlot(slot);

          // Should handle Notes algorithm gracefully (no I/O)
          expect(routing.inputPorts, isEmpty);
          expect(routing.outputPorts, isEmpty);
        },
      };

      for (final entry in testCases.entries) {
        final algorithmJson = algorithms.firstWhere(
          (a) => a['guid'] == entry.key,
          orElse: () => null,
        );

        if (algorithmJson != null) {
          try {
            entry.value(algorithmJson);
            debugPrint(
              '✓ ${algorithmJson['name']} (${entry.key}) passed specific tests',
            );
          } catch (e) {
            fail('Algorithm ${entry.key} failed specific tests: $e');
          }
        } else {
          debugPrint('⚠ Algorithm ${entry.key} not found in JSON data');
        }
      }
    });

    test('should extract correct parameter types from algorithms', () {
      final algorithms = algorithmData['algorithms'] as List;

      for (final algorithmJson in algorithms) {
        final guid = algorithmJson['guid'] as String;
        final name = algorithmJson['name'] as String;
        final parameters = algorithmJson['parameters'] as List?;

        if (parameters == null || parameters.isEmpty) {
          continue;
        }

        final slot = _createSlotFromJson(algorithmJson);

        // Test IO parameter extraction
        final ioParams = AlgorithmRouting.extractIOParameters(slot);

        // Test mode parameter extraction
        final modeParams = AlgorithmRouting.extractModeParameters(slot);
        final modeParamsWithNumbers =
            AlgorithmRouting.extractModeParametersWithNumbers(slot);

        // Verify that mode parameters have matching entries in both maps
        for (final modeName in modeParams.keys) {
          if (modeParamsWithNumbers.containsKey(modeName)) {
            expect(
              modeParams[modeName],
              equals(modeParamsWithNumbers[modeName]?.value),
              reason:
                  'Mode parameter $modeName should have matching values in both maps for $name ($guid)',
            );
          }
        }

        // Notes algorithm should have no I/O parameters
        if (guid == 'note') {
          expect(
            ioParams,
            isEmpty,
            reason: 'Notes algorithm should have no I/O parameters',
          );
        }
      }
    });

    // Additional explicit tests for new ES-5 algorithms
    group('ES-5 Algorithm Factory Tests', () {
      test('Clock Multiplier (clkm) loads correctly', () {
        final slot = Slot(
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'clkm',
            name: 'Clock Multiplier',
          ),
          routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: [],
          values: [],
          enums: const [],
          mappings: const [],
          valueStrings: const [],
        );

        final routing = AlgorithmRouting.fromSlot(
          slot,
          algorithmUuid: 'test-clkm',
        );

        expect(routing, isNotNull);
        expect(routing.runtimeType.toString(), contains('ClockMultiplier'));
      });

      test('Clock Divider (clkd) loads correctly', () {
        final slot = Slot(
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'clkd',
            name: 'Clock Divider',
          ),
          routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: [],
          values: [],
          enums: const [],
          mappings: const [],
          valueStrings: const [],
        );

        final routing = AlgorithmRouting.fromSlot(
          slot,
          algorithmUuid: 'test-clkd',
        );

        expect(routing, isNotNull);
        expect(routing.runtimeType.toString(), contains('ClockDivider'));
      });
    });
  });
}

/// Helper function to create a Slot from JSON algorithm data
Slot _createSlotFromJson(Map<String, dynamic> json) {
  final guid = json['guid'] as String;
  final name = json['name'] as String;
  final parameters = (json['parameters'] as List? ?? []);

  // Create Algorithm
  final algorithm = Algorithm(
    algorithmIndex: 0, // Use 0 for testing
    guid: guid,
    name: name,
  );

  // Create RoutingInfo (empty for testing)
  final routing = RoutingInfo(
    algorithmIndex: 0,
    routingInfo: List.filled(6, 0),
  );

  // Create ParameterPages (empty for testing)
  final pages = ParameterPages(algorithmIndex: 0, pages: []);

  // Create ParameterInfo list
  final parameterInfos = <ParameterInfo>[];
  final parameterValues = <ParameterValue>[];
  final parameterEnums = <ParameterEnumStrings>[];
  final mappings = <Mapping>[];
  final valueStrings = <ParameterValueString>[];

  for (int i = 0; i < parameters.length; i++) {
    final param = parameters[i] as Map<String, dynamic>;

    // Create ParameterInfo
    final paramInfo = ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: param['parameterNumber'] as int? ?? i,
      min: (param['minValue'] as num?)?.toInt() ?? 0,
      max: (param['maxValue'] as num?)?.toInt() ?? 100,
      defaultValue: (param['defaultValue'] as num?)?.toInt() ?? 0,
      unit: _getUnitType(param),
      name: param['name'] as String? ?? 'Parameter $i',
      powerOfTen: 0,
    );
    parameterInfos.add(paramInfo);

    // Create ParameterValue with default value
    final paramValue = ParameterValue(
      algorithmIndex: 0,
      parameterNumber: paramInfo.parameterNumber,
      value: paramInfo.defaultValue,
    );
    parameterValues.add(paramValue);

    // Create empty ParameterEnumStrings
    // Check if this looks like an enum parameter
    final isEnumParam =
        paramInfo.unit == 1 ||
        (paramInfo.unit == 2 &&
            paramInfo.max == 1); // Boolean is also enum-like

    if (isEnumParam) {
      // For mode parameters, create Add/Replace enums
      if (paramInfo.name.toLowerCase().endsWith('mode')) {
        parameterEnums.add(
          ParameterEnumStrings(
            algorithmIndex: 0,
            parameterNumber: paramInfo.parameterNumber,
            values: ['Add', 'Replace'],
          ),
        );
      } else {
        // For other enum parameters, create generic enums based on range
        final enumValues = <String>[];
        for (int v = paramInfo.min; v <= paramInfo.max; v++) {
          enumValues.add('Value $v');
        }
        parameterEnums.add(
          ParameterEnumStrings(
            algorithmIndex: 0,
            parameterNumber: paramInfo.parameterNumber,
            values: enumValues,
          ),
        );
      }
    } else {
      parameterEnums.add(
        ParameterEnumStrings(
          algorithmIndex: 0,
          parameterNumber: paramInfo.parameterNumber,
          values: [],
        ),
      );
    }

    // Create empty Mapping
    mappings.add(
      Mapping(
        algorithmIndex: 0,
        parameterNumber: paramInfo.parameterNumber,
        packedMappingData: PackedMappingData.filler(),
      ),
    );

    // Create empty ParameterValueString
    valueStrings.add(
      ParameterValueString(
        algorithmIndex: 0,
        parameterNumber: paramInfo.parameterNumber,
        value: '',
      ),
    );
  }

  return Slot(
    algorithm: algorithm,
    routing: routing,
    pages: pages,
    parameters: parameterInfos,
    values: parameterValues,
    enums: parameterEnums,
    mappings: mappings,
    valueStrings: valueStrings,
  );
}

/// Helper function to determine the unit type for a parameter
int _getUnitType(Map<String, dynamic> param) {
  final min = (param['minValue'] as num?)?.toInt() ?? 0;
  final max = (param['maxValue'] as num?)?.toInt() ?? 100;
  final name = param['name'] as String? ?? '';
  final unitStr = param['unit'] as String?;

  // Check if this is a bus parameter (routing enum)
  // Bus parameters are identified by:
  // - min is 0 or 1
  // - max is 27, 28, or 30
  // - typically named Input, Output, or contains these words
  if ((min == 0 || min == 1) && (max == 27 || max == 28 || max == 30)) {
    // This is likely a bus routing parameter
    return 1; // enum type
  }

  // Check if this is a boolean parameter
  if (min == 0 && max == 1) {
    // Could be boolean or a 2-value enum
    // If it ends with "mode" it's likely an enum (Add/Replace)
    if (name.toLowerCase().endsWith('mode')) {
      return 1; // enum type
    }
    return 2; // boolean type
  }

  // Check unit string for other types
  if (unitStr != null && unitStr.isNotEmpty) {
    // dB is sometimes used for routing enums
    if (unitStr == 'dB' && (max == 27 || max == 28)) {
      return 1; // enum type for routing
    }
    // These are numeric units
    if (unitStr == 'Hz' ||
        unitStr == 'ms' ||
        unitStr == 'mV' ||
        unitStr == '%' ||
        unitStr == 'V' ||
        unitStr == 'semitones' ||
        unitStr == 'frames' ||
        unitStr == 'degrees') {
      return 0; // Numeric units
    }
  }

  return 0; // Default to numeric
}
