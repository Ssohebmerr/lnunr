import 'dart:async';

import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../core/theme/app_design_tokens.dart';
import '../../core/widgets/app_surface.dart';
import '../cycle/data/cycle_sync_service.dart';

/// Full cycle calendars — opened from Home (keeps main tab light).
class CycleCalendarPage extends StatefulWidget {
  const CycleCalendarPage({super.key});

  @override
  State<CycleCalendarPage> createState() => _CycleCalendarPageState();
}

class _CycleCalendarPageState extends State<CycleCalendarPage> {
  Timer? _syncDebounce;

  void _onDataChanged(dynamic _) {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 600), () {
      CycleSyncService().onCycleDataChanged();
    });
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final weeklyTitle = isAr ? 'التقويم الأسبوعي' : 'Weekly calendar';
    final monthlyTitle = isAr ? 'التقويم الشهري' : 'Monthly calendar';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionHeader(title: weeklyTitle),
        AppGlassCard(
          blur: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 285,
            child: MenstrualCycleCalenderView(
              themeColor: AuraColors.roseDeep,
              daySelectedColor: AuraColors.lavenderSoft,
              backgroundColorCode: Colors.transparent,
              hideInfoView: false,
              onDataChanged: _onDataChanged,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppSectionHeader(title: monthlyTitle),
        AppGlassCard(
          blur: false,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: SizedBox(
            height: 430,
            child: MenstrualCycleMonthlyCalenderView(
              themeColor: AuraColors.roseDeep,
              daySelectedColor: AuraColors.lavenderSoft,
              backgroundColor: Colors.transparent,
              hideInfoView: false,
              onDataChanged: _onDataChanged,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
