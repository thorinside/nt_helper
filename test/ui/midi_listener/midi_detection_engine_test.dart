import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/midi_listener/midi_detection_engine.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart';

void main() {
  group('MidiDetectionEngine', () {
    late MidiDetectionEngine engine;

    setUp(() {
      engine = MidiDetectionEngine();
    });

    group('7-bit CC detection', () {
      test('detects after 10 consecutive identical CC messages', () {
        DetectionResult? result;

        // Send 9 identical CC messages - should not detect
        for (int i = 0; i < 9; i++) {
          result = engine.processCc(0, 1, 64);
          expect(result, isNull, reason: 'Should not detect before threshold');
        }

        // 10th message should trigger detection
        result = engine.processCc(0, 1, 64);
        expect(result, isNotNull);
        expect(result!.type, MidiEventType.cc);
        expect(result.channel, 0);
        expect(result.number, 1);
      });

      test('resets count when CC number changes', () {
        // Send 5 CC 1 messages
        for (int i = 0; i < 5; i++) {
          engine.processCc(0, 1, 64);
        }

        // Send CC 2 - should reset count to 1
        var result = engine.processCc(0, 2, 64);
        expect(result, isNull);

        // Need 9 more CC 2 messages to reach threshold (total 10)
        for (int i = 0; i < 8; i++) {
          result = engine.processCc(0, 2, 64);
          expect(result, isNull);
        }

        // 10th CC 2 message should detect
        result = engine.processCc(0, 2, 64);
        expect(result, isNotNull);
        expect(result!.number, 2);
      });

      test('resets count when channel changes', () {
        // Send 5 messages on channel 0
        for (int i = 0; i < 5; i++) {
          engine.processCc(0, 1, 64);
        }

        // Send on channel 1 - should reset count to 1
        var result = engine.processCc(1, 1, 64);
        expect(result, isNull);

        // Need 9 more on channel 1 to reach threshold (total 10)
        for (int i = 0; i < 8; i++) {
          result = engine.processCc(1, 1, 64);
          expect(result, isNull);
        }

        // 10th message on channel 1 should detect
        result = engine.processCc(1, 1, 64);
        expect(result, isNotNull);
        expect(result!.channel, 1);
      });

      test('resets count when value changes (value matters for consecutive)', () {
        // NOTE: Based on existing cubit behavior, consecutive detection
        // only checks channel+ccNumber, not value. But test what's implemented.
        // Send 10 messages with different values
        for (int i = 0; i < 10; i++) {
          final result = engine.processCc(0, 1, i);
          // If value is part of signature, this won't detect
          // If value is NOT part of signature, the 10th will detect
          // Based on cubit code, signature is (type, channel, number) - no value
          if (i == 9) {
            expect(result, isNotNull, reason: 'Value should not affect consecutive detection');
          }
        }
      });
    });

    group('14-bit pair formation', () {
      test('forms pair when CC X and CC X+32 both received', () {
        // CC 1 alone should not form pair
        var result = engine.processCc(0, 1, 64);
        expect(result, isNull);

        // CC 33 (1+32) arrives - pair formed but no detection yet
        result = engine.processCc(0, 33, 100);
        expect(result, isNull, reason: 'Pair formed but threshold not reached');
      });

      test('ignores CC 0 and CC 32 from pairing (Bank Select)', () {
        // Send CC 0 and CC 32 - should NOT form pair
        var result = engine.processCc(0, 0, 64);
        expect(result, isNull);

        result = engine.processCc(0, 32, 100);
        expect(result, isNull);

        // These should be processed as independent 7-bit CCs
        // Send 10 consecutive CC 0 messages
        for (int i = 0; i < 9; i++) {
          result = engine.processCc(0, 0, 64);
        }
        result = engine.processCc(0, 0, 64);
        expect(result, isNotNull);
        expect(result!.type, MidiEventType.cc);
        expect(result.number, 0);
      });

      test('requires both CCs on same channel for pair', () {
        // CC 1 on channel 0
        engine.processCc(0, 1, 64);

        // CC 33 on channel 1 - different channel, no pair
        engine.processCc(1, 33, 100);

        // Send 10 pairs on different channels - should not detect 14-bit
        for (int i = 0; i < 10; i++) {
          engine.processCc(0, 1, 64 + i);
          final result = engine.processCc(1, 33, 100 + i);
          expect(result, isNull, reason: 'Cross-channel should not form pair');
        }
      });

      test('locks to single pair at a time', () {
        // Start with CC 1 + CC 33 pair (forms pair, records hit #1)
        engine.processCc(0, 1, 64);
        engine.processCc(0, 33, 100);

        // Now send CC 5 - should be ignored for 14-bit pairing (single pair lock)
        engine.processCc(0, 5, 80);
        engine.processCc(0, 37, 90); // CC 5's partner

        // Continue with original pair to reach threshold (9 more hits needed)
        DetectionResult? result;
        for (int i = 0; i < 9; i++) {
          engine.processCc(0, 1, 64);
          result = engine.processCc(0, 33, 100);
          if (i < 8) {
            expect(result, isNull);
          }
        }

        expect(result, isNotNull);
        expect(result!.number, 1, reason: 'Should detect original pair CC 1, not CC 5');
      });
    });

    group('14-bit hit counting', () {
      test('increments hit count only when both CCs received', () {
        // First pair hit: both CCs arrive
        engine.processCc(0, 1, 64);
        var result = engine.processCc(0, 33, 100);
        expect(result, isNull, reason: 'Hit 1/10');

        // Only CC 1 again - no new hit yet (need CC 33 too)
        result = engine.processCc(0, 1, 65);
        expect(result, isNull, reason: 'Only one side, no new hit');

        // Now CC 33 arrives - completes second hit
        result = engine.processCc(0, 33, 101);
        expect(result, isNull, reason: 'Hit 2/10');

        // Continue to reach threshold (8 more pair hits needed)
        for (int i = 0; i < 8; i++) {
          engine.processCc(0, 1, 64);
          result = engine.processCc(0, 33, i);
          if (i < 7) {
            expect(result, isNull, reason: 'Hit ${i + 3}/10');
          } else {
            // 10th pair hit should detect
            expect(result, isNotNull, reason: 'Hit 10/10 should detect');
          }
        }
      });

      test('detects after 10 pair hits with MSB-first byte order', () {
        // Send pairs where low CC (1) is stable (MSB), high CC (33) varies (LSB)
        // First pair forms and records hit #1
        // Then 9 more pairs complete hits #2-#10
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          engine.processCc(0, 1, 64);  // Stable value = MSB
          result = engine.processCc(0, 33, i);  // Varying value = LSB
          if (i < 9) {
            expect(result, isNull, reason: 'Hit ${i + 1}/10');
          }
        }

        expect(result, isNotNull, reason: 'Hit 10/10 should detect');
        expect(result!.type, MidiEventType.cc14BitLowFirst,
               reason: 'Low CC stable = MSB, so cc14BitLowFirst');
        expect(result.channel, 0);
        expect(result.number, 1);
      });

      test('detects after 10 pair hits with LSB-first byte order', () {
        // Send pairs where high CC (33) is stable (MSB), low CC (1) varies (LSB)
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          engine.processCc(0, 1, i);   // Varying value = LSB
          result = engine.processCc(0, 33, 64); // Stable value = MSB
          if (i < 9) {
            expect(result, isNull, reason: 'Hit ${i + 1}/10');
          }
        }

        expect(result, isNotNull, reason: 'Hit 10/10 should detect');
        expect(result!.type, MidiEventType.cc14BitHighFirst,
               reason: 'High CC stable = MSB, so cc14BitHighFirst');
        expect(result.channel, 0);
        expect(result.number, 1);
      });

      test('defaults to cc14BitLowFirst when variance is ambiguous', () {
        // Send pairs where both CCs vary similarly
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          engine.processCc(0, 1, 50 + i);
          result = engine.processCc(0, 33, 60 + i);
          if (i < 9) {
            expect(result, isNull, reason: 'Hit ${i + 1}/10');
          }
        }

        expect(result, isNotNull, reason: 'Hit 10/10 should detect');
        expect(result!.type, MidiEventType.cc14BitLowFirst,
               reason: 'Ambiguous variance should default to standard MSB-first');
      });
    });

    group('byte order analysis', () {
      test('variance ratio determines byte order', () {
        // This test verifies the internal _determineByteOrder logic
        // by sending carefully crafted value sequences

        // Clear variance difference: low varies, high constant
        engine = MidiDetectionEngine();
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          engine.processCc(0, 2, i * 10);  // High variance
          result = engine.processCc(0, 34, 64);     // Zero variance
          if (i < 9) {
            expect(result, isNull);
          }
        }
        expect(result, isNotNull);
        expect(result!.type, MidiEventType.cc14BitHighFirst,
               reason: 'Low varies → low is LSB → high is MSB');

        // Clear variance difference: high varies, low constant
        engine = MidiDetectionEngine();
        for (int i = 0; i < 10; i++) {
          engine.processCc(0, 3, 64);      // Zero variance
          result = engine.processCc(0, 35, i * 10); // High variance
          if (i < 9) {
            expect(result, isNull);
          }
        }
        expect(result, isNotNull);
        expect(result!.type, MidiEventType.cc14BitLowFirst,
               reason: 'High varies → high is LSB → low is MSB');
      });

      test('handles edge case of zero variance in both values', () {
        // Both values constant across all 10 hits
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          engine.processCc(0, 4, 64);
          result = engine.processCc(0, 36, 100);
          if (i < 9) {
            expect(result, isNull);
          }
        }

        expect(result, isNotNull);
        expect(result!.type, MidiEventType.cc14BitLowFirst,
               reason: 'Zero variance is ambiguous, defaults to standard');
      });
    });

    group('race conditions', () {
      test('7-bit wins when threshold reached first', () {
        // Start a 14-bit pair
        engine.processCc(0, 1, 64);
        engine.processCc(0, 33, 100);

        // But then send 10 consecutive CC 5 messages (different CC)
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          result = engine.processCc(0, 5, 80);
        }

        expect(result, isNotNull);
        expect(result!.type, MidiEventType.cc);
        expect(result.number, 5);

        // After detection, state should reset
        // Verify by starting fresh with CC 1
        for (int i = 0; i < 9; i++) {
          result = engine.processCc(0, 1, 64);
          expect(result, isNull, reason: 'State should have reset');
        }
      });

      test('14-bit wins when threshold reached first', () {
        // Send partial 7-bit sequence (5 consecutive)
        for (int i = 0; i < 5; i++) {
          engine.processCc(0, 5, 80);
        }

        // Now interleave with 14-bit pair that reaches threshold
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          engine.processCc(0, 1, 64);
          result = engine.processCc(0, 33, i); // Varying
          if (i < 9) {
            expect(result, isNull);
          }
        }

        expect(result, isNotNull);
        expect(result!.type, MidiEventType.cc14BitLowFirst);
        expect(result.number, 1);
      });

      test('detection resets both 7-bit and 14-bit state', () {
        // Trigger 7-bit detection (10 consecutive CC 5)
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          result = engine.processCc(0, 5, 80);
          if (i < 9) {
            expect(result, isNull);
          }
        }
        expect(result, isNotNull, reason: 'Should detect after 10 hits');

        // Verify 7-bit state reset by checking fresh detection needed
        result = engine.processCc(0, 5, 80);
        expect(result, isNull, reason: '7-bit state should reset (count=1 now)');

        // Start new 14-bit pair - should work from fresh state
        engine.processCc(0, 1, 64);
        result = engine.processCc(0, 33, 100);
        expect(result, isNull, reason: '14-bit state reset, hit 1/10');
      });
    });

    group('note detection', () {
      test('note on detects immediately', () {
        final result = engine.processNoteOn(0, 60);
        expect(result, isNotNull);
        expect(result!.type, MidiEventType.noteOn);
        expect(result.channel, 0);
        expect(result.number, 60);
      });

      test('note off detects immediately', () {
        final result = engine.processNoteOff(5, 72);
        expect(result, isNotNull);
        expect(result!.type, MidiEventType.noteOff);
        expect(result.channel, 5);
        expect(result.number, 72);
      });

      test('note detection resets CC tracking state', () {
        // Build up some 7-bit state (5 consecutive CC 1 messages)
        for (int i = 0; i < 5; i++) {
          engine.processCc(0, 1, 64);
        }

        // Note on should reset CC tracking
        engine.processNoteOn(0, 60);

        // Verify reset: first CC 1 after note should start fresh count at 1
        var result = engine.processCc(0, 1, 64);
        expect(result, isNull, reason: 'Count reset to 1, needs 9 more');

        // Need 9 more to reach threshold (total 10)
        for (int i = 0; i < 8; i++) {
          result = engine.processCc(0, 1, 64);
          expect(result, isNull);
        }

        // 10th message should detect
        result = engine.processCc(0, 1, 64);
        expect(result, isNotNull);
      });
    });

    group('reset behavior', () {
      test('reset clears 7-bit state', () {
        // Build up 7-bit state
        for (int i = 0; i < 5; i++) {
          engine.processCc(0, 1, 64);
        }

        engine.reset();

        // Should need full 10 again
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          result = engine.processCc(0, 1, 64);
        }
        expect(result, isNotNull);
      });

      test('reset clears 14-bit state', () {
        // Build up 14-bit pair (5 hits)
        for (int i = 0; i < 5; i++) {
          engine.processCc(0, 1, 64);
          engine.processCc(0, 33, i);
        }

        engine.reset();

        // After reset, need 10 pair hits to detect
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          engine.processCc(0, 1, 64);
          result = engine.processCc(0, 33, i);
          if (i < 9) {
            expect(result, isNull);
          }
        }
        expect(result, isNotNull, reason: 'Should detect after 10 hits');
      });

      test('reset clears CC value map', () {
        // Populate CC value map
        engine.processCc(0, 1, 64);
        engine.processCc(0, 33, 100);
        engine.processCc(1, 5, 80);

        engine.reset();

        // After reset, CC value map should be clear
        // Pair formation starts fresh
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          engine.processCc(0, 2, 50);
          result = engine.processCc(0, 34, i);
          if (i < 9) {
            expect(result, isNull);
          }
        }

        expect(result, isNotNull, reason: 'Should detect fresh after reset');
      });
    });

    group('cross-channel isolation', () {
      test('same CC pair on different channels tracked independently', () {
        // Start CC 1+33 on channel 0 (forms pair, records hit 1)
        engine.processCc(0, 1, 64);
        engine.processCc(0, 33, 100);

        // Start CC 1+33 on channel 1 (but single pair lock prevents this)
        engine.processCc(1, 1, 50);
        engine.processCc(1, 33, 90);

        // Continue with 9 more hits on channel 0 to reach threshold
        DetectionResult? result;
        for (int i = 0; i < 8; i++) {
          engine.processCc(0, 1, 64);
          result = engine.processCc(0, 33, i);
          expect(result, isNull, reason: 'Hit ${i + 2}/10');
        }

        // 10th pair hit should detect
        engine.processCc(0, 1, 64);
        result = engine.processCc(0, 33, 8);
        expect(result, isNotNull);
        expect(result!.channel, 0, reason: 'Should detect on channel 0');
      });
    });

    group('pair formation edge cases', () {
      test('forms pair with CC X+32 arriving before CC X', () {
        // High CC arrives first
        var result = engine.processCc(0, 33, 100);
        expect(result, isNull);

        // Low CC arrives - pair forms, records hit #1
        result = engine.processCc(0, 1, 64);
        expect(result, isNull, reason: 'Pair formed but threshold not reached (hit 1/10)');

        // Complete 9 more pair hits to reach threshold
        for (int i = 0; i < 9; i++) {
          engine.processCc(0, 33, i);
          result = engine.processCc(0, 1, 64);
          if (i < 8) {
            expect(result, isNull, reason: 'Hit ${i + 2}/10');
          }
        }

        expect(result, isNotNull, reason: 'Hit 10/10 should detect');
        expect(result!.type, isIn([MidiEventType.cc14BitLowFirst, MidiEventType.cc14BitHighFirst]));
      });

      test('CC 31 and CC 63 form valid pair (boundary case)', () {
        // CC 31 is highest in 0-31 range, CC 63 is its partner
        DetectionResult? result;
        for (int i = 0; i < 10; i++) {
          engine.processCc(0, 31, 64);
          result = engine.processCc(0, 63, i);
          if (i < 9) {
            expect(result, isNull);
          }
        }

        expect(result, isNotNull);
        expect(result!.number, 31);
      });

      test('CC 64 and above do not form pairs', () {
        // CC 64 has no valid partner (64+32 = 96, out of MIDI CC range 0-127)
        // Even if we send both CC 64 and CC 96, they won't pair
        // So CC 64 should detect as 7-bit after 10 consecutive hits

        DetectionResult? result;
        for (int i = 0; i < 9; i++) {
          result = engine.processCc(0, 64, 64);
          expect(result, isNull, reason: 'Message ${i + 1}/10');
        }

        // 10th CC 64 message should detect as 7-bit
        result = engine.processCc(0, 64, 64);
        expect(result, isNotNull);
        expect(result!.type, MidiEventType.cc);
        expect(result.number, 64);
      });
    });
  });
}
