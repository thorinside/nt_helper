import 'dart:math';

String cleanTitle(String name) {
  // If name starts with a number followed by a colon, strip that off
  final RegExp regex = RegExp(r'^\d+:\s*');
  return name.replaceAll(regex, '');
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
  return '${((currentValue / pow(10, powerOfTen)).toStringAsFixed(powerOfTen))} $trimmedUnit';
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
