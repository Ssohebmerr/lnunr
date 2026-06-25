import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> {
  static const _phases = [4, 4, 4, 4]; // box breathing seconds
  int _phaseIndex = 0;
  int _secondsLeft = _phases[0];
  bool _running = false;
  Timer? _timer;

  static const _labels = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  static const _labelsAr = ['شهيق', 'حبس', 'زفير', 'حبس'];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        setState(() {
          _phaseIndex = (_phaseIndex + 1) % _phases.length;
          _secondsLeft = _phases[_phaseIndex];
        });
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final label = isAr ? _labelsAr[_phaseIndex] : _labels[_phaseIndex];
    final scale = _phaseIndex.isEven ? 1.0 + (_secondsLeft / _phases[_phaseIndex]) * 0.35 : 0.85;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.selfCareBreathe),
      ),
      body: AppMeshBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.selfCareBreatheDesc, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              AnimatedContainer(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
                width: 180 * scale,
                height: 180 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AuraDecorations.primaryGradient,
                  boxShadow: AppShadows.softRose(opacity: 0.3),
                ),
                child: Center(
                  child: Text(
                    '$_secondsLeft',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(label, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 40),
              AppGradientButton(
                label: _running ? l10n.selfCarePause : l10n.selfCareStart,
                icon: _running ? Icons.pause : Icons.play_arrow,
                expanded: false,
                onPressed: _toggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
