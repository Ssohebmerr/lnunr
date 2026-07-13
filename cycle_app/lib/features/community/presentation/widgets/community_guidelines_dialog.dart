import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/community_seed.dart';
import '../../data/models/community.dart';

/// Tracks per-user acceptance of community guidelines (Play UGC requirement).
class CommunityGuidelinesPrefs {
  static String _key(String uid) => 'community_guidelines_v1_$uid';

  static Future<bool> hasAccepted(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(uid)) ?? false;
  }

  static Future<void> accept(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(uid), true);
  }
}

/// Shows community rules and requires explicit acceptance before joining.
Future<bool> showCommunityGuidelinesDialog(
  BuildContext context, {
  required Community community,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final lang = Localizations.localeOf(context).languageCode;
  final rules = community.rulesForLocale(lang).isNotEmpty
      ? community.rulesForLocale(lang)
      : (lang.startsWith('ar')
            ? CommunitySeed.defaultRulesAr
            : CommunitySeed.defaultRulesEn);

  var agreed = false;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(l10n.communityGuidelinesTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.communityGuidelinesIntro),
              const SizedBox(height: 12),
              Text(rules, style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text(
                l10n.communityDisclaimer,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: agreed,
                onChanged: (v) => setLocal(() => agreed = v ?? false),
                title: Text(l10n.communityGuidelinesAgree),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: agreed ? () => Navigator.of(ctx).pop(true) : null,
            child: Text(l10n.communityGuidelinesAccept),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
