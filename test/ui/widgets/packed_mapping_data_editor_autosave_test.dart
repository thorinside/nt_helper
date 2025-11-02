import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/widgets/packed_mapping_data_editor.dart';

void main() {
  group('PackedMappingDataEditor - TextField Autosave', () {
    late PackedMappingData testData;
    late List<Slot> mockSlots;

    setUp(() {
      testData = PackedMappingData.filler();
      mockSlots = [];
    });

    Widget createTestWidget({
      required Future<void> Function(PackedMappingData) onSave,
      PackedMappingData? initialData,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PackedMappingDataEditor(
            initialData: initialData ?? testData,
            onSave: onSave,
            slots: mockSlots,
            algorithmIndex: 0,
            parameterNumber: 0,
          ),
        ),
      );
    }

    testWidgets('Volts field triggers save after 1-second debounce', (
      tester,
    ) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Volts',
      );

      await tester.enterText(textFieldFinder, '42');
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.volts, equals(42));
    });

    testWidgets('Delta field triggers save after debounce', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Delta',
      );

      await tester.enterText(textFieldFinder, '10');
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.delta, equals(10));
    });

    testWidgets('MIDI CC field triggers save after debounce', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'MIDI CC / Note (0–128)',
      );

      await tester.enterText(textFieldFinder, '64');
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.midiCC, equals(64));
    });

    testWidgets('MIDI Min field triggers save after debounce with negative value',
        (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'MIDI Min',
      );

      await tester.enterText(textFieldFinder, '-700');
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.midiMin, equals(-700));
    });

    testWidgets('MIDI Max field triggers save after debounce with negative value',
        (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'MIDI Max',
      );

      await tester.enterText(textFieldFinder, '-200');
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.midiMax, equals(-200));
    });

    testWidgets('I2C CC field triggers save after debounce', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('I2C'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'I2C CC',
      );

      await tester.enterText(textFieldFinder, '32');
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.i2cCC, equals(32));
    });

    testWidgets('I2C Min field triggers save after debounce with negative value',
        (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('I2C'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'I2C Min',
      );

      await tester.enterText(textFieldFinder, '-1000');
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.i2cMin, equals(-1000));
    });

    testWidgets('I2C Max field triggers save after debounce with negative value',
        (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('I2C'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'I2C Max',
      );

      await tester.enterText(textFieldFinder, '-500');
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.i2cMax, equals(-500));
    });

    testWidgets('Rapid edits collapse to single save after final debounce', (
      tester,
    ) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Volts',
      );

      // Rapid edits
      await tester.enterText(textFieldFinder, '10');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(textFieldFinder, '20');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(textFieldFinder, '30');
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.volts, equals(30));
    });
  });

  group('PackedMappingDataEditor - Dropdown and Switch Autosave', () {
    late PackedMappingData testData;
    late List<Slot> mockSlots;

    setUp(() {
      testData = PackedMappingData.filler();
      mockSlots = [];
    });

    Widget createTestWidget({
      required Future<void> Function(PackedMappingData) onSave,
      PackedMappingData? initialData,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PackedMappingDataEditor(
            initialData: initialData ?? testData,
            onSave: onSave,
            slots: mockSlots,
            algorithmIndex: 0,
            parameterNumber: 0,
          ),
        ),
      );
    }

    testWidgets('Source dropdown triggers immediate save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final dropdownFinder = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownMenu<int> &&
            widget.label.toString().contains('Source'),
      );
      final dropdown = tester.widget<DropdownMenu<int>>(dropdownFinder);

      dropdown.onSelected?.call(2);
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.source, equals(2));
    });

    testWidgets('CV Input dropdown triggers immediate save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final dropdownFinder = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownMenu<int> &&
            widget.label.toString().contains('CV Input'),
      );
      final dropdown = tester.widget<DropdownMenu<int>>(dropdownFinder);

      dropdown.onSelected?.call(3);
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.cvInput, equals(3));
    });

    testWidgets('MIDI Channel dropdown triggers immediate save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final dropdownFinder = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownMenu<int> &&
            widget.label.toString().contains('MIDI Channel'),
      );
      final dropdown = tester.widget<DropdownMenu<int>>(dropdownFinder);

      dropdown.onSelected?.call(5);
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.midiChannel, equals(5));
    });

    testWidgets('MIDI Type dropdown triggers immediate save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final dropdownFinder = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownMenu<MidiMappingType> &&
            widget.label.toString().contains('MIDI Type'),
      );
      final dropdown =
          tester.widget<DropdownMenu<MidiMappingType>>(dropdownFinder);

      dropdown.onSelected?.call(MidiMappingType.noteMomentary);
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.midiMappingType, equals(MidiMappingType.noteMomentary));
    });

    testWidgets('Unipolar switch triggers immediate save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final switchFinder = find.byWidgetPredicate((widget) {
        if (widget is! Row) return false;
        final children = widget.children;
        return children.any(
          (child) => child is Text && child.data == 'Unipolar',
        );
      });

      await tester.tap(
        find.descendant(of: switchFinder, matching: find.byType(Switch)),
      );
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.isUnipolar, equals(true));
    });

    testWidgets('Gate switch triggers immediate save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final switchFinder = find.byWidgetPredicate((widget) {
        if (widget is! Row) return false;
        final children = widget.children;
        return children.any((child) => child is Text && child.data == 'Gate');
      });

      await tester.tap(
        find.descendant(of: switchFinder, matching: find.byType(Switch)),
      );
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.isGate, equals(true));
    });

    testWidgets('MIDI Enabled switch triggers immediate save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final switchFinder = find.byWidgetPredicate((widget) {
        if (widget is! Row) return false;
        final children = widget.children;
        return children.any(
          (child) => child is Text && child.data == 'MIDI Enabled',
        );
      });

      await tester.tap(
        find.descendant(of: switchFinder, matching: find.byType(Switch)),
      );
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.isMidiEnabled, equals(true));
    });

    testWidgets('MIDI Symmetric switch triggers immediate save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final switchFinder = find.byWidgetPredicate((widget) {
        if (widget is! Row) return false;
        final children = widget.children;
        return children.any(
          (child) => child is Text && child.data == 'MIDI Symmetric',
        );
      });

      await tester.tap(
        find.descendant(of: switchFinder, matching: find.byType(Switch)),
      );
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.isMidiSymmetric, equals(true));
    });

    testWidgets('MIDI Relative switch triggers immediate save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      final testDataCC = PackedMappingData.filler()
          .copyWith(midiMappingType: MidiMappingType.cc);

      await tester.pumpWidget(
        createTestWidget(
          initialData: testDataCC,
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final switchFinder = find.byWidgetPredicate((widget) {
        if (widget is! Row) return false;
        final children = widget.children;
        return children.any(
          (child) => child is Text && child.data == 'MIDI Relative',
        );
      });

      await tester.tap(
        find.descendant(of: switchFinder, matching: find.byType(Switch)),
      );
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.isMidiRelative, equals(true));
    });

    testWidgets('I2C Enabled switch triggers immediate save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('I2C'));
      await tester.pumpAndSettle();

      final switchFinder = find.byWidgetPredicate((widget) {
        if (widget is! Row) return false;
        final children = widget.children;
        return children.any(
          (child) => child is Text && child.data == 'I2C Enabled',
        );
      });

      await tester.tap(
        find.descendant(of: switchFinder, matching: find.byType(Switch)),
      );
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.isI2cEnabled, equals(true));
    });

    testWidgets('I2C Symmetric switch triggers immediate save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('I2C'));
      await tester.pumpAndSettle();

      final switchFinder = find.byWidgetPredicate((widget) {
        if (widget is! Row) return false;
        final children = widget.children;
        return children.any(
          (child) => child is Text && child.data == 'I2C Symmetric',
        );
      });

      await tester.tap(
        find.descendant(of: switchFinder, matching: find.byType(Switch)),
      );
      await tester.pump();

      expect(saveCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(saveCount, 1);
      expect(lastSavedData?.isI2cSymmetric, equals(true));
    });
  });

  group('PackedMappingDataEditor - Save on Dispose', () {
    late PackedMappingData testData;
    late List<Slot> mockSlots;

    setUp(() {
      testData = PackedMappingData.filler();
      mockSlots = [];
    });

    Widget createTestWidget({
      required Future<void> Function(PackedMappingData) onSave,
      PackedMappingData? initialData,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PackedMappingDataEditor(
            initialData: initialData ?? testData,
            onSave: onSave,
            slots: mockSlots,
            algorithmIndex: 0,
            parameterNumber: 0,
          ),
        ),
      );
    }

    testWidgets('Pending save is flushed when widget is disposed', (
      tester,
    ) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Volts',
      );

      await tester.enterText(textFieldFinder, '99');
      await tester.pump();

      expect(saveCount, 0);

      // Dispose widget before debounce completes
      await tester.pumpWidget(Container());

      expect(saveCount, 1);
      expect(lastSavedData?.volts, equals(99));
    });

    testWidgets('No save triggered on dispose if no pending changes', (
      tester,
    ) async {
      int saveCount = 0;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            saveCount++;
          },
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      // Don't make any changes
      await tester.pumpWidget(Container());

      expect(saveCount, 0);
    });

    testWidgets('Dialog dismissal triggers pending save', (tester) async {
      int saveCount = 0;
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => PackedMappingDataEditor(
                      initialData: testData,
                      onSave: (data) async {
                        saveCount++;
                        lastSavedData = data;
                      },
                      slots: mockSlots,
                      algorithmIndex: 0,
                      parameterNumber: 0,
                    ),
                  );
                },
                child: const Text('Show Editor'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Editor'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'MIDI CC / Note (0–128)',
      );

      await tester.enterText(textFieldFinder, '100');
      await tester.pump();

      expect(saveCount, 0);

      // Dismiss dialog
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(saveCount, 1);
      expect(lastSavedData?.midiCC, equals(100));
    });
  });

  group('PackedMappingDataEditor - Dirty State Indicator', () {
    late PackedMappingData testData;
    late List<Slot> mockSlots;

    setUp(() {
      testData = PackedMappingData.filler();
      mockSlots = [];
    });

    Widget createTestWidget({
      required Future<void> Function(PackedMappingData) onSave,
      PackedMappingData? initialData,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PackedMappingDataEditor(
            initialData: initialData ?? testData,
            onSave: onSave,
            slots: mockSlots,
            algorithmIndex: 0,
            parameterNumber: 0,
          ),
        ),
      );
    }

    testWidgets('Indicator shows when TextField is modified', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {},
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      // No indicator initially
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.amber,
        ),
        findsNothing,
      );

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Volts',
      );

      await tester.enterText(textFieldFinder, '42');
      await tester.pump();

      // Indicator should appear (amber - dirty)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.amber,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Indicator shows when dropdown is changed', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {},
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final dropdownFinder = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownMenu<int> &&
            widget.label.toString().contains('CV Input'),
      );
      final dropdown = tester.widget<DropdownMenu<int>>(dropdownFinder);

      dropdown.onSelected?.call(1);
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.amber,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Indicator shows when switch is toggled', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {},
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final switchFinder = find.byWidgetPredicate((widget) {
        if (widget is! Row) return false;
        final children = widget.children;
        return children.any(
          (child) => child is Text && child.data == 'Unipolar',
        );
      });

      await tester.tap(
        find.descendant(of: switchFinder, matching: find.byType(Switch)),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.amber,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Indicator shows "saving" state during debounce', (
      tester,
    ) async {
      bool saveCalled = false;
      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            // Simulate async save with a delay
            await Future.delayed(const Duration(milliseconds: 100));
            saveCalled = true;
          },
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Volts',
      );

      await tester.enterText(textFieldFinder, '42');
      await tester.pump();

      // Dirty state (amber)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.amber,
        ),
        findsOneWidget,
      );

      // Wait for debounce to trigger save
      await tester.pump(const Duration(seconds: 1));

      // Pump once more to render the _isSaving=true state before save completes
      await tester.pump();

      // Saving state (blue) - the save is in progress (not yet completed)
      expect(saveCalled, false); // Save hasn't completed yet
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.blue,
        ),
        findsOneWidget,
      );

      // Wait for save to complete
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(); // Process the setState after save
      expect(saveCalled, true); // Now save has completed
    });

    testWidgets('Indicator clears when save completes', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {},
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Volts',
      );

      await tester.enterText(textFieldFinder, '42');
      await tester.pump();

      // Wait for save to complete
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Indicator should be cleared
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              ((widget.decoration as BoxDecoration).color == Colors.amber ||
                  (widget.decoration as BoxDecoration).color == Colors.blue),
        ),
        findsNothing,
      );
    });

    testWidgets('Indicator persists across tab switches until save completes',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {},
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Volts',
      );

      await tester.enterText(textFieldFinder, '42');
      await tester.pump();

      // Switch tabs
      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      // Indicator should still be visible
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.amber,
        ),
        findsOneWidget,
      );

      // Wait for save
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Indicator should be cleared
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              ((widget.decoration as BoxDecoration).color == Colors.amber ||
                  (widget.decoration as BoxDecoration).color == Colors.blue),
        ),
        findsNothing,
      );
    });

    testWidgets('Indicator tooltip displays correct message for dirty state',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {},
        ),
      );

      await tester.tap(find.text('CV'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Volts',
      );

      await tester.enterText(textFieldFinder, '42');
      await tester.pump();

      // Find tooltip with "Unsaved changes" message
      // The Tooltip widget wraps the Container, check both exist
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.amber,
        ),
        findsOneWidget,
      );

      // Verify the indicator is wrapped in a Tooltip
      final tooltipFinder = find.ancestor(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.amber,
        ),
        matching: find.byType(Tooltip),
      );
      expect(tooltipFinder, findsOneWidget);
    });
  });

  group('PackedMappingDataEditor - Negative Number Input', () {
    late PackedMappingData testData;
    late List<Slot> mockSlots;

    setUp(() {
      testData = PackedMappingData.filler();
      mockSlots = [];
    });

    Widget createTestWidget({
      required Future<void> Function(PackedMappingData) onSave,
      PackedMappingData? initialData,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PackedMappingDataEditor(
            initialData: initialData ?? testData,
            onSave: onSave,
            slots: mockSlots,
            algorithmIndex: 0,
            parameterNumber: 0,
          ),
        ),
      );
    }

    testWidgets('MIDI Min TextField accepts negative input with signed keyboard',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {},
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'MIDI Min',
      );

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(
        textField.keyboardType,
        equals(const TextInputType.numberWithOptions(signed: true)),
      );
    });

    testWidgets('MIDI Max TextField accepts negative input with signed keyboard',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {},
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'MIDI Max',
      );

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(
        textField.keyboardType,
        equals(const TextInputType.numberWithOptions(signed: true)),
      );
    });

    testWidgets('I2C Min TextField accepts negative input with signed keyboard',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {},
        ),
      );

      await tester.tap(find.text('I2C'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'I2C Min',
      );

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(
        textField.keyboardType,
        equals(const TextInputType.numberWithOptions(signed: true)),
      );
    });

    testWidgets('I2C Max TextField accepts negative input with signed keyboard',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {},
        ),
      );

      await tester.tap(find.text('I2C'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'I2C Max',
      );

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(
        textField.keyboardType,
        equals(const TextInputType.numberWithOptions(signed: true)),
      );
    });

    testWidgets('MIDI Min clamps value to -32768', (tester) async {
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'MIDI Min',
      );

      await tester.enterText(textFieldFinder, '-40000');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(lastSavedData?.midiMin, equals(-32768));
    });

    testWidgets('MIDI Max clamps value to 32767', (tester) async {
      PackedMappingData? lastSavedData;

      await tester.pumpWidget(
        createTestWidget(
          onSave: (data) async {
            lastSavedData = data;
          },
        ),
      );

      await tester.tap(find.text('MIDI'));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'MIDI Max',
      );

      await tester.enterText(textFieldFinder, '40000');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(lastSavedData?.midiMax, equals(32767));
    });
  });
}
