part of 'chat_tab.dart';

/// Shared frosted surface for chat bubbles. The grouped backdrop filter lets
/// long conversations reuse one backdrop sample instead of blurring the screen
/// independently for every message.
class _ChatGlassSurface extends StatelessWidget {
  const _ChatGlassSurface({
    required this.child,
    required this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.constraints,
    this.gradient,
    this.accent,
    this.strong = false,
  });

  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;
  final Gradient? gradient;
  final Color? accent;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedRadius = borderRadius.resolve(Directionality.of(context));
    final tint = accent ?? theme.colorScheme.primary;
    final surfaceGradient =
        gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AuraColors.darkCard.withValues(alpha: 0.62),
                  AuraColors.darkCard.withValues(alpha: 0.38),
                  tint.withValues(alpha: 0.09),
                ]
              : [
                  Colors.white.withValues(alpha: 0.58),
                  Colors.white.withValues(alpha: 0.30),
                  tint.withValues(alpha: 0.065),
                ],
          stops: const [0, 0.7, 1],
        );

    Widget glass = RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: resolvedRadius,
          boxShadow: [
            BoxShadow(
              color: (strong ? tint : Colors.black).withValues(
                alpha: strong
                    ? (isDark ? 0.18 : 0.11)
                    : (isDark ? 0.20 : 0.055),
              ),
              blurRadius: strong ? 18 : 14,
              offset: const Offset(0, 6),
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: resolvedRadius,
          child: BackdropFilter.grouped(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: resolvedRadius,
                gradient: surfaceGradient,
                border: Border.all(
                  color: strong
                      ? Colors.white.withValues(alpha: isDark ? 0.20 : 0.34)
                      : Colors.white.withValues(alpha: isDark ? 0.14 : 0.58),
                ),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
    if (constraints != null) {
      glass = ConstrainedBox(constraints: constraints!, child: glass);
    }
    return glass;
  }
}

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
    final meta = kLunePersonalityMeta[personality]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LuneAvatar(meta: meta),
          const SizedBox(width: 8),
          Flexible(
            child: _ChatGlassSurface(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(8),
                topEnd: Radius.circular(16),
                bottomStart: Radius.circular(16),
                bottomEnd: Radius.circular(16),
              ),
              child: Builder(
                builder: (context) {
                  final base = TextStyle(
                    color: theme.colorScheme.onSurface,
                    height: 1.62,
                    fontSize: 16,
                  );
                  return RichText(
                    text: TextSpan(
                      style: base,
                      children: [
                        _LuneMarkdown.build(text, base),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 2),
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
    final meta = kLunePersonalityMeta[widget.personality]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LuneAvatar(meta: meta),
          const SizedBox(width: 8),
          _ChatGlassSurface(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(8),
              topEnd: Radius.circular(16),
              bottomStart: Radius.circular(16),
              bottomEnd: Radius.circular(16),
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
