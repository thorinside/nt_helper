import 'dart:convert';

/// Tries to parse a JSON tool result as an image.
///
/// Returns the base64 data and MIME type if the JSON has a `type` field
/// starting with `image/` and a `data` field. Otherwise returns null.
({String data, String mimeType})? tryParseImageResult(String json) {
  try {
    final parsed = jsonDecode(json);
    if (parsed is! Map<String, dynamic>) return null;
    final type = parsed['type'];
    if (type is! String || !type.startsWith('image/')) return null;
    final data = parsed['data'];
    if (data is! String || data.isEmpty) return null;
    return (data: data, mimeType: type);
  } catch (_) {
    return null;
  }
}
