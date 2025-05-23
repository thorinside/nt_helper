import 'dart:convert';

String _stringToSnakeCase(String input) {
  if (input.isEmpty) return '';
  // Add underscore before uppercase letters that are not at the start,
  // or are part of an acronym sequence (e.g. HTTPRequest -> HTTP_Request)
  // then convert to lowercase.
  // Handles camelCase, PascalCase.
  // Simpler version: insert underscore before any capital letter not at the start.
  // More robust: handle sequences of capitals (acronyms) by inserting underscore
  // only when a capital is followed by a lowercase, or a lowercase/digit is followed by a capital.

  // This regex handles:
  // 1. A lowercase letter or digit followed by an uppercase letter (e.g., myValue -> my_Value)
  // 2. An uppercase letter followed by an uppercase letter and then a lowercase letter (e.g., HTTPRequest -> HTTP_Request)
  String result = input
      .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'), (Match m) => '${m[1]}_${m[2]}')
      .replaceAllMapped(
          RegExp(r'([A-Z])([A-Z][a-z])'), (Match m) => '${m[1]}_${m[2]}');
  return result.toLowerCase();
}

Object? convertToSnakeCaseKeys(Object? data) {
  if (data is Map<String, dynamic>) {
    final Map<String, dynamic> newMap = {};
    data.forEach((key, value) {
      newMap[_stringToSnakeCase(key)] = convertToSnakeCaseKeys(value);
    });
    return newMap;
  } else if (data is List) {
    return data.map((item) => convertToSnakeCaseKeys(item)).toList();
  } else {
    return data;
  }
}
