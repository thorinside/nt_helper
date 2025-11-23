/// Scale quantization service for musical pitch mapping
///
/// Provides static methods to quantize MIDI note values to musical scales.
/// This is a UI-only composition aid - quantized values are not persisted
/// to hardware. The hardware stores raw MIDI note values.
///
/// Supports 11 scales: Chromatic, Major, Minor, Dorian, Phrygian, Lydian,
/// Mixolydian, Aeolian, Locrian, Pentatonic Major, and Pentatonic Minor.
class ScaleQuantizer {
  /// Map of scale names to their interval patterns (semitones from root)
  ///
  /// Each scale is defined as a list of integers representing semitone intervals
  /// from the root note. For example, Major scale = [0,2,4,5,7,9,11] represents
  /// the intervals: Root, Whole, Whole, Half, Whole, Whole, Whole.
  static const Map<String, List<int>> scales = {
    'Chromatic': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    'Major': [0, 2, 4, 5, 7, 9, 11],
    'Minor': [0, 2, 3, 5, 7, 8, 10],
    'Dorian': [0, 2, 3, 5, 7, 9, 10],
    'Phrygian': [0, 1, 3, 5, 7, 8, 10],
    'Lydian': [0, 2, 4, 6, 7, 9, 11],
    'Mixolydian': [0, 2, 4, 5, 7, 9, 10],
    'Aeolian': [0, 2, 3, 5, 7, 8, 10],
    'Locrian': [0, 1, 3, 5, 6, 8, 10],
    'Pentatonic Major': [0, 2, 4, 7, 9],
    'Pentatonic Minor': [0, 3, 5, 7, 10],
  };

  /// Quantizes a MIDI note to the nearest degree of the specified scale
  ///
  /// [midiNote] The input MIDI note value (0-127)
  /// [scale] The scale name (must exist in [scales] map)
  /// [root] The root note (0-11, where 0=C, 1=C#, 2=D, etc.)
  ///
  /// Returns the quantized MIDI note value.
  ///
  /// Algorithm:
  /// 1. Extract the note class (0-11) and octave from the input MIDI note
  /// 2. Transpose the scale intervals to the specified root note
  /// 3. Find the scale degree closest to the input note class
  /// 4. Reconstruct the MIDI note from the quantized note class and original octave
  ///
  /// Example:
  /// ```dart
  /// // Quantize C# (61) to C Major
  /// final quantized = ScaleQuantizer.quantize(61, 'Major', 0);
  /// // Result: 60 (C) or 62 (D), whichever is closer
  /// ```
  static int quantize(int midiNote, String scale, int root) {
    // Ensure MIDI note is in valid range
    if (midiNote < 0) return 0;
    if (midiNote > 127) return 127;

    // Ensure root is in valid range (0-11)
    final normalizedRoot = root.clamp(0, 11);

    // Extract note class (0-11) and octave from MIDI note
    final noteClass = midiNote % 12;
    final octave = midiNote ~/ 12;

    // Get scale intervals, defaulting to Chromatic if scale not found
    final scaleIntervals = scales[scale] ?? scales['Chromatic']!;

    // Transpose scale to the specified root note
    final transposedScale = scaleIntervals
        .map((interval) => (interval + normalizedRoot) % 12)
        .toList();

    // Find the nearest scale degree
    int nearest = transposedScale.first;
    int minDistance = (noteClass - nearest).abs();

    for (final degree in transposedScale) {
      final distance = (noteClass - degree).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearest = degree;
      }
    }

    // Reconstruct MIDI note from quantized note class and original octave
    final quantized = (octave * 12) + nearest;

    // Ensure result is within MIDI range
    return quantized.clamp(0, 127);
  }

  /// Get a list of all available scale names
  static List<String> get scaleNames => scales.keys.toList();

  /// Get the intervals for a specific scale
  ///
  /// Returns null if the scale doesn't exist
  static List<int>? getScaleIntervals(String scale) => scales[scale];

  /// Check if a scale name exists
  static bool hasScale(String scale) => scales.containsKey(scale);
}
