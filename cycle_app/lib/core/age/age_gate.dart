import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../privacy/consent_manager.dart';
import '../widgets/app_surface.dart';
import '../../l10n/app_localizations.dart';

enum AgeGroup { under13, teen, adult }

/// Shows an age selection screen during onboarding.
/// Returns [AgeGroup] or null if dismissed.
Future<AgeGroup?> showAgeGate(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  return await showModalBottomSheet<AgeGroup>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AppGlassSheetSurface(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cake_outlined,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.ageGateTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ageGateBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _AgeOption(
              icon: Icons.block_outlined,
              label: l10n.ageGateUnder13,
              color: Colors.red.shade300,
              onTap: () => Navigator.of(ctx).pop(AgeGroup.under13),
            ),
            const SizedBox(height: 10),
            _AgeOption(
              icon: Icons.person_outline,
              label: l10n.ageGate13to17,
              color: Colors.orange.shade400,
              onTap: () => Navigator.of(ctx).pop(AgeGroup.teen),
            ),
            const SizedBox(height: 10),
            _AgeOption(
              icon: Icons.verified_outlined,
              label: l10n.ageGate18plus,
              color: Colors.green.shade500,
              onTap: () => Navigator.of(ctx).pop(AgeGroup.adult),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AgeOption extends StatelessWidget {
  const _AgeOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns true if the user is under 18.
Future<bool> isMinor() async {
  final prefs = await SharedPreferences.getInstance();
  final group = prefs.getString('user_age_group');
  return group == 'under13' || group == 'teen';
}

/// True only after the user explicitly selected the 18+ age group.
/// Unknown/missing age is intentionally not treated as adult for AI access.
Future<bool> isAdult() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_age_group') == AgeGroup.adult.name;
}

/// AI features process sensitive health context and are restricted to adults.
Future<bool> blocksAiByAgeGate() async {
  return !await isAdult();
}

/// True when onboarding age gate blocks community (under 13 or 13–17).
Future<bool> blocksCommunityByAgeGate() async {
  return isMinor();
}

/// True when onboarding age gate blocks completing the app (under 13 only).
Future<bool> blocksAppByAgeGate() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_age_group') == 'under13';
}

/// Persist age gate outcome. [under13] still marks gate done so we don't re-prompt.
Future<void> saveAgeGroup(AgeGroup group) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_age_group', group.name);
  await prefs.setBool('age_gate_done', true);
  await ConsentManager.syncAiEligibility();
}

/// Checks if the user has already completed the age gate.
Future<bool> isAgeGateDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('age_gate_done') ?? false;
}
