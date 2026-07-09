import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/poly_region_math.dart';

void main() {
  group('poly region math', () {
    test('effectiveLow falls back through switchPoint and root', () {
      const ranged = PolySampleRegion(
        path: '/tmp/ranged.wav',
        fileName: 'ranged.wav',
        displayName: 'ranged.wav',
        rangeLow: 36,
        switchPoint: 40,
        rootMidi: 48,
      );
      const switched = PolySampleRegion(
        path: '/tmp/switched.wav',
        fileName: 'switched.wav',
        displayName: 'switched.wav',
        switchPoint: 40,
        rootMidi: 48,
      );
      const rooted = PolySampleRegion(
        path: '/tmp/rooted.wav',
        fileName: 'rooted.wav',
        displayName: 'rooted.wav',
        rootMidi: 48,
      );

      expect(effectiveLow(ranged), 36);
      expect(effectiveLow(switched), 40);
      expect(effectiveLow(rooted), 48);
    });

    test('effectiveHigh uses next lane low minus one', () {
      const first = PolySampleRegion(
        path: '/tmp/first.wav',
        fileName: 'first.wav',
        displayName: 'first.wav',
        rootMidi: 48,
      );
      const second = PolySampleRegion(
        path: '/tmp/second.wav',
        fileName: 'second.wav',
        displayName: 'second.wav',
        rootMidi: 60,
      );
      const regions = [first, second];

      expect(effectiveHigh(first, regions), 59);
      expect(effectiveHigh(second, regions), 127);
    });

    test('midiExtents returns null for unmapped regions', () {
      const regions = [
        PolySampleRegion(
          path: '/tmp/unmapped.wav',
          fileName: 'unmapped.wav',
          displayName: 'unmapped.wav',
        ),
      ];

      expect(midiExtents(regions), isNull);
    });

    test('velocityLanes returns descending distinct lanes', () {
      const regions = [
        PolySampleRegion(
          path: '/tmp/a.wav',
          fileName: 'a.wav',
          displayName: 'a.wav',
          rootMidi: 48,
          velocityLayer: 1,
        ),
        PolySampleRegion(
          path: '/tmp/b.wav',
          fileName: 'b.wav',
          displayName: 'b.wav',
          rootMidi: 48,
          velocityLayer: 2,
        ),
        PolySampleRegion(
          path: '/tmp/c.wav',
          fileName: 'c.wav',
          displayName: 'c.wav',
          rootMidi: 49,
          velocityLayer: 2,
        ),
        PolySampleRegion(
          path: '/tmp/d.wav',
          fileName: 'd.wav',
          displayName: 'd.wav',
          rootMidi: 50,
        ),
      ];

      expect(velocityLanes(regions), [2, 1]);
    });

    test('mappingWarnings reports impossible mappings and overlaps', () {
      const regions = [
        PolySampleRegion(
          path: '/tmp/invalid.wav',
          fileName: 'invalid.wav',
          displayName: 'invalid.wav',
          rangeLow: 72,
          rangeHigh: 60,
        ),
        PolySampleRegion(
          path: '/tmp/outside.wav',
          fileName: 'outside.wav',
          displayName: 'outside.wav',
          rootMidi: 74,
          rangeLow: 48,
          rangeHigh: 60,
        ),
        PolySampleRegion(
          path: '/tmp/overlap-a.wav',
          fileName: 'overlap-a.wav',
          displayName: 'overlap-a.wav',
          rootMidi: 66,
          rangeLow: 64,
          rangeHigh: 72,
          velocityLayer: 2,
          roundRobin: 3,
        ),
        PolySampleRegion(
          path: '/tmp/overlap-b.wav',
          fileName: 'overlap-b.wav',
          displayName: 'overlap-b.wav',
          rootMidi: 71,
          rangeLow: 70,
          rangeHigh: 80,
          velocityLayer: 2,
          roundRobin: 3,
        ),
      ];

      expect(mappingWarnings(regions), [
        'Mapping impossible: invalid.wav has low C5 above high C4.',
        'Mapping impossible: outside.wav root D5 is outside C3–C4.',
        'Mapping overlap: overlap-a.wav and overlap-b.wav overlap on A#4–C5 at velocity 2, RR 3.',
      ]);
    });

    test('selectedRegionFor prefers focusedPath', () {
      const first = PolySampleRegion(
        path: '/tmp/first.wav',
        fileName: 'first.wav',
        displayName: 'first.wav',
      );
      const second = PolySampleRegion(
        path: '/tmp/second.wav',
        fileName: 'second.wav',
        displayName: 'second.wav',
      );
      const regions = [first, second];

      const focusedState = PolyMultisampleBuilderState(
        editedRegions: regions,
        selectedPaths: {'/tmp/first.wav'},
        focusedPath: '/tmp/second.wav',
      );
      const selectedState = PolyMultisampleBuilderState(
        editedRegions: regions,
        selectedPaths: {'/tmp/second.wav'},
      );
      const defaultState = PolyMultisampleBuilderState(editedRegions: regions);

      expect(selectedRegionFor(focusedState), second);
      expect(selectedRegionFor(selectedState), second);
      expect(selectedRegionFor(defaultState), isNull);
    });
  });
}
