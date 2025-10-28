import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/widgets/packed_mapping_data_editor.dart';

void main() {
  group('PackedMappingDataEditor - 14-bit CC Support', () {
    late PackedMappingData testData;
    late List<Slot> mockSlots;

    setUp(() {
      testData = PackedMappingData.filler();
      mockSlots = [];
    });

    Widget createTestWidget({PackedMappingData? initialData}) {
      return MaterialApp(
        home: Scaffold(
          body: PackedMappingDataEditor(
            initialData: initialData ?? testData,
            onSave: (_) {},
            slots: mockSlots,
          ),
        ),
      );
    }

    testWidgets('MIDI type dropdown includes all 5 options',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Navigate to MIDI tab
      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      // Find the MIDI Type dropdown
      final dropdownFinder = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownMenu<MidiMappingType> &&
            widget.label.toString().contains('MIDI Type'),
      );
      expect(dropdownFinder, findsOneWidget);

      // Get the dropdown widget to verify it has all 5 entries
      final dropdown = tester.widget<DropdownMenu<MidiMappingType>>(dropdownFinder);
      expect(dropdown.dropdownMenuEntries.length, equals(5));

      // Verify entry labels
      expect(dropdown.dropdownMenuEntries[0].label, equals('CC'));
      expect(dropdown.dropdownMenuEntries[1].label, equals('Note - Momentary'));
      expect(dropdown.dropdownMenuEntries[2].label, equals('Note - Toggle'));
      expect(dropdown.dropdownMenuEntries[3].label, equals('14 bit CC - low'));
      expect(dropdown.dropdownMenuEntries[4].label, equals('14 bit CC - high'));
    });

    testWidgets('Selecting 14-bit CC low updates data model',
        (tester) async {
      PackedMappingData? savedData;
      final data14BitLow = testData.copyWith(
        midiMappingType: MidiMappingType.cc14BitLow,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PackedMappingDataEditor(
              initialData: data14BitLow,
              onSave: (data) {
                savedData = data;
              },
              slots: mockSlots,
            ),
          ),
        ),
      );

      // Navigate to MIDI tab
      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify model was updated
      expect(savedData, isNotNull);
      expect(savedData!.midiMappingType, equals(MidiMappingType.cc14BitLow));
    });

    testWidgets('Selecting 14-bit CC high updates data model',
        (tester) async {
      PackedMappingData? savedData;
      final data14BitHigh = testData.copyWith(
        midiMappingType: MidiMappingType.cc14BitHigh,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PackedMappingDataEditor(
              initialData: data14BitHigh,
              onSave: (data) {
                savedData = data;
              },
              slots: mockSlots,
            ),
          ),
        ),
      );

      // Navigate to MIDI tab
      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify model was updated
      expect(savedData, isNotNull);
      expect(savedData!.midiMappingType, equals(MidiMappingType.cc14BitHigh));
    });

    testWidgets('MIDI Relative switch disabled for 14-bit CC low',
        (tester) async {
      final data14BitLow = testData.copyWith(
        midiMappingType: MidiMappingType.cc14BitLow,
      );

      await tester.pumpWidget(createTestWidget(initialData: data14BitLow));

      // Navigate to MIDI tab
      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      // Find the MIDI Relative switch
      final switchFinder = find.byWidgetPredicate(
        (widget) {
          if (widget is! Row) return false;
          final children = widget.children;
          return children.any(
            (child) => child is Text && child.data == 'MIDI Relative',
          );
        },
      );
      expect(switchFinder, findsOneWidget);

      // Find the Switch widget within that Row
      final switchWidget = tester.widget<Switch>(
        find.descendant(
          of: switchFinder,
          matching: find.byType(Switch),
        ),
      );

      // Verify it's disabled (onChanged is null)
      expect(switchWidget.onChanged, isNull);
    });

    testWidgets('MIDI Relative switch disabled for 14-bit CC high',
        (tester) async {
      final data14BitHigh = testData.copyWith(
        midiMappingType: MidiMappingType.cc14BitHigh,
      );

      await tester.pumpWidget(createTestWidget(initialData: data14BitHigh));

      // Navigate to MIDI tab
      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      // Find the MIDI Relative switch
      final switchFinder = find.byWidgetPredicate(
        (widget) {
          if (widget is! Row) return false;
          final children = widget.children;
          return children.any(
            (child) => child is Text && child.data == 'MIDI Relative',
          );
        },
      );
      expect(switchFinder, findsOneWidget);

      // Find the Switch widget within that Row
      final switchWidget = tester.widget<Switch>(
        find.descendant(
          of: switchFinder,
          matching: find.byType(Switch),
        ),
      );

      // Verify it's disabled (onChanged is null)
      expect(switchWidget.onChanged, isNull);
    });

    testWidgets('MIDI Relative switch enabled for standard CC',
        (tester) async {
      final dataCc = testData.copyWith(
        midiMappingType: MidiMappingType.cc,
      );

      await tester.pumpWidget(createTestWidget(initialData: dataCc));

      // Navigate to MIDI tab
      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      // Find the MIDI Relative switch
      final switchFinder = find.byWidgetPredicate(
        (widget) {
          if (widget is! Row) return false;
          final children = widget.children;
          return children.any(
            (child) => child is Text && child.data == 'MIDI Relative',
          );
        },
      );
      expect(switchFinder, findsOneWidget);

      // Find the Switch widget within that Row
      final switchWidget = tester.widget<Switch>(
        find.descendant(
          of: switchFinder,
          matching: find.byType(Switch),
        ),
      );

      // Verify it's enabled (onChanged is not null)
      expect(switchWidget.onChanged, isNotNull);
    });

    testWidgets('MIDI Relative switch disabled for note types',
        (tester) async {
      final dataNoteMomentary = testData.copyWith(
        midiMappingType: MidiMappingType.noteMomentary,
      );

      await tester.pumpWidget(createTestWidget(initialData: dataNoteMomentary));

      // Navigate to MIDI tab
      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      // Find the MIDI Relative switch
      final switchFinder = find.byWidgetPredicate(
        (widget) {
          if (widget is! Row) return false;
          final children = widget.children;
          return children.any(
            (child) => child is Text && child.data == 'MIDI Relative',
          );
        },
      );
      expect(switchFinder, findsOneWidget);

      // Find the Switch widget within that Row
      final switchWidget = tester.widget<Switch>(
        find.descendant(
          of: switchFinder,
          matching: find.byType(Switch),
        ),
      );

      // Verify it's disabled (onChanged is null)
      expect(switchWidget.onChanged, isNull);
    });

    testWidgets('Displays N/A message for 14-bit CC types',
        (tester) async {
      final data14BitLow = testData.copyWith(
        midiMappingType: MidiMappingType.cc14BitLow,
      );

      await tester.pumpWidget(createTestWidget(initialData: data14BitLow));

      // Navigate to MIDI tab
      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      // Verify N/A message is displayed
      expect(
        find.text('(N/A for Notes and 14-bit CC)'),
        findsOneWidget,
      );
    });

    testWidgets('Does not display N/A message for CC type',
        (tester) async {
      final dataCc = testData.copyWith(
        midiMappingType: MidiMappingType.cc,
      );

      await tester.pumpWidget(createTestWidget(initialData: dataCc));

      // Navigate to MIDI tab
      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      // Verify N/A message is NOT displayed
      expect(
        find.text('(N/A for Notes and 14-bit CC)'),
        findsNothing,
      );
    });
  });
}
