import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/premium/premium_status_notifier.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/premium/premium_upsell_dialog.dart';
import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../chat/bloc/chat_bloc.dart';
import '../chat/data/chat_message.dart';

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
  int _freeRemaining = 5;

  @override
  void initState() {
    super.initState();
    PremiumStatusNotifier.instance.addListener(_onPremiumChanged);
    _checkConsent();
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    setState(() => _isPremium = PremiumStatusNotifier.instance.isPremium);
  }

  Future<void> _checkConsent() async {
    final premium = await PremiumGate.hasPremium();
    final remaining = await PremiumGate.remainingFreeAiMessages();
    if (mounted) {
      setState(() {
        _isPremium = premium;
        _freeRemaining = remaining;
        _checkingConsent = false;
      });
    }
  }

  @override
  void dispose() {
    PremiumStatusNotifier.instance.removeListener(_onPremiumChanged);
    _controller.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
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
    if (access == PremiumAiAccess.limitReached) {
      await showPremiumUpsellDialog(
        context,
        feature: PremiumUpsellFeature.aiChat,
      );
      if (mounted) await _checkConsent();
      return;
    }

    context.read<ChatBloc>().add(SendChatMessage(text, mode: mode));
    if (preset == null) _controller.clear();
    _focusNode.requestFocus();
  }

  void _handleNotice(ChatNoticeType notice) {
    final bloc = context.read<ChatBloc>();
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
      case ChatNoticeType.premiumRequired:
        showPremiumUpsellDialog(
          context,
          feature: PremiumUpsellFeature.aiAdvanced,
        );
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

    return Column(
      children: [
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
                  isPremium: _isPremium,
                  freeRemaining: _freeRemaining,
                  onModeAction: (prompt, mode) => _send(prompt, mode),
                  onAnalyze: () =>
                      context.read<ChatBloc>().add(AnalyzeCycleRequested()),
                );
              }

              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: messages.length + (sending ? 1 : 0),
                itemBuilder: (context, i) {
                  if (sending && i == messages.length) {
                    return const _TypingBubble();
                  }
                  return _MessageBubble(
                    message: messages[i],
                    theme: theme,
                  );
                },
              );
            },
          ),
        ),
        // Premium status
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Text(
            _isPremium
                ? l10n.homeAiCardSubtitlePremium
                : l10n.premiumAiFreeRemaining(_freeRemaining),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Input bar
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
}

// ---------------------------------------------------------------------------
// Input bar — clean, modern design
// ---------------------------------------------------------------------------
class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.theme,
    required this.l10n,
    required this.onSend,
    required this.onEmergency,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final ThemeData theme;
  final AppLocalizations l10n;
  final VoidCallback onSend;
  final VoidCallback onEmergency;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Emergency button — subtle, only visible when not sending
          if (!sending)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Tooltip(
                message: l10n.aiEmergencyTooltip,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEmergency,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.local_hospital_outlined,
                        color: Colors.red.shade300,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              enabled: !sending,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.aiPlaceholder,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              onSubmitted: sending ? null : (_) => onSend(),
            ),
          ),
          // Send button
          Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: sending ? null : onSend,
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient:
                        sending ? null : AuraDecorations.primaryGradient,
                    color: sending
                        ? theme.colorScheme.surfaceContainerHighest
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: sending
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
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
    required this.isPremium,
    required this.freeRemaining,
    required this.onModeAction,
    required this.onAnalyze,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final bool isPremium;
  final int freeRemaining;
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
        if (!isPremium) ...[
          const SizedBox(height: 6),
          Text(
            l10n.premiumAiFreeRemaining(freeRemaining),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
// Message bubble — clean, modern
// ---------------------------------------------------------------------------
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.theme,
  });

  final ChatMessage message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxW = MediaQuery.of(context).size.width * 0.78;
    final isDark = theme.brightness == Brightness.dark;

    if (isUser) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: maxW),
          decoration: BoxDecoration(
            gradient: AuraDecorations.primaryGradient,
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(18),
              topEnd: Radius.circular(18),
              bottomStart: Radius.circular(18),
              bottomEnd: Radius.circular(4),
            ),
          ),
          child: SelectableText(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              height: 1.55,
              fontSize: 14.5,
            ),
          ),
        ),
      );
    }

    // AI message
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(4),
                  topEnd: Radius.circular(18),
                  bottomStart: Radius.circular(18),
                  bottomEnd: Radius.circular(18),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  height: 1.55,
                  fontSize: 14.5,
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
// Typing indicator — animated dots
// ---------------------------------------------------------------------------
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(4),
                topEnd: Radius.circular(18),
                bottomStart: Radius.circular(18),
                bottomEnd: Radius.circular(18),
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
                    padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
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
