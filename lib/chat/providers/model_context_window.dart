import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ModelContextWindow {
  static const defaultTokens = 100000;

  static int? parseMetadata(Map<String, dynamic> json) {
    for (final key in const [
      'max_input_tokens',
      'context_window',
      'context_window_tokens',
      'context_length',
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
      ]) {
        final value = _positiveInt(capabilities[key]);
        if (value != null) return value;
      }
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
      if (parsed is! Map<String, dynamic>) return null;
      return ModelContextWindow.parseMetadata(parsed);
    } on Object {
      return null;
    }
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
      if (parsed is! Map<String, dynamic>) return null;
      return ModelContextWindow.parseMetadata(parsed);
    } on Object {
      return null;
    }
  }
}
