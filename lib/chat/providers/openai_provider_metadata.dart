/// Opaque reasoning/signature fields are only returned to the endpoint/model
/// that produced them. They are data, never instructions or authentication.
Map<String, dynamic> scopedOpenAIMetadata(
  String endpoint,
  String model,
  Map<String, dynamic> fields,
) => fields.isEmpty
    ? const {}
    : {
        'openaiCompatible': {
          'endpoint': endpoint,
          'model': model,
          'fields': fields,
        },
      };

Map<String, dynamic> openAIFieldsFor(
  Map<String, dynamic> metadata,
  String endpoint,
  String model,
) {
  final value = metadata['openaiCompatible'];
  if (value is! Map ||
      value['endpoint'] != endpoint ||
      value['model'] != model ||
      value['fields'] is! Map) {
    return const {};
  }
  return Map<String, dynamic>.from(value['fields'] as Map);
}

Map<String, dynamic> openAIMessageExtras(Map<String, dynamic> message) => {
  for (final key in ['reasoning_details', 'reasoning_content', 'extra_content'])
    if (message[key] != null) key: message[key],
};

Map<String, dynamic> openAIToolExtras(Map<String, dynamic> call) {
  final function = call['function'] as Map? ?? const {};
  final extraFunction = {
    for (final key in function.keys)
      if (key != 'name' && key != 'arguments') '$key': function[key],
  };
  return {
    for (final key in call.keys)
      if (!['index', 'id', 'type', 'function'].contains(key)) key: call[key],
    if (extraFunction.isNotEmpty) 'function': extraFunction,
  };
}

/// Streaming reasoning_details are indexed fragments; nested Google signatures
/// arrive as complete extra_content values and must not be concatenated.
void mergeOpenAIExtras(
  Map<String, dynamic> target,
  Map<String, dynamic> incoming,
) {
  for (final entry in incoming.entries) {
    final value = entry.value;
    if (entry.key == 'reasoning_details' && value is List) {
      final details = List<dynamic>.of(target[entry.key] as List? ?? const []);
      for (final fragment in value) {
        if (fragment is! Map || fragment['index'] == null) {
          details.add(fragment);
          continue;
        }
        final index = details.indexWhere(
          (d) =>
              d is Map &&
              d['index'] == fragment['index'] &&
              d['type'] == fragment['type'],
        );
        if (index < 0) {
          details.add(Map<String, dynamic>.from(fragment));
          continue;
        }
        final current = Map<String, dynamic>.from(details[index] as Map);
        for (final key in fragment.keys) {
          final next = fragment[key];
          current['$key'] =
              const ['text', 'summary', 'data', 'signature'].contains(key) &&
                  current[key] is String &&
                  next is String
              ? '${current[key]}$next'
              : next;
        }
        details[index] = current;
      }
      target[entry.key] = details;
    } else if (value is Map) {
      final nested = Map<String, dynamic>.from(
        target[entry.key] as Map? ?? const {},
      );
      mergeOpenAIExtras(nested, Map<String, dynamic>.from(value));
      target[entry.key] = nested;
    } else if (entry.key == 'reasoning_content' && value is String) {
      target[entry.key] = '${target[entry.key] ?? ''}$value';
    } else {
      target[entry.key] = value;
    }
  }
}
