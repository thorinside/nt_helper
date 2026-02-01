import 'dart:math';

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
/// Tracks both 7-bit consecutive CC detection and 14-bit CC pair detection,
/// running them in parallel. First to reach threshold wins.
class MidiDetectionEngine {
  /// Number of consecutive hits required for detection.
  static const int kThreshold = 10;

  /// Variance ratio threshold for byte order ambiguity.
  ///
  /// Ratios within [kAmbiguityThreshold, 1/kAmbiguityThreshold] are ambiguous.
  static const double kAmbiguityThreshold = 0.8;

  // --- 7-bit state ---
  ({MidiEventType type, int channel, int number})? _lastEventSignature;
  int _consecutiveCount = 0;

  // --- 14-bit state ---
  /// Track latest value per (channel, ccNumber) for pair detection.
  final Map<(int, int), int> _ccValues = {};

  /// Active pair tracker (nullable - only one pair at a time).
  _PairTracker? _activePair;

  /// Process a CC message.
  ///
  /// Returns [DetectionResult] when threshold is reached, null otherwise.
  DetectionResult? processCc(int channel, int ccNumber, int ccValue) {
    // 1. Exclude Bank Select (CC0/CC32) from 14-bit pairing
    final bool isBankSelect = ccNumber == 0 || ccNumber == 32;

    // 2. Update CC value state
    _ccValues[(channel, ccNumber)] = ccValue;

    // 3. Update 14-bit pair tracker (if not Bank Select)
    if (!isBankSelect) {
      _update14BitTracker(channel, ccNumber, ccValue);
    }

    // 4. Update 7-bit consecutive tracker
    final signature =
        (type: MidiEventType.cc, channel: channel, number: ccNumber);
    if (signature == _lastEventSignature) {
      _consecutiveCount++;
    } else {
      _lastEventSignature = signature;
      _consecutiveCount = 1;
    }

    // 5. Check thresholds - 14-bit first (more specific wins on tie)
    if (_activePair != null && _activePair!.hitCount >= kThreshold) {
      final result = _build14BitResult();
      _resetDetectionState();
      return result;
    }
    if (_consecutiveCount >= kThreshold) {
      final result = DetectionResult(
        type: MidiEventType.cc,
        channel: channel,
        number: ccNumber,
      );
      _resetDetectionState();
      return result;
    }

    return null;
  }

  /// Process a Note On message.
  ///
  /// Returns [DetectionResult] immediately (notes have threshold of 1).
  DetectionResult? processNoteOn(int channel, int note) {
    final result = DetectionResult(
      type: MidiEventType.noteOn,
      channel: channel,
      number: note,
    );
    _resetDetectionState();
    return result;
  }

  /// Process a Note Off message.
  ///
  /// Returns [DetectionResult] immediately.
  DetectionResult? processNoteOff(int channel, int note) {
    final result = DetectionResult(
      type: MidiEventType.noteOff,
      channel: channel,
      number: note,
    );
    _resetDetectionState();
    return result;
  }

  /// Reset all tracking state.
  ///
  /// Clears detection state and CC value map.
  void reset() {
    _resetDetectionState();
    _ccValues.clear();
  }

  // --- Private methods ---

  /// Update 14-bit pair tracker based on incoming CC.
  void _update14BitTracker(int channel, int ccNumber, int ccValue) {
    if (_activePair == null) {
      // No active pair - try to form one
      _tryFormPair(channel, ccNumber);
    } else {
      // Active pair exists - check if this CC matches
      _updateActivePair(channel, ccNumber, ccValue);
    }
  }

