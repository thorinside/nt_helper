import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';

class MockDistingCubit extends Mock implements DistingCubit {}

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  group('RoutingEditorCubit conditional in-place assignment', () {
    late MockDistingCubit distingCubit;
    late RoutingEditorCubit routingCubit;

    setUp(() {
      distingCubit = MockDistingCubit();
      when(() => distingCubit.stream).thenAnswer((_) => const Stream.empty());
      when(
        () => distingCubit.updateParameterValue(
          algorithmIndex: any(named: 'algorithmIndex'),
          parameterNumber: any(named: 'parameterNumber'),
          value: any(named: 'value'),
          userIsChangingTheValue: any(named: 'userIsChangingTheValue'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await routingCubit.close();
    });

    void seedSlot(Slot slot) {
      when(() => distingCubit.state).thenReturn(
        DistingState.synchronized(
          disting: MockDistingMidiManager(),
          distingVersion: '1.0.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          presetName: 'Test Preset',
          algorithms: const [],
          slots: [slot],
          unitStrings: const [],
        ),
      );
      routingCubit = RoutingEditorCubit(distingCubit);
    }

    test('writes None when target bus equals matching input bus', () async {
      seedSlot(_inputOutputSlot(guid: 'attn', inputBus: 5, outputBus: 7));

      final result = await routingCubit.assignBusAndSolve(
        algorithmIndex: 0,
        parameterNumber: 1,
        previousBusValue: 7,
        busValue: 5,
      );

      verify(
        () => distingCubit.updateParameterValue(
          algorithmIndex: 0,
          parameterNumber: 1,
          value: 0,
          userIsChangingTheValue: true,
        ),
      ).called(1);
      expect(result.previousBusValue, equals(7));
      expect(result.newBusValue, equals(0));
    });

    test('writes selected bus when target differs from input bus', () async {
      seedSlot(_inputOutputSlot(guid: 'attn', inputBus: 5, outputBus: 0));

      final result = await routingCubit.assignBusAndSolve(
        algorithmIndex: 0,
        parameterNumber: 1,
        previousBusValue: 5,
        busValue: 13,
      );

      verify(
        () => distingCubit.updateParameterValue(
          algorithmIndex: 0,
          parameterNumber: 1,
          value: 13,
          userIsChangingTheValue: true,
        ),
      ).called(1);
      expect(result.previousBusValue, equals(0));
      expect(result.newBusValue, equals(13));
    });

    test('normalizes literal same-as-input previous value for undo', () async {
      seedSlot(_inputOutputSlot(guid: 'attn', inputBus: 5, outputBus: 5));

      final result = await routingCubit.assignBusAndSolve(
        algorithmIndex: 0,
        parameterNumber: 1,
        previousBusValue: 5,
        busValue: 13,
      );

      expect(result.previousBusValue, equals(0));
      expect(result.newBusValue, equals(13));
    });

    test('does not normalize non-conditional algorithms', () async {
      seedSlot(_inputOutputSlot(guid: 'unkn', inputBus: 5, outputBus: 5));

      final result = await routingCubit.assignBusAndSolve(
        algorithmIndex: 0,
        parameterNumber: 1,
        previousBusValue: 5,
        busValue: 5,
      );

      verify(
        () => distingCubit.updateParameterValue(
          algorithmIndex: 0,
          parameterNumber: 1,
          value: 5,
          userIsChangingTheValue: true,
        ),
      ).called(1);
      expect(result.previousBusValue, equals(5));
      expect(result.newBusValue, equals(5));
    });
  });
}

Slot _inputOutputSlot({
  required String guid,
  required int inputBus,
  required int outputBus,
}) {
  final parameters = [
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 0,
      min: 0,
      max: 28,
      defaultValue: inputBus,
      unit: 1,
      name: 'Input',
      powerOfTen: 0,
      ioFlags: 1,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 1,
      min: 0,
      max: 28,
      defaultValue: outputBus,
      unit: 1,
      name: 'Output',
      powerOfTen: 0,
      ioFlags: 2,
    ),
  ];

  return Slot(
    algorithm: Algorithm(algorithmIndex: 0, guid: guid, name: guid),
    routing: RoutingInfo(algorithmIndex: 0, routingInfo: List.filled(6, 0)),
    pages: ParameterPages(algorithmIndex: 0, pages: []),
    parameters: parameters,
    values: [
      for (final parameter in parameters)
        ParameterValue(
          algorithmIndex: 0,
          parameterNumber: parameter.parameterNumber,
          value: parameter.defaultValue,
        ),
    ],
    enums: const [],
    mappings: const [],
    valueStrings: const [],
  );
}
