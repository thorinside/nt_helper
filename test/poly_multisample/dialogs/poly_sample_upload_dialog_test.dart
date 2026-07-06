import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/poly_multisample/dialogs/poly_sample_upload_dialog.dart';

void main() {
  testWidgets('returns sysex path when SysEx tile is tapped', (tester) async {
    PolySampleUploadChoice? result;
    await _pumpDialogButton(
      tester,
      sysexAvailable: true,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SysEx to NT hardware'));
    await tester.pumpAndSettle();

    expect(result?.path, PolySampleUploadPath.sysex);
    expect(result?.verifyAfterUpload, isFalse);
  });

  testWidgets('returns sysex choice with verification enabled', (tester) async {
    PolySampleUploadChoice? result;
    await _pumpDialogButton(
      tester,
      sysexAvailable: true,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify after upload'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SysEx to NT hardware'));
    await tester.pumpAndSettle();

    expect(result?.path, PolySampleUploadPath.sysex);
    expect(result?.verifyAfterUpload, isTrue);
  });

  testWidgets('returns mounted path when mounted tile is tapped', (
    tester,
  ) async {
    PolySampleUploadChoice? result;
    await _pumpDialogButton(
      tester,
      sysexAvailable: true,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mounted SD-card folder'));
    await tester.pumpAndSettle();

    expect(result?.path, PolySampleUploadPath.mountedSd);
    expect(result?.verifyAfterUpload, isFalse);
  });

  testWidgets('disables SysEx tile without a manager', (tester) async {
    PolySampleUploadChoice? result;
    await _pumpDialogButton(
      tester,
      sysexAvailable: false,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.text('Connect to Disting NT to use SysEx upload.'),
      findsOneWidget,
    );
    await tester.tap(find.text('SysEx to NT hardware'));
    await tester.pump();

    expect(find.text('Upload sample folder'), findsOneWidget);
    expect(result, isNull);
  });
}

Future<void> _pumpDialogButton(
  WidgetTester tester, {
  required bool sysexAvailable,
  required ValueChanged<PolySampleUploadChoice?> onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return TextButton(
            onPressed: () async {
              final result = await showPolySampleUploadPathDialog(
                context,
                sysexAvailable: sysexAvailable,
              );
              onResult(result);
            },
            child: const Text('Open'),
          );
        },
      ),
    ),
  );
}
