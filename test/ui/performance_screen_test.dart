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

  Slot createSlotFromMappedParameters(List<MappedParameter> params) {
    if (params.isEmpty) {
      return Slot(
        algorithm: Algorithm(algorithmIndex: 0, guid: 'empty', name: 'Empty'),
        routing: RoutingInfo.filler(),
        pages: ParameterPages(algorithmIndex: 0, pages: []),
        parameters: [],
        values: [],
        enums: [],
        mappings: [],
        valueStrings: [],
      );
    }

    final algorithmIndex = params.first.parameter.algorithmIndex;

    // Find the maximum parameter number to size our arrays
    final maxParamNum = params.map((p) => p.parameter.parameterNumber).reduce((a, b) => a > b ? a : b);
    final arraySize = maxParamNum + 1;

    // Create properly indexed arrays (filled with filler values)
    final parameters = List<ParameterInfo>.filled(
      arraySize,
      ParameterInfo.filler(),
    );
    final values = List<ParameterValue>.filled(
      arraySize,
      ParameterValue.filler(),
    );
    final enums = List<ParameterEnumStrings>.filled(
      arraySize,
      ParameterEnumStrings.filler(),
    );
    final mappings = List<Mapping>.filled(
      arraySize,
      Mapping.filler(),
    );
    final valueStrings = List<ParameterValueString>.filled(
      arraySize,
      ParameterValueString.filler(),
    );

    // Fill in the actual parameter data at the correct indices
    for (final param in params) {
      final paramNum = param.parameter.parameterNumber;
      parameters[paramNum] = param.parameter;
      values[paramNum] = param.value;
      enums[paramNum] = param.enums;
      mappings[paramNum] = param.mapping;
      valueStrings[paramNum] = param.valueString;
    }

    // Create parameter pages with parameters in order by parameter number
    final paramNums = params.map((p) => p.parameter.parameterNumber).toList()..sort();
    final parameterPages = ParameterPages(
      algorithmIndex: algorithmIndex,
      pages: [
        ParameterPage(
          name: 'Page 1',
          parameters: paramNums,
        ),
      ],
    );

    return Slot(
      algorithm: params.first.algorithm,
      routing: RoutingInfo.filler(),
      pages: parameterPages,
      parameters: parameters,
      values: values,
      enums: enums,
      mappings: mappings,
      valueStrings: valueStrings,
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

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      expect(find.text('No performance parameters assigned'), findsOneWidget);
      expect(find.text('Assign parameters in the property editor'), findsOneWidget);
      expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
    });

    testWidgets('displays navigation rail with page filtering', (tester) async {
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
          slots: [createSlotFromMappedParameters(params)],
          algorithms: const [],
          unitStrings: const [],
          presetName: 'Test',
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      // Wait for post-frame callback to set initial page selection
      await tester.pumpAndSettle();

      // Should show NavigationRail
      expect(find.byType(NavigationRail), findsOneWidget);

      // Should show two pages in navigation rail (as badges P1, P2)
      expect(find.text('P1'), findsOneWidget);
      expect(find.text('P2'), findsOneWidget);

      // Should show only Param 1 initially (first page selected)
      expect(find.text('Param 1'), findsOneWidget);
      expect(find.text('Param 2'), findsNothing);

      // Tap P2 badge
      await tester.tap(find.text('P2'));
      await tester.pumpAndSettle();

      // Should now show only Param 2
      expect(find.text('Param 1'), findsNothing);
      expect(find.text('Param 2'), findsOneWidget);
    });

    testWidgets('sorts parameters by parameter page order within same page', (tester) async {
      // Create parameters where alphabetical order would differ from parameter number order
      // Zebra (param 0) should come before Apple (param 1) because param 0 < param 1
      final algo0Params = [
        createMappedParameter(
          perfPageIndex: 1,
          algorithmName: 'Algo 1',
          algorithmIndex: 0,
          parameterName: 'Zebra',  // Alphabetically last
          parameterNumber: 0,      // But parameter page order first
        ),
        createMappedParameter(
          perfPageIndex: 1,
          algorithmName: 'Algo 1',
          algorithmIndex: 0,
          parameterName: 'Apple',  // Alphabetically first
          parameterNumber: 1,      // But parameter page order second
        ),
      ];

      when(() => mockCubit.state).thenReturn(
        DistingStateSynchronized(
          disting: MockDistingMidiManager(),
          distingVersion: 'v1.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          slots: [
            createSlotFromMappedParameters(algo0Params),
          ],
          algorithms: const [],
          unitStrings: const [],
          presetName: 'Test',
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      // Wait for post-frame callback
      await tester.pumpAndSettle();

      // Both parameters should be visible (same page)
      expect(find.text('Zebra'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);

      // Verify parameter page order (not alphabetical)
      // Zebra (param 0) should appear before Apple (param 1)
      final zebraY = tester.getTopLeft(find.text('Zebra')).dy;
      final appleY = tester.getTopLeft(find.text('Apple')).dy;

      expect(zebraY < appleY, true,
        reason: 'Zebra (param 0) should appear before Apple (param 1) due to parameter page order');
    });

    testWidgets('shows only parameters for selected page', (tester) async {
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
          slots: [createSlotFromMappedParameters(params)],
          algorithms: const [],
          unitStrings: const [],
          presetName: 'Test',
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      // Wait for post-frame callback
      await tester.pumpAndSettle();

      // Should show assigned parameter
      expect(find.text('Page 1 Param'), findsOneWidget);

      // NavigationRail should be present with single page (as badge P1)
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('P1'), findsOneWidget);
    });

    testWidgets('handles multiple parameters on same page', (tester) async {
      final algo0Params = [
        createMappedParameter(
          perfPageIndex: 1,
          algorithmName: 'Algo 1',
          algorithmIndex: 0,
          parameterName: 'Param 1',
          parameterNumber: 0,
        ),
      ];

      final algo1Params = [
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
          slots: [
            createSlotFromMappedParameters(algo0Params),
            createSlotFromMappedParameters(algo1Params),
          ],
          algorithms: const [],
          unitStrings: const [],
          presetName: 'Test',
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        createTestWidget(
          child: const PerformanceScreen(units: []),
        ),
      );

      // Wait for post-frame callback
      await tester.pumpAndSettle();

      // Should show both parameters (same page)
      expect(find.text('Param 1'), findsOneWidget);
      expect(find.text('Param 2'), findsOneWidget);

      // Should show both algorithm names
      expect(find.text('Algo 1'), findsOneWidget);
      expect(find.text('Algo 2'), findsOneWidget);

      // Should have NavigationRail with Page 1 only (as badge P1)
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('P1'), findsOneWidget);
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
