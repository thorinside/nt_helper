import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_sample_mapping_resolver.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/poly_region_math.dart';

void main() {
  group('poly region math', () {
    test('mappingWarningMessages formats resolved overlap', () {
      const regions = [
        PolySampleRegion(
          path: '/tmp/a.wav',
          fileName: 'a.wav',
          displayName: 'a.wav',
          rootMidi: 60,
          velocityLayer: 2,
          roundRobin: 3,
        ),
        PolySampleRegion(
          path: '/tmp/b.wav',
          fileName: 'b.wav',
          displayName: 'b.wav',
          rootMidi: 60,
          velocityLayer: 2,
          roundRobin: 3,
        ),
      ];
      final resolution = const PolySampleMappingResolver().resolve(regions);

      expect(mappingWarningMessages(regions, resolution), [
        'Mapping overlap: a.wav overlaps b.wav on velocity 2, RR 3.',
      ]);
    });

    test('mappingWarningMessages formats automatic natural overflow', () {
      final regions = [
        for (var index = 0; index <= 80; index++)
          PolySampleRegion(
            path: '/tmp/Family${index.toString().padLeft(3, '0')}.wav',
            fileName: 'Family${index.toString().padLeft(3, '0')}.wav',
            displayName: 'Family${index.toString().padLeft(3, '0')}.wav',
          ),
      ];
      final resolution = const PolySampleMappingResolver().resolve(regions);

      expect(mappingWarningMessages(regions, resolution), [
        'Mapping impossible: Family080.wav natural MIDI 128 is outside 0-127.',
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
