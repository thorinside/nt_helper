import 'dart:math';

bool isVersionUnsupported(String currentVersion, String minimumSupportedVersion) {
  final current = parseVersion(currentVersion);
  final minimum = parseVersion(minimumSupportedVersion);
  final length = max(current.length, minimum.length);

  for (var i = 0; i < length; i++) {
    // Use 0 as the default for missing segments.
    final seg1 = i < current.length ? current[i] : 0;
    final seg2 = i < minimum.length ? minimum[i] : 0;
    if (seg1 != seg2) return seg1 < seg2;
  }
  return false; // Versions are equal or currentVersion is higher.
}

List<int> parseVersion(String version) => version
    .split('.')
    .map((part) => int.tryParse(part.replaceAll(RegExp(r'\D'), '')) ?? 0)
    .toList();
