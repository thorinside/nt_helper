import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';

void main() {
  group('PolyMultisampleParser', () {
    test('maps MIDI note numbers to Disting note names', () {
      expect(PolyMultisampleParser.midiToNoteName(48), 'C3');
      expect(PolyMultisampleParser.midiToNoteName(60), 'C4');
      expect(PolyMultisampleParser.midiToNoteName(69), 'A4');
    });

    test('parses factory-style note filenames', () {
      final region = PolyMultisampleParser.parseFile(
        File('/samples/flute/FLUTE2_C4   .wav'),
      );

      expect(region.rootMidi, 60);
      expect(region.rootName, 'C4');
      expect(region.velocityLayer, isNull);
      expect(region.roundRobin, isNull);
      expect(region.issues, isEmpty);
    });

    test('parses Disting switch velocity and round-robin tags', () {
      final region = PolyMultisampleParser.parseFile(
        File('/samples/SoftPiano/SoftPiano_C3_SW48_V2_RR3.wav'),
      );

      expect(region.rootMidi, 48);
      expect(region.rootName, 'C3');
      expect(region.switchPoint, 48);
      expect(region.velocityLayer, 2);
      expect(region.roundRobin, 3);
    });

    test('parses DK Solo Cello style filenames', () {
      final region = PolyMultisampleParser.parseFile(
        File('/samples/DK Solo Cello Spurs/DKMSC_Tremolo_A#3_V1_RR2.wav'),
      );

      expect(region.rootMidi, 58);
      expect(region.rootName, 'A#3');
      expect(region.velocityLayer, 1);
      expect(region.roundRobin, 2);
      expect(region.issues, isEmpty);
    });

    test('normalizes flat notes to sharp Disting names', () {
      final region = PolyMultisampleParser.parseFile(
        File('/samples/Strings/Strings_Bb3.wav'),
      );

      expect(region.rootMidi, 58);
      expect(region.rootName, 'A#3');
    });

    test('flags audio files without root notes', () {
      final region = PolyMultisampleParser.parseFile(
        File('/samples/drums/kick.wav'),
      );

      expect(region.rootMidi, isNull);
      expect(region.issues, contains(PolySampleIssue.missingRootNote));
    });
  });
}
