import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/widgets/poly_sample_list.dart';

void main() {
  testWidgets('renders region info and selected semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    const mapped = PolySampleRegion(
      path: '/tmp/mapped.wav',
      fileName: 'mapped.wav',
      displayName: 'mapped.wav',
      rootMidi: 48,
      rootName: 'C3',
    );
    const unmapped = PolySampleRegion(
      path: '/tmp/unmapped.wav',
      fileName: 'unmapped.wav',
      displayName: 'unmapped.wav',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 160,
            child: PolySampleList(
              regions: const [mapped, unmapped],
              selectedPaths: const {'/tmp/mapped.wav'},
              focusedPath: null,
              previewVisiblePath: null,
              onSelect: (_, _) {},
              onPreview: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Root C3'), findsOneWidget);
    expect(find.textContaining('Root unmapped'), findsOneWidget);
    expect(find.bySemanticsLabel('mapped.wav, root C3'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('plain tap emits replace mode', (tester) async {
    PolyRegionSelectionMode? selectedMode;
    String? selectedPath;
    const region = PolySampleRegion(
      path: '/tmp/mapped.wav',
      fileName: 'mapped.wav',
      displayName: 'mapped.wav',
      rootMidi: 48,
      rootName: 'C3',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 80,
            child: PolySampleList(
              regions: const [region],
              selectedPaths: const {},
              focusedPath: null,
              previewVisiblePath: null,
              onSelect: (path, mode) {
                selectedPath = path;
                selectedMode = mode;
              },
              onPreview: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('mapped.wav'));

    expect(selectedPath, '/tmp/mapped.wav');
    expect(selectedMode, PolyRegionSelectionMode.replace);
  });

  testWidgets('preview button disabled for non-wav files', (tester) async {
    const region = PolySampleRegion(
      path: '/tmp/mapped.aif',
      fileName: 'mapped.aif',
      displayName: 'mapped.aif',
      rootMidi: 48,
      rootName: 'C3',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 80,
            child: PolySampleList(
              regions: const [region],
              selectedPaths: const {},
              focusedPath: null,
              previewVisiblePath: null,
              onSelect: (_, _) {},
              onPreview: (_) {},
            ),
          ),
        ),
      ),
    );

    final button = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(PolySampleList),
        matching: find.byType(IconButton),
      ),
    );

    expect(button.onPressed, isNull);
  });
}
