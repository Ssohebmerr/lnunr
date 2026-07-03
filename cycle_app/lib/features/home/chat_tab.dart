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
      final grant = await PremiumActivationService.grantTesterPremium();
      premium = grant.ok || await PremiumGate.hasPremium();
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
// Welcome state — beautiful feature cards grid
// ---------------------------------------------------------------------------
class _WelcomeState extends StatelessWidget {
  const _WelcomeState({
    required this.l10n,
    required this.theme,
    required this.personality,
    required this.onModeAction,
    required this.onAnalyze,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final LunePersonality personality;
  final void Function(String prompt, String mode) onModeAction;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const SizedBox(height: 8),
        // Greeting icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppShadows.softRose(opacity: 0.25),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.aiWelcome,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.aiWelcomeHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // Feature cards — 2-column grid
        Text(
          l10n.aiQuickActionsTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _FeatureCardsGrid(onModeAction: onModeAction),
        const SizedBox(height: 16),
        // Analyze button
        Center(
          child: Container(
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: AppShadows.softRose(opacity: 0.2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAnalyze,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.analytics_outlined,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l10n.aiAnalyze,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Feature cards — 2-column grid with colored icons
// ---------------------------------------------------------------------------
class _FeatureCardsGrid extends StatelessWidget {
  const _FeatureCardsGrid({required this.onModeAction});

  final void Function(String prompt, String mode) onModeAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final features = <_FeatureCardData>[
      _FeatureCardData(
        icon: Icons.wb_sunny_outlined,
        gradient: const [Color(0xFFFFB347), Color(0xFFFFCC33)],
        label: l10n.aiFeatureBriefing,
        prompt: l10n.aiFeatureBriefingPrompt,
        mode: 'briefing',
      ),
      _FeatureCardData(
        icon: Icons.insights_outlined,
        gradient: const [Color(0xFF6B7FE8), Color(0xFF8F9FF5)],
        label: l10n.aiFeaturePatterns,
        prompt: l10n.aiFeaturePatternsPrompt,
        mode: 'patterns',
      ),
      _FeatureCardData(
        icon: Icons.restaurant_outlined,
        gradient: const [Color(0xFF3D9A78), Color(0xFF5CC4A0)],
        label: l10n.aiFeatureNutrition,
        prompt: l10n.aiFeatureNutritionPrompt,
        mode: 'nutrition',
      ),
      _FeatureCardData(
        icon: Icons.favorite_outline,
        gradient: const [Color(0xFFE85D75), Color(0xFFF58BA0)],
        label: l10n.aiFeaturePartner,
        prompt: l10n.aiFeaturePartnerPrompt,
        mode: 'partner',
      ),
      _FeatureCardData(
        icon: Icons.mood_outlined,
        gradient: const [Color(0xFF9B59B6), Color(0xFFC084E0)],
        label: l10n.aiFeatureMood,
        prompt: l10n.aiFeatureMoodPrompt,
        mode: 'mood',
      ),
      _FeatureCardData(
        icon: Icons.emergency_outlined,
        gradient: const [Color(0xFFE74C3C), Color(0xFFF07070)],
        label: l10n.aiFeatureEmergency,
        prompt: l10n.aiEmergencyPrompt,
        mode: 'emergency',
      ),
      _FeatureCardData(
        icon: Icons.egg_rounded,
        gradient: const [Color(0xFFE85D75), Color(0xFFF4A0B0)],
        label: l10n.aiFeatureFertility,
        prompt: l10n.aiFeatureFertilityPrompt,
        mode: 'fertility',
      ),
      _FeatureCardData(
        icon: Icons.monitor_weight_outlined,
        gradient: const [Color(0xFF3D9A78), Color(0xFF6BC4A0)],
        label: l10n.aiFeatureWeight,
        prompt: l10n.aiFeatureWeightPrompt,
        mode: 'weight',
      ),
      _FeatureCardData(
        icon: Icons.favorite_outline,
        gradient: const [Color(0xFF9B59B6), Color(0xFFC084E0)],
        label: l10n.aiFeatureIntimacy,
        prompt: l10n.aiFeatureIntimacyPrompt,
        mode: 'intimacy',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.6,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        final f = features[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onModeAction(f.prompt, f.mode),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Ink(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.9),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: f.gradient,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(f.icon, size: 17, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureCardData {
  const _FeatureCardData({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.prompt,
    required this.mode,
  });

  final IconData icon;
  final List<Color> gradient;
  final String label;
  final String prompt;
  final String mode;
}

// ---------------------------------------------------------------------------
// Personality picker — three Lune personas as glass chips.
// ---------------------------------------------------------------------------
class _PersonalityPicker extends StatelessWidget {
  const _PersonalityPicker({required this.current, required this.onSelect});

  final LunePersonality current;
  final ValueChanged<LunePersonality> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: LunePersonality.values.map((p) {
          final meta = kLunePersonalityMeta[p]!;
          final selected = current == p;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(p),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(colors: meta.gradient)
                          : null,
                      color: selected
                          ? null
                          : theme.colorScheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : theme.colorScheme.outline.withValues(alpha: 0.12),
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: meta.gradient.first
                                    .withValues(alpha: 0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          meta.icon,
                          size: 16,
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            meta.title(lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
// Message row — user or AI, grouped, with optional avatar/timestamp/actions.
// ---------------------------------------------------------------------------
class _ChatMessageRow extends StatelessWidget {
  const _ChatMessageRow({
    required this.message,
    required this.theme,
    required this.showAvatar,
    required this.showTime,
    required this.personality,
    required this.cleanText,
    required this.suggestedActions,
    required this.onActionTap,
    required this.isSpeaking,
    required this.onTtsTap,
  });

  final ChatMessage message;
  final ThemeData theme;
  final bool showAvatar;
  final bool showTime;
  final LunePersonality personality;
  final String cleanText;
  final List<AiSuggestedAction> suggestedActions;
  final ValueChanged<AiSuggestedAction> onActionTap;
  final bool isSpeaking;
  final Function(ChatMessage, String) onTtsTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxW = MediaQuery.of(context).size.width * 0.78;
    final isDark = theme.brightness == Brightness.dark;
    final timeText = DateFormat.Hm().format(message.timestamp);
    final bubbleSpacing = showAvatar ? 10.0 : 4.0;

    if (isUser) {
      return Padding(
        padding: EdgeInsets.only(bottom: bubbleSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(maxWidth: maxW),
                decoration: BoxDecoration(
                  gradient: AuraDecorations.primaryGradient,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: const Radius.circular(20),
                    topEnd: const Radius.circular(20),
                    bottomStart: const Radius.circular(20),
                    bottomEnd: Radius.circular(showTime ? 6 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SelectableText(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.5,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
            if (showTime)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4, end: 6),
                child: Text(
                  timeText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 10.5,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // AI message
    final meta = kLunePersonalityMeta[personality]!;
    return Padding(
      padding: EdgeInsets.only(bottom: bubbleSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: showAvatar
                ? _LuneAvatar(meta: meta)
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(maxWidth: maxW),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadiusDirectional.only(
                      topStart: Radius.circular(showAvatar ? 6 : 20),
                      topEnd: const Radius.circular(20),
                      bottomStart: const Radius.circular(20),
                      bottomEnd: const Radius.circular(20),
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.65),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.18 : 0.04,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    cleanText.isNotEmpty ? cleanText : message.text,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      height: 1.55,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                if (suggestedActions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _AiActionChips(
                      actions: suggestedActions,
                      onTap: onActionTap,
                    ),
                  ),
                // ── Bottom action row: time + TTS pill + report ────────────
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showTime)
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.only(top: 6, start: 4),
                        child: Text(
                          timeText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // ── TTS pill button — prominent & animated ────────────
                    GestureDetector(
                      onTap: () => onTtsTap(message, cleanText),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSpeaking
                              ? theme.colorScheme.primary.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: isDark ? 0.35 : 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSpeaking
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.55)
                                : theme.colorScheme.outline
                                    .withValues(alpha: 0.18),
                            width: 1,
                          ),
                          boxShadow: isSpeaking
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSpeaking
                                  ? Icons.stop_rounded
                                  : Icons.volume_up_rounded,
                              size: 14,
                              color: isSpeaking
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSpeaking ? 'إيقاف' : 'استمع',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSpeaking
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ── Report button ─────────────────────────────────────
                    GestureDetector(
                      onTap: () => _showAiReportDialog(context,
                          cleanText.isNotEmpty ? cleanText : message.text),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 5),
                        child: Icon(
                          Icons.flag_outlined,
                          size: 15,
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAiReportDialog(BuildContext context, String responseText) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
              isAr ? 'الإبلاغ عن رد الذكاء الاصطناعي' : 'Report AI Response'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAr
                    ? 'هل تعتقد أن هذا الرد غير دقيق، طبي، أو غير مناسب؟ سيتم إرساله للمطورين لمراجعة السلامة.'
                    : 'Do you believe this response is inaccurate, medical, or inappropriate? It will be sent to the developers for safety review.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _reportOption(ctx, isAr ? 'طبي / تشخيصي' : 'Medical / Diagnostic', responseText),
                  _reportOption(ctx, isAr ? 'غير دقيق' : 'Inaccurate', responseText),
                  _reportOption(ctx, isAr ? 'محتوى غير لائق' : 'Inappropriate', responseText),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _reportOption(BuildContext dialogContext, String label, String text) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(dialogContext);
        final isAr =
            Localizations.localeOf(dialogContext).languageCode == 'ar';
        Navigator.pop(dialogContext);

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'سجّلي الدخول أولاً عشان يوصل البلاغ للوحة الإدارة.'
                    : 'Sign in first so the report can reach the admin panel.',
              ),
            ),
          );
          return;
        }

        try {
          final clipped = text.length > 4000 ? text.substring(0, 4000) : text;
          await FirebaseFirestore.instance.collection('aiReports').add({
            'uid': user.uid,
            'email': user.email ?? '',
            'reason': label,
            'response': clipped,
            'source': 'ai_chat',
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'timestamp': FieldValue.serverTimestamp(),
          });
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'شكرًا لإبلاغك. وصل البلاغ للوحة الإدارة لمراجعة السلامة.'
                    : 'Thank you. The report was sent to the admin panel for safety review.',
              ),
            ),
          );
        } catch (e) {
          debugPrint('aiReports write failed: $e');
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'ما قدرنا نرسل البلاغ. تأكدي من الإنترنت وحاولي مرة ثانية.'
                    : 'Could not send the report. Check your connection and try again.',
              ),
            ),
          );
        }
      },
    );
  }
}

class _LuneAvatar extends StatelessWidget {
  const _LuneAvatar({required this.meta});

  final LunePersonalityMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: meta.gradient),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: meta.gradient.first.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(meta.icon, size: 16, color: Colors.white),
    );
  }
}

class _AiActionChips extends StatelessWidget {
  const _AiActionChips({required this.actions, required this.onTap});

  final List<AiSuggestedAction> actions;
  final ValueChanged<AiSuggestedAction> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: actions.map((a) {
        final (icon, label) = _renderFor(a, l10n);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => onTap(a),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: AuraDecorations.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  (IconData, String) _renderFor(
      AiSuggestedAction a, AppLocalizations l10n) {
    return switch (a.type) {
      AiActionType.logMood => (
          Icons.mood_rounded,
          a.label ?? l10n.aiActionLogMood(a.value)
        ),
      AiActionType.logSymptom => (
          Icons.healing_rounded,
          a.label ?? l10n.aiActionLogSymptom(a.value)
        ),
      AiActionType.logWater => (
          Icons.water_drop_rounded,
          a.label ?? l10n.aiActionLogWater(a.value)
        ),
      AiActionType.logPain => (
          Icons.bolt_rounded,
          a.label ?? l10n.aiActionLogPain(a.value)
        ),
      AiActionType.openLog => (
          Icons.edit_note_rounded,
          a.label ?? l10n.aiActionOpenLog
        ),
      AiActionType.openInsights => (
          Icons.insights_rounded,
          a.label ?? l10n.aiActionOpenInsights
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Streaming bubble — shows the live partial reply being generated.
// ---------------------------------------------------------------------------
class _StreamingBubble extends StatelessWidget {
  const _StreamingBubble({
    required this.text,
    required this.theme,
    required this.personality,
  });

  final String text;
  final ThemeData theme;
  final LunePersonality personality;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final meta = kLunePersonalityMeta[personality]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LuneAvatar(meta: meta),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.78),
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(6),
                  topEnd: Radius.circular(20),
                  bottomStart: Radius.circular(20),
                  bottomEnd: Radius.circular(20),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.65),
                ),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    height: 1.55,
                    fontSize: 16.0,
                  ),
                  children: [
                    TextSpan(text: text),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: _BlinkingCaret(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret({required this.color});

  final Color color;

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2.5,
        height: 16,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing indicator — animated dots inside a Lune-style bubble.
// ---------------------------------------------------------------------------
class _TypingBubble extends StatefulWidget {
  const _TypingBubble({required this.personality});

  final LunePersonality personality;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meta = kLunePersonalityMeta[widget.personality]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LuneAvatar(meta: meta),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.78),
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(6),
                topEnd: Radius.circular(20),
                bottomStart: Radius.circular(20),
                bottomEnd: Radius.circular(20),
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.15;
                  final value = ((_controller.value - delay) % 1.0);
                  final opacity = (value < 0.5)
                      ? (0.3 + value * 1.4)
                      : (1.0 - (value - 0.5) * 1.4);
                  return Padding(
                    padding: EdgeInsetsDirectional.only(end: i < 2 ? 5 : 0),
                    child: Opacity(
                      opacity: opacity.clamp(0.3, 1.0),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
