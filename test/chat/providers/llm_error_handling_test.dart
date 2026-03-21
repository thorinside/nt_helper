import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nt_helper/chat/providers/anthropic_provider.dart';
import 'package:nt_helper/chat/providers/llm_error_handling.dart';

class _TestErrorHandler with LlmErrorHandling {}

void main() {
  late _TestErrorHandler handler;

  setUp(() {
    handler = _TestErrorHandler();
  });

  group('LlmErrorHandling', () {
    test('does not throw on 200 response', () {
      final response = http.Response('ok', 200);
      expect(() => handler.throwIfApiError(response, 'Test'), returnsNormally);
    });

    test('throws LlmApiException with statusCode on 429', () {
      final response = http.Response(
        '{"error":{"message":"Rate limit exceeded"}}',
        429,
      );
      expect(
        () => handler.throwIfApiError(response, 'Test'),
        throwsA(
          isA<LlmApiException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.isRateLimited, 'isRateLimited', true)
              .having(
                (e) => e.message,
                'message',
                contains('Rate limit exceeded'),
              ),
        ),
      );
    });

    test('throws LlmApiException with statusCode on 500', () {
      final response = http.Response(
        '{"error":{"message":"Internal server error"}}',
        500,
      );
      expect(
        () => handler.throwIfApiError(response, 'Test'),
        throwsA(
          isA<LlmApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.isRateLimited, 'isRateLimited', false),
        ),
      );
    });

    test('parses Retry-After header', () {
      final response = http.Response(
        '{"error":{"message":"Too many requests"}}',
        429,
        headers: {'retry-after': '5'},
      );
      expect(
        () => handler.throwIfApiError(response, 'Test'),
        throwsA(
          isA<LlmApiException>()
              .having((e) => e.retryAfterSeconds, 'retryAfterSeconds', 5),
        ),
      );
    });

    test('retryAfterSeconds is null when header missing', () {
      final response = http.Response(
        '{"error":{"message":"Too many requests"}}',
        429,
      );
      expect(
        () => handler.throwIfApiError(response, 'Test'),
        throwsA(
          isA<LlmApiException>()
              .having((e) => e.retryAfterSeconds, 'retryAfterSeconds', null),
        ),
      );
    });

    test('falls back to raw body on malformed JSON', () {
      final response = http.Response('not json at all', 400);
      expect(
        () => handler.throwIfApiError(response, 'Test'),
        throwsA(
          isA<LlmApiException>()
              .having(
                (e) => e.message,
                'message',
                contains('not json at all'),
              ),
        ),
      );
    });

    test('includes provider name in error message', () {
      final response = http.Response(
        '{"error":{"message":"Bad request"}}',
        400,
      );
      expect(
        () => handler.throwIfApiError(response, 'My Provider'),
        throwsA(
          isA<LlmApiException>()
              .having(
                (e) => e.message,
                'message',
                startsWith('My Provider error'),
              ),
        ),
      );
    });
  });
}
