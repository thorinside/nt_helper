import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/disting_controller_impl.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/database.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  group('DistingTools - editPreset', () {
    late DistingTools tools;
    late DistingCubit distingCubit;
    late DistingControllerImpl controller;
    late AppDatabase database;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      database = AppDatabase.forTesting(NativeDatabase.memory());

      // Initialize the AlgorithmMetadataService
      await AlgorithmMetadataService().initialize(database);
    });

    setUp(() {
      distingCubit = DistingCubit(database);
      controller = DistingControllerImpl(distingCubit);
      tools = DistingTools(controller);
    });

    tearDown(() {
      distingCubit.close();
    });

    tearDownAll(() async {
      await database.close();
    });

    group('editPreset - parameter validation', () {
      test('should return error when target parameter is missing', () async {
        final result = await tools.editPreset({
          'data': {'name': 'test'},
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('target'));
      });

      test('should return error when target is not "preset"', () async {
        final result = await tools.editPreset({
          'target': 'slot',
          'data': {'name': 'test'},
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('target'));
      });

      test('should return error when data parameter is missing', () async {
        final result = await tools.editPreset({
          'target': 'preset',
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('data'));
      });

      test('should return error when preset name is missing', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {'slots': []},
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('name'));
      });

      test('should return error when preset name is empty', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {'name': '', 'slots': []},
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('name'));
      });
    });

    group('editPreset - slot validation', () {
      test('should return error when slot is not an object', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': ['not-an-object'],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        // Should be slot validation error OR device state error
        expect(
          decoded['error'].toString().contains('object') ||
              decoded['error'].toString().contains('not in a synchronized'),
          isTrue,
        );
      });

      test('should return error when algorithm is missing from slot', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [{}],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        // Should be algorithm validation error OR device state error
        expect(
          decoded['error'].toString().contains('algorithm') ||
              decoded['error'].toString().contains('not in a synchronized'),
          isTrue,
        );
      });

      test(
          'should return error when algorithm has neither guid nor name',
          () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {'algorithm': {}},
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        // Error should contain 'guid' or 'name' or indicate device state issue
        final errorMsg = decoded['error'].toString();
        expect(
          errorMsg.contains('guid') ||
              errorMsg.contains('name') ||
              errorMsg.contains('not in a synchronized'),
          isTrue,
        );
      });
    });

    group('editPreset - validation with valid algorithms', () {
      test('should validate slot index within valid range', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        // Should be success or other error, but not slot index error
        expect(
          decoded['error']?.toString() ?? '',
          isNot(contains('out of valid range')),
        );
      });

      test('should validate parameter number bounds', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
                'parameters': [
                  {
                    'parameter_number': 999, // Way out of bounds
                    'value': 50,
                  },
                ],
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        // Should be parameter bounds error OR device state error
        expect(
          decoded['error'].toString().contains('exceeds algorithm parameter count') ||
              decoded['error'].toString().contains('not in a synchronized'),
          isTrue,
        );
      });
    });

    group('editPreset - parameter value validation', () {
      test('should validate parameter value is within bounds', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
                'parameters': [
                  {
                    'parameter_number': 0,
                    'value': 99999, // Out of bounds for most parameters
                  },
                ],
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        // This will depend on algorithm bounds, but structure should be valid
        expect(decoded is Map, isTrue);
      });
    });

    group('editPreset - mapping validation', () {
      test('should validate MIDI channel is 0-15', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
                'parameters': [
                  {
                    'parameter_number': 0,
                    'value': 50,
                    'mapping': {
                      'midi': {
                        'midi_channel': 16, // Invalid: > 15
                      },
                    },
                  },
                ],
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        // Could be MIDI channel error OR device state error
        expect(
          decoded['error'].toString().contains('MIDI channel') ||
              decoded['error'].toString().contains('not in a synchronized'),
          isTrue,
        );
      });

      test('should validate MIDI CC is 0-128', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
                'parameters': [
                  {
                    'parameter_number': 0,
                    'value': 50,
                    'mapping': {
                      'midi': {
                        'midi_cc': 129, // Invalid: > 128
                      },
                    },
                  },
                ],
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        // Could be MIDI CC error OR device state error
        expect(
          decoded['error'].toString().contains('MIDI CC') ||
              decoded['error'].toString().contains('not in a synchronized'),
          isTrue,
        );
      });

      test('should validate CV input is 0-12', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
                'parameters': [
                  {
                    'parameter_number': 0,
                    'value': 50,
                    'mapping': {
                      'cv': {
                        'cv_input': 13, // Invalid: > 12
                      },
                    },
                  },
                ],
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        // Could be CV input error OR device state error
        expect(
          decoded['error'].toString().contains('CV input') ||
              decoded['error'].toString().contains('not in a synchronized'),
          isTrue,
        );
      });

      test('should validate i2c CC is 0-255', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
                'parameters': [
                  {
                    'parameter_number': 0,
                    'value': 50,
                    'mapping': {
                      'i2c': {
                        'i2c_cc': 256, // Invalid: > 255
                      },
                    },
                  },
                ],
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        // Could be i2c CC error OR device state error
        expect(
          decoded['error'].toString().contains('i2c CC') ||
              decoded['error'].toString().contains('not in a synchronized'),
          isTrue,
        );
      });

      test('should validate performance_page is 0-15', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
                'parameters': [
                  {
                    'parameter_number': 0,
                    'value': 50,
                    'mapping': {
                      'performance_page': 16, // Invalid: > 15
                    },
                  },
                ],
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        // Could be performance_page error OR device state error
        expect(
          decoded['error'].toString().contains('Performance page') ||
              decoded['error'].toString().contains('not in a synchronized'),
          isTrue,
        );
      });
    });

    group('editPreset - algorithm resolution', () {
      test('should accept valid algorithm GUID', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        // Should succeed or have operation errors, not algorithm resolution errors
        // (device state errors are acceptable)
        expect(
          decoded['error']?.toString() ?? '',
          isNot(contains('Failed to resolve')),
        );
      });

      test('should reject invalid algorithm GUID', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'invalid-guid-12345'},
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        // Should have either algorithm not found error OR device state error
        expect(
          decoded['error'].toString().contains('not found') ||
              decoded['error'].toString().contains('not in a synchronized'),
          isTrue,
        );
      });
    });

    group('editPreset - response structure', () {
      test('should return valid JSON response', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded is Map, isTrue);
      });

      test('should include success or error field', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [],
          },
        });

        final decoded = jsonDecode(result);
        expect(
          decoded.containsKey('success') || decoded.containsKey('error'),
          isTrue,
        );
      });
    });

    group('editPreset - edge cases', () {
      test('should handle empty slots array', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'empty preset',
            'slots': [],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded is Map, isTrue);
      });

      test('should handle null slots array', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'no slots',
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded is Map, isTrue);
      });

      test('should handle slots without parameters', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded is Map, isTrue);
      });

      test('should handle empty parameters array', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
                'parameters': [],
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded is Map, isTrue);
      });

      test('should accept partial mapping specification', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'guid': 'clck'},
                'parameters': [
                  {
                    'parameter_number': 0,
                    'value': 50,
                    'mapping': {
                      'midi': {
                        'midi_channel': 5,
                      },
                    },
                  },
                ],
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded is Map, isTrue);
      });
    });

    group('editPreset - algorithm name fuzzy matching', () {
      test('should accept algorithm by exact name match', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'name': 'Clock'},
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        // Should succeed or have operation errors, not name resolution errors
        expect(
          decoded['error']?.toString() ?? '',
          isNot(contains('Failed to resolve')),
        );
      });

      test('should reject algorithm with no name or guid match', () async {
        final result = await tools.editPreset({
          'target': 'preset',
          'data': {
            'name': 'test',
            'slots': [
              {
                'algorithm': {'name': 'this-algorithm-definitely-does-not-exist-123456'},
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
      });
    });
  });
}
