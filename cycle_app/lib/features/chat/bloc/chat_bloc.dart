import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/premium/premium_gate.dart';
import '../data/chat_message.dart';
import '../data/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this.repository,
    required this.uid,
    required this.contextEngine,
  }) : super(ChatInitial()) {
    on<LoadChatMessages>(_onLoad);
    on<SendChatMessage>(_onSend);
    on<AnalyzeCycleRequested>(_onAnalyze);
    on<ClearChatNotice>(_onClearNotice);
  }

  final ChatRepository repository;
  final String uid;
  final AiContextEngine contextEngine;
  StreamSubscription<List<ChatMessage>>? _subscription;

  static const _unavailableReply =
      'عذراً، المساعد غير متاح حالياً.\n'
      'تأكدي من تفعيل Firebase AI Logic في مشروع lune-7d956 '
      'وسجّلي الدخول ثم حاولي مرة أخرى.\n\n'
      'AI is unavailable. Enable Firebase AI Logic for project lune-7d956, '
      'sign in, and try again.';

  void _emitNotice(Emitter<ChatState> emit, ChatNoticeType notice) {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(notice: notice, isSending: false));
    } else {
      emit(ChatLoaded(messages: const [], notice: notice));
    }
  }

  void _clearSending(Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(
        isSending: false,
        clearPartial: true,
      ));
    }
  }

  void _onClearNotice(ClearChatNotice event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(clearNotice: true));
    }
  }

  Future<void> _onLoad(LoadChatMessages event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) emit(ChatLoading());

    await _subscription?.cancel();
    _subscription = repository.watchMessages(uid).listen(
      (messages) {
        final current = state;
        final sending = current is ChatLoaded ? current.isSending : false;
        final notice = current is ChatLoaded ? current.notice : null;
        emit(ChatLoaded(
          messages: messages,
          isSending: sending,
          notice: notice,
        ));
      },
      onError: (_) {
        emit(ChatLoaded(messages: const [], isSending: false));
      },
    );
  }

  Future<void> _onSend(SendChatMessage event, Emitter<ChatState> emit) async {
    final access = await PremiumGate.checkAiChat();
    if (access == PremiumAiAccess.needsConsent) {
      _emitNotice(emit, ChatNoticeType.consent);
      return;
    }
    if (access == PremiumAiAccess.limitReached) {
      _emitNotice(emit, ChatNoticeType.limit);
      return;
    }

    final text = event.text.trim();
    if (text.isEmpty) return;
    final mode = event.mode;

    final history = state is ChatLoaded
        ? List<ChatMessage>.from((state as ChatLoaded).messages)
        : const <ChatMessage>[];

    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(
        isSending: true,
        clearNotice: true,
        clearPartial: true,
      ));
    } else {
      emit(ChatLoaded(messages: const [], isSending: true));
    }

    await repository.saveMessage(
      uid,
      ChatMessage(
        id: '',
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    try {
      final context = await contextEngine.buildAnonymizedContext();
      final reply = await _streamReplyWithFallback(
        emit: emit,
        message: text,
        cycleContext: context,
        mode: mode,
        history: history,
      );
      await repository.saveMessage(
        uid,
        ChatMessage(
          id: '',
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      await PremiumGate.recordAiMessage();
    } catch (_) {
      await repository.saveMessage(
        uid,
        ChatMessage(
          id: '',
          text: _unavailableReply,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _clearSending(emit);
    }
  }

  /// Streams the reply token-by-token via [ChatRepository.streamAiReply],
  /// emitting partial state for live rendering. If the stream yields nothing
  /// (e.g. no API key), falls back to a single-shot [requestAiReply].
  Future<String> _streamReplyWithFallback({
    required Emitter<ChatState> emit,
    required String message,
    required Map<String, dynamic> cycleContext,
    required String mode,
    required List<ChatMessage> history,
    bool analyzeMode = false,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in repository.streamAiReply(
      message: message,
      cycleContext: cycleContext,
      mode: analyzeMode ? 'analyze' : mode,
      history: history,
    )) {
      buffer.write(chunk);
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(
          isSending: true,
          partialReply: buffer.toString(),
        ));
      }
    }

    if (buffer.isNotEmpty) return buffer.toString();

    // Stream produced nothing — fall back to single-shot call.
    return repository.requestAiReply(
      message: message,
      cycleContext: cycleContext,
      analyzeMode: analyzeMode,
      mode: mode,
      history: history,
      unavailableMessage: _unavailableReply,
    );
  }

  Future<void> _onAnalyze(
    AnalyzeCycleRequested event,
    Emitter<ChatState> emit,
  ) async {
    final access = await PremiumGate.checkAiChat();
    if (access == PremiumAiAccess.needsConsent) {
      _emitNotice(emit, ChatNoticeType.consent);
      return;
    }
    if (access == PremiumAiAccess.limitReached) {
      _emitNotice(emit, ChatNoticeType.limit);
      return;
    }

    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(
        isSending: true,
        clearNotice: true,
        clearPartial: true,
      ));
    } else {
      emit(ChatLoaded(messages: const [], isSending: true));
    }

    const prompt =
        'Analyze my menstrual cycle patterns and give wellness insights.';
    await repository.saveMessage(
      uid,
      ChatMessage(
        id: '',
        text: prompt,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    try {
      final context = await contextEngine.buildAnonymizedContext();
      final reply = await _streamReplyWithFallback(
        emit: emit,
        message: prompt,
        cycleContext: context,
        mode: 'analyze',
        history: const [],
        analyzeMode: true,
      );
      await repository.saveMessage(
        uid,
        ChatMessage(
          id: '',
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      await PremiumGate.recordAiMessage();
    } catch (_) {
      await repository.saveMessage(
        uid,
        ChatMessage(
          id: '',
          text: _unavailableReply,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _clearSending(emit);
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
