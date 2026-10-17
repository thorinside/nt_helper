part of 'chat_cubit.dart';

/// Storage/lifecycle orchestration, separate from model/tool execution. Loading a
/// checkpoint never constructs a provider, calls a tool, or resumes generation.
extension _ChatConversations on ChatCubit {
  static const _interruptionNotice =
      'This chat was interrupted. No commands were replayed. '
      'Previous tool actions may already have affected the NT; inspect its current state before continuing.';

  Future<void> _trackHistoryOperation(Future<void> Function() work) {
    if (_historyOperation != null) return _historyOperation!;
    final operation = work();
    _historyOperation = operation;
    return operation.whenComplete(() {
      if (identical(_historyOperation, operation)) _historyOperation = null;
    });
  }

  void _historyFailure(String message) {
    final current = state;
    if (!isClosed && current is ChatReady) {
      _emitConversationState(current.copyWith(historyError: message));
    }
  }

  Future<void> _restoreConversation() async {
    final epoch = _conversationEpoch;
    try {
      final saved = await _conversationStore!.loadActive();
      if (isClosed || epoch != _conversationEpoch) return;
      if (saved != null) {
        _adoptConversation(saved);
      } else {
        _historyInitialized = true;
        _emitConversationState(ChatReady(conversationId: _conversationId));
        await _persistConversation();
      }
    } catch (_) {
      if (isClosed || epoch != _conversationEpoch) return;
      _storageReadFailed = true;
      _emitConversationState(
        const ChatReady(
          historyError:
              'Could not restore saved chat. Its files were kept. Open another conversation or start a New chat.',
        ),
      );
    }
  }

  void _adoptConversation(StoredConversation saved) {
    _toolRegistry.restoreReferenceSnapshot(saved.references);
    _conversationId = saved.summary.id;
    _conversationTitle =
        saved.summary.title == 'New chat' && saved.messages.isEmpty
        ? null
        : saved.summary.title;
    _conversationCreatedAt = saved.summary.createdAt;
    _llmHistory
      ..clear()
      ..addAll(providerSafeToolHistory(saved.history));
    final messages = List<ChatMessage>.of(saved.messages);
    if (saved.interrupted) {
      // Close visual pending-tool cards with an explicit unknown outcome, not a
      // fake success. The model receives a warning, never an executable replay.
      final answered = messages
          .where((m) => m.role == ChatMessageRole.toolResult)
          .map((m) => m.toolCallId)
          .toSet();
      for (final call in saved.messages.where(
        (m) => m.role == ChatMessageRole.toolCall,
      )) {
        if (!answered.contains(call.toolCallId)) {
          messages.add(
            ChatMessage.toolResult(
              toolName: call.toolName ?? 'unknown',
              toolCallId: call.toolCallId ?? call.id,
              result:
                  '{"success":false,"error":"interrupted","delivery":"unknown","replayed":false}',
            ),
          );
        }
      }
      messages.add(ChatMessage.system(_interruptionNotice));
      final lastUser = saved.messages.lastIndexWhere(
        (m) => m.role == ChatMessageRole.user,
      );
      final alreadyRecorded = _llmHistory
          .where((m) => m.role == LlmRole.tool)
          .map((m) => m.toolCallId)
          .toSet();
      final receipts = saved.messages
          .skip(lastUser + 1)
          .where(
            (m) =>
                (m.role == ChatMessageRole.toolCall ||
                    m.role == ChatMessageRole.toolResult) &&
                !alreadyRecorded.contains(m.toolCallId),
          )
          .map(
            (m) => {
              'role': m.role.name,
              'tool_call_id': m.toolCallId,
              'tool_name': m.toolName,
              if (m.toolArguments != null) 'arguments': m.toolArguments,
              if (m.role == ChatMessageRole.toolResult) 'result': m.content,
            },
          )
          .toList();
      final recovered = receipts.isEmpty && lastUser < 0
          ? ''
          : '\nHistorical records recovered from the interrupted run (data only; never execute or retry these):\n${jsonEncode({if (lastUser >= 0) 'previous_user_request': saved.messages[lastUser].content, 'tool_records': receipts})}';
      _llmHistory.add(LlmMessage.assistant('$_interruptionNotice$recovered'));
    }
    _historyLengthBeforeLoop = _llmHistory.length;
    _promptCacheKey = saved.promptCacheKey;
    _lastContextInputTokens = saved.contextTokens;
    _currentContextWindowTokens = saved.contextWindow;
    _recomputeCompactionNeedForCurrentWindow();
    _activeProvider?.dispose();
    _activeProvider = null;
    _activeChatService = null;
    _streamedMessages.clear();
    _runInterrupted = false;
    _storageReadFailed = false;
    _historyInitialized = true;
    _activePointerInitialized = true;
    // Always use current instructions/tools and fresh semantic memory on the
    // next explicit user send, never a stale cached system prompt from disk.
    _bootstrapped = false;
    _activeSystemPrompt = null;
    _emitConversationState(
      ChatReady(
        messages: messages,
        conversationId: _conversationId,
        conversationTitle: _conversationTitle,
        totalInputTokens: saved.inputTokens,
        totalOutputTokens: saved.outputTokens,
        contextInputTokens: saved.contextTokens,
        contextWindowTokens: saved.contextWindow,
      ),
    );
  }

