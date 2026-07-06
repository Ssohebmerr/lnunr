/// Professional report sections produced by AI from on-device app data.
/// Rendered inside the printable report — never as a separate AI card.
class DoctorReportEnrichment {
  const DoctorReportEnrichment({
    this.clinicalSummary,
    this.patterns = const [],
    this.discussionPoints = const [],
    this.redFlags = const [],
    this.dataQualityNote,
  });

  final String? clinicalSummary;
  final List<String> patterns;
  final List<String> discussionPoints;

  /// Observations the AI thinks are worth raising with a clinician sooner
  /// rather than later. Never diagnostic — always "mention to your doctor".
  final List<String> redFlags;

  final String? dataQualityNote;

  bool get isEmpty =>
      (clinicalSummary == null || clinicalSummary!.trim().isEmpty) &&
      patterns.isEmpty &&
      discussionPoints.isEmpty &&
      redFlags.isEmpty &&
      (dataQualityNote == null || dataQualityNote!.trim().isEmpty);
}
