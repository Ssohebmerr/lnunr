import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart' as md;
import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:provider/provider.dart';

import '../../../core/age/age_gate.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/profile/local_profile.dart';
import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/notifications/notification_rationale_dialog.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/security/cycle_encryption_keys.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../core/widgets/avatar_picker_row.dart';
import '../../../core/widgets/feminine_icons_custom.dart';
import '../../../l10n/app_localizations.dart';
import '../../cycle/data/cycle_sync_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _sync = CycleSyncService();

  static const _totalSteps = 6;
  int _step = 0;
  int _avatarIndex = 0;
  UserGoalTypes _goal = UserGoalTypes.general;
  int _cycleLength = 28;
  int _periodDuration = 5;
  DateTime _lastPeriod = DateTime.now().subtract(const Duration(days: 14));
  DateTime? _birthDate;
  DateFormats _dateFormat = DateFormats.dmy;
  bool _privacyAccepted = false;
  bool _saving = false;
  bool _blockedUnder13 = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await blocksAppByAgeGate()) {
        if (mounted) setState(() => _blockedUnder13 = true);
        return;
      }
      await _showAgeGateIfNeeded();
    });
  }

  Future<void> _showAgeGateIfNeeded() async {
    if (await isAgeGateDone()) return;
    if (!mounted) return;

    final group = await showAgeGate(context);
    if (group == null) return;

    if (group == AgeGroup.under13) {
      await saveAgeGroup(group);
      if (mounted) setState(() => _blockedUnder13 = true);
      return;
    }

    await saveAgeGroup(group);

    if (group == AgeGroup.teen && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.ageGateMinorNote),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      setState(() => _step--);
    }
  }

  Future<void> _pickBirthDate() async {
    final initial = _birthDate ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: AppLocalizations.of(context)!.onboardingBirthDateLabel,
    );
    if (picked != null) {
      setState(() => _birthDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriod,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lastPeriod = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _ensureCycleWidgetReady() async {
    if (MenstrualCycleWidget.instance != null) return;
    final keys = await CycleEncryptionKeys.loadOrCreate();
    MenstrualCycleWidget.init(
      secretKey: keys['secretKey'],
      ivKey: keys['ivKey'],
    );
  }

  Future<void> _finish() async {
    if (!_privacyAccepted || _saving) return;
    final lang = context.read<LocaleController>().locale.languageCode;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    if (_blockedUnder13 || await blocksAppByAgeGate()) return;
    if (!mounted) return;
    setState(() => _saving = true);

    var enteredHome = false;
    try {
      await LocalProfile.saveAvatarIndex(_avatarIndex);
      await _ensureCycleWidgetReady();
      // For postpartum, the date field IS the baby's birth date — anchor the
      // recovery experience so the home section doesn't prompt again.
      if (_goal.isPostpartumMode) {
        await UserPrefs.setPostpartumStartDate(_lastPeriod);
      }
      await _sync.completeOnboarding(
        cycleLength: _cycleLength,
        periodDuration: _periodDuration,
        lastPeriodDate: _lastPeriod,
        languageCode: lang,
        dateFormat: _dateFormat,
        displayName: _nameController.text.trim(),
        birthDate: _birthDate,
        goal: _goal,
      );
      if (!mounted) return;
      await showNotificationRationale(context);
      try {
        await NotificationService.scheduleFromPrefs();
      } catch (e) {
        debugPrint('Onboarding notification schedule skipped: $e');
      }
      if (mounted) {
        router.go('/home');
        enteredHome = true;
      }
    } catch (e, st) {
      debugPrint('Onboarding finish failed: $e\n$st');
      final done = await UserPrefs.isOnboardingDone();
      if (mounted && done && !enteredHome) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.onboardingPartialSave)),
        );
        router.go('/home');
      } else if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mdL10n = md.AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_blockedUnder13) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.gradientBackground(context),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.block_outlined,
                      size: 56,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.ageGateTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.ageGateUnder13Message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: AppTheme.gradientBackground(context),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    if (_step > 0)
                      IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back))
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            l10n.onboardingStepLabel(_step + 1, _totalSteps),
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: (_step + 1) / _totalSteps,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomeStep(l10n: l10n),
                    _ProfileStep(
                      l10n: l10n,
                      nameController: _nameController,
                      avatarIndex: _avatarIndex,
                      birthDate: _birthDate,
                      onPickBirthDate: _pickBirthDate,
                      onAvatarChanged: (i) => setState(() => _avatarIndex = i),
                    ),
                    _GoalStep(
                      selected: _goal,
                      mdL10n: mdL10n,
                      l10n: l10n,
                      onChanged: (g) => setState(() => _goal = g),
                    ),
                    _CycleStep(
                      l10n: l10n,
                      goal: _goal,
                      cycleLength: _cycleLength,
                      periodDuration: _periodDuration,
                      lastPeriod: _lastPeriod,
                      dateFormat: _dateFormat,
                      onCycleLength: (v) => setState(() => _cycleLength = v),
                      onPeriodDuration: (v) => setState(() => _periodDuration = v),
                      onPickDate: _pickDate,
                      onDateFormat: (v) => setState(() => _dateFormat = v),
                    ),
                    _PrivacyStep(
                      l10n: l10n,
                      accepted: _privacyAccepted,
                      onChanged: (v) => setState(() => _privacyAccepted = v),
                    ),
                    _FeaturesStep(l10n: l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_step == _totalSteps - 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.onboardingReadyHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              AppGradientButton(
                label: _step == _totalSteps - 1
                    ? l10n.getStarted
                    : l10n.continueBtn,
                loading: _saving,
                onPressed: _canContinue() ? _next : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canContinue() {
    if (_blockedUnder13) return false;
    if (_step == 1) {
      return _nameController.text.trim().isNotEmpty &&
          _birthDate != null &&
          !_saving;
    }
    if (_step == 4) return _privacyAccepted && !_saving;
    return !_saving;
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.l10n,
    required this.nameController,
    required this.avatarIndex,
    required this.birthDate,
    required this.onPickBirthDate,
    required this.onAvatarChanged,
  });

  final AppLocalizations l10n;
  final TextEditingController nameController;
  final int avatarIndex;
  final DateTime? birthDate;
  final VoidCallback onPickBirthDate;
  final ValueChanged<int> onAvatarChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AppGlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Center(child: AppAvatar(radius: 44, avatarIndex: avatarIndex)),
          const SizedBox(height: 16),
          Text(l10n.avatarPickTitle, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          AvatarPickerRow(
            selectedIndex: avatarIndex,
            onSelected: onAvatarChanged,
          ),
          const SizedBox(height: 20),
          Text(l10n.onboardingProfileTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.onboardingProfileSubtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingNoEmailNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.onboardingNameLabel,
              hintText: l10n.onboardingNameHint,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onPickBirthDate,
            icon: const Icon(Icons.cake_outlined),
            label: Text(
              birthDate == null
                  ? l10n.onboardingBirthDateHint
                  : MaterialLocalizations.of(context).formatMediumDate(birthDate!),
            ),
            style: OutlinedButton.styleFrom(
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          if (birthDate == null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                l10n.onboardingBirthDateRequired,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.selected,
    required this.mdL10n,
    required this.l10n,
    required this.onChanged,
  });

  static const _displayGoals = [
    UserGoalTypes.general,
    UserGoalTypes.pregnant,
    UserGoalTypes.conceive,
    UserGoalTypes.avoid,
    UserGoalTypes.menopause,
    UserGoalTypes.pcos,
    UserGoalTypes.postpartum,
  ];

  final UserGoalTypes selected;
  final md.AppLocalizations? mdL10n;
  final AppLocalizations l10n;
  final ValueChanged<UserGoalTypes> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardingGoalTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.onboardingGoalSubtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: _displayGoals.map((goal) {
                final isSelected = goal == selected;
                return AppGlassCard(
                  onTap: () => onChanged(goal),
                  padding: const EdgeInsets.all(14),
                  radius: AppRadius.lg,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.06)
                          : null,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary
                                          .withValues(alpha: isSelected ? 0.22 : 0.12),
                                      theme.colorScheme.secondary
                                          .withValues(alpha: isSelected ? 0.14 : 0.08),
                                    ],
                                  ),
                                ),
                                child: FeminineIconView(
                                  goal.femIcon,
                                  size: 30,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                mdL10n != null
                                    ? goal.getDisplayName(mdL10n!)
                                    : goal.dbName,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          PositionedDirectional(
                            top: 0,
                            end: 0,
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleStep extends StatelessWidget {
  const _CycleStep({
    required this.l10n,
    required this.goal,
    required this.cycleLength,
    required this.periodDuration,
    required this.lastPeriod,
    required this.dateFormat,
    required this.onCycleLength,
    required this.onPeriodDuration,
    required this.onPickDate,
    required this.onDateFormat,
  });

  final AppLocalizations l10n;
  final UserGoalTypes goal;
  final int cycleLength;
  final int periodDuration;
  final DateTime lastPeriod;
  final DateFormats dateFormat;
  final ValueChanged<int> onCycleLength;
  final ValueChanged<int> onPeriodDuration;
  final VoidCallback onPickDate;
  final ValueChanged<DateFormats> onDateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPregnant = goal.isPregnancyMode;
    final isPostpartum = goal.isPostpartumMode;
    final isCycleMode = goal.isCycleGoalMode;
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');

    final String title;
    final String subtitle;
    final String dateLabel;
    final IconData dateIcon;
    if (isPregnant) {
      title = l10n.onboardingPregnancyDataTitle;
      subtitle = l10n.onboardingPregnancyDataSubtitle;
      dateLabel = l10n.onboardingPregnancyLmp;
      dateIcon = Icons.calendar_today;
    } else if (isPostpartum) {
      title = l10n.postpartumSetDateTitle;
      subtitle = l10n.postpartumSetDatePrompt;
      dateLabel = l10n.postpartumBirthDateLabel;
      dateIcon = Icons.child_care_outlined;
    } else if (isCycleMode) {
      title = l10n.onboardingCycleTitle;
      subtitle = l10n.onboardingCycleSubtitle;
      dateLabel = l10n.lastPeriodDate;
      dateIcon = Icons.calendar_today;
    } else {
      title = isAr ? 'تفاصيل سريعة' : 'A few quick details';
      subtitle = isAr
          ? 'سنسأل فقط عن آخر دورة لتبدأ التتبّع.'
          : 'We only ask for the basics so we can start tracking.';
      dateLabel = l10n.lastPeriodDate;
      dateIcon = Icons.calendar_today;
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        if (isCycleMode) ...[
          _StepperCard(label: l10n.cycleLength, value: cycleLength, onChanged: onCycleLength),
          const SizedBox(height: 12),
          _StepperCard(label: l10n.periodDuration, value: periodDuration, onChanged: onPeriodDuration),
          const SizedBox(height: 12),
        ],
        AppGlassCard(
          onTap: onPickDate,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(dateIcon, color: theme.colorScheme.primary),
            title: Text(dateLabel),
            subtitle: Text(
              '${lastPeriod.year}-${lastPeriod.month.toString().padLeft(2, '0')}-${lastPeriod.day.toString().padLeft(2, '0')}',
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppGlassCard(
          child: DropdownButtonFormField<DateFormats>(
            initialValue: dateFormat,
            decoration: InputDecoration(
              labelText: l10n.onboardingDateFormat,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            items: [
              DropdownMenuItem(value: DateFormats.dmy, child: Text(l10n.dateFormatDDMMYYYY)),
              DropdownMenuItem(value: DateFormats.mdy, child: Text(l10n.dateFormatMMDDYYYY)),
              DropdownMenuItem(value: DateFormats.ymd, child: Text(l10n.dateFormatYYYYMMDD)),
            ],
            onChanged: (v) {
              if (v != null) onDateFormat(v);
            },
          ),
        ),
      ],
    );
  }
}

class _PrivacyStep extends StatelessWidget {
  const _PrivacyStep({
    required this.l10n,
    required this.accepted,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(l10n.privacyTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(l10n.privacyCenterIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          CheckboxListTile(
            value: accepted,
            onChanged: (v) => onChanged(v ?? false),
            title: Text(l10n.onboardingPrivacyAgree),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          TextButton(
            onPressed: openPrivacyPolicy,
            child: Text(l10n.privacyPolicyLink),
          ),
          TextButton(
            onPressed: openTermsOfService,
            child: Text(l10n.termsOfServiceLink),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AuraDecorations.primaryGradient,
            ),
            child: const Icon(Icons.spa_rounded, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingWelcomeTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingWelcomeSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingWelcomeHelps,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _WelcomeBullet(icon: Icons.person_outline, text: l10n.onboardingWelcomeTrack, theme: theme),
          _WelcomeBullet(icon: Icons.auto_awesome_rounded, text: l10n.onboardingWelcomeAi, theme: theme),
          _WelcomeBullet(icon: Icons.groups_rounded, text: l10n.onboardingWelcomeCommunity, theme: theme),
          _WelcomeBullet(icon: Icons.pregnant_woman_rounded, text: l10n.onboardingWelcomePregnancy, theme: theme),
          _WelcomeBullet(icon: Icons.favorite_rounded, text: l10n.onboardingWelcomeSelfCare, theme: theme),
        ],
      ),
    );
  }
}

class _WelcomeBullet extends StatelessWidget {
  const _WelcomeBullet({required this.icon, required this.text, required this.theme});
  final IconData icon;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _FeaturesStep extends StatelessWidget {
  const _FeaturesStep({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingFeaturesTitle,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingFeaturesSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _FeatureCard(
                  icon: Icons.home_rounded,
                  color: theme.colorScheme.primary,
                  title: l10n.onboardingFeatureHome,
                  desc: l10n.onboardingFeatureHomeDesc,
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.spa_rounded,
                  color: theme.colorScheme.secondary,
                  title: l10n.onboardingFeatureSelfCare,
                  desc: l10n.onboardingFeatureSelfCareDesc,
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.groups_rounded,
                  color: const Color(0xFFE91E63),
                  title: l10n.onboardingFeatureCommunity,
                  desc: l10n.onboardingFeatureCommunityDesc,
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.summarize_rounded,
                  color: theme.colorScheme.tertiary,
                  title: l10n.onboardingFeatureReports,
                  desc: l10n.onboardingFeatureReportsDesc,
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.person_rounded,
                  color: AuraColors.peachGold,
                  title: l10n.onboardingFeatureAccount,
                  desc: l10n.onboardingFeatureAccountDesc,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.theme,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperCard extends StatelessWidget {
  const _StepperCard({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$value', style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
