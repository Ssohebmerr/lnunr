import 'dart:convert';

import 'models/health_snapshot.dart';

/// Builds a structured doctor visit summary from on-device cycle data.
/// Works without AI — used as fallback and as the base for QR payloads.
class DoctorReportBuilder {
  DoctorReportBuilder._();

  static String build(HealthSnapshot s, {required String languageCode}) {
    final ar = languageCode.startsWith('ar');
    final date = _formatDate(DateTime.now(), ar);
    final buf = StringBuffer();

    if (ar) {
      buf.writeln('تقرير Lune للزيارة الطبية');
      buf.writeln('التاريخ: $date');
      buf.writeln('────────────────────────');
      if (s.isPregnancyMode) {
        _pregnancySection(buf, s, ar: true);
      } else {
        _cycleSection(buf, s, ar: true);
      }
      _patternSignalsSection(buf, s, ar: true);
      _symptomsSection(buf, s, ar: true);
      _wellnessSection(buf, s, ar: true);
      buf.writeln('\n⚠️ هذا ملخص تتبّع شخصي من التطبيق — ليس تشخيصاً طبياً.');
    } else {
      buf.writeln('Lune visit summary');
      buf.writeln('Date: $date');
      buf.writeln('────────────────────────');
      if (s.isPregnancyMode) {
        _pregnancySection(buf, s, ar: false);
      } else {
        _cycleSection(buf, s, ar: false);
      }
      _patternSignalsSection(buf, s, ar: false);
      _symptomsSection(buf, s, ar: false);
      _wellnessSection(buf, s, ar: false);
      buf.writeln('\n⚠️ Personal tracking summary — not a medical diagnosis.');
    }
    return buf.toString().trim();
  }

  /// Compact JSON for QR scanning (stats + short excerpt).
  static String qrPayload(HealthSnapshot s, String reportExcerpt) {
    final payload = <String, dynamic>{
      'app': 'Lune',
      'v': 1,
      'date': DateTime.now().toIso8601String().split('T').first,
      'goal': s.userGoal,
      if (s.currentPhase != null) 'phase': s.currentPhase,
      if (s.currentCycleDay != null) 'cycleDay': s.currentCycleDay,
      if (s.cycleLength != null) 'cycleLength': s.cycleLength,
      if (s.periodDuration != null) 'periodDays': s.periodDuration,
      if (s.cycleRegularity != null) 'regularity': s.cycleRegularity,
      if (s.averagePainLevel != null) 'avgPain': s.averagePainLevel,
      if (s.pregnancyWeek != null) 'pregnancyWeek': s.pregnancyWeek,
      if (s.recentSymptoms.isNotEmpty) 'symptoms': s.recentSymptoms,
      'excerpt': reportExcerpt.length > 600
          ? '${reportExcerpt.substring(0, 600)}…'
          : reportExcerpt,
    };
    return jsonEncode(payload);
  }

  /// Objective cycle-pattern observations worth a clinician's attention.
  ///
  /// Deliberately phrased as measurements, not impressions: a doctor needs the
  /// number of days, not an app's opinion about what it might mean.
  static void _patternSignalsSection(
    StringBuffer buf,
    HealthSnapshot s, {
    required bool ar,
  }) {
    if (s.patternSignals.isEmpty) return;

    buf.writeln();
    buf.writeln(ar ? '🔎 ملاحظات على نمط الدورة' : '🔎 Cycle pattern notes');
    for (final signal in s.patternSignals) {
      final text = switch (signal) {
        'prolongedCycles' => ar
            ? 'عدة دورات مسجّلة تجاوزت ٣٥ يوماً'
            : 'Multiple logged cycles exceeded 35 days',
        'shortCycles' => ar
            ? 'عدة دورات مسجّلة كانت أقصر من ٢١ يوماً'
            : 'Multiple logged cycles were shorter than 21 days',
        'highVariability' => ar
            ? 'تباين طول الدورة ٩ أيام أو أكثر بين الدورات'
            : 'Cycle-to-cycle length varied by 9 or more days',
        'absentCycles' => ar
            ? 'فجوة ٩٠ يوماً أو أكثر بلا دورة مسجّلة'
            : 'A gap of 90 or more days with no logged period',
        _ => null,
      };
      if (text != null) buf.writeln('• $text');
    }
  }

