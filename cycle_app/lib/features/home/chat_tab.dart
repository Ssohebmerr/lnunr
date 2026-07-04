import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

import '../../../core/ai/ai_action_parser.dart';
import '../../../core/ai/lune_personality.dart';
import '../../../core/app_home_refresh.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/premium/premium_activation_service.dart';
import '../../../core/premium/premium_status_notifier.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/premium/premium_upsell_dialog.dart';
import '../../../core/privacy/consent_dialogs.dart';
import '../premium/presentation/subscription_plans_screen.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../chat/bloc/chat_bloc.dart';
import '../chat/data/chat_message.dart';
import '../cycle/data/daily_log_writer.dart';

part 'chat_tab_bubbles.dart';
part 'chat_tab_welcome.dart';
part 'chat_tab_message.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _focusNode = FocusNode();
  bool _checkingConsent = true;
  bool _isPremium = false;
  LunePersonality _personality = LunePersonalityPrefs.current;
  final FlutterTts _tts = FlutterTts();
  String? _speakingMessageId;

  @override
  void initState() {
    super.initState();
    PremiumStatusNotifier.instance.addListener(_onPremiumChanged);
    _checkConsent();
    _controller.addListener(_onTextChanged);

    // ── TTS quality settings ──────────────────────────────────────────────
    // Rate: 0.45 = comfortable listening pace (0.0 slowest, 1.0 fastest)
    // Pitch: 1.05 = slightly warmer than robotic 1.0
    // Volume: 1.0 = full volume
    _tts.setSpeechRate(0.45);
    _tts.setPitch(1.05);
    _tts.setVolume(1.0);

    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingMessageId = null);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _speakingMessageId = null);
    });
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onPersonalitySelected(LunePersonality p) async {
    if (p == _personality) return;
    HapticFeedback.selectionClick();
    await LunePersonalityPrefs.set(p);
    if (!mounted) return;
    setState(() => _personality = p);
  }

  Future<void> _handleAction(AiSuggestedAction action) async {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    // Navigation actions don't persist anything — just deep-link.
    switch (action.type) {
      case AiActionType.openLog:
        HomeShellActions.openLog?.call();
        return;
      case AiActionType.openInsights:
        HomeShellActions.openReports?.call();
        return;
      default:
        break;
    }

    final label = action.label ?? action.value;

    // Persist the action into today's daily log (shared store the log screen
    // and the AI snapshot both read), then confirm with a real result.
    DailyLogWriteResult result;
    switch (action.type) {
      case AiActionType.logWater:
        final digits = action.value.replaceAll(RegExp(r'[^0-9]'), '');
        result = await DailyLogWriter.logWater(int.tryParse(digits) ?? 1);
      case AiActionType.logMood:
      case AiActionType.logSymptom:
      case AiActionType.logPain:
        result = await DailyLogWriter.logSymptom(action.value);
      default:
        return;
    }

    if (!mounted) return;

    if (result.ok) {
      HomeRefreshScope.refresh();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.aiActionLogged(result.matchedName ?? label)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.aiActionLogFailed),
          action: SnackBarAction(
            label: l10n.aiActionOpenLog,
            onPressed: () => HomeShellActions.openLog?.call(),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    setState(() => _isPremium = PremiumStatusNotifier.instance.isPremium);
  }

  Future<void> _checkConsent() async {
    var premium = await PremiumGate.hasPremium();
    if (premium) {
      // Re-validate the local flag against Firestore (server is authoritative).
      final status = await PremiumActivationService.refreshPremiumStatus();
      premium = status.ok || await PremiumGate.hasPremium();
    }
    if (mounted) {
      setState(() {
        _isPremium = premium;
        _checkingConsent = false;
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    PremiumStatusNotifier.instance.removeListener(_onPremiumChanged);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Cleans markdown and symbols so TTS reads naturally.
  /// Picks the best on-device TTS locale (no paid APIs — uses flutter_tts).
  Future<void> _setTtsLocale(bool arabic) async {
    final codes = arabic
        ? const ['ar-SA', 'ar-EG', 'ar']
        : const ['en-US', 'en-GB', 'en'];
    for (final code in codes) {
      try {
        final result = await _tts.setLanguage(code);
        if (result == 1) return;
      } catch (_) {
        // Try next fallback locale.
      }
    }
  }

  String _cleanForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\*{1,3}'), '')      // bold/italic asterisks
        .replaceAll(RegExp(r'_+'), '')             // underscores
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '') // headings
        .replaceAll(RegExp(r'^[-*•]\s+', multiLine: true), '') // bullets
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1') // links → label
        .replaceAll(RegExp(r'`{1,3}[^`]*`{1,3}'), '') // code blocks
        .replaceAll(RegExp(r'\n{2,}'), '. ')       // double newlines → pause
        .replaceAll('\n', ', ')                    // single newlines → comma
        .trim();
  }

  Future<void> _toggleTts(ChatMessage message, String cleanText) async {
    HapticFeedback.lightImpact();
    if (_speakingMessageId == message.id) {
      await _tts.stop();
      setState(() => _speakingMessageId = null);
    } else {
      await _tts.stop();
      final rawText = cleanText.isNotEmpty ? cleanText : message.text;
      final sanitized = AiActionParser.sanitizeForDisplay(rawText);
      final textToSpeak = _cleanForSpeech(sanitized);
      if (textToSpeak.isEmpty) return;

      // Automatic Arabic vs English character detection
      final isAr = RegExp(r'[\u0600-\u06FF]').hasMatch(textToSpeak);
      await _setTtsLocale(isAr);
      // Arabic needs slightly slower rate for clarity; pitch stays warm.
      await _tts.setSpeechRate(isAr ? 0.40 : 0.45);
      await _tts.setPitch(1.05);

      setState(() => _speakingMessageId = message.id);
      await _tts.speak(textToSpeak);
    }
  }

  Future<void> _send([String? preset, String mode = 'chat']) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;

    final access = await PremiumGate.checkAiChat();
    if (!mounted) return;

    if (access == PremiumAiAccess.needsConsent) {
      final ok = await showAiConsentDialog(context);
      if (!ok || !mounted) return;
    }
    if (access == PremiumAiAccess.needsPremium ||
        access == PremiumAiAccess.limitReached) {
      return;
    }

    context.read<ChatBloc>().add(SendChatMessage(text, mode: mode));
    if (preset == null) _controller.clear();
    _focusNode.requestFocus();
  }

  void _handleNotice(ChatNoticeType notice) {
    final bloc = context.read<ChatBloc>();
    final l10n = AppLocalizations.of(context)!;
    switch (notice) {
      case ChatNoticeType.consent:
        showAiConsentDialog(context);
      case ChatNoticeType.limit:
        showPremiumUpsellDialog(
          context,
          feature: PremiumUpsellFeature.aiChat,
        ).then((_) {
          if (mounted) _checkConsent();
        });
      case ChatNoticeType.dailyLimit:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiDailyLimitReached),
            duration: const Duration(seconds: 5),
          ),
        );
      case ChatNoticeType.premiumRequired:
        showPremiumUpsellDialog(
          context,
          feature: PremiumUpsellFeature.aiChat,
        ).then((_) {
          if (mounted) _checkConsent();
        });
    }
    bloc.add(ClearChatNotice());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_checkingConsent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isPremium) {
      return SubscriptionPlansScreen(
        embedded: true,
        onSubscribed: _checkConsent,
      );
    }

    return Column(
      children: [
        _PersonalityPicker(
          current: _personality,
          onSelect: _onPersonalitySelected,
        ),
        Expanded(
          child: BlocConsumer<ChatBloc, ChatState>(
            listener: (context, state) {
              if (state is ChatLoaded) {
                if (state.notice != null) {
                  _handleNotice(state.notice!);
                }
                _checkConsent();
                _scrollToBottom();
              }
            },
            builder: (context, state) {
              if (state is ChatLoading) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(l10n.loading),
                    ],
                  ),
                );
              }

              final messages =
                  state is ChatLoaded ? state.messages : <ChatMessage>[];
              final sending = state is ChatLoaded && state.isSending;

              if (messages.isEmpty && !sending) {
                return _WelcomeState(
                  l10n: l10n,
                  theme: theme,
                  personality: _personality,
                  onModeAction: (prompt, mode) => _send(prompt, mode),
                  onAnalyze: () =>
                      context.read<ChatBloc>().add(AnalyzeCycleRequested()),
                );
              }

              final items = _buildTimeline(messages, sending: sending);
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  if (item is _TimelineDayHeader) {
                    return _DaySeparator(label: item.label);
                  }
                  if (item is _TimelineMessage) {
                    final isAi = !item.message.isUser;
                    final actions = isAi
                        ? AiActionParser.parse(item.message.text)
                        : const AiActionParseResult(
                            cleanText: '', actions: []);
                    return _ChatMessageRow(
                      message: item.message,
                      theme: theme,
                      showAvatar: item.showAvatar,
                      showTime: item.showTime,
                      personality: _personality,
                      cleanText: isAi ? actions.cleanText : item.message.text,
                      suggestedActions: actions.actions,
                      onActionTap: _handleAction,
                      isSpeaking: _speakingMessageId == item.message.id,
                      onTtsTap: _toggleTts,
                    );
                  }
                  if (item is _TimelineTyping) {
                    return _TypingBubble(personality: _personality);
                  }
                  if (item is _TimelineStreaming) {
                    return _StreamingBubble(
                      text: item.text,
                      theme: theme,
                      personality: _personality,
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final messages =
                state is ChatLoaded ? state.messages : <ChatMessage>[];
            final sending = state is ChatLoaded && state.isSending;
            if (messages.isEmpty || sending || _controller.text.isNotEmpty) {
              return const SizedBox.shrink();
            }
            return _SuggestionStrip(
              l10n: l10n,
              personality: _personality,
              onTap: (text) => _send(text),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Text(
            l10n.homeAiCardSubtitlePremium,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final sending = state is ChatLoaded && state.isSending;
                return _ChatInputBar(
                  controller: _controller,
                  focusNode: _focusNode,
                  sending: sending,
                  hasText: _controller.text.trim().isNotEmpty,
                  theme: theme,
                  l10n: l10n,
                  onSend: () => _send(),
                  onEmergency: () =>
                      _send(l10n.aiEmergencyPrompt, 'emergency'),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Folds a flat message list into a timeline of day separators, message
  /// rows (with grouping hints), and a trailing typing/streaming row.
  List<Object> _buildTimeline(
    List<ChatMessage> messages, {
    required bool sending,
  }) {
    final items = <Object>[];
    DateTime? lastDay;
    DateTime? lastSenderTime;
    bool? lastIsUser;

    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final day = DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);
      if (lastDay == null || day != lastDay) {
        items.add(_TimelineDayHeader(_dayLabel(day)));
        lastDay = day;
        lastIsUser = null;
        lastSenderTime = null;
      }

      final isUser = m.isUser;
      final senderChanged = lastIsUser != isUser;
      final timeGap = lastSenderTime == null ||
          m.timestamp.difference(lastSenderTime).inMinutes >= 4;
      final showAvatar = senderChanged || timeGap;

      // Determine if this is the last message of its block.
      final next = i + 1 < messages.length ? messages[i + 1] : null;
      final blockEnds = next == null ||
          next.isUser != isUser ||
          next.timestamp.difference(m.timestamp).inMinutes >= 4 ||
          DateTime(next.timestamp.year, next.timestamp.month,
                  next.timestamp.day) !=
              day;

      items.add(_TimelineMessage(
        message: m,
        showAvatar: showAvatar,
        showTime: blockEnds,
      ));

      lastIsUser = isUser;
      lastSenderTime = m.timestamp;
    }

    if (sending) {
      final partial = context.select<ChatBloc, String?>((b) {
        final s = b.state;
        return s is ChatLoaded ? s.partialReply : null;
      });
      if (partial != null && partial.isNotEmpty) {
        items.add(_TimelineStreaming(partial));
      } else {
        items.add(const _TimelineTyping());
      }
    }
    return items;
  }

  String _dayLabel(DateTime day) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.dayLabelToday;
    if (diff == 1) return l10n.dayLabelYesterday;
    if (diff < 7) return DateFormat.EEEE(_locale()).format(day);
    return DateFormat.yMMMd(_locale()).format(day);
  }

  String _locale() => Localizations.localeOf(context).toLanguageTag();
}

// Timeline tokens (internal-only).
class _TimelineDayHeader {
  const _TimelineDayHeader(this.label);
  final String label;
}

class _TimelineMessage {
  const _TimelineMessage({
    required this.message,
    required this.showAvatar,
    required this.showTime,
  });
  final ChatMessage message;
  final bool showAvatar;
  final bool showTime;
}

class _TimelineTyping {
  const _TimelineTyping();
}

class _TimelineStreaming {
  const _TimelineStreaming(this.text);
  final String text;
}

// ---------------------------------------------------------------------------
// Input bar — clean, modern design
// ---------------------------------------------------------------------------
class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.hasText,
    required this.theme,
    required this.l10n,
    required this.onSend,
    required this.onEmergency,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool hasText;
  final ThemeData theme;
  final AppLocalizations l10n;
  final VoidCallback onSend;
  final VoidCallback onEmergency;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final canSend = hasText && !sending;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: focusNode.hasFocus
              ? theme.colorScheme.primary.withValues(alpha: 0.45)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : theme.colorScheme.outline.withValues(alpha: 0.10)),
          width: focusNode.hasFocus ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: focusNode.hasFocus
                ? theme.colorScheme.primary.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
            child: Tooltip(
              message: l10n.aiEmergencyTooltip,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: sending ? null : onEmergency,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.medical_services_outlined,
                      color: sending
                          ? theme.colorScheme.outline
                          : Colors.red.shade300,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              enabled: !sending,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              decoration: InputDecoration(
                hintText: l10n.aiPlaceholder,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.55),
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
              ),
              onSubmitted: canSend ? (_) => onSend() : null,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6, bottom: 6),
            child: AnimatedScale(
              scale: canSend || sending ? 1.0 : 0.92,
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: canSend ? onSend : null,
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: canSend
                          ? AuraDecorations.primaryGradient
                          : null,
                      color: canSend
                          ? null
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.7)),
                      shape: BoxShape.circle,
                      boxShadow: canSend
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: sending
                        ? Padding(
                            padding: const EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            color: canSend
                                ? Colors.white
                                : theme.colorScheme.outline,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day separator — pill chip between message groups from different days.
// ---------------------------------------------------------------------------
class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Suggestion strip — quick prompts that appear above the composer.
// ---------------------------------------------------------------------------
class _SuggestionStrip extends StatelessWidget {
  const _SuggestionStrip({
    required this.l10n,
    required this.personality,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final LunePersonality personality;
  final ValueChanged<String> onTap;

  List<({IconData icon, String label})> _items() {
    return switch (personality) {
      LunePersonality.doctor => [
          (icon: Icons.spa_outlined, label: l10n.aiSuggestExplainPhase),
          (icon: Icons.science_outlined, label: l10n.aiSuggestSymptomCheck),
          (icon: Icons.medical_information_outlined, label: l10n.aiSuggestPrep),
        ],
      LunePersonality.coach => [
          (icon: Icons.bolt_outlined, label: l10n.aiSuggestEnergyBoost),
          (icon: Icons.fitness_center_outlined, label: l10n.aiSuggestMoveToday),
          (icon: Icons.flag_outlined, label: l10n.aiSuggestSetGoal),
        ],
      LunePersonality.friend => [
          (icon: Icons.wb_sunny_outlined, label: l10n.aiSuggestHowsMyDay),
          (icon: Icons.mood_outlined, label: l10n.aiSuggestMoodCheck),
          (icon: Icons.restaurant_outlined, label: l10n.aiSuggestFoodIdeas),
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = _items();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => onTap(item.label),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Streaming bubble — shows the live partial reply being generated.
// ---------------------------------------------------------------------------
// _StreamingBubble, _BlinkingCaret, and _TypingBubble live in
// chat_tab_bubbles.dart (part of this library).
