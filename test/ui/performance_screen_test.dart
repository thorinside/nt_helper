import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/ui/performance_screen.dart';

class MockDistingCubit extends Mock implements DistingCubit {}

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  late MockDistingCubit mockCubit;

  setUp(() {
    mockCubit = MockDistingCubit();
  });

  Widget createTestWidget({required Widget child}) {
    return MaterialApp(
      home: BlocProvider<DistingCubit>.value(
        value: mockCubit,
        child: child,
      ),
    );
  }

  MappedParameter createMappedParameter({
    required int perfPageIndex,
    required String algorithmName,
    required int algorithmIndex,
    required String parameterName,
    required int parameterNumber,
  }) {
    return MappedParameter(
      parameter: ParameterInfo(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        name: parameterName,
        unit: 0,
        min: 0,
        max: 100,
        defaultValue: 50,
        powerOfTen: 0,
      ),
      value: ParameterValue(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        value: 50,
      ),
      enums: ParameterEnumStrings(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        values: const [],
      ),
      valueString: ParameterValueString(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        value: '50',
      ),
      mapping: Mapping(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        packedMappingData: PackedMappingData(
          source: 0,
          cvInput: 0,
          isUnipolar: false,
          isGate: false,
          volts: 0,
          delta: 0,
          midiChannel: 0,
          midiMappingType: MidiMappingType.cc,
          midiCC: 1,
          isMidiEnabled: true,
          isMidiSymmetric: false,
          isMidiRelative: false,
          midiMin: 0,
          midiMax: 127,
          i2cCC: 0,
          isI2cEnabled: false,
          isI2cSymmetric: false,
          i2cMin: 0,
          i2cMax: 0,
          perfPageIndex: perfPageIndex,
          version: 5,
        ),
      ),
      algorithm: Algorithm(
        algorithmIndex: algorithmIndex,
        guid: 'test-guid-$algorithmIndex',
        name: algorithmName,
      ),
    );
  }

  group('PerformanceScreen', () {
    testWidgets('displays empty state when no parameters assigned', (tester) async {
      when(() => mockCubit.state).thenReturn(
        DistingStateSynchronized(
          disting: MockDistingMidiManager(),
          distingVersion: 'v1.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          slots: [],
          algorithms: const [],
          unitStrings: const [],
          presetName: 'Test',
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.buildMappedParameterList()).thenReturn([]);

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      expect(find.text('No performance parameters assigned'), findsOneWidget);
      expect(find.text('Assign parameters to performance pages in the property editor'), findsOneWidget);
      expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
    });

    testWidgets('displays navigation rail when pages have parameters', (tester) async {
      final params = [
        createMappedParameter(
          perfPageIndex: 1,
          algorithmName: 'Test Algo',
          algorithmIndex: 0,
          parameterName: 'Param 1',
          parameterNumber: 0,
        ),
        createMappedParameter(
          perfPageIndex: 2,
          algorithmName: 'Test Algo',
          algorithmIndex: 0,
          parameterName: 'Param 2',
          parameterNumber: 1,
        ),
      ];

      when(() => mockCubit.state).thenReturn(
        DistingStateSynchronized(
          disting: MockDistingMidiManager(),
          distingVersion: 'v1.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          slots: [],
          algorithms: const [],
          unitStrings: const [],
          presetName: 'Test',
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.buildMappedParameterList()).thenReturn(params);

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
    });

    testWidgets('filters parameters by selected page', (tester) async {
      final params = [
        createMappedParameter(
          perfPageIndex: 1,
          algorithmName: 'Algo 1',
          algorithmIndex: 0,
          parameterName: 'Page 1 Param',
          parameterNumber: 0,
        ),
        createMappedParameter(
          perfPageIndex: 2,
          algorithmName: 'Algo 2',
          algorithmIndex: 1,
          parameterName: 'Page 2 Param',
          parameterNumber: 0,
        ),
      ];

      when(() => mockCubit.state).thenReturn(
        DistingStateSynchronized(
          disting: MockDistingMidiManager(),
          distingVersion: 'v1.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          slots: [],
          algorithms: const [],
          unitStrings: const [],
          presetName: 'Test',
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.buildMappedParameterList()).thenReturn(params);

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      // Should show Page 1 parameters by default (first page)
      expect(find.text('Page 1 Param'), findsOneWidget);
      expect(find.text('Page 2 Param'), findsNothing);

      // Switch to Page 2
      await tester.tap(find.text('Page 2'));
      await tester.pumpAndSettle();

      // Should now show Page 2 parameters
      expect(find.text('Page 1 Param'), findsNothing);
      expect(find.text('Page 2 Param'), findsOneWidget);
    });

    testWidgets('ignores parameters with perfPageIndex = 0', (tester) async {
      final params = [
        createMappedParameter(
          perfPageIndex: 0, // Not assigned to any page
          algorithmName: 'Test Algo',
          algorithmIndex: 0,
          parameterName: 'Unassigned Param',
          parameterNumber: 0,
        ),
        createMappedParameter(
          perfPageIndex: 1,
          algorithmName: 'Test Algo',
          algorithmIndex: 0,
          parameterName: 'Page 1 Param',
          parameterNumber: 1,
        ),
      ];

      when(() => mockCubit.state).thenReturn(
        DistingStateSynchronized(
          disting: MockDistingMidiManager(),
          distingVersion: 'v1.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          slots: [],
          algorithms: const [],
          unitStrings: const [],
          presetName: 'Test',
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.buildMappedParameterList()).thenReturn(params);

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      // Should only show Page 1 in navigation rail
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 0'), findsNothing);

      // Should only show assigned parameter
      expect(find.text('Page 1 Param'), findsOneWidget);
      expect(find.text('Unassigned Param'), findsNothing);
    });

    testWidgets('handles multiple parameters on same page', (tester) async {
      final params = [
        createMappedParameter(
          perfPageIndex: 1,
          algorithmName: 'Algo 1',
          algorithmIndex: 0,
          parameterName: 'Param 1',
          parameterNumber: 0,
        ),
        createMappedParameter(
          perfPageIndex: 1,
          algorithmName: 'Algo 2',
          algorithmIndex: 1,
          parameterName: 'Param 2',
          parameterNumber: 0,
        ),
      ];

      when(() => mockCubit.state).thenReturn(
        DistingStateSynchronized(
          disting: MockDistingMidiManager(),
          distingVersion: 'v1.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          slots: [],
          algorithms: const [],
          unitStrings: const [],
          presetName: 'Test',
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.buildMappedParameterList()).thenReturn(params);

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      // Should show both parameters
      expect(find.text('Param 1'), findsOneWidget);
      expect(find.text('Param 2'), findsOneWidget);

      // Should show both algorithm names
      expect(find.text('Algo 1'), findsOneWidget);
      expect(find.text('Algo 2'), findsOneWidget);
    });

    testWidgets('displays polling controls', (tester) async {
      when(() => mockCubit.state).thenReturn(
        DistingStateSynchronized(
          disting: MockDistingMidiManager(),
          distingVersion: 'v1.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          slots: [],
          algorithms: const [],
          unitStrings: const [],
          presetName: 'Test',
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.buildMappedParameterList()).thenReturn([]);
      when(() => mockCubit.startPollingMappedParameters()).thenReturn(null);
      when(() => mockCubit.stopPollingMappedParameters()).thenReturn(null);

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      // Should find polling control button
      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);

      // Tap to start polling
      await tester.tap(find.byIcon(Icons.play_circle_fill));
      await tester.pumpAndSettle();

      // Should change to pause icon
      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);

      verify(() => mockCubit.startPollingMappedParameters()).called(1);
    });
  });
}
