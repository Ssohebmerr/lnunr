import 'package:flutter/material.dart';

import '../../../core/ai/lune_personality.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';

/// Segmented Lune persona switcher rendered inside the chat header banner.
///
/// Styling is IDENTICAL to the original in-body picker (same glass panel,
/// blur, borders, and shadows) — only its position moved into the banner.
class LunePersonalityPicker extends StatelessWidget {
  const LunePersonalityPicker({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final LunePersonality current;
  final ValueChanged<LunePersonality> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return AppFloatingGlassPanel(
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
    );
  }
}
