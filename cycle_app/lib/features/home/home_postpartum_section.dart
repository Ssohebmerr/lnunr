import 'package:flutter/material.dart';

import '../../core/storage/user_prefs.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../core/widgets/app_surface.dart';
import '../../l10n/app_localizations.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../goals/data/goal_mode_content.dart';
import '../postpartum/data/postpartum_recovery_content.dart';

/// Postpartum-mode home: a dedicated recovery experience (the "fourth
/// trimester") instead of the generic cycle ring. Anchored on the baby's
/// birth date so recovery week + milestones are real, not cycle-derived.
class HomePostpartumSection extends StatefulWidget {
  const HomePostpartumSection({
    super.key,
    required this.data,
    this.onOpenCalendar,
  });

  final CycleDashboardData data;
  final VoidCallback? onOpenCalendar;

  @override
  State<HomePostpartumSection> createState() => _HomePostpartumSectionState();
}

class _HomePostpartumSectionState extends State<HomePostpartumSection> {
  DateTime? _birthDate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final date = await UserPrefs.getPostpartumStartDate();
    if (mounted) {
      setState(() {
        _birthDate = date;
        _loading = false;
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now.subtract(const Duration(days: 14)),
      firstDate: now.subtract(const Duration(days: 400)),
      lastDate: now,
      helpText: AppLocalizations.of(context)!.postpartumBirthDateLabel,
    );
    if (picked == null) return;
    final normalized = DateTime(picked.year, picked.month, picked.day);
    await UserPrefs.setPostpartumStartDate(normalized);
    if (mounted) setState(() => _birthDate = normalized);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final birthDate = _birthDate;
    if (birthDate == null) {
      return _SetBirthDatePrompt(onSet: _pickBirthDate);
    }

    final week = PostpartumRecoveryContent.recoveryWeek(birthDate);
    final stage = PostpartumRecoveryContent.forWeek(week);
    final rituals = GoalModeContent.rituals(UserGoalTypes.postpartum);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Recovery banner ────────────────────────────────────────────────
        AppGlassCard(
          blur: false,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              gradient: const LinearGradient(
                colors: [Color(0xFFEC407A), Color(0xFFF48FB1)],
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.child_care_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.postpartumRecoveryWeek(week),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stage.titleFor(lang),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _pickBirthDate,
                  tooltip: l10n.postpartumBirthDateLabel,
                  icon: const Icon(Icons.edit_calendar_outlined,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Today's focus ──────────────────────────────────────────────────
        AppGlassCard(
          blur: false,
          child: Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.postpartumTodayFocus,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stage.focusFor(lang),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Your body / your baby this stage ──────────────────────────────
        AppGlassCard(
          blur: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StageNote(
                icon: Icons.favorite_outline,
                title: l10n.postpartumYourBody,
                body: stage.bodyFor(lang),
                accent: theme.colorScheme.secondary,
              ),
              const Divider(height: 24),
              _StageNote(
                icon: Icons.child_friendly_outlined,
                title: l10n.postpartumYourBaby,
                body: stage.babyFor(lang),
                accent: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Daily rituals ─────────────────────────────────────────────────
        AppSectionHeader(title: l10n.postpartumDailyRituals),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rituals
              .map((r) => AppStatChip(
                    icon: Icons.spa_outlined,
                    label: r.forLang(lang),
                  ))
              .toList(),
        ),
        const SizedBox(height: 14),

        // ── Wellbeing / baby-blues awareness ──────────────────────────────
        AppGlassCard(
          blur: false,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.volunteer_activism_outlined,
                    color: theme.colorScheme.tertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.postpartumWellbeingTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.postpartumWellbeingBody,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (widget.onOpenCalendar != null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: widget.onOpenCalendar,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(l10n.homeOpenCalendar),
          ),
        ],
      ],
    );
  }
}

class _StageNote extends StatelessWidget {
  const _StageNote({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetBirthDatePrompt extends StatelessWidget {
  const _SetBirthDatePrompt({required this.onSet});

  final VoidCallback onSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AppGlassCard(
      blur: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC407A), Color(0xFFF48FB1)],
                ),
              ),
              child: const Icon(Icons.child_care_rounded,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.postpartumSetDateTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.postpartumSetDatePrompt,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            AppGradientButton(
              label: l10n.postpartumSetDateCta,
              icon: Icons.event_available_outlined,
              onPressed: onSet,
            ),
          ],
        ),
      ),
    );
  }
}
