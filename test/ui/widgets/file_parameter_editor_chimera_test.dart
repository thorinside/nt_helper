import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/ui/parameter_editor_registry.dart';
import 'package:nt_helper/ui/widgets/file_parameter_editor.dart';

class _MockDistingCubit extends Mock implements DistingCubit {}

class _MockDistingMidiManager extends Mock implements IDistingMidiManager {}

DirectoryEntry _dir(String name) =>
    DirectoryEntry(name: '$name/', attributes: 0x10, date: 0, time: 0, size: 0);

DirectoryEntry _file(String name, {int size = 128}) =>
    DirectoryEntry(name: name, attributes: 0x20, date: 0, time: 0, size: size);

void main() {
  late _MockDistingCubit cubit;
  late _MockDistingMidiManager manager;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ParameterEditorRegistry.setFirmwareVersion(FirmwareVersion('1.17.0'));
  });

  setUp(() {
    cubit = _MockDistingCubit();
    manager = _MockDistingMidiManager();
    when(() => cubit.state).thenReturn(DistingStateInitial());
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.disting()).thenReturn(manager);
    _stubChimeraSampleTree(manager);
  });

  testWidgets('Chimera folder picker uses recursive NT sample folder values', (
    tester,
  ) async {
    final writtenValues = <int>[];

    await _pumpEditor(
      tester,
      cubit: cubit,
      slot: _chimeraSlot(),
      parameterNumber: 0,
      onValueChanged: writtenValues.add,
    );

    expect(find.text('Breaks/Lion'), findsOneWidget);

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drums/Beef'));
    await tester.pumpAndSettle();

    expect(writtenValues.single, 4);
  });

  testWidgets(
    'Chimera Goat sample loads its corresponding folder and writes zero-based file values',
    (tester) async {
      final writtenValues = <int>[];

      await _pumpEditor(
        tester,
        cubit: cubit,
        slot: _chimeraSlot(),
        parameterNumber: 3,
        onValueChanged: writtenValues.add,
      );

      expect(find.text('goat-a'), findsOneWidget);
      expect(find.text('lion-a'), findsNothing);

      await tester.tap(find.text('Browse'));
      await tester.pumpAndSettle();

      expect(find.text('goat-a'), findsWidgets);
      expect(find.text('goat-b'), findsOneWidget);
      expect(find.text('lion-a'), findsNothing);

      await tester.tap(find.text('goat-b'));
      await tester.pumpAndSettle();

      expect(writtenValues.single, 1);
    },
  );

  testWidgets(
    'Chimera Beef sample maps None to zero and the first file to one',
    (tester) async {
      final writtenValues = <int>[];

      await _pumpEditor(
        tester,
        cubit: cubit,
        slot: _chimeraSlot(),
        parameterNumber: 5,
        onValueChanged: writtenValues.add,
      );

      expect(find.text('None'), findsOneWidget);
      expect(find.text('kick-a'), findsNothing);

      await tester.tap(find.text('Browse'));
      await tester.pumpAndSettle();

      expect(find.text('kick-a'), findsOneWidget);
      expect(find.text('kick-b'), findsOneWidget);

      await tester.tap(find.text('kick-a'));
      await tester.pumpAndSettle();

      expect(writtenValues.single, 1);
    },
  );
}

void _stubChimeraSampleTree(_MockDistingMidiManager manager) {
  final listings = <String, DirectoryListing>{
    '/samples': DirectoryListing(entries: [_dir('Drums'), _dir('Breaks')]),
    '/samples/Breaks': DirectoryListing(entries: [_dir('Lion'), _dir('Goat')]),
    '/samples/Breaks/Goat': DirectoryListing(
      entries: [_file('goat-b.wav'), _file('goat-a.wav')],
    ),
    '/samples/Breaks/Lion': DirectoryListing(
      entries: [_file('lion-b.wav'), _file('lion-a.wav')],
    ),
    '/samples/Drums': DirectoryListing(entries: [_dir('Beef')]),
    '/samples/Drums/Beef': DirectoryListing(
      entries: [_file('kick-b.wav'), _file('kick-a.wav')],
    ),
  };

  when(() => manager.requestDirectoryListing(any())).thenAnswer((invocation) {
    final path = invocation.positionalArguments.single as String;
    return Future.value(listings[path] ?? DirectoryListing(entries: const []));
  });
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required DistingCubit cubit,
  required Slot slot,
  required int parameterNumber,
  ValueChanged<int>? onValueChanged,
}) async {
  final editor = ParameterEditorRegistry.findEditorFor(
    slot: slot,
    parameterInfo: slot.parameters[parameterNumber],
    parameterNumber: parameterNumber,
    currentValue: slot.values[parameterNumber].value,
    onValueChanged: onValueChanged ?? (_) {},
  );
  expect(editor, isA<FileParameterEditor>());

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider<DistingCubit>.value(
          value: cubit,
          child: SizedBox(width: 520, child: editor),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Slot _chimeraSlot({
  int lionFolderValue = 2,
  int lionSampleValue = 0,
  int goatFolderValue = 1,
  int goatSampleValue = 0,
  int beefFolderValue = 4,
  int kickSampleValue = 0,
}) {
  final parameterValues = [
    lionFolderValue,
    lionSampleValue,
    goatFolderValue,
    goatSampleValue,
    beefFolderValue,
    kickSampleValue,
  ];

  return Slot(
    algorithm: Algorithm(algorithmIndex: 0, guid: 'Chim', name: 'Chimera'),
    routing: RoutingInfo(algorithmIndex: 0, routingInfo: List.filled(6, 0)),
    pages: ParameterPages(algorithmIndex: 0, pages: []),
    parameters: [
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        min: 0,
        max: 100,
        defaultValue: 0,
        unit: ParameterUnits.modernHasStrings,
        name: 'Lion folder',
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 1,
        min: 0,
        max: 1,
        defaultValue: 0,
        unit: ParameterUnits.modernConfirm,
        name: 'Lion sample',
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 2,
        min: 0,
        max: 100,
        defaultValue: 0,
        unit: ParameterUnits.modernHasStrings,
        name: 'Goat folder',
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 3,
        min: 0,
        max: 1,
        defaultValue: 0,
        unit: ParameterUnits.modernConfirm,
        name: 'Goat sample',
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 4,
        min: 0,
        max: 100,
        defaultValue: 0,
        unit: ParameterUnits.modernHasStrings,
        name: 'Beef folder',
        powerOfTen: 0,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 5,
        min: 0,
        max: 2,
        defaultValue: 0,
        unit: ParameterUnits.modernConfirm,
        name: 'Kick sample',
        powerOfTen: 0,
      ),
    ],
    values: List.generate(
      parameterValues.length,
      (index) => ParameterValue(
        algorithmIndex: 0,
        parameterNumber: index,
        value: parameterValues[index],
      ),
    ),
    enums: List.generate(
      parameterValues.length,
      (index) => ParameterEnumStrings(
        algorithmIndex: 0,
        parameterNumber: index,
        values: const [],
      ),
    ),
    mappings: List.generate(
      parameterValues.length,
      (index) => Mapping(
        algorithmIndex: 0,
        parameterNumber: index,
        packedMappingData: PackedMappingData.filler(),
      ),
    ),
    valueStrings: List.generate(
      parameterValues.length,
      (index) => ParameterValueString(
        algorithmIndex: 0,
        parameterNumber: index,
        value: '',
      ),
    ),
  );
}
