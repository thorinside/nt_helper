import 'package:equatable/equatable.dart';
import 'package:nt_helper/chat/models/chat_message.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatReady extends ChatState {
  final List<ChatMessage> messages;
  final bool isProcessing;
  final String? currentToolName;
  final int totalInputTokens;
  final int totalOutputTokens;

  const ChatReady({
    this.messages = const [],
    this.isProcessing = false,
    this.currentToolName,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
  });

  ChatReady copyWith({
    List<ChatMessage>? messages,
    bool? isProcessing,
    String? currentToolName,
    bool clearToolName = false,
    int? totalInputTokens,
    int? totalOutputTokens,
  }) {
    return ChatReady(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      currentToolName:
          clearToolName ? null : (currentToolName ?? this.currentToolName),
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isProcessing,
        currentToolName,
        totalInputTokens,
        totalOutputTokens,
      ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
