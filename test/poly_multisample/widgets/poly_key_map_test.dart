import 'package:flutter/material.dart';
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
