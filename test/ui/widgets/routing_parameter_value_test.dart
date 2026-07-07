import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/bus_picker_dialog.dart';
import 'package:nt_helper/ui/widgets/routing_parameter_value.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('RoutingParameterValue', () {
    testWidgets('renders current bus label and semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          RoutingParameterValue(
            portLabel: 'Output 1',
            currentBus: 13,
            showEs5: false,
            hasExtendedAuxBuses: false,
            onValueChanged: (_) {},
          ),
        ),
      );
      expect(find.text('O1'), findsOneWidget);
      expect(find.bySemanticsLabel('Output 1: O1'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('renders None when currentBus is 0', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RoutingParameterValue(
            portLabel: 'Output 1',
            currentBus: 0,
            showEs5: false,
            hasExtendedAuxBuses: false,
            onValueChanged: (_) {},
          ),
        ),
      );
      expect(find.text('None'), findsOneWidget);
    });

    testWidgets(
      'tapping opens the bus picker and selecting a bus fires callback',
      (tester) async {
        int? selected;
        await tester.pumpWidget(
          _wrap(
            RoutingParameterValue(
              portLabel: 'Output 1',
              currentBus: 13,
              showEs5: false,
              hasExtendedAuxBuses: false,
              onValueChanged: (b) => selected = b,
            ),
          ),
        );

        // Open the picker by tapping the chip.
        await tester.tap(find.byIcon(Icons.route_rounded), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.byType(BusPickerDialog), findsOneWidget);

        // Select bus 14 (O2).
        await tester.tap(find.text('O2'));
        await tester.pumpAndSettle();

        expect(selected, 14);
      },
    );

    testWidgets('disabled control does not open the picker', (tester) async {
      int? selected;
      await tester.pumpWidget(
        _wrap(
          RoutingParameterValue(
            portLabel: 'Output 1',
            currentBus: 13,
            showEs5: false,
            hasExtendedAuxBuses: false,
            enabled: false,
            onValueChanged: (b) => selected = b,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.route_rounded), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(BusPickerDialog), findsNothing);
      expect(selected, isNull);
    });

    testWidgets('shows ES-5 section when showEs5 is true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RoutingParameterValue(
            portLabel: 'Output 1',
            currentBus: 13,
            showEs5: true,
            hasExtendedAuxBuses: false,
            onValueChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.route_rounded), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('ES-5'), findsOneWidget);
      expect(find.text('ES-5 L'), findsOneWidget);
    });

    testWidgets('shows aux buses', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RoutingParameterValue(
            portLabel: 'Output 1',
            currentBus: 13,
            showEs5: false,
            hasExtendedAuxBuses: false,
            onValueChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.route_rounded), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Aux'), findsOneWidget);
      expect(find.text('A1'), findsOneWidget);
    });
  });
}
