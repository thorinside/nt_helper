import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/widgets/poly_key_map.dart';

void main() {
  testWidgets('exposes a keyboard map semantics label', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 200,
            child: PolyKeyMap(
              height: 200,
              regions: const [
                PolySampleRegion(
                  path: '/tmp/a.wav',
                  fileName: 'a.wav',
                  displayName: 'a.wav',
                  rootMidi: 48,
                ),
                PolySampleRegion(
                  path: '/tmp/b.wav',
                  fileName: 'b.wav',
                  displayName: 'b.wav',
                  rootMidi: 60,
                ),
              ],
              selectedPath: null,
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Keyboard map with 2 mapped samples'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('a.wav, root C3, range C3 to B3, velocity 1'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('tap on a mapped zone selects the region', (tester) async {
    PolySampleRegion? selected;
    const region = PolySampleRegion(
      path: '/tmp/c3.wav',
      fileName: 'c3.wav',
      displayName: 'c3.wav',
      rootMidi: 48,
      rangeLow: 0,
      rangeHigh: 127,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 200,
            child: PolyKeyMap(
              height: 200,
              regions: const [region],
              selectedPath: null,
              onSelect: (region) => selected = region,
            ),
          ),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(PolyKeyMap));
    await tester.tapAt(topLeft + const Offset(800 / 2, (24 + (200 - 50)) / 2));

    expect(selected, region);
  });

  testWidgets('tap on keyboard strip previews the tapped midi note', (
    tester,
  ) async {
    PolySampleRegion? selected;
    int? previewedNote;
    const region = PolySampleRegion(
      path: '/tmp/c3.wav',
      fileName: 'c3.wav',
      displayName: 'c3.wav',
      rootMidi: 60,
      rangeLow: 0,
      rangeHigh: 127,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 200,
            child: PolyKeyMap(
              height: 200,
              regions: const [region],
              selectedPath: null,
              onSelect: (region) => selected = region,
              onPreviewNote: (midi) => previewedNote = midi,
            ),
          ),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(PolyKeyMap));
    await tester.tapAt(
      topLeft + const Offset(16 + ((60.5) / 128) * (800 - 32), 176),
    );

    expect(previewedNote, 60);
    expect(selected, isNull);
  });

  testWidgets('tap on mapped zone still selects without previewing', (
    tester,
  ) async {
    PolySampleRegion? selected;
    int? previewedNote;
    const region = PolySampleRegion(
      path: '/tmp/c3.wav',
      fileName: 'c3.wav',
      displayName: 'c3.wav',
      rootMidi: 48,
      rangeLow: 0,
      rangeHigh: 127,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 200,
            child: PolyKeyMap(
              height: 200,
              regions: const [region],
              selectedPath: null,
              onSelect: (region) => selected = region,
              onPreviewNote: (midi) => previewedNote = midi,
            ),
          ),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(PolyKeyMap));
    await tester.tapAt(topLeft + const Offset(800 / 2, (24 + (200 - 50)) / 2));

    expect(selected, region);
    expect(previewedNote, isNull);
  });

  testWidgets('exposes piano note preview semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 200,
            child: PolyKeyMap(
              height: 200,
              regions: const [
                PolySampleRegion(
                  path: '/tmp/c4.wav',
                  fileName: 'c4.wav',
                  displayName: 'c4.wav',
                  rootMidi: 60,
                ),
              ],
              selectedPath: null,
              onSelect: (_) {},
              onPreviewNote: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Preview C4'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('keyboard focus can activate a mapped region', (tester) async {
    PolySampleRegion? selected;
    const region = PolySampleRegion(
      path: '/tmp/c3.wav',
      fileName: 'c3.wav',
      displayName: 'c3.wav',
      rootMidi: 48,
      rangeLow: 0,
      rangeHigh: 127,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextButton(onPressed: () {}, child: const Text('Before')),
              SizedBox(
                width: 800,
                height: 200,
                child: PolyKeyMap(
                  height: 200,
                  regions: const [region],
                  selectedPath: null,
                  onSelect: (region) => selected = region,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, region);
  });

  testWidgets('disambiguates duplicate sample names in semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 200,
            child: PolyKeyMap(
              height: 200,
              regions: const [
                PolySampleRegion(
                  path: '/tmp/Kit/close/C4.wav',
                  fileName: 'C4.wav',
                  displayName: 'C4.wav',
                  rootMidi: 60,
                ),
                PolySampleRegion(
                  path: '/tmp/Kit/room/C4.wav',
                  fileName: 'C4.wav',
                  displayName: 'C4.wav',
                  rootMidi: 62,
                ),
              ],
              selectedPath: null,
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'close/C4.wav, root C4, range C4 to C#4, velocity 1',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('room/C4.wav, root D4, range D4 to G9, velocity 1'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('renders without mapped regions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 200,
            child: PolyKeyMap(
              height: 200,
              regions: const [],
              selectedPath: null,
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(PolyKeyMap),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });
}
