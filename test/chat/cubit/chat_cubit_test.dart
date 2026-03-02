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

  group('Bug 3: cancelProcessing resets state', () {
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
}
