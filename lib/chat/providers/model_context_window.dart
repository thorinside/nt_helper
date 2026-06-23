import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ModelContextWindow {
  static const defaultTokens = 100000;

  static int? parseMetadataResponse(Object? decoded, {String? model}) {
    if (decoded is Map<String, dynamic>) {
      final direct = parseMetadata(decoded);
      if (direct != null) return direct;

      for (final key in const ['data', 'models']) {
        final parsed = _parseModelList(decoded[key], model: model);
        if (parsed != null) return parsed;
      }
    }

    return _parseModelList(decoded, model: model);
  }

  static int? parseMetadata(Map<String, dynamic> json) {
    for (final key in const [
      'max_input_tokens',
      'context_window',
      'context_window_tokens',
      'context_length',
      'max_context_window',
      'max_context_tokens',
      'input_token_limit',
    ]) {
      final value = _positiveInt(json[key]);
      if (value != null) return value;
    }

    final capabilities = json['capabilities'];
    if (capabilities is Map<String, dynamic>) {
      for (final key in const [
        'max_input_tokens',
        'context_window',
        'context_window_tokens',
        'context_length',
        'max_context_window',
      ]) {
        final value = _positiveInt(capabilities[key]);
        if (value != null) return value;
      }
    }

    return null;
  }

  static int? _parseModelList(Object? value, {String? model}) {
    if (value is! List) return null;

    final normalizedModel = model?.toLowerCase();
    for (final item in value) {
      if (item is! Map<String, dynamic>) continue;
      if (normalizedModel != null) {
        final id = item['id'] ?? item['model'] ?? item['slug'];
        if (id is String && id.toLowerCase() != normalizedModel) continue;
      }
      final parsed = parseMetadata(item);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static int? _positiveInt(Object? value) {
    final parsed = switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v),
      _ => null,
    };
    return parsed != null && parsed > 0 ? parsed : null;
  }
}

class OpenAIContextWindowResolver {
  static final Map<String, int> _metadataCache = {};

  static Future<int?> resolve({
    required String model,
    required String baseUrl,
    required String apiKey,
    required http.Client client,
  }) async {
    final cacheKey = 'openai:$baseUrl:$model';
    final cached = _metadataCache[cacheKey];
    if (cached != null) return cached;

    final queried = await _queryModelMetadata(
      model: model,
      baseUrl: baseUrl,
      apiKey: apiKey,
      client: client,
    );
    if (queried != null) {
      _metadataCache[cacheKey] = queried;
      return queried;
    }

    final inferred = infer(model);
    if (inferred != null) {
      _metadataCache[cacheKey] = inferred;
    }
    return inferred;
  }

  static int? infer(String model) {
    final normalized = model.toLowerCase();
    if (normalized.startsWith('gpt-5.5') ||
        normalized == 'gpt-5.4' ||
        normalized.startsWith('gpt-5.4-20') ||
        normalized.startsWith('gpt-4.1')) {
      return 1000000;
    }
    if (normalized.startsWith('gpt-5.4-mini') ||
        normalized.startsWith('gpt-5.4-nano')) {
      return 400000;
    }
    if (normalized.startsWith('gpt-5') ||
        normalized.startsWith('gpt-4o') ||
        normalized.startsWith('o1') ||
        normalized.startsWith('o3') ||
        normalized.startsWith('o4')) {
      return 128000;
    }
    return null;
  }

  static Future<int?> resolveSubscription({
    required String model,
    required Map<String, String> headers,
    required http.Client client,
    required String clientVersion,
    String baseUrl = 'https://chatgpt.com/backend-api/codex/responses',
  }) async {
    final cacheKey = 'openai-subscription:$baseUrl:$clientVersion:$model';
    final cached = _metadataCache[cacheKey];
    if (cached != null) return cached;

    final queried = await _querySubscriptionModelMetadata(
      model: model,
      baseUrl: baseUrl,
      headers: headers,
      client: client,
      clientVersion: clientVersion,
    );
    if (queried != null) {
      _metadataCache[cacheKey] = queried;
      return queried;
    }

    final inferred = inferSubscription(model);
    if (inferred != null) {
      _metadataCache[cacheKey] = inferred;
    }
    return inferred;
  }

  static int? inferSubscription(String model) {
    final normalized = model.toLowerCase();
    if (normalized.startsWith('gpt-5.5')) {
      return 272000;
    }
    if (normalized == 'gpt-5.4' ||
        normalized.startsWith('gpt-5.4-20') ||
        normalized.startsWith('gpt-4.1')) {
      return 1000000;
    }
    if (normalized.startsWith('gpt-5.4-mini') ||
        normalized.startsWith('gpt-5.4-nano')) {
      return 400000;
    }
    if (normalized.startsWith('gpt-5') ||
        normalized.startsWith('gpt-4o') ||
        normalized.startsWith('o1') ||
        normalized.startsWith('o3') ||
        normalized.startsWith('o4')) {
      return 128000;
    }
    return null;
  }

