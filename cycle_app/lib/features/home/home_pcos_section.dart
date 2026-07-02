import 'package:flutter/material.dart';

import '../cycle/data/cycle_bridge_service.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../goals/presentation/goal_cycle_mode_section.dart';

class HomePcosSection extends StatelessWidget {
  const HomePcosSection({
    super.key,
    required this.data,
    this.onOpenCalendar,
  });

  final CycleDashboardData data;
  final VoidCallback? onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return GoalModeHomeSection(
      data: data,
      goal: UserGoalTypes.pcos,
      showRing: true,
      showWeekCalendar: false,
      onOpenCalendar: onOpenCalendar ?? () {},
    );
  }
}
