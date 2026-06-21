import 'dart:math';

bool isEditableNumericParameterValue({
  required bool enabled,
  required String name,
  required String? unit,
  required String? displayString,
  required List<String>? dropdownItems,
  required bool isOnOff,
  required bool isBpmUnit,
  required bool hasFileEditor,
}) {
  if (!enabled) return false;
  if (isBpmUnit || hasFileEditor) return false;
  if (isOnOff) return false;
  if (dropdownItems != null) return false;
  if (name.toLowerCase().contains("note") && unit != "%") return false;
  if (name.toLowerCase().contains("midi channel")) return false;
  if (displayString != null) return false;
  return true;
}

String formatEditableNumericValue(int value, int powerOfTen) {
  if (powerOfTen < 0) {
    final scaled = value * pow(10, powerOfTen);
    return scaled.toStringAsFixed(powerOfTen.abs());
  }
  return (value * pow(10, powerOfTen)).round().toString();
}

int? parseEditableNumericValue({
  required String text,
  required int min,
  required int max,
  required int powerOfTen,
}) {
  final parsed = double.tryParse(text.trim());
  if (parsed == null) return null;
  final raw = (parsed / pow(10, powerOfTen)).round();
  return raw.clamp(min, max);
}

RegExp editableNumericInputPattern({
  required int min,
  required int powerOfTen,
}) {
  final hasDecimal = powerOfTen < 0;
  final allowNegative = min < 0;

  if (allowNegative && hasDecimal) return RegExp(r'[-\d.]');
  if (allowNegative) return RegExp(r'[-\d]');
  if (hasDecimal) return RegExp(r'[\d.]');
  return RegExp(r'\d');
}
