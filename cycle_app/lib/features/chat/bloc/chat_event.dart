part of 'chat_bloc.dart';

abstract class ChatEvent {}

class LoadChatMessages extends ChatEvent {}

class SendChatMessage extends ChatEvent {
  final String text;
  final String mode;
  SendChatMessage(this.text, {this.mode = 'chat'});
}

class AnalyzeCycleRequested extends ChatEvent {}

class ClearChatNotice extends ChatEvent {}
