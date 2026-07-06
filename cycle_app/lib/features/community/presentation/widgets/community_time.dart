import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

/// Locale-aware relative timestamp for community posts and comments:
/// "Just now", "5m ago" / "منذ ٥ دقائق", falling back to a localized short
/// date once the content is older than a week.
String communityRelativeTime(BuildContext context, DateTime time) {
  final l10n = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inSeconds < 60) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);

  final locale = Localizations.localeOf(context).toString();
  if (time.year == now.year) {
    return DateFormat.MMMd(locale).format(time);
  }
  return DateFormat.yMMMd(locale).format(time);
}
