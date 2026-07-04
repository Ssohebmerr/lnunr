part of 'chat_tab.dart';

// ---------------------------------------------------------------------------
// Empty-state welcome view, the quick-action feature grid, and the persona
// picker. Extracted from chat_tab.dart to keep the screen file focused.
// ---------------------------------------------------------------------------

class _WelcomeState extends StatelessWidget {
  const _WelcomeState({
    required this.l10n,
    required this.theme,
    required this.personality,
    required this.onModeAction,
    required this.onAnalyze,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final LunePersonality personality;
  final void Function(String prompt, String mode) onModeAction;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const SizedBox(height: 8),
        // Greeting icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppShadows.softRose(opacity: 0.25),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.aiWelcome,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.aiWelcomeHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // Feature cards — 2-column grid
        Text(
          l10n.aiQuickActionsTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _FeatureCardsGrid(onModeAction: onModeAction),
        const SizedBox(height: 16),
        // Analyze button
        Center(
          child: Container(
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: AppShadows.softRose(opacity: 0.2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAnalyze,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.analytics_outlined,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l10n.aiAnalyze,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Feature cards — 2-column grid with colored icons
// ---------------------------------------------------------------------------
class _FeatureCardsGrid extends StatelessWidget {
  const _FeatureCardsGrid({required this.onModeAction});

  final void Function(String prompt, String mode) onModeAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final features = <_FeatureCardData>[
      _FeatureCardData(
        icon: Icons.wb_sunny_outlined,
        gradient: const [Color(0xFFFFB347), Color(0xFFFFCC33)],
        label: l10n.aiFeatureBriefing,
        prompt: l10n.aiFeatureBriefingPrompt,
        mode: 'briefing',
      ),
      _FeatureCardData(
        icon: Icons.insights_outlined,
        gradient: const [Color(0xFF6B7FE8), Color(0xFF8F9FF5)],
        label: l10n.aiFeaturePatterns,
        prompt: l10n.aiFeaturePatternsPrompt,
        mode: 'patterns',
      ),
      _FeatureCardData(
        icon: Icons.restaurant_outlined,
        gradient: const [Color(0xFF3D9A78), Color(0xFF5CC4A0)],
        label: l10n.aiFeatureNutrition,
        prompt: l10n.aiFeatureNutritionPrompt,
        mode: 'nutrition',
      ),
      _FeatureCardData(
        icon: Icons.favorite_outline,
        gradient: const [Color(0xFFE85D75), Color(0xFFF58BA0)],
        label: l10n.aiFeaturePartner,
        prompt: l10n.aiFeaturePartnerPrompt,
        mode: 'partner',
      ),
      _FeatureCardData(
        icon: Icons.mood_outlined,
        gradient: const [Color(0xFF9B59B6), Color(0xFFC084E0)],
        label: l10n.aiFeatureMood,
        prompt: l10n.aiFeatureMoodPrompt,
        mode: 'mood',
      ),
      _FeatureCardData(
        icon: Icons.emergency_outlined,
        gradient: const [Color(0xFFE74C3C), Color(0xFFF07070)],
        label: l10n.aiFeatureEmergency,
        prompt: l10n.aiEmergencyPrompt,
        mode: 'emergency',
      ),
      _FeatureCardData(
        icon: Icons.egg_rounded,
        gradient: const [Color(0xFFE85D75), Color(0xFFF4A0B0)],
        label: l10n.aiFeatureFertility,
        prompt: l10n.aiFeatureFertilityPrompt,
        mode: 'fertility',
      ),
      _FeatureCardData(
        icon: Icons.monitor_weight_outlined,
        gradient: const [Color(0xFF3D9A78), Color(0xFF6BC4A0)],
        label: l10n.aiFeatureWeight,
        prompt: l10n.aiFeatureWeightPrompt,
        mode: 'weight',
      ),
      _FeatureCardData(
        icon: Icons.favorite_outline,
        gradient: const [Color(0xFF9B59B6), Color(0xFFC084E0)],
        label: l10n.aiFeatureIntimacy,
        prompt: l10n.aiFeatureIntimacyPrompt,
        mode: 'intimacy',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.6,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        final f = features[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onModeAction(f.prompt, f.mode),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Ink(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.9),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: f.gradient,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(f.icon, size: 17, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureCardData {
  const _FeatureCardData({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.prompt,
    required this.mode,
  });

  final IconData icon;
  final List<Color> gradient;
  final String label;
  final String prompt;
  final String mode;
}

// ---------------------------------------------------------------------------
// Personality picker — three Lune personas as glass chips.
// ---------------------------------------------------------------------------
class _PersonalityPicker extends StatelessWidget {
  const _PersonalityPicker({required this.current, required this.onSelect});

  final LunePersonality current;
  final ValueChanged<LunePersonality> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: LunePersonality.values.map((p) {
          final meta = kLunePersonalityMeta[p]!;
          final selected = current == p;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(p),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(colors: meta.gradient)
                          : null,
                      color: selected
                          ? null
                          : theme.colorScheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : theme.colorScheme.outline.withValues(alpha: 0.12),
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: meta.gradient.first
                                    .withValues(alpha: 0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          meta.icon,
                          size: 16,
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            meta.title(lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
