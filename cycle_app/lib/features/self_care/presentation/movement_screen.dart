import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/movement_content.dart';

/// A guided, phase-aware gentle-movement session. Replaces the old "stretch"
/// snackbar with a real timed routine (step name, form cue, countdown).
class MovementScreen extends StatefulWidget {
  const MovementScreen({super.key, required this.routine});

  final MovementRoutine routine;

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  int _stepIndex = 0;
  late int _secondsLeft = widget.routine.steps.first.seconds;
  bool _running = false;
  bool _finished = false;
  Timer? _timer;

  List<MovementStep> get _steps => widget.routine.steps;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_finished) {
      _restart();
      return;
    }
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_secondsLeft > 1) {
      setState(() => _secondsLeft--);
      return;
    }
    _advance();
  }

  void _advance() {
    if (_stepIndex >= _steps.length - 1) {
      _timer?.cancel();
      HapticFeedback.mediumImpact();
      setState(() {
        _running = false;
        _finished = true;
      });
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _stepIndex++;
      _secondsLeft = _steps[_stepIndex].seconds;
    });
  }

  void _skip() {
    if (_finished) return;
    _advance();
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _stepIndex = 0;
      _secondsLeft = _steps.first.seconds;
      _running = false;
      _finished = false;
    });
  }

  double get _progress {
    if (_finished) return 1;
    var elapsed = 0;
    for (var i = 0; i < _stepIndex; i++) {
      elapsed += _steps[i].seconds;
    }
    elapsed += _steps[_stepIndex].seconds - _secondsLeft;
    return (elapsed / widget.routine.totalSeconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final step = _steps[_stepIndex];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.routine.title(lang)),
      ),
      body: AppMeshBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, kToolbarHeight, 20, 24),
            child: Column(
              children: [
                Text(
                  widget.routine.subtitle(lang),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _progress),
                          duration: const Duration(milliseconds: 400),
                          builder: (_, value, _) => CircularProgressIndicator(
                            value: value,
                            strokeWidth: 10,
                            backgroundColor:
                                theme.colorScheme.primary.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_finished)
                            Icon(Icons.check_circle_rounded,
                                size: 64, color: theme.colorScheme.primary)
                          else ...[
                            Text(
                              '$_secondsLeft',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.selfCareMovementStep(
                                _stepIndex + 1,
                                _steps.length,
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _finished ? l10n.selfCareMovementDone : step.name(lang),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _finished ? l10n.selfCareMovementDoneCue : step.cue(lang),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppGradientButton(
                        label: _finished
                            ? l10n.selfCareRestart
                            : (_running ? l10n.selfCarePause : l10n.selfCareStart),
                        icon: _finished
                            ? Icons.replay_rounded
                            : (_running ? Icons.pause : Icons.play_arrow),
                        onPressed: _toggle,
                      ),
                    ),
                    if (!_finished) ...[
                      const SizedBox(width: 12),
                      _OutlineIconButton(
                        icon: Icons.skip_next_rounded,
                        label: l10n.selfCareSkip,
                        onTap: _skip,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineIconButton extends StatelessWidget {
  const _OutlineIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
