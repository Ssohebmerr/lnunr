part of 'chat_bloc.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

/// Transient UI notice — never replaces the message list.
enum ChatNoticeType { consent, limit, premiumRequired }

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isSending;
  final ChatNoticeType? notice;

  ChatLoaded({
    required this.messages,
    this.isSending = false,
    this.notice,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    ChatNoticeType? notice,
    bool clearNotice = false,
  }) =>
      ChatLoaded(
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
        notice: clearNotice ? null : (notice ?? this.notice),
      );
}
