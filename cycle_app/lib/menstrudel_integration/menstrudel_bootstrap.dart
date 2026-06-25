import 'package:cycle_aura/menstrudel/coordinators/data_refresh_coordinator.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart' as md;
import 'package:cycle_aura/menstrudel/services/user_service.dart';
import 'package:cycle_aura/menstrudel/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Ensures Menstrudel services are ready before opening care-center screens.
class MenstrudelBootstrap {
  MenstrudelBootstrap._();

  static void registerL10n(BuildContext context) {
    final l10n = md.AppLocalizations.of(context);
    if (l10n == null) return;
    context.read<DataRefreshCoordinator>().registerL10n(l10n);
  }

  static Future<void> ensureUser(BuildContext context) async {
    final userService = context.read<UserService>();
    if (userService.user == null) {
      await userService.ensureDefaultUser(context.read<SettingsService>());
    }
  }

  static Future<void> prepare(BuildContext context) async {
    registerL10n(context);
    await ensureUser(context);
  }
}
