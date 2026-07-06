import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';

/// The four kinds of step in a breathing cycle. [scale] is the target size of
/// the animated orb during that step (1.0 = neutral) so the visual expands on
/// inhale, holds full/empty, and contracts on exhale.
enum BreathPhaseType {
  inhale(1.35),
  hold(1.35),
  exhale(0.85),
  holdEmpty(0.85);

  const BreathPhaseType(this.scale);
  final double scale;
}

class BreathStep {
  const BreathStep({
    required this.type,
    required this.seconds,
    required this.en,
    required this.ar,
  });

  final BreathPhaseType type;
  final int seconds;
  final String en;
  final String ar;

  String label(String lang) => lang.startsWith('ar') ? ar : en;
}

class BreathingPattern {
  const BreathingPattern({
    required this.key,
    required this.en,
    required this.ar,
    required this.descEn,
    required this.descAr,
    required this.steps,
    required this.color,
  });

  final String key;
  final String en;
  final String ar;
  final String descEn;
  final String descAr;
  final List<BreathStep> steps;
  final Color color;

  String name(String lang) => lang.startsWith('ar') ? ar : en;
  String desc(String lang) => lang.startsWith('ar') ? descAr : descEn;

  int get totalSeconds => steps.fold(0, (sum, s) => sum + s.seconds);
}

class BreathingPatterns {
  BreathingPatterns._();

  static const _inhale4 =
      BreathStep(type: BreathPhaseType.inhale, seconds: 4, en: 'Inhale', ar: 'شهيق');
  static const _hold4 =
      BreathStep(type: BreathPhaseType.hold, seconds: 4, en: 'Hold', ar: 'حبس');
  static const _exhale4 =
      BreathStep(type: BreathPhaseType.exhale, seconds: 4, en: 'Exhale', ar: 'زفير');
  static const _holdEmpty4 =
      BreathStep(type: BreathPhaseType.holdEmpty, seconds: 4, en: 'Hold', ar: 'حبس');

  static const box = BreathingPattern(
    key: 'box',
    en: 'Box breathing',
    ar: 'التنفّس المربّع',
    descEn: 'Equal 4-count breaths to steady the nervous system.',
    descAr: 'أنفاس متساوية 4 عدّات لتهدئة الجهاز العصبي.',
    color: AuraColors.rose,
    steps: [_inhale4, _hold4, _exhale4, _holdEmpty4],
  );

  static const relax478 = BreathingPattern(
    key: 'relax',
    en: '4-7-8 relaxing',
    ar: 'استرخاء 4-7-8',
    descEn: 'A longer exhale to unwind and ease into sleep.',
    descAr: 'زفير أطول للاسترخاء والمساعدة على النوم.',
    color: AuraColors.lavenderSoft,
    steps: [
      BreathStep(type: BreathPhaseType.inhale, seconds: 4, en: 'Inhale', ar: 'شهيق'),
      BreathStep(type: BreathPhaseType.hold, seconds: 7, en: 'Hold', ar: 'حبس'),
      BreathStep(type: BreathPhaseType.exhale, seconds: 8, en: 'Exhale', ar: 'زفير'),
    ],
  );

  static const calm = BreathingPattern(
    key: 'calm',
    en: 'Calming 4-6',
    ar: 'تهدئة 4-6',
    descEn: 'Gentle rhythm for cramps and anxious moments.',
    descAr: 'إيقاع لطيف للتشنّجات ولحظات القلق.',
    color: Color(0xFF26A69A),
    steps: [
      BreathStep(type: BreathPhaseType.inhale, seconds: 4, en: 'Inhale', ar: 'شهيق'),
      BreathStep(type: BreathPhaseType.exhale, seconds: 6, en: 'Exhale', ar: 'زفير'),
    ],
  );

  static const focus = BreathingPattern(
    key: 'focus',
    en: 'Coherent 5-5',
    ar: 'اتّزان 5-5',
    descEn: 'Balanced breathing to focus and center yourself.',
    descAr: 'تنفّس متوازن للتركيز واستعادة الاتّزان.',
    color: AuraColors.peachGold,
    steps: [
      BreathStep(type: BreathPhaseType.inhale, seconds: 5, en: 'Inhale', ar: 'شهيق'),
      BreathStep(type: BreathPhaseType.exhale, seconds: 5, en: 'Exhale', ar: 'زفير'),
    ],
  );

  static const all = <BreathingPattern>[box, relax478, calm, focus];

  static BreathingPattern byKey(String? key) =>
      all.firstWhere((p) => p.key == key, orElse: () => box);
}
