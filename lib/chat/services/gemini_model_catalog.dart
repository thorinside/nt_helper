import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nt_helper/chat/services/model_catalog_service.dart';

/// Google's native catalog supplies input-token limits that the compatibility
/// catalog may omit. Generation itself uses Google's OpenAI-compatible API.
class GeminiModelCatalog implements ChatModelCatalog {
  final String apiKey;
  final http.Client _client;
  GeminiModelCatalog({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<List<LlmModelOption>> fetchModels() async {
    final models = <LlmModelOption>[];
    final seen = <String>{};
    final pages = <String>{};
    String? next;
    for (var page = 0; page < 10; page++) {
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models',
        {'pageSize': '1000', 'pageToken': ?next},
      );
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'x-goog-api-key': apiKey.trim(),
            },
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ModelCatalogException(
          'Could not load Gemini models (${response.statusCode}).',
        );
      }
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        for (final item in data['models'] as List? ?? const []) {
          if (item is! Map ||
              !(item['supportedGenerationMethods'] as List? ?? const [])
                  .contains('generateContent')) {
            continue;
          }
          final raw = item['name'];
          if (raw is! String || !raw.startsWith('models/')) continue;
          final id = raw.substring('models/'.length);
          if (id.isEmpty || !seen.add(id)) continue;
          final limit = item['inputTokenLimit'];
          models.add(
            LlmModelOption(
              id: id,
              displayName: item['displayName'] as String? ?? id,
              contextWindowTokens: limit is int && limit > 0 ? limit : null,
            ),
          );
        }
        next = data['nextPageToken'] as String?;
      } on Object {
        throw const ModelCatalogException(
          'The Gemini model list was not valid.',
        );
      }
      if (next == null || next.isEmpty) return List.unmodifiable(models);
      if (!pages.add(next)) break;
    }
    throw const ModelCatalogException(
      'The Gemini model list could not be fully loaded. Try again or enter a model ID.',
    );
  }

  @override
  void dispose() => _client.close();
}
