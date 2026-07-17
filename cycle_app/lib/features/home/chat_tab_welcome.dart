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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppShadows.softRose(opacity: 0.18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 16),
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
              boxShadow: AppShadows.softRose(opacity: 0.14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAnalyze,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
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
class _FeatureCardsGrid extends StatefulWidget {
  const _FeatureCardsGrid({required this.onModeAction});

  final void Function(String prompt, String mode) onModeAction;

  @override
  State<_FeatureCardsGrid> createState() => _FeatureCardsGridState();
}

class _FeatureCardsGridState extends State<_FeatureCardsGrid> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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

    final visibleCount = _showAll ? features.length : 4;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 64,
            ),
            itemCount: visibleCount,
            itemBuilder: (context, i) {
              final f = features[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onModeAction(f.prompt, f.mode),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: _ChatGlassSurface(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    accent: f.gradient.first,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: f.gradient),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(f.icon, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 9),
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
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          key: const ValueKey('ai-topics-toggle'),
          onPressed: () => setState(() => _showAll = !_showAll),
          icon: Icon(
            _showAll
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 19,
          ),
          label: Text(_showAll ? l10n.showLess : l10n.showMore),
        ),
      ],
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
// Personality picker — all three Lune styles stay visible at a glance.
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
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 5),
      child: AppFloatingGlassPanel(
        padding: const EdgeInsets.all(4),
        radius: AppRadius.pill,
        tint: theme.colorScheme.primary,
        blurSigma: 18,
        child: Row(
          children: LunePersonality.values.map((personality) {
            final meta = kLunePersonalityMeta[personality]!;
            final selected = current == personality;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: '${meta.title(lang)}، ${meta.tag(lang)}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelect(personality),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        constraints: const BoxConstraints(minHeight: 42),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? LinearGradient(colors: meta.gradient)
                              : null,
                          color: selected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.12,
                                  ),
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: meta.gradient.first.withValues(
                                      alpha: 0.20,
                                    ),
                                    blurRadius: 9,
                                    offset: const Offset(0, 3),
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
                            const SizedBox(width: 5),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  meta.title(lang),
                                  maxLines: 1,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
