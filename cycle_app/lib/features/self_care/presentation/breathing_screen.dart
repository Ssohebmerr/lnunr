import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/breathing_patterns.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key, this.pattern});

  final BreathingPattern? pattern;

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> {
  late BreathingPattern _pattern = widget.pattern ?? BreathingPatterns.box;
  int _stepIndex = 0;
  late int _secondsLeft = _pattern.steps.first.seconds;
  bool _running = false;
  Timer? _timer;
  int _completedCycles = 0;

  double _scale = 0.85;
  Duration _animDuration = const Duration(milliseconds: 600);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectPattern(BreathingPattern p) {
    if (p.key == _pattern.key) return;
    _timer?.cancel();
    setState(() {
      _pattern = p;
      _stepIndex = 0;
      _secondsLeft = p.steps.first.seconds;
      _running = false;
      _completedCycles = 0;
      _scale = 0.85;
      _animDuration = const Duration(milliseconds: 600);
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() {
      _running = true;
      _applyStepAnimation();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_secondsLeft > 1) {
      setState(() => _secondsLeft--);
      return;
    }
    // Advance to next step (wrapping) and pulse a haptic cue.
    HapticFeedback.selectionClick();
    setState(() {
      final next = (_stepIndex + 1) % _pattern.steps.length;
      if (next == 0) _completedCycles++;
      _stepIndex = next;
      _secondsLeft = _pattern.steps[_stepIndex].seconds;
      _applyStepAnimation();
    });
  }

  /// Sets the orb's target size + how long it takes to get there, so the
  /// visual grows across the whole inhale and shrinks across the whole exhale.
  void _applyStepAnimation() {
    final step = _pattern.steps[_stepIndex];
    _scale = step.type.scale;
    final isTransition = step.type == BreathPhaseType.inhale ||
        step.type == BreathPhaseType.exhale;
    _animDuration = isTransition
        ? Duration(seconds: step.seconds)
        : const Duration(milliseconds: 300);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final step = _pattern.steps[_stepIndex];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.selfCareBreathe),
      ),
      body: AppMeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight),
              // Pattern selector
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final p in BreathingPatterns.all)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _PatternChip(
                          label: p.name(lang),
                          selected: p.key == _pattern.key,
                          color: p.color,
                          onTap: () => _selectPattern(p),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _pattern.desc(lang),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimatedContainer(
                      duration: _animDuration,
                      curve: Curves.easeInOut,
                      width: 180 * _scale,
                      height: 180 * _scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _pattern.color,
                            _pattern.color.withValues(alpha: 0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _pattern.color.withValues(alpha: 0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$_secondsLeft',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(step.label(lang),
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      l10n.selfCareBreatheCycles(_completedCycles),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppGradientButton(
                      label: _running ? l10n.selfCarePause : l10n.selfCareStart,
                      icon: _running ? Icons.pause : Icons.play_arrow,
                      expanded: false,
                      onPressed: _toggle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternChip extends StatelessWidget {
  const _PatternChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.22)
              : theme.colorScheme.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.7)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
