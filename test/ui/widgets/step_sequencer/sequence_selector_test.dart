import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/sequence_selector.dart';

void main() {
  group('SequenceSelector Widget Tests', () {
    testWidgets('displays 32 sequence options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SequenceSelector(
              currentSequence: 0,
              isLoading: false,
              onSequenceChanged: (_) {},
            ),
          ),
        ),
      );

      // Find the dropdown
      final dropdown = find.byType(DropdownButtonFormField<int>);
      expect(dropdown, findsOneWidget);

      // Open dropdown
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Verify first few sequences are visible (not all 32 will be visible in scrollable menu)
      expect(find.text('Sequence 1'), findsWidgets);
      expect(find.text('Sequence 2'), findsWidgets);
      expect(find.text('Sequence 3'), findsWidgets);
    });

    testWidgets('displays current sequence correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SequenceSelector(
              currentSequence: 5, // Hardware value 5 = display "Sequence 6"
              isLoading: false,
              onSequenceChanged: (_) {},
            ),
          ),
        ),
      );

      // Should display "Sequence 6" (hardware value 5 + 1)
      expect(find.text('Sequence 6'), findsOneWidget);
    });

    testWidgets('calls onSequenceChanged when selection changes',
        (tester) async {
      int? selectedSequence;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SequenceSelector(
              currentSequence: 0,
              isLoading: false,
              onSequenceChanged: (sequence) {
                selectedSequence = sequence;
              },
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Select "Sequence 10" (hardware value 9)
      await tester.tap(find.text('Sequence 10').last);
      await tester.pumpAndSettle();

      // Verify callback was called with correct hardware value (0-indexed)
      expect(selectedSequence, equals(9));
    });

    testWidgets('shows loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SequenceSelector(
              currentSequence: 0,
              isLoading: true,
              onSequenceChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify loading indicator is present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify dropdown is disabled (onChanged should be null)
      final dropdown =
          tester.widget<DropdownButtonFormField<int>>(find.byType(DropdownButtonFormField<int>));
      expect(dropdown.onChanged, isNull);
    });

    testWidgets('hides loading indicator when isLoading is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SequenceSelector(
              currentSequence: 0,
              isLoading: false,
              onSequenceChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify loading indicator is NOT present
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify dropdown is enabled
      final dropdown =
          tester.widget<DropdownButtonFormField<int>>(find.byType(DropdownButtonFormField<int>));
      expect(dropdown.onChanged, isNotNull);
    });

    testWidgets('displays custom sequence names when provided',
        (tester) async {
      final customNames = {
        0: 'Intro',
        1: 'Verse',
        2: 'Chorus',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SequenceSelector(
              currentSequence: 0,
              isLoading: false,
              onSequenceChanged: (_) {},
              sequenceNames: customNames,
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Verify custom names are displayed (may appear multiple times due to dropdown value + menu items)
      expect(find.text('Intro'), findsWidgets);
      expect(find.text('Verse'), findsWidgets);
      expect(find.text('Chorus'), findsWidgets);

      // Verify unnamed sequences still show default naming
      expect(find.text('Sequence 4'), findsWidgets);
    });

    testWidgets('dropdown disabled when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SequenceSelector(
              currentSequence: 0,
              isLoading: true,
              onSequenceChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify dropdown is disabled by checking onChanged is null
      final dropdown =
          tester.widget<DropdownButtonFormField<int>>(find.byType(DropdownButtonFormField<int>));
      expect(dropdown.onChanged, isNull);

      // Also verify loading indicator is present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SequenceSelector(
              currentSequence: 0,
              isLoading: false,
              onSequenceChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify widget renders without errors in dark mode
      expect(find.byType(SequenceSelector), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });

    testWidgets('renders correctly in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SequenceSelector(
              currentSequence: 0,
              isLoading: false,
              onSequenceChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify widget renders without errors in light mode
      expect(find.byType(SequenceSelector), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });
  });
}
