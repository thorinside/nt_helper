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
      when(() => mockCubit.buildMappedParameterList(any())).thenReturn([]);

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      expect(find.text('No performance parameters assigned'), findsOneWidget);
      expect(find.text('Assign parameters in the property editor'), findsOneWidget);
      expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
    });

    testWidgets('displays all parameters without navigation rail', (tester) async {
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
      when(() => mockCubit.buildMappedParameterList(any())).thenReturn(params);

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      // Should NOT show NavigationRail
      expect(find.byType(NavigationRail), findsNothing);

      // Should show both parameters
      expect(find.text('Param 1'), findsOneWidget);
      expect(find.text('Param 2'), findsOneWidget);
    });

    testWidgets('sorts parameters by page then alphabetically', (tester) async {
      // Create parameters in intentionally unsorted order
      final params = [
        createMappedParameter(
          perfPageIndex: 2,
          algorithmName: 'Algo 2',
          algorithmIndex: 1,
          parameterName: 'Zebra',
          parameterNumber: 2,
        ),
        createMappedParameter(
          perfPageIndex: 1,
          algorithmName: 'Algo 1',
          algorithmIndex: 0,
          parameterName: 'Beta',
          parameterNumber: 1,
        ),
        createMappedParameter(
          perfPageIndex: 1,
          algorithmName: 'Algo 1',
          algorithmIndex: 0,
          parameterName: 'Alpha',
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
      when(() => mockCubit.buildMappedParameterList(any())).thenReturn(params);

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      // All parameters should be visible
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Zebra'), findsOneWidget);

      // Verify sort order: Page 1 (Alpha, Beta), then Page 2 (Zebra)
      // We can verify this by checking the vertical positions of the text widgets
      final alphaY = tester.getTopLeft(find.text('Alpha')).dy;
      final betaY = tester.getTopLeft(find.text('Beta')).dy;
      final zebraY = tester.getTopLeft(find.text('Zebra')).dy;

      expect(alphaY < betaY, true, reason: 'Alpha should appear before Beta');
      expect(betaY < zebraY, true, reason: 'Beta should appear before Zebra');
    });

    testWidgets('shows only parameters returned by buildMappedParameterList', (tester) async {
      // buildMappedParameterList already filters out perfPageIndex = 0,
      // so we only include parameters with perfPageIndex > 0
      final params = [
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
      when(() => mockCubit.buildMappedParameterList(any())).thenReturn(params);

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      // Should show assigned parameter
      expect(find.text('Page 1 Param'), findsOneWidget);

      // No NavigationRail should be present
      expect(find.byType(NavigationRail), findsNothing);
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
      when(() => mockCubit.buildMappedParameterList(any())).thenReturn(params);

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
      when(() => mockCubit.buildMappedParameterList(any())).thenReturn([]);
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
