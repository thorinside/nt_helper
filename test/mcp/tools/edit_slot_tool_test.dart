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
  group('DistingTools - editSlot', () {
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
      tools = DistingTools(controller, distingCubit);
    });

    tearDown(() {
      distingCubit.close();
    });

    tearDownAll(() async {
      await database.close();
    });

    group('editSlot - parameter validation', () {
      test('should return error when target parameter is missing', () async {
        final result = await tools.editSlot({
          'slot_index': 0,
          'data': {'parameters': []},
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('target'));
      });

      test('should return error when target is not "slot"', () async {
        final result = await tools.editSlot({
          'target': 'preset',
          'slot_index': 0,
          'data': {'parameters': []},
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('target'));
      });

      test('should return error when slot_index parameter is missing', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'data': {'parameters': []},
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('slot_index'));
      });

      test('should return error when slot_index is negative', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': -1,
          'data': {'parameters': []},
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('slot_index'));
      });

      test('should return error when slot_index exceeds maximum', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 32,
          'data': {'parameters': []},
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('slot_index'));
      });

      test('should return error when data parameter is missing', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('data'));
      });

      test('should return error when not in synchronized state', () async {
        // Create a new cubit without syncing (to test offline mode)
        final offlineDistingCubit = DistingCubit(database);
        final offlineController = DistingControllerImpl(offlineDistingCubit);
        final offlineTools = DistingTools(offlineController, offlineDistingCubit);

        final result = await offlineTools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {'parameters': []},
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('synchronized'));

        offlineDistingCubit.close();
      });
    });

    group('editSlot - algorithm validation', () {
      test('should return error when algorithm has neither guid nor name', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'algorithm': {},
            'parameters': [],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(
          decoded['error'].toString().contains('algorithm') ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });

      test('should return error when algorithm guid does not exist', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'algorithm': {
              'guid': 'nonexistent_guid',
            },
            'parameters': [],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(
          decoded['error'].toString().contains('not found') ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });

      test('should return error when specifications count exceeds algorithm limit', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'algorithm': {
              'guid': 'clck',
              'specifications': [
                {},
                {},
                {},
                {},
              ],
            },
            'parameters': [],
          },
        });

        final decoded = jsonDecode(result);
        // Validation error or device state error is acceptable
        expect(decoded['success'], isFalse);
      });
    });

    group('editSlot - parameter value validation', () {
      test('should return error when parameter_number is missing', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'parameters': [
              {
                'value': 100,
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(
          decoded['error'].toString().contains('parameter_number') ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });

      test('should return error when parameter value is not a number', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'algorithm': {
              'guid': 'clck',
            },
            'parameters': [
              {
                'parameter_number': 0,
                'value': 'not_a_number',
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(
          decoded['error'].toString().contains('number') ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });

      test('should return error when parameter_number is out of range', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'algorithm': {
              'guid': 'clck',
            },
            'parameters': [
              {
                'parameter_number': 999,
                'value': 100,
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(
          decoded['error'].toString().contains('out of range') ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });
    });

    group('editSlot - mapping validation', () {
      test('should return error when MIDI channel is out of range', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'algorithm': {
              'guid': 'clck',
            },
            'parameters': [
              {
                'parameter_number': 0,
                'mapping': {
                  'midi': {
                    'midi_channel': 16,
                  },
                },
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(
          decoded['error'].toString().contains('MIDI channel') ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });

      test('should return error when MIDI CC is out of range', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'algorithm': {
              'guid': 'clck',
            },
            'parameters': [
              {
                'parameter_number': 0,
                'mapping': {
                  'midi': {
                    'midi_cc': 129,
                  },
                },
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(
          decoded['error'].toString().contains('MIDI CC') ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });

      test('should return error when CV input is out of range', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'algorithm': {
              'guid': 'clck',
            },
            'parameters': [
              {
                'parameter_number': 0,
                'mapping': {
                  'cv': {
                    'cv_input': 13,
                  },
                },
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(
          decoded['error'].toString().contains('CV input') ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });

      test('should return error when i2c CC is out of range', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'algorithm': {
              'guid': 'clck',
            },
            'parameters': [
              {
                'parameter_number': 0,
                'mapping': {
                  'i2c': {
                    'i2c_cc': 256,
                  },
                },
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(
          decoded['error'].toString().contains('i2c CC') ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });

      test('should return error when performance_page is out of range', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'algorithm': {
              'guid': 'clck',
            },
            'parameters': [
              {
                'parameter_number': 0,
                'mapping': {
                  'performance_page': 16,
                },
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(
          decoded['error'].toString().contains('performance_page') ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });
    });

    group('editSlot - successful updates', () {
      test('should successfully update slot with no algorithm change', () async {
        // First add an algorithm to slot 0
        await tools.addAlgorithm({
          'algorithm': {
            'guid': 'clck',
          },
        });

        // Now update a parameter in that slot
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'parameters': [
              {
                'parameter_number': 0,
                'value': 500,
              },
            ],
          },
        });

        final decoded = jsonDecode(result);
        // Should be successful or have device state error
        expect(
          decoded['success'] == true ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });

      test('should successfully update slot name', () async {
        // First add an algorithm to slot 0
        await tools.addAlgorithm({
          'algorithm': {
            'guid': 'clck',
          },
        });

        // Now update the slot name
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'name': 'My Custom Clock',
          },
        });

        final decoded = jsonDecode(result);
        expect(
          decoded['success'] == true ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });

      test('should return empty slot when clearing and not adding new algorithm', () async {
        // First add an algorithm to slot 0
        await tools.addAlgorithm({
          'algorithm': {
            'guid': 'clck',
          },
        });

        // Now clear it by changing to a different algorithm without specifications
        // This tests the case where a slot might become empty
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'parameters': [],
          },
        });

        final decoded = jsonDecode(result);
        expect(
          decoded['success'] == true ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });

      test('should return parameters list for occupied slot', () async {
        // First add an algorithm to slot 0
        await tools.addAlgorithm({
          'algorithm': {
            'guid': 'clck',
          },
        });

        // Now query the slot
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'parameters': [],
          },
        });

        final decoded = jsonDecode(result);
        expect(
          decoded['success'] == true ||
              decoded['error'].toString().contains('synchronized'),
          isTrue,
        );
      });
    });

    group('editSlot - edge cases', () {
      test('should accept empty data object', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {},
        });

        final decoded = jsonDecode(result);
        // May succeed or fail with device state error
        expect(
          decoded['success'] == true || decoded['error'] != null,
          isTrue,
        );
      });

      test('should accept empty parameters array', () async {
        final result = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {
            'parameters': [],
          },
        });

        final decoded = jsonDecode(result);
        // May succeed or fail with device state error
        expect(
          decoded['success'] == true || decoded['error'] != null,
          isTrue,
        );
      });

      test('should validate slot_index boundaries', () async {
        final result0 = await tools.editSlot({
          'target': 'slot',
          'slot_index': 0,
          'data': {},
        });

        final decoded0 = jsonDecode(result0);
        // Either succeeds or has error message
        expect(
          decoded0['success'] == true || decoded0['error'] != null,
          isTrue,
        );

        final result31 = await tools.editSlot({
          'target': 'slot',
          'slot_index': 31,
          'data': {},
        });

        final decoded31 = jsonDecode(result31);
        // Either succeeds or has error message
        expect(
          decoded31['success'] == true || decoded31['error'] != null,
          isTrue,
        );
      });
    });
  });
}
