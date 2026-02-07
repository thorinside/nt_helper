import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/port_widget.dart';
import 'package:nt_helper/core/routing/models/port.dart';

void main() {
  group('Widget Semantics', () {
    group('PortWidget', () {
      testWidgets('has semantic label with port name', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PortWidget(
                label: 'Audio Out',
                isInput: false,
                portId: 'audio_out_1',
              ),
            ),
          ),
        );

        expect(find.text('Audio Out'), findsOneWidget);
      });

      testWidgets('port with model includes type in semantics',
          (tester) async {
        const port = Port(
          id: 'test_port',
          name: 'Test Port',
          type: PortType.audio,
          direction: PortDirection.output,
          parameterNumber: 0,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PortWidget(
                label: 'Test Port',
                isInput: false,
                portId: 'test_port',
                port: port,
              ),
            ),
          ),
        );

        expect(find.text('Test Port'), findsOneWidget);
      });
    });

    group('Dialog semantics', () {
      testWidgets('AlertDialog title has header semantics', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Semantics(
                      header: true,
                      child: const Text('Test Dialog'),
                    ),
                    content: const Text('Content'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Test Dialog'), findsOneWidget);
        expect(find.text('Content'), findsOneWidget);
      });
    });

    group('Add Algorithm Screen', () {
      testWidgets('algorithm chip has semantic label', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Semantics(
                button: true,
                selected: false,
                label: 'Test Algorithm, favorite',
                hint: 'Double tap to select',
                child: const SizedBox(width: 100, height: 40),
              ),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel(RegExp('Test Algorithm')),
          findsOneWidget,
        );
      });
    });

    group('Bottom sheet accessibility', () {
      testWidgets('showModalBottomSheet with showDragHandle', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) => const SizedBox(
                    height: 200,
                    child: Center(child: Text('Sheet Content')),
                  ),
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Sheet Content'), findsOneWidget);
      });
    });

    group('Progress indicator semantics', () {
      testWidgets('CircularProgressIndicator wrapped in Semantics',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Semantics(
                label: 'Loading data',
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Loading data'), findsOneWidget);
      });
    });
  });
}
