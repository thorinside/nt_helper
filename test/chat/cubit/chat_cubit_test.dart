import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/chat/cubit/chat_cubit.dart';
import 'package:nt_helper/chat/cubit/chat_state.dart';
import 'package:nt_helper/chat/models/chat_message.dart';
import 'package:nt_helper/chat/models/chat_settings.dart';
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/providers/llm_provider.dart';
import 'package:nt_helper/chat/services/memory_service.dart';
import 'package:nt_helper/mcp/tool_registry.dart';

class MockToolRegistry extends Mock implements ToolRegistry {}

class MockMemoryService extends Mock implements MemoryService {}

class MockLlmProvider extends Mock implements LlmProvider {}

class FakeLlmMessage extends Fake implements LlmMessage {}

const _settings = ChatSettings(
  provider: LlmProviderType.anthropic,
  anthropicApiKey: 'test-key',
  anthropicModel: 'claude-haiku-4-5-20251001',
);

void main() {
  late MockToolRegistry toolRegistry;
  late MockMemoryService memoryService;

  setUpAll(() {
    registerFallbackValue(<LlmMessage>[]);
    registerFallbackValue(<LlmToolDefinition>[]);
    registerFallbackValue(FakeLlmMessage());
  });

  setUp(() {
    toolRegistry = MockToolRegistry();
    memoryService = MockMemoryService();

    when(() => toolRegistry.entries).thenReturn(const []);
    when(() => toolRegistry.findByName(any())).thenReturn(null);
    when(() => memoryService.readMemory()).thenAnswer((_) async => '');
    when(() => memoryService.readDailyLogs()).thenAnswer((_) async => '');
    when(() => memoryService.saveSessionSnapshot(any()))
        .thenAnswer((_) async {});
  });

  group('Bug 1: permanent thinking spinner — onDone without isFinal', () {
    blocTest<ChatCubit, ChatState>(
      'resets isProcessing when stream completes without isFinal',
      build: () {
        final provider = MockLlmProvider();
        when(() => provider.dispose()).thenReturn(null);
        when(
          () => provider.sendMessages(
            messages: any(named: 'messages'),
            tools: any(named: 'tools'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenThrow(Exception('network error'));

        return ChatCubit(
          toolRegistry: toolRegistry,
          memoryService: memoryService,
          providerFactory: (_) => provider,
        );
      },
      act: (cubit) async {
        await cubit.sendMessage('hello', _settings);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      expect: () => [
        isA<ChatReady>()
            .having((s) => s.isProcessing, 'isProcessing', true)
            .having((s) => s.messages, 'messages', hasLength(1)),
        isA<ChatReady>()
            .having((s) => s.isProcessing, 'isProcessing', false)
            .having(
              (s) => s.messages.last.role,
              'last message role',
              ChatMessageRole.assistant,
            )
            .having(
              (s) => s.messages.last.content,
              'last message content',
              contains('Error'),
            ),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'resets isProcessing when stream ends after ChatLoopError event',
      build: () {
        final provider = MockLlmProvider();
        when(() => provider.dispose()).thenReturn(null);
        when(
          () => provider.sendMessages(
            messages: any(named: 'messages'),
            tools: any(named: 'tools'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenThrow(Exception('API unreachable'));

        return ChatCubit(
          toolRegistry: toolRegistry,
          memoryService: memoryService,
          providerFactory: (_) => provider,
        );
      },
      act: (cubit) async {
        await cubit.sendMessage('test message', _settings);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      verify: (cubit) {
        final s = cubit.state;
        expect(s, isA<ChatReady>());
        expect((s as ChatReady).isProcessing, isFalse);
      },
    );

    blocTest<ChatCubit, ChatState>(
      'resets isProcessing when provider returns final response normally',
      build: () {
        final provider = MockLlmProvider();
        when(() => provider.dispose()).thenReturn(null);
        when(
          () => provider.sendMessages(
            messages: any(named: 'messages'),
            tools: any(named: 'tools'),
            systemPrompt: any(named: 'systemPrompt'),
          ),
        ).thenAnswer(
          (_) async => const LlmResponse(
            content: 'Hello!',
            isComplete: true,
            usage: LlmUsage(inputTokens: 10, outputTokens: 5),
          ),
        );

        return ChatCubit(
          toolRegistry: toolRegistry,
          memoryService: memoryService,
          providerFactory: (_) => provider,
        );
      },
      act: (cubit) async {
        await cubit.sendMessage('hi', _settings);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      verify: (cubit) {
        final s = cubit.state as ChatReady;
        expect(s.isProcessing, isFalse);
        expect(
          s.messages.any(
            (m) =>
                m.role == ChatMessageRole.assistant && m.content == 'Hello!',
          ),
          isTrue,
        );
      },
    );
  });

  group('Bug 2: isProcessing stuck on exception during sendMessage', () {
    blocTest<ChatCubit, ChatState>(
      'resets isProcessing when providerFactory throws',
      build: () {
        return ChatCubit(
          toolRegistry: toolRegistry,
          memoryService: memoryService,
          providerFactory: (_) => throw Exception('provider creation failed'),
        );
      },
      act: (cubit) async {
        await cubit.sendMessage('hello', _settings);
      },
      expect: () => [
        isA<ChatReady>()
            .having((s) => s.isProcessing, 'isProcessing', true)
            .having((s) => s.messages, 'messages', hasLength(1)),
        isA<ChatReady>()
            .having((s) => s.isProcessing, 'isProcessing', false)
            .having(
              (s) => s.messages.last.content,
              'error message',
              contains('provider creation failed'),
            ),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'resets isProcessing when memory bootstrap throws',
      build: () {
        when(() => memoryService.readMemory())
            .thenThrow(Exception('filesystem error'));

        final provider = MockLlmProvider();
        when(() => provider.dispose()).thenReturn(null);

        return ChatCubit(
          toolRegistry: toolRegistry,
          memoryService: memoryService,
          providerFactory: (_) => provider,
        );
      },
      act: (cubit) async {
        await cubit.sendMessage('hello', _settings);
      },
      expect: () => [
        isA<ChatReady>().having((s) => s.isProcessing, 'isProcessing', true),
        isA<ChatReady>()
            .having((s) => s.isProcessing, 'isProcessing', false)
            .having(
              (s) => s.messages.last.content,
              'error message',
              contains('filesystem error'),
            ),
      ],
    );

    blocTest<ChatCubit, ChatState>(
      'shows error message to user when exception occurs',
      build: () {
        return ChatCubit(
          toolRegistry: toolRegistry,
          memoryService: memoryService,
          providerFactory: (_) => throw Exception('boom'),
        );
      },
      act: (cubit) async {
        await cubit.sendMessage('test', _settings);
      },
      verify: (cubit) {
        final s = cubit.state as ChatReady;
        expect(s.isProcessing, isFalse);
        final errorMessages = s.messages.where(
          (m) =>
              m.role == ChatMessageRole.assistant &&
              m.content.contains('Error'),
        );
        expect(errorMessages, isNotEmpty);
      },
    );
  });

  group('Bug 3: cancelProcessing after completed loop wipes history', () {
    test('cancelProcessing after successful loop preserves conversation history',
        () async {
      final provider = MockLlmProvider();
      when(() => provider.dispose()).thenReturn(null);
      when(
        () => provider.sendMessages(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).thenAnswer(
        (_) async => const LlmResponse(
          content: 'Hello!',
          isComplete: true,
          usage: LlmUsage(inputTokens: 10, outputTokens: 5),
        ),
      );

      final cubit = ChatCubit(
        toolRegistry: toolRegistry,
        memoryService: memoryService,
        providerFactory: (_) => provider,
      );
      addTearDown(cubit.close);

      // Send a message and let the loop complete
      await cubit.sendMessage('hello', _settings);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final stateBeforeCancel = cubit.state as ChatReady;
      expect(stateBeforeCancel.isProcessing, isFalse);
      expect(stateBeforeCancel.messages, hasLength(2)); // user + assistant

      // Cancel after loop already completed — should be a no-op
      cubit.cancelProcessing();

      // Send another message — it should work, proving history wasn't wiped
      when(
        () => provider.sendMessages(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).thenAnswer(
        (_) async => const LlmResponse(
          content: 'Second response',
          isComplete: true,
          usage: LlmUsage(inputTokens: 15, outputTokens: 8),
        ),
      );

      await cubit.sendMessage('second message', _settings);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // The LLM should have received the full conversation history
      // (user + assistant from first turn, plus user from second turn).
      // If cancelProcessing wiped the internal history, the LLM would only
      // see the second user message.
      final captured = verify(
        () => provider.sendMessages(
          messages: captureAny(named: 'messages'),
          tools: any(named: 'tools'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).captured;

      // The second sendMessage call's messages should include the first turn.
      // captured contains one list per invocation. The second invocation (index 1)
      // is the one from the agentic loop's second call.
      // But sendMessages is called once per loop iteration, and our mock returns
      // a final response immediately. So the second call to sendMessages is from
      // the second sendMessage(). The messages passed should be:
      // user("hello"), assistant("Hello!"), user("second message")
      final secondCallMessages = captured.last as List<LlmMessage>;
      expect(
        secondCallMessages.length,
        greaterThanOrEqualTo(3),
        reason: 'Expected at least 3 messages: '
            '${secondCallMessages.map((m) => '${m.role.name}:${m.content}').join(', ')}',
      );
      // First-turn user message should be present
      expect(secondCallMessages[0].content, 'hello');
      // First-turn assistant response should be present
      expect(secondCallMessages[1].content, 'Hello!');
      // Second-turn user message should be present
      expect(secondCallMessages[2].content, 'second message');
    });
  });

  group('Bug 4: cancelProcessing resets state', () {
    test('cancelProcessing resets isProcessing to false', () async {
      final completer = Completer<LlmResponse>();
      final provider = MockLlmProvider();
      when(() => provider.dispose()).thenReturn(null);
      when(
        () => provider.sendMessages(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).thenAnswer((_) => completer.future);

      final cubit = ChatCubit(
        toolRegistry: toolRegistry,
        memoryService: memoryService,
        providerFactory: (_) => provider,
      );
      addTearDown(cubit.close);

      unawaited(cubit.sendMessage('hello', _settings));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect((cubit.state as ChatReady).isProcessing, isTrue);

      cubit.cancelProcessing();

      final s = cubit.state as ChatReady;
      expect(s.isProcessing, isFalse);
      expect(s.currentToolName, isNull);

      completer.complete(const LlmResponse(
        content: 'late',
        isComplete: true,
      ));
    });

    test('cancelProcessing clears currentToolName', () async {
      final completer = Completer<LlmResponse>();
      final provider = MockLlmProvider();
      when(() => provider.dispose()).thenReturn(null);
      when(
        () => provider.sendMessages(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).thenAnswer((_) => completer.future);

      final cubit = ChatCubit(
        toolRegistry: toolRegistry,
        memoryService: memoryService,
        providerFactory: (_) => provider,
      );
      addTearDown(cubit.close);

      unawaited(cubit.sendMessage('hello', _settings));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      cubit.cancelProcessing();

      final s = cubit.state as ChatReady;
      expect(s.currentToolName, isNull);

      completer.complete(const LlmResponse(
        content: 'late',
        isComplete: true,
      ));
    });
  });

  group('Bug 5: compaction trim breaks message role ordering', () {
    test(
        'after compaction, history sent to provider starts with user message '
        'even when trim boundary falls mid-tool-sequence', () async {
      int callCount = 0;

      final provider = MockLlmProvider();
      when(() => provider.dispose()).thenReturn(null);
      when(
        () => provider.sendMessages(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        switch (callCount) {
          case 1:
            // Turn 1, iteration 1: return tool calls to build up history
            return const LlmResponse(
              isComplete: false,
              toolCalls: [
                LlmToolCall(id: 'tc1', name: 'fake_tool', arguments: {}),
                LlmToolCall(id: 'tc2', name: 'fake_tool', arguments: {}),
                LlmToolCall(id: 'tc3', name: 'fake_tool', arguments: {}),
              ],
            );
          case 2:
            // Turn 1, iteration 2: more tool calls
            return const LlmResponse(
              isComplete: false,
              toolCalls: [
                LlmToolCall(id: 'tc4', name: 'fake_tool', arguments: {}),
                LlmToolCall(id: 'tc5', name: 'fake_tool', arguments: {}),
                LlmToolCall(id: 'tc6', name: 'fake_tool', arguments: {}),
              ],
            );
          case 3:
            // Turn 1, iteration 3: final response with high tokens to trigger
            // compaction (limit/2 = 100000 for haiku's 200000).
            return const LlmResponse(
              content: 'Done with tools.',
              isComplete: true,
              usage: LlmUsage(inputTokens: 110000, outputTokens: 500),
            );
          case 4:
            // Compaction loop: simple final response
            return const LlmResponse(
              content: 'Context saved.',
              isComplete: true,
              usage: LlmUsage(inputTokens: 100, outputTokens: 50),
            );
          default:
            // Turn 2 actual message: final response
            return const LlmResponse(
              content: 'Second turn response.',
              isComplete: true,
              usage: LlmUsage(inputTokens: 100, outputTokens: 50),
            );
        }
      });

      final cubit = ChatCubit(
        toolRegistry: toolRegistry,
        memoryService: memoryService,
        providerFactory: (_) => provider,
      );
      addTearDown(cubit.close);

      // Turn 1: builds up tool call history and triggers _needsCompaction
      await cubit.sendMessage('hello', _settings);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect((cubit.state as ChatReady).isProcessing, isFalse);

      // Turn 2: triggers compaction, then sends the real message.
      // Before the fix, the trim could leave orphaned tool messages at the
      // start of history, causing OpenAI to reject with 400.
      await cubit.sendMessage('second question', _settings);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect((cubit.state as ChatReady).isProcessing, isFalse);

      // Verify the last sendMessages call got a history starting with user
      final captured = verify(
        () => provider.sendMessages(
          messages: captureAny(named: 'messages'),
          tools: any(named: 'tools'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).captured;

      // The last captured messages list is from the post-compaction real call
      final lastMessages = captured.last as List<LlmMessage>;
      expect(
        lastMessages.first.role,
        equals(LlmRole.user),
        reason:
            'After compaction trim, history must start with a user message. '
            'Got: ${lastMessages.map((m) => m.role.name).join(', ')}',
      );
    });
  });
}
