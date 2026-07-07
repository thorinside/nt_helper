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
  });

  testWidgets('describes the automatic SysEx upload check', (tester) async {
    await _pumpDialogButton(tester, sysexAvailable: true, onResult: (_) {});

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('SysEx to NT hardware'), findsOneWidget);
    expect(find.text('Slow'), findsOneWidget);
    expect(
      find.text('Uses MIDI SysEx and checks uploaded filenames and sizes.'),
      findsOneWidget,
    );
    expect(find.text('Verify after upload'), findsNothing);
  });

  testWidgets('labels mounted SD-card upload as fast', (tester) async {
    await _pumpDialogButton(tester, sysexAvailable: true, onResult: (_) {});

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Mounted SD-card folder'), findsOneWidget);
    expect(find.text('Fast'), findsOneWidget);
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

  testWidgets('mounted destination dialog returns NT folder choice', (
    tester,
  ) async {
    PolySampleMountedSdDestinationChoice? result;
    await _pumpMountedDestinationDialogButton(
      tester,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NT multisample folder'));
    await tester.pumpAndSettle();

    expect(
      result?.mode,
      PolySampleMountedSdDestinationMode.ntMultisampleFolder,
    );
  });

  testWidgets('mounted destination dialog returns selected folder choice', (
    tester,
  ) async {
    PolySampleMountedSdDestinationChoice? result;
    await _pumpMountedDestinationDialogButton(
      tester,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selected folder'));
    await tester.pumpAndSettle();

    expect(result?.mode, PolySampleMountedSdDestinationMode.selectedFolder);
  });

  testWidgets('mounted destination dialog offers folder creation', (
    tester,
  ) async {
    PolySampleMountedSdDestinationChoice? result;
    await _pumpMountedDestinationDialogButton(
      tester,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('/Volumes/NT/multisamples/Piano'),
      findsOneWidget,
    );
    expect(find.textContaining('/Volumes/NT'), findsNWidgets(3));

    await tester.tap(find.text('Create folder'));
    await tester.pumpAndSettle();

    expect(result?.mode, PolySampleMountedSdDestinationMode.createFolder);
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

Future<void> _pumpMountedDestinationDialogButton(
  WidgetTester tester, {
  required ValueChanged<PolySampleMountedSdDestinationChoice?> onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return TextButton(
            onPressed: () async {
              final result = await showPolySampleMountedSdDestinationDialog(
                context,
                selectedFolder: '/Volumes/NT',
                ntMultisampleFolder: '/Volumes/NT/multisamples/Piano',
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
