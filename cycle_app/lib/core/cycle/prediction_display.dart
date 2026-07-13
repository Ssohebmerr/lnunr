import 'package:intl/intl.dart';

/// Formats a prediction date range for home / dashboard display.
class PredictionDisplay {
  PredictionDisplay._();

  static String formatPredictionRange({
    required DateTime center,
    required int windowDays,
    required String languageCode,
  }) {
    if (windowDays <= 0) {
      return _formatDay(center, languageCode);
    }
    final start = DateTime(center.year, center.month, center.day)
        .subtract(Duration(days: windowDays));
    final end = DateTime(center.year, center.month, center.day)
        .add(Duration(days: windowDays));
    return '${_formatDay(start, languageCode)} – ${_formatDay(end, languageCode)}';
  }

  static String _formatDay(DateTime date, String languageCode) {
    final locale = languageCode == 'ar' ? 'ar' : 'en';
    return DateFormat.yMMMd(locale).format(date);
  }

  static DateTime? tryParseDashboardDate(String raw) {
    if (raw.isEmpty || raw == '—' || raw == '-') return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
