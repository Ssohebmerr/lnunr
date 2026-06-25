import 'package:cycle_aura/menstrudel/controllers/log_reversible_contraceptive_ui_controller.dart';
import 'package:cycle_aura/menstrudel/controllers/log_sanitary_ui_controller.dart';
import 'package:cycle_aura/menstrudel/controllers/log_sex_ui_controller.dart';
import 'package:cycle_aura/menstrudel/controllers/log_ui_controller.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart' as md;
import 'package:cycle_aura/menstrudel/screens/dashboards/logs/logs_screen.dart';
import 'package:cycle_aura/menstrudel/screens/dashboards/pills_screen.dart';
import 'package:cycle_aura/menstrudel/screens/dashboards/reversible_contraceptive/reversible_contraceptive_screen.dart';
import 'package:cycle_aura/menstrudel/screens/dashboards/sanitary_screen.dart';
import 'package:cycle_aura/menstrudel/screens/dashboards/sex/sex_screen.dart';
import 'package:cycle_aura/menstrudel/screens/settings/sections/birth_control_settings_screen.dart';
import 'package:cycle_aura/menstrudel/services/symptom_service.dart';
import 'package:cycle_aura/menstrudel/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/app_surface.dart';
import '../l10n/app_localizations.dart';
import 'menstrudel_bootstrap.dart';
import 'menstrudel_screen_shell.dart';

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

  void _openFeature({
    required String title,
    required Widget screen,
    Widget? Function(BuildContext ctx)? fabBuilder,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MenstrudelScreenShell(
          title: title,
          body: screen,
          floatingActionButtonBuilder: fabBuilder,
        ),
      ),
    );
  }

  Future<void> _openBirthControlSetup(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Localizations.override(
          context: context,
          delegates: md.AppLocalizations.localizationsDelegates,
          locale: Localizations.localeOf(context),
          child: const BirthControlSettingsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mdL10n = md.AppLocalizations.of(context);
    final theme = Theme.of(context);
    final userService = context.watch<UserService>();
    final age = userService.age;

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
              onTap: () => _openFeature(
                title: mdL10n?.mainScreen_logsPageTitle ?? l10n.wellnessDailyLog,
                screen: const LogsScreen(),
                fabBuilder: (ctx) => FloatingActionButton(
                  onPressed: () => ctx.read<LogUIController>().handleCreateNewLog(
                        context: ctx,
                        selectedDate: DateTime.now(),
                        symptomService: ctx.read<SymptomService>(),
                        age: age,
                      ),
                  child: const Icon(Icons.add),
                ),
              ),
            ),
            AppHubCard(
              icon: Icons.medication_outlined,
              title: l10n.wellnessPills,
              subtitle: l10n.wellnessPillsDesc,
              color: theme.colorScheme.secondary,
              onTap: () => _openFeature(
                title: mdL10n?.mainScreen_pillsPageTitle ?? l10n.wellnessPills,
                screen: PillsScreen(
                  onSetupRegimen: () => _openBirthControlSetup(context),
                ),
              ),
            ),
            AppHubCard(
              icon: Icons.sanitizer_outlined,
              title: l10n.wellnessSanitary,
              subtitle: l10n.wellnessSanitaryDesc,
              color: AppColors.accent,
              onTap: () => _openFeature(
                title: mdL10n?.mainScreen_sanitaryPageTitle ?? l10n.wellnessSanitary,
                screen: const SanitaryScreen(),
                fabBuilder: (ctx) => FloatingActionButton(
                  onPressed: () =>
                      ctx.read<LogSanitaryUIController>().handleCreateNewSanitaryLog(context: ctx),
                  child: const Icon(Icons.add),
                ),
              ),
            ),
            AppHubCard(
              icon: Icons.favorite_outline,
              title: l10n.wellnessSex,
              subtitle: l10n.wellnessSexDesc,
              color: const Color(0xFFE57373),
              onTap: () => _openFeature(
                title: mdL10n?.mainSceen_sexActivityPageTitle ?? l10n.wellnessSex,
                screen: const SexScreen(),
                fabBuilder: (ctx) => FloatingActionButton(
                  onPressed: () => ctx.read<LogSexUIController>().handleCreateNewSexLog(context: ctx),
                  child: const Icon(Icons.add),
                ),
              ),
            ),
            AppHubCard(
              icon: Icons.shield_outlined,
              title: l10n.wellnessLarc,
              subtitle: l10n.wellnessLarcDesc,
              color: const Color(0xFF26A69A),
              onTap: () => _openFeature(
                title: mdL10n?.mainScreen_reversibleContraceptivesPageTitle ?? l10n.wellnessLarc,
                screen: const ReversibleContraceptiveScreen(),
                fabBuilder: (ctx) => FloatingActionButton(
                  onPressed: () => ctx
                      .read<LogReversibleContraceptiveUIController>()
                      .handleCreateNewReversibleContraceptiveLog(context: ctx),
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
