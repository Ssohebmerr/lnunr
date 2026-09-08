import 'package:cycle_aura/menstrudel/controllers/log_reversible_contraceptive_ui_controller.dart';
import 'package:cycle_aura/menstrudel/controllers/log_sanitary_ui_controller.dart';
import 'package:cycle_aura/menstrudel/controllers/log_sex_ui_controller.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart' as md;
import 'package:cycle_aura/menstrudel/screens/dashboards/pills_screen.dart';
import 'package:cycle_aura/menstrudel/screens/dashboards/reversible_contraceptive/reversible_contraceptive_screen.dart';
import 'package:cycle_aura/menstrudel/screens/dashboards/sanitary_screen.dart';
import 'package:cycle_aura/menstrudel/screens/dashboards/sex/sex_screen.dart';
import 'package:cycle_aura/menstrudel/screens/settings/sections/birth_control_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import 'menstrudel_screen_shell.dart';

/// Opens the individual health-tracking tools of the Wellness Hub.
///
/// Daily symptom/flow logging deliberately lives outside this class: it is the
/// app's own log screen (the + button), which writes to the main store. The
/// tools below are the ones with no equivalent there — pills, sanitary
/// products, intimacy, and LARC.
///
/// Extracted so the tools can be surfaced from the Self-care tab without
/// duplicating the navigation wiring.
/// Every feature is wrapped in [MenstrudelScreenShell], which bootstraps the
/// Menstrudel services (default user, localization) before the screen builds.
class WellnessHubLauncher {
  WellnessHubLauncher._();

  static void _open(
    BuildContext context, {
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

  static Future<void> _openBirthControlSetup(BuildContext context) async {
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

  static void openPills(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mdL10n = md.AppLocalizations.of(context);
    _open(
      context,
      title: mdL10n?.mainScreen_pillsPageTitle ?? l10n.wellnessPills,
      screen: PillsScreen(
        onSetupRegimen: () => _openBirthControlSetup(context),
      ),
    );
  }

  static void openSanitary(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mdL10n = md.AppLocalizations.of(context);
    _open(
      context,
      title: mdL10n?.mainScreen_sanitaryPageTitle ?? l10n.wellnessSanitary,
      screen: const SanitaryScreen(),
      fabBuilder: (ctx) => FloatingActionButton(
        onPressed: () => ctx
            .read<LogSanitaryUIController>()
            .handleCreateNewSanitaryLog(context: ctx),
        child: const Icon(Icons.add),
      ),
    );
  }

  static void openSex(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mdL10n = md.AppLocalizations.of(context);
    _open(
      context,
      title: mdL10n?.mainSceen_sexActivityPageTitle ?? l10n.wellnessSex,
      screen: const SexScreen(),
      fabBuilder: (ctx) => FloatingActionButton(
        onPressed: () =>
            ctx.read<LogSexUIController>().handleCreateNewSexLog(context: ctx),
        child: const Icon(Icons.add),
      ),
    );
  }

  static void openLarc(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mdL10n = md.AppLocalizations.of(context);
    _open(
      context,
      title: mdL10n?.mainScreen_reversibleContraceptivesPageTitle ??
          l10n.wellnessLarc,
      screen: const ReversibleContraceptiveScreen(),
      fabBuilder: (ctx) => FloatingActionButton(
        onPressed: () => ctx
            .read<LogReversibleContraceptiveUIController>()
            .handleCreateNewReversibleContraceptiveLog(context: ctx),
        child: const Icon(Icons.add),
      ),
    );
  }
}
