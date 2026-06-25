import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';
import 'package:cycle_aura/menstrudel/screens/dashboards/logs/widgets/tabs/logs_screen_insights_tab.dart';
import 'package:cycle_aura/menstrudel/screens/dashboards/logs/widgets/tabs/logs_screen_log_tab.dart';
import 'package:cycle_aura/menstrudel/screens/dashboards/logs/widgets/tabs/logs_screen_period_quick_view_tab.dart';
import 'package:cycle_aura/menstrudel/services/period_service.dart';
import 'package:cycle_aura/menstrudel/services/user_service.dart';
import 'package:cycle_aura/menstrudel_integration/menstrudel_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => LogsScreenState();
}

class LogsScreenState extends State<LogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MenstrudelBootstrap.registerL10n(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final periodService = context.watch<PeriodService>();
    final userAge = context.watch<UserService>().age;

    return DefaultTabController(
      length: 3,
      child: Stack(
        children: [
          Column(
            children: [
              TabBar(
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: l10n.today),
                  Tab(text: l10n.logs),
                  Tab(text: l10n.insights),
                ],
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    LogsScreenPeriodQuickViewTab(periodService: periodService),
                    LogsScreenLogTab(periodService: periodService, userAge: userAge),
                    LogsScreenInsightsTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