  static Future<int?> _queryModelMetadata({
    required String model,
    required String baseUrl,
    required String apiKey,
    required http.Client client,
  }) async {
    final uri = _modelMetadataUri(baseUrl, model);
    if (uri == null) return null;

    try {
      final response = await client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 2));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final parsed = jsonDecode(response.body);
      return ModelContextWindow.parseMetadataResponse(parsed, model: model);
    } on Object {
      return null;
    }
  }

  static Future<int?> _querySubscriptionModelMetadata({
    required String model,
    required String baseUrl,
    required Map<String, String> headers,
    required http.Client client,
    required String clientVersion,
  }) async {
    for (final uri in _subscriptionModelMetadataUris(
      baseUrl,
      model,
      clientVersion,
    )) {
      try {
        final response = await client
            .get(uri, headers: {'Content-Type': 'application/json', ...headers})
            .timeout(const Duration(seconds: 2));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          continue;
        }
        final parsed = jsonDecode(response.body);
        final contextWindow = ModelContextWindow.parseMetadataResponse(
          parsed,
          model: model,
        );
        if (contextWindow != null) return contextWindow;
      } on Object {
        continue;
      }
    }
    return null;
  }

  static Uri? _modelMetadataUri(String baseUrl, String model) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;

    var path = uri.path;
    for (final suffix in const ['/chat/completions', '/responses']) {
      if (path.endsWith(suffix)) {
        path = path.substring(0, path.length - suffix.length);
        break;
      }
    }
    if (path.isEmpty) path = '/';
    if (!path.endsWith('/')) path = '$path/';

    return uri
        .replace(path: path, query: null, fragment: null)
        .resolve('models/${Uri.encodeComponent(model)}');
  }

  static List<Uri> _subscriptionModelMetadataUris(
    String baseUrl,
    String model,
    String clientVersion,
  ) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return const [];

    var path = uri.path;
    if (path.endsWith('/responses')) {
      path = path.substring(0, path.length - '/responses'.length);
    }
    if (path.isEmpty) path = '/';
    if (!path.endsWith('/')) path = '$path/';

    final base = uri.replace(path: path, query: null, fragment: null);
    return [
      base
          .resolve('models')
          .replace(
            queryParameters: {'model': model, 'client_version': clientVersion},
          ),
    ];
  }
}

class AnthropicContextWindowResolver {
  static final Map<String, int> _metadataCache = {};
  static const _modelsBaseUrl = 'https://api.anthropic.com/v1/models';

  static Future<int?> resolveWithApiKey({
    required String model,
    required String apiKey,
    required String apiVersion,
    required http.Client client,
  }) {
    return _resolve(
      cacheKey: 'anthropic-api-key:$model',
      model: model,
      headers: {'x-api-key': apiKey, 'anthropic-version': apiVersion},
      client: client,
    );
  }

  static Future<int?> resolveWithBearerToken({
    required String model,
    required String token,
    required String apiVersion,
    required String betaHeader,
    required http.Client client,
  }) {
    return _resolve(
      cacheKey: 'anthropic-bearer:$model',
      model: model,
      headers: {
        'Authorization': 'Bearer $token',
        'anthropic-version': apiVersion,
        'anthropic-beta': betaHeader,
      },
      client: client,
    );
  }

  static Future<int?> _resolve({
    required String cacheKey,
    required String model,
    required Map<String, String> headers,
    required http.Client client,
  }) async {
    final cached = _metadataCache[cacheKey];
    if (cached != null) return cached;

    final queried = await _queryModelMetadata(
      model: model,
      headers: headers,
      client: client,
    );
    if (queried != null) {
      _metadataCache[cacheKey] = queried;
      return queried;
    }

    final inferred = infer(model);
    if (inferred != null) {
      _metadataCache[cacheKey] = inferred;
    }
    return inferred;
  }

  static int? infer(String model) {
    final normalized = model.toLowerCase();
    if (normalized.startsWith('claude-fable-5') ||
        normalized.startsWith('claude-mythos-5') ||
        normalized.startsWith('claude-opus-4-8') ||
        normalized.startsWith('claude-sonnet-4-6')) {
      return 1000000;
    }
    if (normalized.startsWith('claude-') ||
        normalized.startsWith('anthropic.claude-')) {
      return 200000;
    }
    return null;
  }

  static Future<int?> _queryModelMetadata({
    required String model,
    required Map<String, String> headers,
    required http.Client client,
  }) async {
    final uri = Uri.parse('$_modelsBaseUrl/${Uri.encodeComponent(model)}');

    try {
      final response = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 2));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final parsed = jsonDecode(response.body);
      return ModelContextWindow.parseMetadataResponse(parsed, model: model);
    } on Object {
      return null;
    }
  }
}
