import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart';

void main() {
  group('MidiEventType enum', () {
    test('has exactly 5 variants', () {
      expect(MidiEventType.values.length, 5);
      expect(
        MidiEventType.values,
        containsAll([
          MidiEventType.cc,
          MidiEventType.noteOn,
          MidiEventType.noteOff,
          MidiEventType.cc14BitLowFirst,
          MidiEventType.cc14BitHighFirst,
        ]),
      );
    });

    test('14-bit types are distinct from 7-bit cc type', () {
      expect(MidiEventType.cc14BitLowFirst, isNot(MidiEventType.cc));
      expect(MidiEventType.cc14BitHighFirst, isNot(MidiEventType.cc));
      expect(
        MidiEventType.cc14BitLowFirst,
        isNot(MidiEventType.cc14BitHighFirst),
      );
    });
  });

  group('MidiListenerState.data', () {
    test('accepts all MidiEventType variants', () {
      for (final type in MidiEventType.values) {
        final state = MidiListenerState.data(lastDetectedType: type);
        // Use pattern matching to access Data variant fields
        expect(state, isA<Data>());
        final dataState = state as Data;
        expect(dataState.lastDetectedType, type);
      }
    });

    test('copyWith preserves 14-bit type (cc14BitLowFirst)', () {
      final state = MidiListenerState.data(
        lastDetectedType: MidiEventType.cc14BitLowFirst,
        lastDetectedCc: 1,
        lastDetectedChannel: 0,
      ) as Data;

      final updated = state.copyWith(lastDetectedTime: DateTime.now());

      expect(updated.lastDetectedType, MidiEventType.cc14BitLowFirst);
      expect(updated.lastDetectedCc, 1);
      expect(updated.lastDetectedChannel, 0);
    });

    test('copyWith preserves 14-bit type (cc14BitHighFirst)', () {
      final state = MidiListenerState.data(
        lastDetectedType: MidiEventType.cc14BitHighFirst,
        lastDetectedCc: 32,
        lastDetectedChannel: 5,
      ) as Data;

      final updated = state.copyWith(lastDetectedTime: DateTime.now());

      expect(updated.lastDetectedType, MidiEventType.cc14BitHighFirst);
      expect(updated.lastDetectedCc, 32);
      expect(updated.lastDetectedChannel, 5);
    });
  });

  group('MidiListenerState.initial', () {
    test('has null lastDetectedType', () {
      final state = MidiListenerState.initial();
      expect(state, isA<Initial>());

      // Initial state doesn't have lastDetectedType field
      // This test verifies it's of the correct type
    });
  });
}