  static void _cycleSection(StringBuffer buf, HealthSnapshot s, {required bool ar}) {
    buf.writeln(ar ? '\n📊 ملخص الدورة' : '\n📊 Cycle overview');
    _line(buf, ar ? 'المرحلة الحالية' : 'Current phase', s.currentPhase);
    _line(buf, ar ? 'يوم الدورة' : 'Cycle day', s.currentCycleDay?.toString());
    _line(buf, ar ? 'طول الدورة (متوسط)' : 'Avg cycle length', s.cycleLength != null ? '${s.cycleLength} ${ar ? 'يوم' : 'days'}' : null);
    _line(buf, ar ? 'مدة الحيض (متوسط)' : 'Avg period length', s.periodDuration != null ? '${s.periodDuration} ${ar ? 'يوم' : 'days'}' : null);
    _line(buf, ar ? 'انتظام الدورة' : 'Cycle regularity', s.cycleRegularity);
    _line(buf, ar ? 'الدورة القادمة (تقدير)' : 'Next period (est.)', s.nextPeriodDate);
    if (s.ovulationConfirmedByTemperature) {
      final rise = s.temperatureRiseCelsius?.toStringAsFixed(2);
      _line(
        buf,
        ar ? 'الإباضة (مؤكّدة بالحرارة)' : 'Ovulation (BBT-confirmed)',
        rise == null
            ? s.ovulationDate
            : '${s.ovulationDate} '
                  '(${ar ? 'ارتفاع' : 'rise'} $rise°C)',
      );
    } else {
      _line(buf, ar ? 'الإباضة (تقدير)' : 'Ovulation (est.)', s.ovulationDate);
    }
    _line(buf, ar ? 'احتمال الحمل' : 'Pregnancy chance', s.pregnancyChances);
    if (s.isPeriodActive) {
      buf.writeln(ar ? '• الدورة الشهرية جارية الآن' : '• Period is active now');
    }
    if (s.isOvulationDay) {
      buf.writeln(ar ? '• اليوم يوم إباضة متوقع' : '• Today is predicted ovulation day');
    }
  }

  static void _pregnancySection(StringBuffer buf, HealthSnapshot s, {required bool ar}) {
    buf.writeln(ar ? '\n🤰 ملخص الحمل' : '\n🤰 Pregnancy overview');
    _line(buf, ar ? 'أسبوع الحمل' : 'Pregnancy week', s.pregnancyWeek?.toString());
    _line(buf, ar ? 'الثلث' : 'Trimester', s.trimester?.toString());
    _line(buf, ar ? 'موعد الولادة المتوقع' : 'Due date', s.expectedDueDate);
    _line(buf, ar ? 'يوم الحمل' : 'Gestational day', s.gestationalDay?.toString());
    if (s.fetalDevelopmentSnippet != null && s.fetalDevelopmentSnippet!.isNotEmpty) {
      _line(buf, ar ? 'تطور الجنين' : 'Fetal development', s.fetalDevelopmentSnippet);
    }
  }

  static void _symptomsSection(StringBuffer buf, HealthSnapshot s, {required bool ar}) {
    if (s.recentSymptoms.isEmpty && s.averagePainLevel == null) return;
    buf.writeln(ar ? '\n📋 الأعراض (آخر 30 يوماً)' : '\n📋 Symptoms (last 30 days)');
    if (s.averagePainLevel != null) {
      _line(buf, ar ? 'متوسط الألم' : 'Average pain', s.averagePainLevel!.toStringAsFixed(1));
    }
    final sorted = s.recentSymptoms.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted.take(8)) {
      buf.writeln('• ${e.key}: ${e.value}');
    }
    if (s.wellnessLogCount > 0) {
      _line(buf, ar ? 'عدد سجلات العافية' : 'Wellness log entries', '${s.wellnessLogCount}');
    }
  }

  static void _wellnessSection(StringBuffer buf, HealthSnapshot s, {required bool ar}) {
    if (s.wellnessHub.isEmpty) return;
    buf.writeln(ar ? '\n💊 مركز العناية' : '\n💊 Wellness hub');
    for (final entry in s.wellnessHub.entries.take(6)) {
      final value = entry.value;
      if (value is Map) {
        final label = value['label'] ?? value['name'] ?? entry.key;
        final detail = value['value'] ?? value['status'] ?? value['summary'];
        if (detail != null) {
          buf.writeln('• $label: $detail');
        } else {
          buf.writeln('• $label');
        }
      } else if (value != null && value.toString().trim().isNotEmpty) {
        buf.writeln('• ${entry.key}: $value');
      }
    }
  }

  static void _line(StringBuffer buf, String label, String? value) {
    if (value == null || value.trim().isEmpty || value == '—' || value == '-') return;
    buf.writeln('• $label: $value');
  }

  static String _formatDate(DateTime d, bool ar) {
    if (ar) return '${d.year}/${d.month}/${d.day}';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
