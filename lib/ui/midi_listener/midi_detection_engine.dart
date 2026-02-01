import 'midi_listener_cubit.dart';

/// Result of MIDI event detection.
class DetectionResult {
  /// The detected event type.
  final MidiEventType type;

  /// MIDI channel (0-15).
  final int channel;

  /// CC number (for CC types) or note number (for note types).
  final int number;

  const DetectionResult({
    required this.type,
    required this.channel,
    required this.number,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectionResult &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          channel == other.channel &&
          number == other.number;

  @override
  int get hashCode => Object.hash(type, channel, number);

  @override
  String toString() =>
      'DetectionResult(type: $type, channel: $channel, number: $number)';
}

/// Standalone engine for detecting MIDI CC and note patterns.
///
/// Uses a sliding buffer of the last 10 CC events. When the buffer is full,
/// it analyzes the contents to detect 7-bit or 14-bit CC patterns.
class MidiDetectionEngine {
  /// Number of CC events required in the buffer for detection.
  static const int kBufferSize = 10;

  /// Sliding window of recent CC events.
  final List<({int channel, int cc})> _buffer = [];

  /// Process a CC message.
  ///
  /// Returns [DetectionResult] when a pattern is detected, null otherwise.
  DetectionResult? processCc(int channel, int ccNumber, int ccValue) {
    _buffer.add((channel: channel, cc: ccNumber));
    if (_buffer.length > kBufferSize) {
      _buffer.removeAt(0);
    }

    if (_buffer.length < kBufferSize) {
      return null;
    }

    return _analyze();
  }

  /// Process a Note On message.
  ///
  /// Returns [DetectionResult] immediately (notes have threshold of 1).
  DetectionResult? processNoteOn(int channel, int note) {
    _buffer.clear();
    return DetectionResult(
      type: MidiEventType.noteOn,
      channel: channel,
      number: note,
    );
  }

  /// Process a Note Off message.
  ///
  /// Returns [DetectionResult] immediately.
  DetectionResult? processNoteOff(int channel, int note) {
    _buffer.clear();
    return DetectionResult(
      type: MidiEventType.noteOff,
      channel: channel,
      number: note,
    );
  }

  /// Reset all tracking state.
  void reset() {
    _buffer.clear();
  }

  /// Analyze the buffer for 7-bit or 14-bit CC patterns.
  DetectionResult? _analyze() {
    final channels = _buffer.map((e) => e.channel).toSet();
    if (channels.length != 1) {
      return null;
    }
    final channel = channels.first;

    final uniqueCCs = _buffer.map((e) => e.cc).toSet();

    if (uniqueCCs.length == 1) {
      // All same CC → 7-bit detection
      final result = DetectionResult(
        type: MidiEventType.cc,
        channel: channel,
        number: uniqueCCs.first,
      );
      _buffer.clear();
      return result;
    }

    if (uniqueCCs.length == 2) {
      final sorted = uniqueCCs.toList()..sort();
      final low = sorted[0];
      final high = sorted[1];

      // Must be exactly 32 apart, and lower CC must be < 32
      if (high - low == 32 && low < 32) {
        // Determine byte order by which CC appears first in the buffer
        final firstCc = _buffer.first.cc;
        final type = firstCc == low
            ? MidiEventType.cc14BitLowFirst
            : MidiEventType.cc14BitHighFirst;

        final result = DetectionResult(
          type: type,
          channel: channel,
          number: low,
        );
        _buffer.clear();
        return result;
      }
    }

    return null;
  }
}
