import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/parameter_editor_registry.dart';
import 'package:nt_helper/ui/widgets/file_parameter_editor.dart';

void main() {
  Slot createTestSlot({
    required String guid,
    required String parameterName,
    required int unit,
  }) {
    return Slot(
      algorithm: Algorithm(
        algorithmIndex: 0,
        guid: guid,
        name: 'Test Algorithm',
      ),
      routing: RoutingInfo(
        algorithmIndex: 0,
        routingInfo: List.filled(6, 0),
      ),
      pages: ParameterPages(algorithmIndex: 0, pages: []),
      parameters: [
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 0,
          min: 0,
          max: 100,
          defaultValue: 0,
          unit: unit,
          name: parameterName,
          powerOfTen: 0,
        ),
      ],
      values: [
        ParameterValue(
          algorithmIndex: 0,
          parameterNumber: 0,
          value: 0,
        ),
      ],
      enums: [ParameterEnumStrings.filler()],
      mappings: [
        Mapping(
          algorithmIndex: 0,
          parameterNumber: 0,
          packedMappingData: PackedMappingData.filler(),
        ),
      ],
      valueStrings: [ParameterValueString.filler()],
    );
  }

  group('ParameterEditorRegistry - Legacy firmware (≤1.12)', () {
    setUp(() {
      // Set to legacy firmware scheme
      ParameterEditorRegistry.setFirmwareVersion(FirmwareVersion('1.12.0'));
    });

    test('Lua Script Program parameter (unit 13) matches directFile rule', () {
      final slot = createTestSlot(
        guid: 'lua ', // Note: trailing space
        parameterName: 'Program',
        unit: ParameterUnits.legacyFilePath,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      expect(editor, isNotNull);
      expect(editor, isA<FileParameterEditor>());
      final fileEditor = editor as FileParameterEditor;
      expect(fileEditor.rule.mode, equals(FileSelectionMode.directFile));
      expect(
          fileEditor.rule.description.toLowerCase(), contains('lua script'));
    });

    test('Three Pot Program parameter (unit 13) matches directFile rule', () {
      final slot = createTestSlot(
        guid: 'spin',
        parameterName: 'Program',
        unit: ParameterUnits.legacyFilePath,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      expect(editor, isNotNull);
      expect(editor, isA<FileParameterEditor>());
      final fileEditor = editor as FileParameterEditor;
      expect(fileEditor.rule.mode, equals(FileSelectionMode.directFile));
      expect(fileEditor.rule.description.toLowerCase(), contains('three pot'));
    });

    test('Sample Player Folder parameter (unit 14) matches folderOnly rule',
        () {
      final slot = createTestSlot(
        guid: 'splr',
        parameterName: 'Folder',
        unit: ParameterUnits.legacyFileFolder,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      expect(editor, isNotNull);
      expect(editor, isA<FileParameterEditor>());
      final fileEditor = editor as FileParameterEditor;
      expect(fileEditor.rule.mode, equals(FileSelectionMode.folderOnly));
    });

    test('Sample Player Sample parameter (unit 14) matches fileOnly rule', () {
      final slot = createTestSlot(
        guid: 'splr',
        parameterName: 'Sample',
        unit: ParameterUnits.legacyFileFolder,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      expect(editor, isNotNull);
      expect(editor, isA<FileParameterEditor>());
      final fileEditor = editor as FileParameterEditor;
      expect(fileEditor.rule.mode, equals(FileSelectionMode.fileOnly));
    });

    test('Unit 17 parameter matches textInput rule', () {
      final slot = createTestSlot(
        guid: 'test',
        parameterName: 'Mix Name',
        unit: ParameterUnits.legacyTextInput,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      expect(editor, isNotNull);
      expect(editor, isA<FileParameterEditor>());
      final fileEditor = editor as FileParameterEditor;
      expect(fileEditor.rule.mode, equals(FileSelectionMode.textInput));
    });

    test('isStringTypeUnit returns true for legacy string units', () {
      expect(
          ParameterEditorRegistry.isStringTypeUnit(ParameterUnits.legacyFilePath),
          isTrue);
      expect(
          ParameterEditorRegistry.isStringTypeUnit(ParameterUnits.legacyFileFolder),
          isTrue);
      expect(
          ParameterEditorRegistry.isStringTypeUnit(ParameterUnits.legacyTextInput),
          isTrue);
      expect(ParameterEditorRegistry.isStringTypeUnit(0), isFalse);
      expect(ParameterEditorRegistry.isStringTypeUnit(1), isFalse);
    });
  });

  group('ParameterEditorRegistry - Modern firmware (≥1.13)', () {
    setUp(() {
      // Set to modern firmware scheme
      ParameterEditorRegistry.setFirmwareVersion(FirmwareVersion('1.13.0'));
    });

    test('Lua Script Program parameter (unit 17) matches directFile rule', () {
      final slot = createTestSlot(
        guid: 'lua ', // Note: trailing space
        parameterName: 'Program',
        unit: ParameterUnits.modernConfirm,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      expect(editor, isNotNull);
      expect(editor, isA<FileParameterEditor>());
      final fileEditor = editor as FileParameterEditor;
      expect(fileEditor.rule.mode, equals(FileSelectionMode.directFile));
      expect(
          fileEditor.rule.description.toLowerCase(), contains('lua script'));
    });

    test('Three Pot Program parameter (unit 17) matches directFile rule', () {
      final slot = createTestSlot(
        guid: 'spin',
        parameterName: 'Program',
        unit: ParameterUnits.modernConfirm,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      expect(editor, isNotNull);
      expect(editor, isA<FileParameterEditor>());
      final fileEditor = editor as FileParameterEditor;
      expect(fileEditor.rule.mode, equals(FileSelectionMode.directFile));
      expect(fileEditor.rule.description.toLowerCase(), contains('three pot'));
    });

    test('Sample Player Folder parameter (unit 16) matches folderOnly rule',
        () {
      final slot = createTestSlot(
        guid: 'splr',
        parameterName: 'Folder',
        unit: ParameterUnits.modernHasStrings,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      expect(editor, isNotNull);
      expect(editor, isA<FileParameterEditor>());
      final fileEditor = editor as FileParameterEditor;
      expect(fileEditor.rule.mode, equals(FileSelectionMode.folderOnly));
    });

    test('Sample Player Sample parameter (unit 16) matches fileOnly rule', () {
      final slot = createTestSlot(
        guid: 'splr',
        parameterName: 'Sample',
        unit: ParameterUnits.modernHasStrings,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      expect(editor, isNotNull);
      expect(editor, isA<FileParameterEditor>());
      final fileEditor = editor as FileParameterEditor;
      expect(fileEditor.rule.mode, equals(FileSelectionMode.fileOnly));
    });

    test('Unit 18 parameter matches textInput rule', () {
      final slot = createTestSlot(
        guid: 'test',
        parameterName: 'Mix Name',
        unit: ParameterUnits.modernTextInput,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      expect(editor, isNotNull);
      expect(editor, isA<FileParameterEditor>());
      final fileEditor = editor as FileParameterEditor;
      expect(fileEditor.rule.mode, equals(FileSelectionMode.textInput));
    });

    test('Unit 14 (BPM) does NOT match any file editor rule', () {
      final slot = createTestSlot(
        guid: 'clck',
        parameterName: 'Tempo',
        unit: ParameterUnits.modernBPM,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      // BPM should NOT have a file editor
      expect(editor, isNull);
    });

    test('isStringTypeUnit returns true for modern string units', () {
      expect(
          ParameterEditorRegistry.isStringTypeUnit(ParameterUnits.modernHasStrings),
          isTrue);
      expect(
          ParameterEditorRegistry.isStringTypeUnit(ParameterUnits.modernConfirm),
          isTrue);
      expect(
          ParameterEditorRegistry.isStringTypeUnit(ParameterUnits.modernTextInput),
          isTrue);
      // BPM is NOT a string type
      expect(ParameterEditorRegistry.isStringTypeUnit(ParameterUnits.modernBPM),
          isFalse);
      expect(ParameterEditorRegistry.isStringTypeUnit(0), isFalse);
      expect(ParameterEditorRegistry.isStringTypeUnit(1), isFalse);
    });
  });

  group('ParameterEditorRegistry - Common tests', () {
    test('Regular parameter (unit 0) returns null', () {
      final slot = createTestSlot(
        guid: 'test',
        parameterName: 'Level',
        unit: 0,
      );

      final editor = ParameterEditorRegistry.findEditorFor(
        slot: slot,
        parameterInfo: slot.parameters[0],
        parameterNumber: 0,
        currentValue: 0,
        onValueChanged: (_) {},
      );

      expect(editor, isNull);
    });

    test('schemeFor correctly detects legacy firmware', () {
      expect(ParameterUnits.schemeFor(FirmwareVersion('1.12.0')),
          equals(ParameterUnitScheme.legacy));
      expect(ParameterUnits.schemeFor(FirmwareVersion('1.11.5')),
          equals(ParameterUnitScheme.legacy));
      expect(ParameterUnits.schemeFor(FirmwareVersion('1.0.0')),
          equals(ParameterUnitScheme.legacy));
    });

    test('schemeFor correctly detects modern firmware', () {
      expect(ParameterUnits.schemeFor(FirmwareVersion('1.13.0')),
          equals(ParameterUnitScheme.modern));
      expect(ParameterUnits.schemeFor(FirmwareVersion('1.13.1')),
          equals(ParameterUnitScheme.modern));
      expect(ParameterUnits.schemeFor(FirmwareVersion('1.14.0')),
          equals(ParameterUnitScheme.modern));
      expect(ParameterUnits.schemeFor(FirmwareVersion('2.0.0')),
          equals(ParameterUnitScheme.modern));
    });

    test('schemeFor returns modern for null version', () {
      expect(ParameterUnits.schemeFor(null), equals(ParameterUnitScheme.modern));
    });
  });
}
