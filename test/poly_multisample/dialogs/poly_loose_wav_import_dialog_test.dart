import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/dialogs/poly_loose_wav_import_dialog.dart';

void main() {
  testWidgets('lists files and mapping modes', (tester) async {
    await _pumpDialogButton(tester, paths: const ['/tmp/A.wav', '/tmp/B.wav']);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('A.wav'), findsOneWidget);
    expect(find.text('B.wav'), findsOneWidget);
    expect(find.text('Use note names from file names'), findsOneWidget);
    expect(find.text('Leave unmapped'), findsOneWidget);
    expect(find.text('Spread chromatically from start note'), findsOneWidget);
    expect(find.text('Stack as round robins on one note'), findsOneWidget);
    expect(find.text('Stack as velocity layers on one note'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('None'), findsOneWidget);
  });

  testWidgets('start note row appears for chromatic mode', (tester) async {
    await _pumpDialogButton(tester, paths: const ['/tmp/A.wav']);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spread chromatically from start note'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Start note: C4'), findsOneWidget);
  });

  testWidgets('cancel returns null', (tester) async {
    PolyStagedImport? result = const PolyStagedImport(
      name: 'sentinel',
      sourceLabel: 'sentinel',
      regions: [],
    );
    await _pumpDialogButton(
      tester,
      paths: const ['/tmp/A.wav'],
      onResult: (value) => result = value,
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}

Future<void> _pumpDialogButton(
  WidgetTester tester, {
  required List<String> paths,
  ValueChanged<PolyStagedImport?>? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final result = await showPolyLooseWavImportDialog(
                  context,
                  paths: paths,
                );
                onResult?.call(result);
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    ),
  );
}
