part of 'chat_tab.dart';

// ---------------------------------------------------------------------------
// Message row — user or AI, grouped, with optional avatar/timestamp/actions.
// Includes the Lune avatar, AI action chips, and the safety-report dialog.
// Extracted from chat_tab.dart to keep the screen file focused.
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
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
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                        padding: const EdgeInsetsDirectional.only(
                          top: 6,
                          start: 4,
                        ),
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
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSpeaking
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                )
                              : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: isDark ? 0.35 : 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSpeaking
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.55,
                                  )
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.18,
                                  ),
                            width: 1,
                          ),
                          boxShadow: isSpeaking
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.25,
                                    ),
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
                              isSpeaking
                                  ? (isArabic ? 'إيقاف' : 'Stop')
                                  : (isArabic ? 'استمع' : 'Listen'),
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
                      onTap: () => _showAiReportDialog(
                        context,
                        cleanText.isNotEmpty ? cleanText : message.text,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 5,
                        ),
                        child: Icon(
                          Icons.flag_outlined,
                          size: 15,
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.5,
                          ),
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
            isAr ? 'الإبلاغ عن رد الذكاء الاصطناعي' : 'Report AI Response',
          ),
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
                  _reportOption(
                    ctx,
                    isAr ? 'طبي / تشخيصي' : 'Medical / Diagnostic',
                    responseText,
                  ),
                  _reportOption(
                    ctx,
                    isAr ? 'غير دقيق' : 'Inaccurate',
                    responseText,
                  ),
                  _reportOption(
                    ctx,
                    isAr ? 'محتوى غير لائق' : 'Inappropriate',
                    responseText,
                  ),
                ],
              ),
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
        final isAr = Localizations.localeOf(dialogContext).languageCode == 'ar';
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: AuraDecorations.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
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

  (IconData, String) _renderFor(AiSuggestedAction a, AppLocalizations l10n) {
    return switch (a.type) {
      AiActionType.logMood => (
        Icons.mood_rounded,
        a.label ?? l10n.aiActionLogMood(a.value),
      ),
      AiActionType.logSymptom => (
        Icons.healing_rounded,
        a.label ?? l10n.aiActionLogSymptom(a.value),
      ),
      AiActionType.logWater => (
        Icons.water_drop_rounded,
        a.label ?? l10n.aiActionLogWater(a.value),
      ),
      AiActionType.logPain => (
        Icons.bolt_rounded,
        a.label ?? l10n.aiActionLogPain(a.value),
      ),
      AiActionType.openLog => (
        Icons.edit_note_rounded,
        a.label ?? l10n.aiActionOpenLog,
      ),
      AiActionType.openInsights => (
        Icons.insights_rounded,
        a.label ?? l10n.aiActionOpenInsights,
      ),
    };
  }
}