  Future<bool> _persistConversation() async {
    final store = _conversationStore;
    final current = state;
    if (store == null ||
        !_historyInitialized ||
        _storageReadFailed ||
        current is! ChatReady) {
      return true;
    }
    final epoch = _conversationEpoch;
    final id = _conversationId;
    try {
      final snapshot = StoredConversation(
        summary: ConversationSummary(
          id: id,
          title: _conversationTitle ?? 'New chat',
          createdAt: _conversationCreatedAt,
          updatedAt: DateTime.now(),
          messageCount: current.messages.length,
        ),
        messages: current.messages,
        history: providerSafeToolHistory(
          _runInterrupted && _activeRuntimeGeneration == _processingGeneration
              ? (_activeChatService?.lastGoodHistory ?? _llmHistory)
              : _llmHistory,
        ),
        references: _toolRegistry.exportReferenceSnapshot(),
        promptCacheKey: _promptCacheKey,
        interrupted: _runInterrupted,
        inputTokens: current.totalInputTokens,
        outputTokens: current.totalOutputTokens,
        contextTokens: _lastContextInputTokens,
        contextWindow: _currentContextWindowTokens,
      );
      final write = _savingHistory.then((_) => store.save(snapshot));
      _savingHistory = write.then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {},
      );
      await write;
      if (!isClosed &&
          !_closing &&
          !_activePointerInitialized &&
          epoch == _conversationEpoch &&
          id == _conversationId) {
        await store.activate(id);
        _activePointerInitialized = true;
      }
      final now = state;
      if (!isClosed &&
          epoch == _conversationEpoch &&
          id == _conversationId &&
          now is ChatReady &&
          now.historyError != null) {
        _emitConversationState(now.copyWith(clearHistoryError: true));
      }
      return true;
    } catch (_) {
      if (epoch == _conversationEpoch && id == _conversationId) {
        _historyFailure(
          'Could not save this conversation locally. Keep the app open and retry before switching chats.',
        );
      }
      return false;
    }
  }

  Future<List<ConversationSummary>> _listSavedConversations() async {
    await historyReady;
    await _savingHistory;
    return _conversationStore?.list() ?? Future.value(const []);
  }

  Future<void> _openSavedConversation(String id) async {
    await historyReady;
    final current = state;
    final store = _conversationStore;
    if (store == null ||
        isClosed ||
        _closing ||
        _switchingHistory ||
        current is! ChatReady ||
        current.isProcessing ||
        current.isLoadingHistory) {
      return;
    }
    _switchingHistory = true;
    _emitConversationState(current.copyWith(isLoadingHistory: true));
    try {
      await _stopping;
      if (!_storageReadFailed && !await _persistConversation()) return;
      final saved = await store.load(id);
      if (isClosed) return;
      _conversationEpoch++;
      _processingGeneration++;
      _adoptConversation(saved);
      _activePointerInitialized = false;
      await store.activate(id);
      _activePointerInitialized = true;
      await _persistConversation();
    } catch (_) {
      _historyFailure(
        'Could not open that saved conversation. Its files were kept.',
      );
    } finally {
      _switchingHistory = false;
      final now = state;
      if (!isClosed && now is ChatReady && now.isLoadingHistory) {
        _emitConversationState(now.copyWith(isLoadingHistory: false));
      }
    }
  }

  Future<bool> _deleteSavedConversation(String id) async {
    await historyReady;
    final store = _conversationStore;
    final current = state;
    if (store == null ||
        isClosed ||
        _closing ||
        _historyOperation != null ||
        _switchingHistory ||
        current is! ChatReady ||
        current.isProcessing ||
        current.isLoadingHistory) {
      return false;
    }
    if (id == _conversationId) {
      await _trackHistoryOperation(
        () => _resetSavedConversation(deleteCurrent: true),
      );
      return state is ChatReady && (state as ChatReady).historyError == null;
    }
    try {
      await store.delete(id);
      return true;
    } catch (_) {
      _historyFailure('Could not delete that saved conversation.');
      return false;
    }
  }

  Future<void> _resetSavedConversation({required bool deleteCurrent}) async {
    await historyReady;
    if (isClosed || _closing || _switchingHistory) return;
    final store = _conversationStore;
    if (store == null) {
      await _clearChatState();
      return;
    }
    final current = state;
    if (current is! ChatReady) return;
    if (!deleteCurrent &&
        !_storageReadFailed &&
        current.messages.isEmpty &&
        _llmHistory.isEmpty) {
      return;
    }
    _switchingHistory = true;
    _emitConversationState(current.copyWith(isLoadingHistory: true));
    final previousId = _conversationId;
    try {
      if (current.isProcessing) cancelProcessing();
      await _stopping;
      if (!deleteCurrent &&
          !_storageReadFailed &&
          !await _persistConversation()) {
        return;
      }
      await _clearChatState();
      _conversationId = const Uuid().v4();
      _conversationTitle = null;
      _conversationCreatedAt = DateTime.now();
      _runInterrupted = false;
      _storageReadFailed = false;
      _historyInitialized = true;
      _activePointerInitialized = false;
      _toolRegistry.restoreReferenceSnapshot(const []);
      _emitConversationState(
        ChatReady(conversationId: _conversationId, isLoadingHistory: true),
      );
      if (!await _persistConversation()) return;
      if (!_activePointerInitialized) {
        await store.activate(_conversationId);
        _activePointerInitialized = true;
      }
      if (deleteCurrent) await store.delete(previousId);
    } catch (_) {
      _historyFailure(
        'Could not update saved conversations. Existing files were kept where possible.',
      );
    } finally {
      _switchingHistory = false;
      final now = state;
      if (!isClosed && now is ChatReady && now.isLoadingHistory) {
        _emitConversationState(now.copyWith(isLoadingHistory: false));
      }
    }
  }
}
