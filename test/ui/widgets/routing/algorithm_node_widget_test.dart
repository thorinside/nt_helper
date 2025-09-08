import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';

class MockDistingCubit extends Mock implements DistingCubit {
  @override
  Stream<DistingState> get stream => const Stream.empty();
}
class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  group('AlgorithmNodeWidget Mapping Tests', () {
    late MockDistingCubit mockCubit;
    late MockDistingMidiManager mockManager;

    setUp(() {
      mockCubit = MockDistingCubit();
      mockManager = MockDistingMidiManager();
    });

    testWidgets('should show mapping icon when slot has mapped parameters', (tester) async {
      // Create a mapped parameter data (not filler = mapped)
      final mappedData = PackedMappingData(
        source: 1,
        cvInput: 0,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 1,
        midiChannel: 1,
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
        i2cMax: 127,
        version: 1,
      );
      
      // Create a slot with a mapped parameter
      final mappedSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'test',
          name: 'Test Algorithm',
        ),
        routing: RoutingInfo(
          algorithmIndex: 0,
          routingInfo: const [],
        ),
        pages: ParameterPages(
          algorithmIndex: 0,
          pages: const [],
        ),
        parameters: [
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            min: 0,
            max: 100,
            defaultValue: 50,
            unit: 0,
            name: 'Test Param',
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(
            algorithmIndex: 0,
            parameterNumber: 0,
            value: 50,
          ),
        ],
        enums: [
          ParameterEnumStrings(
            algorithmIndex: 0,
            parameterNumber: 0,
            values: const [],
          ),
        ],
        mappings: [
          Mapping(
            algorithmIndex: 0,
            parameterNumber: 0,
            packedMappingData: mappedData,
          ),
        ],
        valueStrings: [
          ParameterValueString(
            algorithmIndex: 0,
            parameterNumber: 0,
            value: '50',
          ),
        ],
      );

      final state = DistingStateSynchronized(
        disting: mockManager,
        distingVersion: 'v1.0',
        firmwareVersion: FirmwareVersion('1.0.0'),
        presetName: 'Test Preset',
        algorithms: [],
        slots: [mappedSlot],
        unitStrings: const [],
      );

      when(() => mockCubit.state).thenReturn(state);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<DistingCubit>.value(
              value: mockCubit,
              child: AlgorithmNodeWidget(
                algorithmName: 'Test Algorithm',
                slotNumber: 1,
                position: const Offset(100, 100),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the mapping icon in the title bar
      final mappingIcon = find.descendant(
        of: find.byType(AlgorithmNodeWidget),
        matching: find.byIcon(Icons.map_sharp),
      );

      expect(mappingIcon, findsOneWidget);

      // Verify the icon is styled correctly
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: mappingIcon,
          matching: find.byType(IconButton),
        ),
      );
      expect(iconButton.style?.backgroundColor?.resolve({}), isNotNull);
    });

    testWidgets('should show mapped parameter menu items when slot has mappings', (tester) async {
      // Create multiple mapped parameters
      final mappedData1 = PackedMappingData(
        source: 1,
        cvInput: 0,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 1,
        midiChannel: 1,
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
        i2cMax: 127,
        version: 1,
      );

      final mappedData2 = PackedMappingData(
        source: 2,
        cvInput: 1,
        isUnipolar: false,
        isGate: false,
        volts: 10,
        delta: 2,
        midiChannel: 2,
        midiMappingType: MidiMappingType.cc,
        midiCC: 2,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 0,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 127,
        version: 1,
      );
      
      // Create a slot with mapped parameters
      final mappedSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'test',
          name: 'Test Algorithm',
        ),
        routing: RoutingInfo(
          algorithmIndex: 0,
          routingInfo: const [],
        ),
        pages: ParameterPages(
          algorithmIndex: 0,
          pages: const [],
        ),
        parameters: [
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            min: 0,
            max: 100,
            defaultValue: 50,
            unit: 0,
            name: 'Frequency',
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 1,
            min: 0,
            max: 100,
            defaultValue: 75,
            unit: 0,
            name: 'Resonance',
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(
            algorithmIndex: 0,
            parameterNumber: 0,
            value: 50,
          ),
          ParameterValue(
            algorithmIndex: 0,
            parameterNumber: 1,
            value: 75,
          ),
        ],
        enums: [
          ParameterEnumStrings(
            algorithmIndex: 0,
            parameterNumber: 0,
            values: const [],
          ),
          ParameterEnumStrings(
            algorithmIndex: 0,
            parameterNumber: 1,
            values: const [],
          ),
        ],
        mappings: [
          Mapping(
            algorithmIndex: 0,
            parameterNumber: 0,
            packedMappingData: mappedData1,
          ),
          Mapping(
            algorithmIndex: 0,
            parameterNumber: 1,
            packedMappingData: mappedData2,
          ),
        ],
        valueStrings: [
          ParameterValueString(
            algorithmIndex: 0,
            parameterNumber: 0,
            value: '50',
          ),
          ParameterValueString(
            algorithmIndex: 0,
            parameterNumber: 1,
            value: '75',
          ),
        ],
      );

      final state = DistingStateSynchronized(
        disting: mockManager,
        distingVersion: 'v1.0',
        firmwareVersion: FirmwareVersion('1.0.0'),
        presetName: 'Test Preset',
        algorithms: [],
        slots: [mappedSlot],
        unitStrings: const [],
      );

      when(() => mockCubit.state).thenReturn(state);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<DistingCubit>.value(
              value: mockCubit,
              child: AlgorithmNodeWidget(
                algorithmName: 'Test Algorithm',
                slotNumber: 1,
                position: const Offset(100, 100),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the popup menu button
      final popupMenuButton = find.byIcon(Icons.more_vert);
      await tester.tap(popupMenuButton);
      await tester.pumpAndSettle();

      // Verify mapped parameter items are present
      expect(find.text('Frequency'), findsOneWidget);
      expect(find.text('Resonance'), findsOneWidget);

      // Verify mapping icons are present for each mapped parameter
      final mappingIcons = find.byIcon(Icons.map_sharp);
      expect(mappingIcons, findsAtLeast(2)); // At least 2 in menu items (plus title bar icon)

      // Verify divider is present
      expect(find.byType(PopupMenuDivider), findsOneWidget);

      // Verify delete item is still present at the bottom
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}