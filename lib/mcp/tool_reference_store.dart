import 'dart:convert';

class ToolReferenceStore {
  static const referenceThresholdChars = 20000;
  static const defaultReadLimitChars = 8000;
  static const maxReadLimitChars = 16000;
  static const defaultSearchLimit = 20;
  static const maxSearchLimit = 50;
  static const defaultSearchContextChars = 120;
  static const maxSearchContextChars = 500;
  static const maxReferences = 32;

  static const readToolName = 'read_reference';
  static const searchToolName = 'search_reference';

  final _references = <String, _ToolReference>{};
  int _counter = 0;

  bool get isEmpty => _references.isEmpty;

  void clear() {
    _references.clear();
  }

  bool shouldReference(String toolName, String result) {
    if (toolName == readToolName || toolName == searchToolName) return false;
    return result.length > referenceThresholdChars;
  }

  String storeIfLarge({required String toolName, required String result}) {
    if (!shouldReference(toolName, result)) return result;
    final reference = _store(toolName: toolName, content: result);
    return jsonEncode({
      'success': true,
      'type': 'tool_reference',
      'reference_id': reference.id,
      'tool_name': reference.toolName,
      'total_chars': reference.content.length,
      'instructions':
          'This tool result was stored as a reference because it is large. '
          'Use read_reference with reference_id to page through it, or '
          'search_reference with reference_id and query to find relevant parts.',
    });
  }

  Future<String> readReference(Map<String, dynamic> args) async {
    final reference = _lookup(args['reference_id']);
    if (reference == null) {
      return _error('reference_not_found');
    }

    final offset = _intArg(args['offset'], fallback: 0, min: 0);
    final limit = _intArg(
      args['limit'],
      fallback: defaultReadLimitChars,
      min: 1,
      max: maxReadLimitChars,
    );
    if (offset >= reference.content.length) {
      return jsonEncode({
        'success': true,
        'reference_id': reference.id,
        'tool_name': reference.toolName,
        'offset': offset,
        'limit': limit,
        'content': '',
        'total_chars': reference.content.length,
        'has_more': false,
        'next_offset': null,
      });
    }

    final end = (offset + limit).clamp(0, reference.content.length);
    return jsonEncode({
      'success': true,
      'reference_id': reference.id,
      'tool_name': reference.toolName,
      'offset': offset,
      'limit': limit,
      'content': reference.content.substring(offset, end),
      'total_chars': reference.content.length,
      'has_more': end < reference.content.length,
      'next_offset': end < reference.content.length ? end : null,
    });
  }

  Future<String> searchReference(Map<String, dynamic> args) async {
    final reference = _lookup(args['reference_id']);
    if (reference == null) {
      return _error('reference_not_found');
    }

    final query = args['query'];
    if (query is! String || query.trim().isEmpty) {
      return _error('missing_query');
    }

    final startOffset = _intArg(args['start_offset'], fallback: 0, min: 0);
    final limit = _intArg(
      args['limit'],
      fallback: defaultSearchLimit,
      min: 1,
      max: maxSearchLimit,
    );
    final contextChars = _intArg(
      args['context_chars'],
      fallback: defaultSearchContextChars,
      min: 0,
      max: maxSearchContextChars,
    );

    final content = reference.content;
    final lowerContent = content.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <Map<String, dynamic>>[];
    var searchFrom = startOffset.clamp(0, content.length);

    while (matches.length < limit && searchFrom < content.length) {
      final matchOffset = lowerContent.indexOf(lowerQuery, searchFrom);
      if (matchOffset < 0) break;
      final previewStart = (matchOffset - contextChars).clamp(
        0,
        content.length,
      );
      final previewEnd = (matchOffset + query.length + contextChars).clamp(
        0,
        content.length,
      );
      matches.add({
        'offset': matchOffset,
        'preview': content.substring(previewStart, previewEnd),
      });
      searchFrom = matchOffset + query.length;
    }

    return jsonEncode({
      'success': true,
      'reference_id': reference.id,
      'tool_name': reference.toolName,
      'query': query,
      'matches': matches,
      'truncated': matches.length >= limit,
      'next_start_offset': matches.length >= limit ? searchFrom : null,
      'total_chars': content.length,
    });
  }

  _ToolReference _store({required String toolName, required String content}) {
    if (_references.length >= maxReferences) {
      _references.remove(_references.keys.first);
    }
    final id = 'ref_${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
    final reference = _ToolReference(
      id: id,
      toolName: toolName,
      content: content,
    );
    _references[id] = reference;
    return reference;
  }

  _ToolReference? _lookup(Object? rawId) {
    if (rawId is! String || rawId.isEmpty) return null;
    return _references[rawId];
  }

  static int _intArg(
    Object? value, {
    required int fallback,
    int? min,
    int? max,
  }) {
    final parsed = switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v),
      _ => null,
    };
    var result = parsed ?? fallback;
    if (min != null && result < min) result = min;
    if (max != null && result > max) result = max;
    return result;
  }

  static String _error(String error) {
    return jsonEncode({'success': false, 'error': error});
  }
}

class _ToolReference {
  const _ToolReference({
    required this.id,
    required this.toolName,
    required this.content,
  });

  final String id;
  final String toolName;
  final String content;
}
