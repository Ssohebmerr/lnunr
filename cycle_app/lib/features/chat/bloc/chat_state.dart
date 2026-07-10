part of 'chat_bloc.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

/// Transient UI notice — never replaces the message list.
enum ChatNoticeType { consent, limit, dailyLimit, premiumRequired, adultRequired }

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isSending;
  final ChatNoticeType? notice;

  /// Partial assistant reply currently being streamed (token-by-token from
  /// Gemini). Rendered as a temporary bubble while [isSending] is true; the
  /// finalized message is saved to [messages] once streaming completes.
  final String? partialReply;

  ChatLoaded({
    required this.messages,
    this.isSending = false,
    this.notice,
    this.partialReply,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    ChatNoticeType? notice,
    bool clearNotice = false,
    String? partialReply,
    bool clearPartial = false,
  }) =>
      ChatLoaded(
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
        notice: clearNotice ? null : (notice ?? this.notice),
        partialReply: clearPartial ? null : (partialReply ?? this.partialReply),
      );
}
