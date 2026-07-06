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

    await _pumpList(
      tester,
      regions: const [mapped, unmapped],
      selectedPaths: const {'/tmp/mapped.wav'},
    );

    expect(find.textContaining('Root C3'), findsOneWidget);
    expect(find.textContaining('Root Unset'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'mapped.wav, root C3, low C3, high G9, velocity 1, RR 1',
      ),
      findsOneWidget,
    );
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

    await _pumpList(
      tester,
      regions: const [region],
      onSelect: (path, mode) {
        selectedPath = path;
        selectedMode = mode;
      },
    );

    await tester.tap(find.text('mapped.wav'));

    expect(selectedPath, '/tmp/mapped.wav');
    expect(selectedMode, PolyRegionSelectionMode.replace);
  });

  testWidgets('disambiguates duplicate display names', (tester) async {
    final semantics = tester.ensureSemantics();
    const close = PolySampleRegion(
      path: '/tmp/Kit/close/C4.wav',
      fileName: 'C4.wav',
      displayName: 'C4.wav',
      rootMidi: 60,
      rootName: 'C4',
    );
    const room = PolySampleRegion(
      path: '/tmp/Kit/room/C4.wav',
      fileName: 'C4.wav',
      displayName: 'C4.wav',
      rootMidi: 60,
      rootName: 'C4',
    );

    await _pumpList(tester, regions: const [close, room]);

    expect(find.text('close/C4.wav'), findsOneWidget);
    expect(find.text('room/C4.wav'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'close/C4.wav, root C4, low C4, high G9, velocity 1, RR 1',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('preview button disabled for non-wav files', (tester) async {
    const region = PolySampleRegion(
      path: '/tmp/mapped.aif',
      fileName: 'mapped.aif',
      displayName: 'mapped.aif',
      rootMidi: 48,
      rootName: 'C3',
    );

    await _pumpList(tester, regions: const [region]);

    final button = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Preview sample',
      ),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('renders inline mapping steppers for each sample row', (
    tester,
  ) async {
    const region = PolySampleRegion(
      path: '/tmp/mapped.wav',
      fileName: 'mapped.wav',
      displayName: 'mapped.wav',
      rootMidi: 48,
      rootName: 'C3',
      rangeLow: 47,
      rangeHigh: 55,
      velocityLayer: 2,
      roundRobin: 3,
    );

    await _pumpList(tester, regions: const [region]);

    expect(find.text('Root C3'), findsOneWidget);
    expect(find.text('Low B2'), findsOneWidget);
    expect(find.text('High G3'), findsOneWidget);
    expect(find.text('Vel 2'), findsOneWidget);
    expect(find.text('RR 3'), findsOneWidget);
  });

  testWidgets('inline steppers emit clamped mapping updates', (tester) async {
    int? root;
    int? low;
    int? high;
    int? velocity;
    int? roundRobin;
    const region = PolySampleRegion(
      path: '/tmp/boundary.wav',
      fileName: 'boundary.wav',
      displayName: 'boundary.wav',
      rootMidi: 0,
      rootName: 'C-1',
      rangeLow: 0,
      rangeHigh: 0,
      velocityLayer: 1,
      roundRobin: 1,
    );

    await _pumpList(
      tester,
      regions: const [region],
      onUpdateRoot: (_, midi) => root = midi,
      onUpdateRangeLow: (_, midi) => low = midi,
      onUpdateRangeHigh: (_, midi) => high = midi,
      onUpdateVelocity: (_, layer) => velocity = layer,
      onUpdateRoundRobin: (_, lane) => roundRobin = lane,
    );

    await _tapTooltipButton(tester, 'Decrease Root for boundary.wav');
    await _tapTooltipButton(tester, 'Decrease Low for boundary.wav');
    await _tapTooltipButton(tester, 'Decrease High for boundary.wav');
    await _tapTooltipButton(tester, 'Decrease Vel for boundary.wav');
    await _tapTooltipButton(tester, 'Decrease RR for boundary.wav');

    expect(root, 0);
    expect(low, 0);
    expect(high, 0);
    expect(velocity, 1);
    expect(roundRobin, 1);
  });

  testWidgets('inline stepper semantics name values and actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const region = PolySampleRegion(
      path: '/tmp/mapped.wav',
      fileName: 'mapped.wav',
      displayName: 'mapped.wav',
      rootMidi: 48,
      rootName: 'C3',
      rangeLow: 48,
      rangeHigh: 55,
      velocityLayer: 2,
      roundRobin: 3,
    );

    await _pumpList(tester, regions: const [region]);

    expect(
      find.bySemanticsLabel(
        'mapped.wav, root C3, low C3, high G3, velocity 2, RR 3',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Decrease Root for mapped.wav'), findsOneWidget);
    expect(find.byTooltip('Increase RR for mapped.wav'), findsOneWidget);
    semantics.dispose();
  });
}

Future<void> _tapTooltipButton(WidgetTester tester, String tooltip) async {
  await tester.tap(
    find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == tooltip,
    ),
  );
  await tester.pump();
}

Future<void> _pumpList(
  WidgetTester tester, {
  required List<PolySampleRegion> regions,
  Set<String> selectedPaths = const {},
  String? focusedPath,
  String? previewVisiblePath,
  void Function(String path, PolyRegionSelectionMode mode)? onSelect,
  ValueChanged<String>? onPreview,
  void Function(String path, int midi)? onUpdateRoot,
  void Function(String path, int midi)? onUpdateRangeLow,
  void Function(String path, int midi)? onUpdateRangeHigh,
  void Function(String path, int layer)? onUpdateVelocity,
  void Function(String path, int lane)? onUpdateRoundRobin,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 220,
          child: PolySampleList(
            regions: regions,
            selectedPaths: selectedPaths,
            focusedPath: focusedPath,
            previewVisiblePath: previewVisiblePath,
            onSelect: onSelect ?? (_, _) {},
            onPreview: onPreview ?? (_) {},
            onUpdateRoot: onUpdateRoot ?? (_, _) {},
            onUpdateRangeLow: onUpdateRangeLow ?? (_, _) {},
            onUpdateRangeHigh: onUpdateRangeHigh ?? (_, _) {},
            onUpdateVelocity: onUpdateVelocity ?? (_, _) {},
            onUpdateRoundRobin: onUpdateRoundRobin ?? (_, _) {},
          ),
        ),
      ),
    ),
  );
}
