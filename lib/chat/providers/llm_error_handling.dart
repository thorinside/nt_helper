import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nt_helper/chat/providers/anthropic_provider.dart';
import 'package:nt_helper/services/debug_service.dart';

/// Shared error handling for LLM API providers.
///
/// Extracts common HTTP error parsing, Retry-After header detection, and
/// exception throwing so each provider doesn't duplicate this logic.
mixin LlmErrorHandling {
  void throwIfApiError(http.Response response, String providerName) {
    if (response.statusCode == 200) return;

    String errorMessage;
    try {
      final errorBody = jsonDecode(response.body.trim());
      errorMessage =
          errorBody['error']?['message'] as String? ?? 'Unknown API error';
    } on FormatException {
      errorMessage = response.body;
    }

    final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');

    DebugService().addLocalMessage('$providerName error: $errorMessage');
    throw LlmApiException(
      '$providerName error (${response.statusCode}): $errorMessage',
      statusCode: response.statusCode,
      retryAfterSeconds: retryAfter,
    );
  }
}
