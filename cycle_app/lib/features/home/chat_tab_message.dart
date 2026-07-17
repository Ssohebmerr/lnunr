part of 'chat_tab.dart';

// ---------------------------------------------------------------------------
// Message row — user or AI, grouped, with optional avatar/timestamp/actions.
// Includes the Lune avatar, AI action chips, and the safety-report dialog.
// Extracted from chat_tab.dart to keep the screen file focused.
// ---------------------------------------------------------------------------
class _ChatMessageRow extends StatelessWidget {
  const _ChatMessageRow({
    super.key,
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
    required this.isExpanded,
    required this.onToggleExpand,
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

  /// Whether this AI reply is currently expanded past the "Read more" fold.
  /// Held by the parent (keyed by message id) so it survives list recycling.
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxW = MediaQuery.of(context).size.width * 0.78;
    // AI replies get a touch more width for comfortable long-form reading.
    final aiMaxW = MediaQuery.of(context).size.width * 0.88;
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
              child: _ChatGlassSurface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                constraints: BoxConstraints(maxWidth: maxW),
                borderRadius: BorderRadiusDirectional.only(
                  topStart: const Radius.circular(20),
                  topEnd: const Radius.circular(20),
                  bottomStart: const Radius.circular(20),
                  bottomEnd: Radius.circular(showTime ? 6 : 18),
                ),
                strong: true,
                accent: theme.colorScheme.primary,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.78),
                    AuraColors.roseDeep.withValues(alpha: 0.68),
                    AuraColors.lavender.withValues(alpha: 0.46),
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
                _ChatGlassSurface(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  constraints: BoxConstraints(maxWidth: aiMaxW),
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(showAvatar ? 8 : 16),
                    topEnd: const Radius.circular(16),
                    bottomStart: const Radius.circular(16),
                    bottomEnd: const Radius.circular(16),
                  ),
                  child: AiResponseText(
                    span: _LuneMarkdown.build(
                      cleanText.isNotEmpty ? cleanText : message.text,
                      TextStyle(
                        color: theme.colorScheme.onSurface,
                        height: 1.62,
                        fontSize: 16,
                      ),
                    ),
                    expanded: isExpanded,
                    onToggle: onToggleExpand,
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
                // Quiet, accessible response actions. Secondary safety
                // actions stay available in the overflow menu.
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
                    _AiMessageActionButton(
                      tooltip: isSpeaking
                          ? (isArabic ? 'إيقاف القراءة' : 'Stop reading')
                          : (isArabic ? 'الاستماع للرد' : 'Listen to response'),
                      icon: isSpeaking
                          ? Icons.stop_rounded
                          : Icons.volume_up_outlined,
                      active: isSpeaking,
                      onPressed: () => onTtsTap(message, cleanText),
                    ),
                    _AiMessageActionButton(
                      tooltip: isArabic ? 'نسخ الرد' : 'Copy response',
                      icon: Icons.copy_all_outlined,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final text = cleanText.isNotEmpty
                            ? cleanText
                            : message.text;
                        await Clipboard.setData(ClipboardData(text: text));
                        HapticFeedback.selectionClick();
                        messenger.showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            content: Text(
                              isArabic ? 'تم نسخ الرد' : 'Response copied',
                            ),
                          ),
                        );
                      },
                    ),
                    PopupMenuButton<_AiMessageMenuAction>(
                      tooltip: isArabic ? 'المزيد' : 'More',
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.72,
                        ),
                      ),
                      onSelected: (action) {
                        if (action == _AiMessageMenuAction.report) {
                          _showAiReportDialog(
                            context,
                            cleanText.isNotEmpty ? cleanText : message.text,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _AiMessageMenuAction.report,
                          child: Row(
                            children: [
                              const Icon(Icons.flag_outlined, size: 19),
                              const SizedBox(width: 10),
                              Text(
                                isArabic
                                    ? 'الإبلاغ عن الرد'
                                    : 'Report response',
                              ),
                            ],
                          ),
                        ),
                      ],
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

enum _AiMessageMenuAction { report }

class _AiMessageActionButton extends StatelessWidget {
  const _AiMessageActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: 40,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: active
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          foregroundColor: active
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),
        icon: Icon(icon, size: 19),
      ),
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
            color: meta.gradient.first.withValues(alpha: 0.24),
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
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
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

// ---------------------------------------------------------------------------
// Collapsible AI reply text — ChatGPT/Claude-style comfortable reading.
//
// Long replies fold to [_collapsedLines] lines behind a "Read more" toggle
// that expands with a smooth height animation and a soft fade at the fold.
// Short replies render untouched.
//
// This widget is CONTROLLED: the expanded flag is owned by the parent (keyed
// by message id), so scrolling the list never recycles a stale expand state
// onto the wrong message and the text never "jumps open" on its own. Pure UI:
// no message data, logic, or API is altered here.
// ---------------------------------------------------------------------------
class AiResponseText extends StatelessWidget {
  const AiResponseText({
    super.key,
    required this.span,
    required this.expanded,
    required this.onToggle,
  });

