import '../../../core/ai/doctor_report_analyzer.dart';
import '../../../l10n/app_localizations.dart';

/// Maps a computed [ClinicalFlag] to a localized, doctor-facing sentence.
/// Shared by the on-screen report, the plain-text export, and the PDF so the
/// wording stays identical everywhere.
class DoctorReportFlagText {
  DoctorReportFlagText._();

  static String of(AppLocalizations l10n, ClinicalFlag flag) {
    switch (flag.type) {
      case ClinicalFlagType.shortCycle:
        return l10n.clinicalFlagShortCycle(flag.value);
      case ClinicalFlagType.longCycle:
        return l10n.clinicalFlagLongCycle(flag.value);
      case ClinicalFlagType.irregularCycle:
        return l10n.clinicalFlagIrregularCycle(flag.value);
      case ClinicalFlagType.prolongedPeriod:
        return l10n.clinicalFlagProlongedPeriod(flag.value);
      case ClinicalFlagType.highPain:
        return l10n.clinicalFlagHighPain;
    }
  }
}
