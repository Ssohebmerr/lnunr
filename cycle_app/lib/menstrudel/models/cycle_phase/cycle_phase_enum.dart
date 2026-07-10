import 'package:flutter/material.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';

enum CyclePhase {
  /// Menstruation phase (On Period)
  menstruation,
  /// Follicular phase (Pre-Ovulation)
  follicular,
  /// Fertile Window
  fertileWindow,
  /// Ovulation phase (Peak Fertility)
  ovulation,
  /// Luteal phase (Post-Ovulation)
  luteal,
  /// Late phase (After Cycle)
  late,
  /// Unknown phase
  unknown,
}

extension FlowExtension on CyclePhase {
  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case CyclePhase.menstruation:
        return l10n.cyclePhase_menstruation;
      case CyclePhase.follicular:
        return l10n.cyclePhase_follicular;
      case CyclePhase.fertileWindow:
        return l10n.cyclePhase_fertileWindow;
      case CyclePhase.ovulation:
        return l10n.cyclePhase_ovulation;
      case CyclePhase.luteal:
        return l10n.cyclePhase_luteal;
      case CyclePhase.late:
        return l10n.cyclePhase_late;
      case CyclePhase.unknown:
        return l10n.cyclePhase_unknown;
    }
  }

  String getDescription(AppLocalizations l10n) {
    switch (this) {
      case CyclePhase.menstruation:
        return l10n.cyclePhase_menstruationDescription;
      case CyclePhase.follicular:
        return l10n.cyclePhase_follicularDescription;
      case CyclePhase.fertileWindow:
        return l10n.cyclePhase_fertileWindowDescription;
      case CyclePhase.ovulation:
        return l10n.cyclePhase_ovulationDescription;
      case CyclePhase.luteal:
        return l10n.cyclePhase_lutealDescription;
      case CyclePhase.late:
        return l10n.cyclePhase_lateDescription;
      case CyclePhase.unknown:
        return l10n.cyclePhase_unknownDescription;
    }
  }

  IconData get icon {
    switch (this) {
      case CyclePhase.menstruation:
        return Icons.water_drop;
      case CyclePhase.follicular:
        return Icons.wb_sunny_outlined;
      case CyclePhase.fertileWindow:
        return Icons.favorite;
      case CyclePhase.ovulation:
        return Icons.favorite;
      case CyclePhase.luteal:
        return Icons.cloud_queue;
      case CyclePhase.late:
        return Icons.error_outline;
      case CyclePhase.unknown:
        return Icons.help_outline;
    }
  }

  /// Phase colours aligned to the Lune (Aura) palette. Each phase stays
  /// visually distinct, but all now live in the app's rose/lavender/peach
  /// world instead of raw blue/teal/red so the calendar reads as one brand.
  Color get color {
    switch (this) {
      case CyclePhase.menstruation:
        return const Color(0xFFD84A83); // berry — the flow phase
      case CyclePhase.follicular:
        return const Color(0xFFFFB4A2); // warm peach — rising energy
      case CyclePhase.fertileWindow:
        return const Color(0xFFD4C4F0); // soft lavender
      case CyclePhase.ovulation:
        return const Color(0xFF9B7ED4); // deeper lavender — peak fertility
      case CyclePhase.luteal:
        return const Color(0xFFB58AA8); // muted mauve — winding down
      case CyclePhase.late:
        return const Color(0xFFE8A06A); // warm amber — attention
      case CyclePhase.unknown:
        return const Color(0xFFBBAEB6); // neutral
    }
  }
}