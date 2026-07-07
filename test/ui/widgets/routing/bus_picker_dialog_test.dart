import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/bus_picker_dialog.dart';

String testBusLabel(int bus) {
  if (bus <= 0) return 'None';
  if (bus <= 12) return 'I$bus';
  if (bus <= 20) return 'O${bus - 12}';
  return 'A${bus - 20}';
}

void main() {
  testWidgets(
    'bus picker displays all supplied buses and marks current bus selected',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BusPickerDialog(
              portLabel: 'Output',
              currentBus: 13,
              availableBuses: const [11, 12, 14],
              showEs5: false,
              busLabel: testBusLabel,
            ),
          ),
        ),
      );

      expect(find.text('I11'), findsOneWidget);
      expect(find.text('I12'), findsOneWidget);
      expect(find.text('O1'), findsOneWidget);
      expect(find.text('O2'), findsOneWidget);
      expect(find.bySemanticsLabel('Current bus O1'), findsOneWidget);
      final node = tester.getSemantics(find.bySemanticsLabel('Current bus O1'));
      // ignore: deprecated_member_use
      expect(node.hasFlag(SemanticsFlag.isSelected), isTrue);
      expect(find.bySemanticsLabel('Route to O2'), findsOneWidget);

      semantics.dispose();
    },
  );

  testWidgets('bus picker scrolls current bus near vertical center', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(440, 360));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BusPickerDialog(
            portLabel: 'Output',
            currentBus: 50,
            availableBuses: List<int>.generate(64, (index) => index + 1),
            showEs5: false,
            busLabel: testBusLabel,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(Dialog));
    final selectedY = tester.getCenter(find.text('A30')).dy;
    expect(selectedY, greaterThan(dialogRect.top + dialogRect.height * 0.30));
    expect(selectedY, lessThan(dialogRect.top + dialogRect.height * 0.80));
  });
}
