part of 'chat_tab.dart';

// ---------------------------------------------------------------------------
// Streaming reply bubble + blinking caret, and the typing indicator.
// Extracted from chat_tab.dart to keep that file focused on the screen.
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
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: Builder(
                builder: (context) {
                  final base = TextStyle(
                    color: theme.colorScheme.onSurface,
                    height: 1.68,
                    fontSize: 16.5,
                  );
                  return RichText(
                    text: TextSpan(
                      style: base,
                      children: [
                        _LuneMarkdown.build(text, base),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 2),
                            child: _BlinkingCaret(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
