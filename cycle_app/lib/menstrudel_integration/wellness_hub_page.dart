import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/app_surface.dart';
import '../l10n/app_localizations.dart';
import 'menstrudel_bootstrap.dart';
import 'wellness_hub_launcher.dart';

/// Health tracking tools (pills, sanitary, etc.) — opened from Self-care.
class WellnessHubPage extends StatefulWidget {
  const WellnessHubPage({super.key});

  @override
  State<WellnessHubPage> createState() => _WellnessHubPageState();
}

class _WellnessHubPageState extends State<WellnessHubPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MenstrudelBootstrap.prepare(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.wellnessHubTitle)),
      body: AppMeshBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.wellnessHubTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.wellnessHubSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppHubCard(
              icon: Icons.edit_calendar_outlined,
              title: l10n.wellnessDailyLog,
              subtitle: l10n.wellnessDailyLogDesc,
              color: theme.colorScheme.primary,
              onTap: () => WellnessHubLauncher.openDailyLog(context),
            ),
            AppHubCard(
              icon: Icons.medication_outlined,
              title: l10n.wellnessPills,
              subtitle: l10n.wellnessPillsDesc,
              color: theme.colorScheme.secondary,
              onTap: () => WellnessHubLauncher.openPills(context),
            ),
            AppHubCard(
              icon: Icons.sanitizer_outlined,
              title: l10n.wellnessSanitary,
              subtitle: l10n.wellnessSanitaryDesc,
              color: AppColors.accent,
              onTap: () => WellnessHubLauncher.openSanitary(context),
            ),
            AppHubCard(
              icon: Icons.favorite_outline,
              title: l10n.wellnessSex,
              subtitle: l10n.wellnessSexDesc,
              color: const Color(0xFFE57373),
              onTap: () => WellnessHubLauncher.openSex(context),
            ),
            AppHubCard(
              icon: Icons.shield_outlined,
              title: l10n.wellnessLarc,
              subtitle: l10n.wellnessLarcDesc,
              color: const Color(0xFF26A69A),
              onTap: () => WellnessHubLauncher.openLarc(context),
            ),
          ],
        ),
      ),
    );
  }
}
