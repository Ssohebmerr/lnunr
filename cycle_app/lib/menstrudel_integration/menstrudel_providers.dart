import 'package:cycle_aura/menstrudel/controllers/log_reversible_contraceptive_ui_controller.dart';
import 'package:cycle_aura/menstrudel/controllers/log_sanitary_ui_controller.dart';
import 'package:cycle_aura/menstrudel/controllers/log_sex_ui_controller.dart';
import 'package:cycle_aura/menstrudel/controllers/log_ui_controller.dart';
import 'package:cycle_aura/menstrudel/coordinators/data_refresh_coordinator.dart';
import 'package:cycle_aura/menstrudel/database/repositories/logs_repository.dart';
import 'package:cycle_aura/menstrudel/database/repositories/periods_repository.dart';
import 'package:cycle_aura/menstrudel/notifiers/locale_notifier.dart';
import 'package:cycle_aura/menstrudel/notifiers/theme_notifier.dart';
import 'package:cycle_aura/menstrudel/services/log_service.dart';
import 'package:cycle_aura/menstrudel/services/period_service.dart';
import 'package:cycle_aura/menstrudel/services/settings_service.dart';
import 'package:cycle_aura/menstrudel/services/symptom_service.dart';
import 'package:cycle_aura/menstrudel/services/user_service.dart';
import 'package:cycle_aura/menstrudel/services/wear_sync_service.dart';
import 'package:cycle_aura/menstrudel/services/widget_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/cycle/data/cycle_sync_service.dart';
import '../features/cycle/data/period_bridge_service.dart';

/// Menstrudel (project 3) provider tree — pills, sanitary, sex, LARC, etc.
class MenstrudelProviders extends StatelessWidget {
  const MenstrudelProviders({
    super.key,
    required this.child,
    required this.sharedPreferences,
    required this.settingsService,
    required this.userService,
    required this.symptomService,
    required this.watchService,
    required this.logsRepository,
  });

  final Widget child;
  final SharedPreferences sharedPreferences;
  final SettingsService settingsService;
  final UserService userService;
  final SymptomService symptomService;
  final WatchSyncService watchService;
  final LogsRepository logsRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: sharedPreferences),
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: userService),
        ChangeNotifierProvider.value(value: symptomService),
        Provider(create: (_) => logsRepository),
        Provider(create: (_) => PeriodsRepository()),
        ChangeNotifierProvider(
          create: (context) => ThemeNotifier(context.read<SettingsService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => LocaleNotifier(context.read<SettingsService>()),
        ),
        Provider(create: (_) => WidgetController()),
        ChangeNotifierProvider(
          create: (context) => LogService(context.read<LogsRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => PeriodService(
            context.read<SettingsService>(),
            context.read<PeriodsRepository>(),
          ),
        ),
        Provider(
          create: (context) {
            final logService = context.read<LogService>();
            final coordinator = DataRefreshCoordinator(
              logService: logService,
              periodService: context.read<PeriodService>(),
              widgetController: context.read<WidgetController>(),
            );

            // Menstrudel → widget: mirror bleeding days after every log change.
            coordinator.onLogsSynced = (logs) async {
              final changed =
                  await PeriodBridgeService.instance.syncMenstrudelToWidget(logs);
              if (changed) await CycleSyncService().onCycleDataChanged();
            };

            // Widget → Menstrudel: reload in-memory logs after external changes.
            PeriodBridgeService.instance.onMenstrudelDataChanged = () async {
              await logService.loadLogs();
              coordinator.onLogsChanged();
            };

            return coordinator;
          },
        ),
        ChangeNotifierProvider(create: (_) => LogUIController()),
        ChangeNotifierProvider(create: (_) => LogSanitaryUIController()),
        ChangeNotifierProvider(create: (_) => LogSexUIController()),
        ChangeNotifierProvider(
          create: (_) => LogReversibleContraceptiveUIController(),
        ),
        Provider.value(value: watchService),
      ],
      child: child,
    );
  }
}
