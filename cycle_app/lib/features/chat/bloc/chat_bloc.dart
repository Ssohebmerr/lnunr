import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/ai_action_parser.dart';
import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/ai_gateway_exception.dart';
import '../../../core/ai/lune_personality.dart';
import '../../../core/premium/premium_activation_service.dart';
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
  bool _retriedPremiumSync = false;

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

  Future<void> _saveAssistantReply(
    String text,
  ) async {
    try {
      // The reply is already on screen via the local Firestore cache; the
      // timeout just stops a flaky network from locking the composer while
      // the write keeps syncing in the background.
      await repository
          .saveMessage(
            uid,
            ChatMessage(
              id: '',
              text: text,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[ChatBloc] save assistant reply failed: $e');
    }
  }

  Future<bool> _tryRecoverPremium() async {
    if (_retriedPremiumSync) return false;
    _retriedPremiumSync = true;
    // The local flag may be stale (e.g. right after a purchase) — re-read the
    // server-side entitlement once and retry if it says premium.
    final result =
        await PremiumActivationService.refreshPremiumStatus(force: true);
    return result.ok;
  }

  Future<void> _onSend(SendChatMessage event, Emitter<ChatState> emit) async {
    final access = await PremiumGate.checkAiChat();
    if (access == PremiumAiAccess.needsAdult) {
      _emitNotice(emit, ChatNoticeType.adultRequired);
      return;
    }
    if (access == PremiumAiAccess.needsPremium) {
      _emitNotice(emit, ChatNoticeType.premiumRequired);
      return;
    }
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

    // Fire-and-forget: the message shows up instantly through the local
    // Firestore cache; waiting for the server ack here only delayed the
    // start of the AI reply on slow networks.
    unawaited(
      repository
          .saveMessage(
            uid,
            ChatMessage(
              id: '',
              text: text,
              isUser: true,
              timestamp: DateTime.now(),
            ),
          )
          .catchError(
            (Object e) => debugPrint('[ChatBloc] save user message failed: $e'),
          ),
    );

    try {
      final context = await _safeContext();
      final reply = await _streamReplyWithFallback(
        emit: emit,
        message: text,
        cycleContext: context,
        mode: mode,
        history: history,
      );
      await _saveAssistantReply(reply);
    } on AiGatewayException catch (e) {
      if (e.isPremiumRequired || e.isProfileRequired) {
        if (await _tryRecoverPremium()) {
          try {
            final context = await _safeContext();
            final reply = await _streamReplyWithFallback(
              emit: emit,
              message: text,
              cycleContext: context,
              mode: mode,
              history: history,
            );
            await _saveAssistantReply(reply);
            return;
          } on AiGatewayException catch (retryError) {
            await _handleGatewayError(retryError, emit);
            return;
          }
        }
        _emitNotice(emit, ChatNoticeType.premiumRequired);
        await _saveAssistantReply(e.userMessage);
        return;
      }
      await _handleGatewayError(e, emit);
    } catch (e, st) {
      debugPrint('[ChatBloc] send failed: $e\n$st');
      await _saveAssistantReply(
        const AiGatewayException('server_error').userMessage,
      );
    } finally {
      _clearSending(emit);
    }
  }

  Future<Map<String, dynamic>> _safeContext() async {
    try {
      return await contextEngine.buildAnonymizedContext();
    } catch (e, st) {
      debugPrint('[ChatBloc] context build failed: $e\n$st');
      return const {'userLocale': 'ar'};
    }
  }

  Future<void> _handleGatewayError(
    AiGatewayException e,
    Emitter<ChatState> emit,
  ) async {
    if (e.isDailyLimit) {
      _emitNotice(emit, ChatNoticeType.dailyLimit);
      await _saveAssistantReply(e.userMessage);
      return;
    }
    if (e.isPremiumRequired || e.isProfileRequired) {
      _emitNotice(emit, ChatNoticeType.premiumRequired);
    }
    if (e.isConsentRequired) {
      _emitNotice(emit, ChatNoticeType.consent);
    }
    if (e.isAdultRequired) {
      _emitNotice(emit, ChatNoticeType.adultRequired);
    }
    await _saveAssistantReply(e.userMessage);
  }

  /// Streams the reply token-by-token via [ChatRepository.streamAiReply],
  /// emitting partial state for live rendering.
  Future<String> _streamReplyWithFallback({
    required Emitter<ChatState> emit,
    required String message,
    required Map<String, dynamic> cycleContext,
    required String mode,
    required List<ChatMessage> history,
    bool analyzeMode = false,
  }) async {
    final buffer = StringBuffer();
    final personality = LunePersonalityPrefs.current.id;

    await for (final chunk in repository.streamAiReply(
      message: message,
      cycleContext: cycleContext,
      mode: analyzeMode ? 'analyze' : mode,
      personality: personality,
      history: history,
    )) {
      buffer.write(chunk);
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(
          isSending: true,
          partialReply: AiActionParser.sanitizeForDisplay(buffer.toString()),
        ));
      }
    }

    if (buffer.isNotEmpty) {
      return buffer.toString();
    }

    return repository.requestAiReply(
      message: message,
      cycleContext: cycleContext,
      analyzeMode: analyzeMode,
      mode: mode,
      personality: personality,
      history: history,
    );
  }

  Future<void> _onAnalyze(
    AnalyzeCycleRequested event,
    Emitter<ChatState> emit,
  ) async {
    final access = await PremiumGate.checkAiChat();
    if (access == PremiumAiAccess.needsAdult) {
      _emitNotice(emit, ChatNoticeType.adultRequired);
      return;
    }
    if (access == PremiumAiAccess.needsPremium) {
      _emitNotice(emit, ChatNoticeType.premiumRequired);
      return;
    }
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
    unawaited(
      repository
          .saveMessage(
            uid,
            ChatMessage(
              id: '',
              text: prompt,
              isUser: true,
              timestamp: DateTime.now(),
            ),
          )
          .catchError(
            (Object e) =>
                debugPrint('[ChatBloc] save analyze prompt failed: $e'),
          ),
    );

    try {
      final context = await _safeContext();
      final reply = await _streamReplyWithFallback(
        emit: emit,
        message: prompt,
        cycleContext: context,
        mode: 'analyze',
        history: const [],
        analyzeMode: true,
      );
      await _saveAssistantReply(reply);
    } on AiGatewayException catch (e) {
      if (e.isPremiumRequired || e.isProfileRequired) {
        if (await _tryRecoverPremium()) {
          try {
            final context = await _safeContext();
            final reply = await _streamReplyWithFallback(
              emit: emit,
              message: prompt,
              cycleContext: context,
              mode: 'analyze',
              history: const [],
              analyzeMode: true,
            );
            await _saveAssistantReply(reply);
            return;
          } on AiGatewayException catch (retryError) {
            await _handleGatewayError(retryError, emit);
            return;
          }
        }
      }
      await _handleGatewayError(e, emit);
    } catch (e, st) {
      debugPrint('[ChatBloc] analyze failed: $e\n$st');
      await _saveAssistantReply(
        const AiGatewayException('server_error').userMessage,
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
