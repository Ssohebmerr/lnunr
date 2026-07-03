/// Professional report sections produced by AI from on-device app data.
/// Rendered inside the printable report — never as a separate AI card.
class DoctorReportEnrichment {
  const DoctorReportEnrichment({
    this.clinicalSummary,
    this.patterns = const [],
    this.discussionPoints = const [],
    this.dataQualityNote,
  });

  final String? clinicalSummary;
  final List<String> patterns;
  final List<String> discussionPoints;
  final String? dataQualityNote;

  bool get isEmpty =>
      (clinicalSummary == null || clinicalSummary!.trim().isEmpty) &&
      patterns.isEmpty &&
      discussionPoints.isEmpty &&
      (dataQualityNote == null || dataQualityNote!.trim().isEmpty);
}
