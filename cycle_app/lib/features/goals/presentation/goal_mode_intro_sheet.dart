import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';

/// Lightweight, single-screen "welcome" sheet shown right after the user
/// picks one of the three lifecycle goals (menopause, pcos, postpartum).
///
/// Goal: in 2-3 lines, tell the user *what we'll focus on* and give them
/// one quick "areas to track" tap chip. It does NOT re-onboard — the home
/// section already does the heavy lifting. Keep it short and warm.
class GoalModeIntroSheet extends StatelessWidget {
  const GoalModeIntroSheet({super.key, required this.goal});

  final UserGoalTypes goal;

  static Future<void> show(BuildContext context, UserGoalTypes goal) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => GoalModeIntroSheet(goal: goal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang.startsWith('ar');
    final (title, body, gradient, focusAreas) = _copy(goal, isAr);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  gradient: gradient,
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        goal.icon,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr
                                ? 'سنرافقكِ خطوة بخطوة'
                                : 'We\'ll walk with you step by step',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'سنركّز على:' : 'We\'ll focus on:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: focusAreas
                    .map(
                      (it) => AppStatChip(
                        icon: it.$1,
                        label: it.$2,
                        highlight: true,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: Text(
                  isAr ? 'ابدئي' : 'Get started',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (
    String,
    String,
    LinearGradient,
    List<(IconData, String)>,
  ) _copy(UserGoalTypes goal, bool isAr) {
    return switch (goal) {
      UserGoalTypes.pregnant => (
          isAr ? 'مرحباً في رحلة الحمل' : 'Welcome to Pregnancy Tracking',
          isAr
              ? 'سنتابع أسابيع حملكِ، نموّ الجنين، ونصائح الراحة والتغذية.'
              : 'We\'ll track your weeks, baby\'s growth, and gentle rest and nutrition tips.',
          const LinearGradient(colors: [Color(0xFFEC407A), Color(0xFFC2185B)]),
          [
            (Icons.pregnant_woman_rounded, isAr ? 'أسبوع الحمل' : 'Pregnancy week'),
            (Icons.favorite_outline, isAr ? 'النمو' : 'Growth'),
            (Icons.bedtime_outlined, isAr ? 'الراحة' : 'Rest'),
          ],
        ),
      UserGoalTypes.conceive => (
          isAr ? 'مرحباً في محاولة الحمل' : 'Welcome to Trying to Conceive',
          isAr
              ? 'سنساعدكِ على تتبّع نافذة الخصوبة والأيام الذهبية.'
              : 'We\'ll help you track your fertile window and golden days.',
          const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFAD1457)]),
          [
            (Icons.child_friendly, isAr ? 'الخصوبة' : 'Fertility'),
            (Icons.calendar_today, isAr ? 'الدورة' : 'Cycle'),
            (Icons.favorite, isAr ? 'الصحة' : 'Wellness'),
          ],
        ),
      UserGoalTypes.avoid => (
          isAr ? 'مرحباً في تجنّب الحمل' : 'Welcome to Avoid Pregnancy',
          isAr
              ? 'سنركّز على أيام الحماية وتذكيراتكِ اليومية.'
              : 'We\'ll focus on protection days and your daily reminders.',
          const LinearGradient(colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)]),
          [
            (Icons.shield, isAr ? 'الحماية' : 'Protection'),
            (Icons.event, isAr ? 'التقويم' : 'Calendar'),
          ],
        ),
      _ => (
          isAr ? 'مرحباً بكِ' : 'Welcome',
          isAr ? 'هدفكِ الجديد محفوظ.' : 'Your new goal is saved.',
          AuraDecorations.primaryGradient,
          <(IconData, String)>[],
        ),
    };
  }
}