  /// Pre-built rich span for the reply (bold / bullets already applied).
  final TextSpan span;
  final bool expanded;
  final VoidCallback onToggle;

  /// A long response shows seven readable lines before the explicit toggle.
  /// This is intentionally the same threshold used for measurement, so an
  /// eighth line always gets a "Show more" affordance instead of being clipped.
  static const collapsedLines = 7;

  @visibleForTesting
  static const collapsedTextKey = ValueKey('ai-response-collapsed');

  @visibleForTesting
  static const expandedTextKey = ValueKey('ai-response-expanded');

  @visibleForTesting
  static const toggleKey = ValueKey('ai-response-toggle');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textDirection = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width * 0.84;

        // Measure — at the exact render width — whether the reply exceeds the
        // seven-line fold. Uses the same span the SelectableText renders, so the
        // decision is pixel-accurate.
        final painter = TextPainter(
          text: span,
          textDirection: textDirection,
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.localeOf(context),
          maxLines: collapsedLines,
        )..layout(maxWidth: maxWidth);
        final overflows = painter.didExceedMaxLines;

        final content = SelectableText.rich(
          span,
          key: expanded ? expandedTextKey : collapsedTextKey,
          maxLines: (!overflows || expanded) ? null : collapsedLines,
        );

        // Short reply: render as-is, no toggle.
        if (!overflows) return content;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? content
                  : ShaderMask(
                      shaderCallback: (bounds) {
                        // Fade only the last ~28px so the fold reads as
                        // "there's more", not a hard cut.
                        final h = bounds.height;
                        final stop = h <= 44 ? 0.55 : (h - 28) / h;
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: const [
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [0.0, stop.clamp(0.0, 1.0), 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: content,
                    ),
            ),
            _ReadMoreButton(
              expanded: expanded,
              color: theme.colorScheme.primary,
              onTap: onToggle,
            ),
          ],
        );
      },
    );
  }
}

class _ReadMoreButton extends StatelessWidget {
  const _ReadMoreButton({
    required this.expanded,
    required this.color,
    required this.onTap,
  });

  final bool expanded;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = expanded ? l10n.showLess : l10n.showMore;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: AiResponseText.toggleKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        // Generous hit area (≥40px tall) for comfortable tapping on mobile.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lightweight inline markdown → rich text.
//
// Lune replies are prose-first but occasionally use **bold** for emphasis,
// `#` headings, and `-`/`*` bullet lines. We render those as real formatting
// (no external package, no dependency changes) instead of leaking raw
// asterisks to the reader. Every leaf carries an explicit style so the span is
// measured and rendered identically. Purely presentational — the underlying
// message text is never modified.
// ---------------------------------------------------------------------------
class _LuneMarkdown {
  _LuneMarkdown._();

  static final _bold = RegExp(r'\*\*(.+?)\*\*|__(.+?)__');
  static final _heading = RegExp(r'^\s{0,3}#{1,6}\s+');
  static final _bullet = RegExp(r'^(\s*)[-*•]\s+');

  static TextSpan build(String text, TextStyle base) {
    final lines = text.split('\n');
    final children = <InlineSpan>[];
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      var lineStyle = base;

      // Heading marker → bold line, drop the leading hashes.
      if (_heading.hasMatch(line)) {
        line = line.replaceFirst(_heading, '');
        lineStyle = base.copyWith(fontWeight: FontWeight.w700);
      }

      // Bullet marker → normalise to a real bullet glyph.
      final bullet = _bullet.firstMatch(line);
      if (bullet != null) {
        final indent = bullet.group(1) ?? '';
        line = '$indent•  ${line.substring(bullet.end)}';
      }

      children.addAll(_inline(line, lineStyle));
      if (i != lines.length - 1) {
        children.add(TextSpan(text: '\n', style: base));
      }
    }
    return TextSpan(style: base, children: children);
  }

  static List<InlineSpan> _inline(String line, TextStyle lineStyle) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _bold.allMatches(line)) {
      if (m.start > last) {
        spans.add(
          TextSpan(text: line.substring(last, m.start), style: lineStyle),
        );
      }
      final content = m.group(1) ?? m.group(2) ?? '';
      spans.add(
        TextSpan(
          text: content,
          style: lineStyle.copyWith(fontWeight: FontWeight.w700),
        ),
      );
      last = m.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last), style: lineStyle));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: '', style: lineStyle));
    return spans;
  }
}
