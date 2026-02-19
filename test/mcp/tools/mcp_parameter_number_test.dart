import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show Algorithm, Mapping, ParameterEnumStrings, ParameterInfo, ParameterValue;
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/services/disting_controller.dart';
import 'package:nt_helper/cubit/disting_cubit.dart'
    show DistingCubit, DistingStateInitial;
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/metadata_import_service.dart';
import 'package:nt_helper/db/database.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class MockDistingController extends Mock implements DistingController {}

class MockDistingCubit extends Mock implements DistingCubit {}

class FakePackedMappingData extends Fake implements PackedMappingData {}

void main() {
  late MockDistingController controller;
  late MockDistingCubit cubit;
  late DistingTools distingTools;
  late MCPAlgorithmTools algoTools;
  late AppDatabase database;

  // Test slot with non-contiguous parameter numbers: hardware [0, 5, 10]
  final testAlgorithm = Algorithm(
    algorithmIndex: 0,
    guid: 'test',
    name: 'TestAlgo',
  );

  final testParameters = [
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 0,
      min: 0,
      max: 100,
      defaultValue: 50,
      unit: 0,
      name: 'Level',
      powerOfTen: 0,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 5,
      min: 0,
      max: 100,
      defaultValue: 50,
      unit: 0,
      name: 'Mix',
      powerOfTen: 0,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 10,
      min: 0,
      max: 1000,
      defaultValue: 500,
      unit: 0,
      name: 'Freq',
      powerOfTen: 0,
    ),
  ];

  final testValues = [
    ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 50),
    ParameterValue(algorithmIndex: 0, parameterNumber: 5, value: 75),
    ParameterValue(algorithmIndex: 0, parameterNumber: 10, value: 500),
  ];

  final testMappings = [
    Mapping(
      algorithmIndex: 0,
      parameterNumber: 0,
      packedMappingData: PackedMappingData.filler(),
    ),
    Mapping(
      algorithmIndex: 0,
      parameterNumber: 5,
      packedMappingData: PackedMappingData.filler(),
    ),
    Mapping(
      algorithmIndex: 0,
      parameterNumber: 10,
      packedMappingData: PackedMappingData.filler(),
    ),
  ];

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(FakePackedMappingData());
    registerFallbackValue(Algorithm(algorithmIndex: 0, guid: 'fake', name: 'Fake'));

    database = AppDatabase.forTesting(NativeDatabase.memory());

    var current = Directory.current;
    while (!File(path.join(current.path, 'pubspec.yaml')).existsSync()) {
      final parent = current.parent;
      if (parent.path == current.path) {
        throw Exception('Could not find project root');
      }
      current = parent;
    }
    final metadataPath = path.join(
      current.path,
      'assets',
      'metadata',
      'full_metadata.json',
    );
    final file = File(metadataPath);
    final jsonString = file.readAsStringSync();

    final importService = MetadataImportService(database);
    await importService.importFromJson(jsonString);

    await AlgorithmMetadataService().initialize(database);
  });

  setUp(() {
    controller = MockDistingController();
    cubit = MockDistingCubit();
    distingTools = DistingTools(controller, cubit);
    algoTools = MCPAlgorithmTools(controller, cubit);

    // Default stubs for synchronized state
    when(() => controller.isSynchronized).thenReturn(true);
    when(() => controller.getAlgorithmInSlot(0))
        .thenAnswer((_) async => testAlgorithm);
    when(() => controller.getParametersForSlot(0))
        .thenAnswer((_) async => testParameters);
    when(() => controller.getValuesForSlot(0))
        .thenAnswer((_) async => testValues);
    when(() => controller.getMappingsForSlot(0))
        .thenAnswer((_) async => testMappings);
    when(() => controller.flushParameterQueue()).thenAnswer((_) async {});
    when(() => controller.savePreset()).thenAnswer((_) async {});
    when(() => controller.getCurrentPresetName())
        .thenAnswer((_) async => 'TestPreset');
    when(() => controller.getAllSlots()).thenAnswer((_) async => {
          0: testAlgorithm,
        });
    when(() => controller.setPresetName(any())).thenAnswer((_) async {});
    // Stub cubit.state for _getAllKnownAlgorithms (returns non-synchronized)
    when(() => cubit.state).thenReturn(const DistingStateInitial());
  });

  tearDownAll(() async {
    await database.close();
  });

  group('show tools — non-contiguous parameter numbers', () {
    test('showSlot returns hardware parameter numbers', () async {
      when(() => controller.refreshSlot(0)).thenAnswer((_) async {});

      final result = await algoTools.showSlot(0);
      final json = jsonDecode(result) as Map<String, dynamic>;
      final params = json['parameters'] as List<dynamic>;

      final paramNumbers =
          params.map((p) => (p as Map<String, dynamic>)['parameter_number']).toList();
      expect(paramNumbers, equals([0, 5, 10]));
    });

    test('showParameter(5) finds correct param', () async {
      final result = await algoTools.showParameter('0:5');
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['parameter_number'], equals(5));
      expect(json['parameter_name'], equals('Mix'));
    });

    test('showParameter(3) errors with available numbers', () async {
      final result = await algoTools.showParameter('0:3');
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], contains('3'));
      expect(json['error'], contains('[0, 5, 10]'));
    });

    test('showParameter(1) errors — array index exists but not a hardware number',
        () async {
      final result = await algoTools.showParameter('0:1');
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], contains('1'));
      expect(json['error'], contains('[0, 5, 10]'));
    });
  });

  group('editParameter — parameter resolution + call ordering', () {
    test('editParameter by number=5 calls controller with 5', () async {
      when(() => controller.updateParameterValue(0, 5, 80))
          .thenAnswer((_) async {});
      when(() => controller.getParameterValue(0, 5)).thenAnswer(
        (_) async =>
            ParameterValue(algorithmIndex: 0, parameterNumber: 5, value: 80),
      );
      when(() => controller.getParameterMapping(0, 5))
          .thenAnswer((_) async => testMappings[1]);

      await distingTools.editParameter({
        'target': 'parameter',
        'slot_index': 0,
        'parameter': 5,
        'value': 80,
      });

      verify(() => controller.updateParameterValue(0, 5, 80)).called(1);
    });

    test('editParameter by name="Mix" resolves to hardware number 5', () async {
      when(() => controller.updateParameterValue(0, 5, 80))
          .thenAnswer((_) async {});
      when(() => controller.getParameterValue(0, 5)).thenAnswer(
        (_) async =>
            ParameterValue(algorithmIndex: 0, parameterNumber: 5, value: 80),
      );
      when(() => controller.getParameterMapping(0, 5))
          .thenAnswer((_) async => testMappings[1]);

      await distingTools.editParameter({
        'target': 'parameter',
        'slot_index': 0,
        'parameter': 'Mix',
        'value': 80,
      });

      verify(() => controller.updateParameterValue(0, 5, 80)).called(1);
    });

    test('editParameter returns hardware param number in response', () async {
      when(() => controller.updateParameterValue(0, 5, 80))
          .thenAnswer((_) async {});
      when(() => controller.getParameterValue(0, 5)).thenAnswer(
        (_) async =>
            ParameterValue(algorithmIndex: 0, parameterNumber: 5, value: 80),
      );
      when(() => controller.getParameterMapping(0, 5))
          .thenAnswer((_) async => testMappings[1]);

      final result = await distingTools.editParameter({
        'target': 'parameter',
        'slot_index': 0,
        'parameter': 5,
        'value': 80,
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['parameter_number'], equals(5));
    });

    test('editParameter(3) errors with available hardware numbers', () async {
      final result = await distingTools.editParameter({
        'target': 'parameter',
        'slot_index': 0,
        'parameter': 3,
        'value': 50,
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], contains('3'));
      expect(json['error'], contains('0:'));
      expect(json['error'], contains('5:'));
      expect(json['error'], contains('10:'));
    });

    test('editParameter(1) errors — array index, not hardware number', () async {
      final result = await distingTools.editParameter({
        'target': 'parameter',
        'slot_index': 0,
        'parameter': 1,
        'value': 50,
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], contains('1'));
    });

    test('editParameter flushes before save', () async {
      when(() => controller.updateParameterValue(0, 5, 80))
          .thenAnswer((_) async {});
      when(() => controller.getParameterValue(0, 5)).thenAnswer(
        (_) async =>
            ParameterValue(algorithmIndex: 0, parameterNumber: 5, value: 80),
      );
      when(() => controller.getParameterMapping(0, 5))
          .thenAnswer((_) async => testMappings[1]);

      await distingTools.editParameter({
        'target': 'parameter',
        'slot_index': 0,
        'parameter': 5,
        'value': 80,
      });

      verifyInOrder([
        () => controller.updateParameterValue(0, 5, 80),
        () => controller.flushParameterQueue(),
        () => controller.savePreset(),
      ]);
    });

    test('editParameter reads back after flush+save', () async {
      when(() => controller.updateParameterValue(0, 5, 80))
          .thenAnswer((_) async {});
      when(() => controller.getParameterValue(0, 5)).thenAnswer(
        (_) async =>
            ParameterValue(algorithmIndex: 0, parameterNumber: 5, value: 80),
      );
      when(() => controller.getParameterMapping(0, 5))
          .thenAnswer((_) async => testMappings[1]);

      await distingTools.editParameter({
        'target': 'parameter',
        'slot_index': 0,
        'parameter': 5,
        'value': 80,
      });

      verifyInOrder([
        () => controller.flushParameterQueue(),
        () => controller.savePreset(),
        () => controller.getParameterValue(0, 5),
      ]);
    });

    test('editParameter read-back returns post-write value', () async {
      when(() => controller.updateParameterValue(0, 5, 80))
          .thenAnswer((_) async {});
      when(() => controller.getParameterValue(0, 5)).thenAnswer(
        (_) async =>
            ParameterValue(algorithmIndex: 0, parameterNumber: 5, value: 80),
      );
      when(() => controller.getParameterMapping(0, 5))
          .thenAnswer((_) async => testMappings[1]);

      final result = await distingTools.editParameter({
        'target': 'parameter',
        'slot_index': 0,
        'parameter': 5,
        'value': 80,
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['value'], equals(80));
    });
  });

  group('editSlot — multi-param + ordering', () {
    test('editSlot resolves param by hardware number', () async {
      when(() => controller.updateParameterValue(0, 5, 80))
          .thenAnswer((_) async {});
      when(() => controller.getParameterValue(0, any(that: isA<int>())))
          .thenAnswer((inv) async {
        final paramNum = inv.positionalArguments[1] as int;
        final idx = testParameters.indexWhere((p) => p.parameterNumber == paramNum);
        return ParameterValue(
          algorithmIndex: 0,
          parameterNumber: paramNum,
          value: paramNum == 5 ? 80 : testValues[idx].value,
        );
      });
      when(() => controller.getSlotName(0)).thenAnswer((_) async => null);

      await distingTools.editSlot({
        'target': 'slot',
        'slot_index': 0,
        'data': {
          'parameters': [
            {'parameter_number': 5, 'value': 80},
          ],
        },
      });

      verify(() => controller.updateParameterValue(0, 5, 80)).called(1);
    });

    test('editSlot errors with available numbers for invalid param', () async {
      final result = await distingTools.editSlot({
        'target': 'slot',
        'slot_index': 0,
        'data': {
          'parameters': [
            {'parameter_number': 3, 'value': 50},
          ],
        },
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], contains('3'));
    });

    test('editSlot read-back uses hardware param numbers', () async {
      when(() => controller.updateParameterValue(0, 5, 80))
          .thenAnswer((_) async {});
      when(() => controller.getParameterValue(0, any(that: isA<int>())))
          .thenAnswer((inv) async {
        final paramNum = inv.positionalArguments[1] as int;
        final idx = testParameters.indexWhere((p) => p.parameterNumber == paramNum);
        return ParameterValue(
          algorithmIndex: 0,
          parameterNumber: paramNum,
          value: paramNum == 5 ? 80 : testValues[idx].value,
        );
      });
      when(() => controller.getSlotName(0)).thenAnswer((_) async => null);

      final result = await distingTools.editSlot({
        'target': 'slot',
        'slot_index': 0,
        'data': {
          'parameters': [
            {'parameter_number': 5, 'value': 80},
          ],
        },
      });
      final json = jsonDecode(result) as Map<String, dynamic>;
      final params = json['parameters'] as List<dynamic>;

      final paramNumbers =
          params.map((p) => (p as Map<String, dynamic>)['parameter_number']).toList();
      expect(paramNumbers, equals([0, 5, 10]));
    });

    test('editSlot with multiple params: flush before save', () async {
      when(() => controller.updateParameterValue(0, any(that: isA<int>()), any(that: isA<int>())))
          .thenAnswer((_) async {});
      when(() => controller.getParameterValue(0, any(that: isA<int>())))
          .thenAnswer((inv) async {
        final paramNum = inv.positionalArguments[1] as int;
        return ParameterValue(
          algorithmIndex: 0,
          parameterNumber: paramNum,
          value: 80,
        );
      });
      when(() => controller.getSlotName(0)).thenAnswer((_) async => null);

      await distingTools.editSlot({
        'target': 'slot',
        'slot_index': 0,
        'data': {
          'parameters': [
            {'parameter_number': 0, 'value': 80},
            {'parameter_number': 5, 'value': 80},
          ],
        },
      });

      verifyInOrder([
        () => controller.updateParameterValue(0, 0, 80),
        () => controller.updateParameterValue(0, 5, 80),
        () => controller.flushParameterQueue(),
        () => controller.savePreset(),
      ]);
    });

    test('editSlot read-back returns post-write values', () async {
      when(() => controller.updateParameterValue(0, 5, 80))
          .thenAnswer((_) async {});
      when(() => controller.getParameterValue(0, any(that: isA<int>())))
          .thenAnswer((inv) async {
        final paramNum = inv.positionalArguments[1] as int;
        return ParameterValue(
          algorithmIndex: 0,
          parameterNumber: paramNum,
          value: paramNum == 5 ? 80 : 50,
        );
      });
      when(() => controller.getSlotName(0)).thenAnswer((_) async => null);

      final result = await distingTools.editSlot({
        'target': 'slot',
        'slot_index': 0,
        'data': {
          'parameters': [
            {'parameter_number': 5, 'value': 80},
          ],
        },
      });
      final json = jsonDecode(result) as Map<String, dynamic>;
      final params = json['parameters'] as List<dynamic>;

      final mixParam = params.firstWhere(
        (p) => (p as Map<String, dynamic>)['parameter_number'] == 5,
      ) as Map<String, dynamic>;
      expect(mixParam['value'], equals(80));
    });
  });

  group('editPreset — ordering', () {
    test('editPreset flushes before save', () async {
      // Use empty preset so _applyDiff doesn't need extensive stubs
      when(() => controller.getAllSlots()).thenAnswer((_) async => <int, Algorithm?>{});
      when(() => controller.getCurrentPresetName())
          .thenAnswer((_) async => 'OldPreset');

      await distingTools.editPreset({
        'target': 'preset',
        'data': {
          'name': 'NewPreset',
        },
      });

      verifyInOrder([
        () => controller.flushParameterQueue(),
        () => controller.savePreset(),
      ]);
    });

    test('editPreset read-back uses hardware param numbers', () async {
      // Use empty preset for simplicity; the flush→save ordering is verified above
      when(() => controller.getAllSlots()).thenAnswer((_) async => <int, Algorithm?>{});
      // Simulate name changing: first call returns old, subsequent return new
      var nameCallCount = 0;
      when(() => controller.getCurrentPresetName()).thenAnswer((_) async {
        nameCallCount++;
        return nameCallCount <= 1 ? 'OldPreset' : 'NewPreset';
      });

      final result = await distingTools.editPreset({
        'target': 'preset',
        'data': {
          'name': 'NewPreset',
        },
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      expect(json['preset_name'], equals('NewPreset'));
    });
  });

  group('show tools don\'t flush', () {
    test('showSlot does not call flushParameterQueue', () async {
      when(() => controller.refreshSlot(0)).thenAnswer((_) async {});

      await algoTools.showSlot(0);

      verifyNever(() => controller.flushParameterQueue());
    });

    test('showParameter does not call flushParameterQueue', () async {
      await algoTools.showParameter('0:5');

      verifyNever(() => controller.flushParameterQueue());
    });
  });

  group('editPreset _applyDiff — mapping collection uses hardware param numbers', () {
    test('getParameterMapping called with hardware numbers not array indices',
        () async {
      // Preset has one slot with non-contiguous params [0, 5, 10].
      // editPreset keeps same algorithm (no swap). The pre-collection
      // loop in _applyDiff should call getParameterMapping with hardware
      // parameter numbers, NOT array indices.
      //
      // Bug: loop uses `paramNum` (0,1,2) instead of
      // `paramList[paramNum].parameterNumber` (0,5,10).

      // Use a real GUID so _validateDiff passes metadata checks
      const realGuid = 'attn';
      final realAlgorithm = Algorithm(
        algorithmIndex: 0,
        guid: realGuid,
        name: 'Attenuator',
      );

      when(() => controller.getAllSlots()).thenAnswer((_) async => {
            0: realAlgorithm,
          });
      when(() => controller.getAlgorithmInSlot(0))
          .thenAnswer((_) async => realAlgorithm);
      when(() => controller.getParametersForSlot(0))
          .thenAnswer((_) async => testParameters);
      when(() => controller.getCurrentPresetName())
          .thenAnswer((_) async => 'TestPreset');

      // Stub getParameterMapping for hardware numbers
      when(() => controller.getParameterMapping(0, 0))
          .thenAnswer((_) async => testMappings[0]);
      when(() => controller.getParameterMapping(0, 5))
          .thenAnswer((_) async => testMappings[1]);
      when(() => controller.getParameterMapping(0, 10))
          .thenAnswer((_) async => testMappings[2]);

      // Stub the buggy array-index calls so the test doesn't throw
      when(() => controller.getParameterMapping(0, 1))
          .thenAnswer((_) async => null);
      when(() => controller.getParameterMapping(0, 2))
          .thenAnswer((_) async => null);

      // Stub read-back methods
      when(() => controller.getParameterValue(0, any(that: isA<int>())))
          .thenAnswer((inv) async {
        final paramNum = inv.positionalArguments[1] as int;
        return ParameterValue(
          algorithmIndex: 0,
          parameterNumber: paramNum,
          value: 50,
        );
      });

      // editPreset: same algorithm, no parameter changes — just triggers
      // the mapping pre-collection loop
      await distingTools.editPreset({
        'target': 'preset',
        'data': {
          'name': 'TestPreset',
          'slots': [
            {
              'algorithm': {'guid': realGuid},
            },
          ],
        },
      });

      // The mapping pre-collection should use hardware param numbers
      verify(() => controller.getParameterMapping(0, 0)).called(greaterThanOrEqualTo(1));
      verify(() => controller.getParameterMapping(0, 5)).called(greaterThanOrEqualTo(1));
      verify(() => controller.getParameterMapping(0, 10)).called(greaterThanOrEqualTo(1));

      // Array indices 1 and 2 should NEVER be used as parameter numbers
      verifyNever(() => controller.getParameterMapping(0, 1));
      verifyNever(() => controller.getParameterMapping(0, 2));
    });
  });

  group('newWithAlgorithms — non-contiguous parameter read-back', () {
    // Use a real GUID so algorithm resolution works
    const realGuid = 'attn';
    final realAlgorithm = Algorithm(
      algorithmIndex: 0,
      guid: realGuid,
      name: 'Attenuator',
    );

    // Make param at index 1 (hardware number 5) an enum param (unit=1)
    final enumTestParameters = [
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Level',
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 5,
        min: 0,
        max: 3,
        defaultValue: 0,
        unit: 1, // enum unit
        name: 'Mode',
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 10,
        min: 0,
        max: 1000,
        defaultValue: 500,
        unit: 0,
        name: 'Freq',
        powerOfTen: 0,
      ),
    ];

    setUp(() {
      // Stubs for newWithAlgorithms flow
      when(() => controller.newPreset()).thenAnswer((_) async {});
      when(() => controller.setPresetName(any())).thenAnswer((_) async {});
      when(() => controller.addAlgorithm(any())).thenAnswer((_) async {});
      when(() => controller.getAllSlots()).thenAnswer((_) async => {
            0: realAlgorithm,
          });
      when(() => controller.getAlgorithmInSlot(0))
          .thenAnswer((_) async => realAlgorithm);
      when(() => controller.getParametersForSlot(0))
          .thenAnswer((_) async => enumTestParameters);
      when(() => controller.getValuesForSlot(0))
          .thenAnswer((_) async => testValues);
      when(() => controller.getCurrentPresetName())
          .thenAnswer((_) async => 'TestPreset');
    });

    test(
        'read-back calls getParameterEnumStrings with hardware numbers, not array indices',
        () async {
      // Stub getParameterEnumStrings for hardware number 5 (the enum param)
      when(() => controller.getParameterEnumStrings(0, 5)).thenAnswer(
        (_) async => ParameterEnumStrings(
          algorithmIndex: 0,
          parameterNumber: 5,
          values: ['Off', 'Low', 'Mid', 'High'],
        ),
      );

      // Stub the buggy call (array index 1) so it doesn't throw
      when(() => controller.getParameterEnumStrings(0, 1))
          .thenAnswer((_) async => null);

      // Stub getParameterMapping for all hardware numbers
      when(() => controller.getParameterMapping(0, any(that: isA<int>())))
          .thenAnswer((_) async => null);

      // Stub getParameterValue for read-back
      when(() => controller.getParameterValue(0, any(that: isA<int>())))
          .thenAnswer((inv) async {
        final paramNum = inv.positionalArguments[1] as int;
        return ParameterValue(
            algorithmIndex: 0, parameterNumber: paramNum, value: 50);
      });

      await distingTools.newWithAlgorithms({
        'name': 'Test Preset',
        'algorithms': [
          {'guid': realGuid},
        ],
      });

      // Should call with hardware number 5, not array index 1
      verify(() => controller.getParameterEnumStrings(0, 5)).called(1);
      verifyNever(() => controller.getParameterEnumStrings(0, 1));
    });

    test(
        'read-back calls getParameterMapping with hardware numbers, not array indices',
        () async {
      // Stub getParameterMapping for hardware numbers
      when(() => controller.getParameterMapping(0, 0))
          .thenAnswer((_) async => testMappings[0]);
      when(() => controller.getParameterMapping(0, 5))
          .thenAnswer((_) async => testMappings[1]);
      when(() => controller.getParameterMapping(0, 10))
          .thenAnswer((_) async => testMappings[2]);

      // Stub buggy array-index calls
      when(() => controller.getParameterMapping(0, 1))
          .thenAnswer((_) async => null);
      when(() => controller.getParameterMapping(0, 2))
          .thenAnswer((_) async => null);

      // Stub getParameterEnumStrings for enum param
      when(() => controller.getParameterEnumStrings(0, 5))
          .thenAnswer((_) async => null);

      // Stub getParameterValue for read-back
      when(() => controller.getParameterValue(0, any(that: isA<int>())))
          .thenAnswer((inv) async {
        final paramNum = inv.positionalArguments[1] as int;
        return ParameterValue(
            algorithmIndex: 0, parameterNumber: paramNum, value: 50);
      });

      await distingTools.newWithAlgorithms({
        'name': 'Test Preset',
        'algorithms': [
          {'guid': realGuid},
        ],
      });

      // Should use hardware param numbers
      verify(() => controller.getParameterMapping(0, 0))
          .called(greaterThanOrEqualTo(1));
      verify(() => controller.getParameterMapping(0, 5))
          .called(greaterThanOrEqualTo(1));
      verify(() => controller.getParameterMapping(0, 10))
          .called(greaterThanOrEqualTo(1));

      // Array indices 1 and 2 should NEVER be used
      verifyNever(() => controller.getParameterMapping(0, 1));
      verifyNever(() => controller.getParameterMapping(0, 2));
    });
  });

  group('editPreset _validateDiff — hardware parameter number validation', () {
    const realGuid = 'attn';
    final realAlgorithm = Algorithm(
      algorithmIndex: 0,
      guid: realGuid,
      name: 'Attenuator',
    );

    setUp(() {
      when(() => controller.getAllSlots()).thenAnswer((_) async => {
            0: realAlgorithm,
          });
      when(() => controller.getAlgorithmInSlot(0))
          .thenAnswer((_) async => realAlgorithm);
      when(() => controller.getParametersForSlot(0))
          .thenAnswer((_) async => testParameters);
      when(() => controller.getCurrentPresetName())
          .thenAnswer((_) async => 'TestPreset');
    });

    test('accepts valid hardware parameter number for existing algorithm',
        () async {
      // Stub for the apply phase
      when(() => controller.updateParameterValue(0, 5, 75))
          .thenAnswer((_) async {});
      when(() => controller.getParameterValue(0, any(that: isA<int>())))
          .thenAnswer((inv) async {
        final paramNum = inv.positionalArguments[1] as int;
        return ParameterValue(
            algorithmIndex: 0, parameterNumber: paramNum, value: 75);
      });
      when(() => controller.getParameterMapping(0, any(that: isA<int>())))
          .thenAnswer((_) async => null);
      when(() => controller.getSlotName(0)).thenAnswer((_) async => null);

      final result = await distingTools.editPreset({
        'target': 'preset',
        'data': {
          'name': 'TestPreset',
          'slots': [
            {
              'algorithm': {'guid': realGuid},
              'parameters': [
                {'parameter_number': 5, 'value': 75},
              ],
            },
          ],
        },
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
    });

    test('rejects invalid hardware parameter number for existing algorithm',
        () async {
      final result = await distingTools.editPreset({
        'target': 'preset',
        'data': {
          'name': 'TestPreset',
          'slots': [
            {
              'algorithm': {'guid': realGuid},
              'parameters': [
                {'parameter_number': 3, 'value': 50},
              ],
            },
          ],
        },
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], contains('3'));
      expect(json['error'], contains('[0, 5, 10]'));
    });

    test('validates bounds using correct parameter for existing algorithm',
        () async {
      final result = await distingTools.editPreset({
        'target': 'preset',
        'data': {
          'name': 'TestPreset',
          'slots': [
            {
              'algorithm': {'guid': realGuid},
              'parameters': [
                {'parameter_number': 10, 'value': 5000},
              ],
            },
          ],
        },
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], contains('bounds'));
      expect(json['error'], contains('5000'));
    });
  });
}
