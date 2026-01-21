import 'dart:math';

String cleanTitle(String name) {
  // Return the full parameter name as-is.
  // The parameterUiPrefix API allows arbitrary prefixes (not just "N:"),
  // so the entire name is significant and should be displayed.
  return name;
}

String formatWithUnit(
  int currentValue, {
  required int min,
  required int max,
  required String name,
  String? unit,
  required int powerOfTen,
}) {
  if (unit == null || unit.isEmpty) return currentValue.toString();

  final trimmedUnit = unit.trim();
  final decimalPlaces = powerOfTen.abs();
  return '${((currentValue * pow(10, powerOfTen)).toStringAsFixed(decimalPlaces))} $trimmedUnit';
}

String midiNoteToNoteString(int midiNoteNumber) {
  if (midiNoteNumber == -1) return "";

  if (midiNoteNumber < 0 || midiNoteNumber > 127) {
    throw ArgumentError('MIDI note number must be between 0 and 127.');
  }

  // Note names
  List<String> noteNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  // Calculate the octave and note index
  int octave = (midiNoteNumber ~/ 12) - 1;
  String note = noteNames[midiNoteNumber % 12];

  return '$note$octave';
}