  /// Try to form a 14-bit pair from the current CC.
  void _tryFormPair(int channel, int ccNumber) {
    // Check if this CC has a partner in the value map
    int? partnerCc;
    int? lowCc;
    int? highCc;

    if (ccNumber < 32) {
      // This is a potential low CC (0-31), check for high CC (32-63)
      partnerCc = ccNumber + 32;
      lowCc = ccNumber;
      highCc = partnerCc;
    } else if (ccNumber >= 32 && ccNumber < 64) {
      // This is a potential high CC (32-63), check for low CC (0-31)
      partnerCc = ccNumber - 32;
      lowCc = partnerCc;
      highCc = ccNumber;
    }

    // If partner exists in value map on same channel, lock the pair
    if (partnerCc != null &&
        lowCc != null &&
        highCc != null &&
        _ccValues.containsKey((channel, partnerCc))) {
      _activePair = _PairTracker(
        channel: channel,
        lowCc: lowCc,
        highCc: highCc,
      );

      // Mark this CC as seen
      if (ccNumber == lowCc) {
        _activePair!.lowSeen = true;
      } else {
        _activePair!.highSeen = true;
      }

      // Both CCs have already arrived (partner exists in map), so record first hit
      final lowValue = _ccValues[(channel, lowCc)]!;
      final highValue = _ccValues[(channel, highCc)]!;
      _activePair!.valueSamples.add((low: lowValue, high: highValue));
      _activePair!.hitCount = 1;

      // Reset seen flags for next hit cycle
      _activePair!.lowSeen = false;
      _activePair!.highSeen = false;
    }
  }

  /// Update active pair with incoming CC.
  void _updateActivePair(int channel, int ccNumber, int ccValue) {
    final pair = _activePair!;

    // Only process if this CC is part of the active pair on the correct channel
    if (channel != pair.channel) {
      return;
    }

    if (ccNumber == pair.lowCc) {
      pair.lowSeen = true;
    } else if (ccNumber == pair.highCc) {
      pair.highSeen = true;
    } else {
      // This CC is not part of the active pair - ignore for 14-bit
      return;
    }

    // If both sides seen, increment hit count and record sample
    if (pair.lowSeen && pair.highSeen) {
      final lowValue = _ccValues[(channel, pair.lowCc)]!;
      final highValue = _ccValues[(channel, pair.highCc)]!;

      pair.valueSamples.add((low: lowValue, high: highValue));
      pair.hitCount++;

      // Reset seen flags for next hit cycle
      pair.lowSeen = false;
      pair.highSeen = false;
    }
  }

  /// Build 14-bit detection result from active pair.
  DetectionResult _build14BitResult() {
    final pair = _activePair!;
    final byteOrder = determineByteOrder(pair.valueSamples);

    return DetectionResult(
      type: byteOrder,
      channel: pair.channel,
      number: pair.lowCc, // Base CC (lower number)
    );
  }

  /// Determine byte order from value samples using variance ratio.
  static MidiEventType determineByteOrder(
    List<({int low, int high})> samples,
  ) {
    if (samples.isEmpty) {
      return MidiEventType.cc14BitLowFirst; // Default
    }

    // Calculate variance for low and high values
    final lowValues = samples.map((s) => s.low.toDouble()).toList();
    final highValues = samples.map((s) => s.high.toDouble()).toList();

    final lowVariance = _calculateVariance(lowValues);
    final highVariance = _calculateVariance(highValues);

    // Avoid division by zero with small epsilon
    const epsilon = 0.001;
    final ratio = lowVariance / (highVariance + epsilon);

    // If low varies more (ratio > 1/threshold), low is LSB → high is MSB
    if (ratio > 1 / kAmbiguityThreshold) {
      return MidiEventType.cc14BitHighFirst;
    }

    // If high varies more (ratio < threshold), high is LSB → low is MSB
    if (ratio < kAmbiguityThreshold) {
      return MidiEventType.cc14BitLowFirst;
    }

    // Ambiguous - default to standard MSB-first (low = MSB)
    return MidiEventType.cc14BitLowFirst;
  }

  /// Calculate variance of a list of values.
  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) {
      return 0.0;
    }

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  /// Reset detection state (both 7-bit and 14-bit).
  ///
  /// Preserves CC value map for re-detection performance.
  void _resetDetectionState() {
    // Reset 7-bit state
    _lastEventSignature = null;
    _consecutiveCount = 0;

    // Reset 14-bit state
    _activePair = null;
  }
}

/// Internal tracker for 14-bit CC pair detection.
class _PairTracker {
  final int channel;
  final int lowCc; // 0-31
  final int highCc; // 32-63

  int hitCount = 0;
  bool lowSeen = false;
  bool highSeen = false;

  final List<({int low, int high})> valueSamples = [];

  _PairTracker({
    required this.channel,
    required this.lowCc,
    required this.highCc,
  });
}
