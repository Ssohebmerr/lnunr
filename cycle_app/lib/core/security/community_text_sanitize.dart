/// Strips HTML-like markup and normalizes community UGC before save/display.
class CommunityTextSanitize {
  CommunityTextSanitize._();

  static const int maxPostLength = 2000;
  static const int maxCommentLength = 1000;

  static final _htmlTag = RegExp(r'<[^>]*>', multiLine: true);
  static final _controlChars = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');
  static final _multiSpace = RegExp(r'[ \t]{2,}');
  static final _multiNewline = RegExp(r'\n{3,}');

  /// Sanitize post body (max 2000 chars).
  static String post(String raw) => _sanitize(raw, maxPostLength);

  /// Sanitize comment body (max 1000 chars).
  static String comment(String raw) => _sanitize(raw, maxCommentLength);

  /// Sanitize for display (same rules, keeps stored length cap).
  static String forDisplay(String raw, {int maxLength = maxPostLength}) =>
      _sanitize(raw, maxLength);

  static String _sanitize(String raw, int maxLength) {
    var value = raw.replaceAll(_controlChars, '');
    value = value.replaceAll(_htmlTag, '');
    value = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    value = value.replaceAll(_multiSpace, ' ');
    value = value.replaceAll(_multiNewline, '\n\n');
    value = value.trim();
    if (value.length > maxLength) {
      value = value.substring(0, maxLength).trimRight();
    }
    return value;
  }
}
