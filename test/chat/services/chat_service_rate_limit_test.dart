import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/providers/anthropic_provider.dart';
import 'package:nt_helper/chat/providers/llm_provider.dart';
import 'package:nt_helper/chat/services/chat_service.dart';
import 'package:nt_helper/chat/services/tool_bridge_service.dart';
import 'package:nt_helper/mcp/tool_registry.dart';

class MockLlmProvider extends Mock implements LlmProvider {}

class MockToolRegistry extends Mock implements ToolRegistry {}

void main() {
  late MockLlmProvider provider;
  late ToolBridgeService toolBridge;
  late ChatService chatService;

  setUpAll(() {
    registerFallbackValue(<LlmMessage>[]);
    registerFallbackValue(<LlmToolDefinition>[]);
  });

  setUp(() {
    provider = MockLlmProvider();
    final toolRegistry = MockToolRegistry();
    when(() => toolRegistry.entries).thenReturn(const []);
    toolBridge = ToolBridgeService(toolRegistry);
    chatService = ChatService(
      provider: provider,
      toolBridge: toolBridge,
      systemPrompt: 'test',
    );
  });

  group('Rate limit retry', () {
    test('single 429 then success yields rate limited event then result',
        () async {
      var callCount = 0;
      when(
        () => provider.sendMessages(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw LlmApiException(
            'Rate limit exceeded',
            statusCode: 429,
            retryAfterSeconds: 0,
          );
        }
        return const LlmResponse(
          content: 'Hello!',
          isComplete: true,
          usage: LlmUsage(inputTokens: 10, outputTokens: 5),
        );
      });

      final events = await chatService
          .runAgenticLoop([LlmMessage.user('Hi')])
          .toList();

      final types = events.map((e) => e.runtimeType).toList();
      expect(types, contains(ChatLoopRateLimited));
      expect(types, contains(ChatLoopAssistantMessage));
      expect(types, isNot(contains(ChatLoopError)));
    });

    test('all retries exhausted yields rate limited events then error',
        () async {
      when(
        () => provider.sendMessages(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).thenThrow(
        LlmApiException(
          'Rate limit exceeded',
          statusCode: 429,
          retryAfterSeconds: 0,
        ),
      );

      final events = await chatService
          .runAgenticLoop([LlmMessage.user('Hi')])
          .toList();

      final rateLimitEvents =
          events.whereType<ChatLoopRateLimited>().toList();
      final errorEvents = events.whereType<ChatLoopError>().toList();

      expect(rateLimitEvents.length, 4);
      expect(errorEvents.length, 1);
      expect(errorEvents.first.message, contains('Rate limited'));
    });

    test('retry-after header value is used for wait time', () {
      fakeAsync((clock) {
        var callCount = 0;
        when(
          () => provider.sendMessages(
            messages: any(named: 'messages'),
            tools: any(named: 'tools'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw LlmApiException(
              'Rate limit exceeded',
              statusCode: 429,
              retryAfterSeconds: 7,
            );
          }
          return const LlmResponse(
            content: 'Done',
            isComplete: true,
            usage: LlmUsage(inputTokens: 10, outputTokens: 5),
          );
        });

        final events = <ChatLoopEvent>[];
        chatService
            .runAgenticLoop([LlmMessage.user('Hi')])
            .listen(events.add);

        clock.elapse(const Duration(seconds: 10));

        final rateLimitEvent =
            events.whereType<ChatLoopRateLimited>().first;
        expect(rateLimitEvent.waitSeconds, 7);
      });
    });

    test('non-429 error is not retried', () async {
      when(
        () => provider.sendMessages(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).thenThrow(
        LlmApiException('Server error', statusCode: 500),
      );

      final events = await chatService
          .runAgenticLoop([LlmMessage.user('Hi')])
          .toList();

      final rateLimitEvents =
          events.whereType<ChatLoopRateLimited>().toList();
      final errorEvents = events.whereType<ChatLoopError>().toList();

      expect(rateLimitEvents, isEmpty);
      expect(errorEvents.length, 1);
      expect(errorEvents.first.message, contains('Server error'));
    });

    test('non-LlmApiException is not retried', () async {
      when(
        () => provider.sendMessages(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).thenThrow(Exception('Network error'));

      final events = await chatService
          .runAgenticLoop([LlmMessage.user('Hi')])
          .toList();

      final rateLimitEvents =
          events.whereType<ChatLoopRateLimited>().toList();
      final errorEvents = events.whereType<ChatLoopError>().toList();

      expect(rateLimitEvents, isEmpty);
      expect(errorEvents.length, 1);
    });

    test('backoff is capped at max seconds', () {
      fakeAsync((clock) {
        var callCount = 0;
        when(
          () => provider.sendMessages(
            messages: any(named: 'messages'),
            tools: any(named: 'tools'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw LlmApiException(
              'Rate limit exceeded',
              statusCode: 429,
              retryAfterSeconds: 999,
            );
          }
          return const LlmResponse(
            content: 'Done',
            isComplete: true,
            usage: LlmUsage(inputTokens: 10, outputTokens: 5),
          );
        });

        final events = <ChatLoopEvent>[];
        chatService
            .runAgenticLoop([LlmMessage.user('Hi')])
            .listen(events.add);

        clock.elapse(const Duration(seconds: 35));

        final rateLimitEvent =
            events.whereType<ChatLoopRateLimited>().first;
        expect(rateLimitEvent.waitSeconds, 30);
      });
    });
  });
}
