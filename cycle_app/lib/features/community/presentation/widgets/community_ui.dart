import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../l10n/app_localizations.dart';

/// Topic-based accent gradients for community cards and headers.
class CommunityTopicPalette {
  CommunityTopicPalette._();

  static List<Color> gradient(String topic) => switch (topic) {
    'conception' => const [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
    'contraception' => const [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    'condition' => const [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
    'support' => const [AuraColors.rose, AuraColors.peachGold],
    'culture' => const [Color(0xFF667EEA), Color(0xFF764BA2)],
    'age' => const [Color(0xFFF093FB), Color(0xFFF5576C)],
    _ => AuraColors.gradientRoseLavender,
  };

  static Color iconColor(String topic) => switch (topic) {
    'conception' => const Color(0xFFE85D75),
    'contraception' => const Color(0xFF7B5EA7),
    'condition' => const Color(0xFF3D9A78),
    'support' => AuraColors.roseDeep,
    'culture' => const Color(0xFF5C6BC0),
    'age' => const Color(0xFFD94F8A),
    _ => AuraColors.roseDeep,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header — premium glassmorphic design
// ─────────────────────────────────────────────────────────────────────────────

class CommunityHeroHeader extends StatelessWidget {
  const CommunityHeroHeader({
    super.key,
    required this.l10n,
    required this.joinedCount,
    this.alias,
    this.avatarIndex = 0,
    this.photoUrl,
    this.uidSeed,
    this.onEditProfile,
    this.onActivityTap,
    this.unreadCount = 0,
    this.onGuidelinesTap,
  });

  final AppLocalizations l10n;
  final int joinedCount;
  final String? alias;
  final int avatarIndex;
  final String? photoUrl;
  final String? uidSeed;
  final VoidCallback? onEditProfile;
  final VoidCallback? onActivityTap;
  final int unreadCount;
  final VoidCallback? onGuidelinesTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // The app shell already provides the page title and account avatar. Keep
    // this area to actions and identity only, rather than repeating a second
    // oversized title card above another tab bar.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          if (alias != null && alias!.isNotEmpty)
            Expanded(
              child: SizedBox(
                height: 52,
                child: _ProfileChip(
                  alias: alias!,
                  avatarIndex: avatarIndex,
                  photoUrl: photoUrl,
                  uidSeed: uidSeed,
                  onTap: onEditProfile,
                  isDark: isDark,
                  aliasLabel: l10n.communityYourAlias,
                ),
              ),
            )
          else
            Expanded(
              child: Text(
                l10n.communityPrivacyNote,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(width: 8),
          _GlassChip(
            icon: Icons.groups_rounded,
            label: '$joinedCount',
            sub: l10n.communityTabMine,
            isDark: isDark,
          ),
          if (onGuidelinesTap != null)
            _HeaderIconBtn(
              icon: Icons.menu_book_outlined,
              tooltip: l10n.communityGuidelinesShort,
              onTap: onGuidelinesTap!,
            ),
          if (onActivityTap != null)
            Stack(
              clipBehavior: Clip.none,
              children: [
                _HeaderIconBtn(
                  icon: Icons.notifications_outlined,
                  tooltip: l10n.communityActivityTitle,
                  onTap: onActivityTap!,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: _UnreadBadge(count: unreadCount, isDark: isDark),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count, required this.isDark});

  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: AuraColors.danger,
      shape: BoxShape.circle,
      border: Border.all(
        color: isDark ? const Color(0xFF2A1520) : Colors.white,
        width: 1.5,
      ),
    ),
    child: Center(
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.icon,
    required this.label,
    required this.sub,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String sub;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AuraColors.darkCard
            : theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: (isDark ? Colors.white : theme.colorScheme.outline).withValues(
            alpha: isDark ? 0.07 : 0.08,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            sub,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.alias,
    required this.avatarIndex,
    required this.photoUrl,
    required this.uidSeed,
    required this.onTap,
    required this.isDark,
    required this.aliasLabel,
  });

  final String alias;
  final int avatarIndex;
  final String? photoUrl;
  final String? uidSeed;
  final VoidCallback? onTap;
  final bool isDark;
  final String aliasLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : theme.colorScheme.surface)
                .withValues(alpha: isDark ? 0.08 : 0.7),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                AppAvatar(
                  radius: 14,
                  avatarIndex: avatarIndex,
                  networkUrl: photoUrl,
                  uidSeed: uidSeed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aliasLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        alias,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsetsDirectional.only(start: 4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : theme.colorScheme.surface).withValues(
          alpha: isDark ? 0.08 : 0.65,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : theme.colorScheme.outline.withValues(alpha: 0.06),
        ),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar — premium segmented style
// ─────────────────────────────────────────────────────────────────────────────

class CommunityHubTabBar extends StatelessWidget {
  const CommunityHubTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  final TabController controller;
  final List<({IconData icon, String label})> tabs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isDark
              ? AuraColors.darkCard
              : Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: (isDark ? Colors.white : theme.colorScheme.outline)
                .withValues(alpha: isDark ? 0.07 : 0.08),
          ),
        ),
        child: TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.all(4),
          indicator: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          unselectedLabelStyle: theme.textTheme.labelMedium,
          tabs: tabs
              .map(
                (t) => Tab(
                  height: 38,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon, size: 16),
                      const SizedBox(width: 6),
                      Text(t.label),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips — horizontal scroll
// ─────────────────────────────────────────────────────────────────────────────

class CommunityFilterChips extends StatelessWidget {
  const CommunityFilterChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<({String id, String label, IconData? icon})> items;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return CommunityChoiceChip(
            label: item.label,
            icon: item.icon,
            selected: selected == item.id,
            onTap: () => onSelected(item.id),
          );
        },
      ),
    );
  }
}

class CommunityChoiceChip extends StatelessWidget {
  const CommunityChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white : theme.colorScheme.surface)
                        .withValues(alpha: isDark ? 0.06 : 0.85),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : (isDark ? Colors.white : theme.colorScheme.outline)
                          .withValues(alpha: isDark ? 0.08 : 0.1),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: icon != null ? 12 : 16,
              vertical: 9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search field
// ─────────────────────────────────────────────────────────────────────────────

class CommunitySearchField extends StatelessWidget {
  const CommunitySearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          filled: true,
          fillColor: isDark
              ? AuraColors.darkCard
              : Colors.white.withValues(alpha: 0.94),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14, end: 10),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class CommunityEmptyState extends StatelessWidget {
  const CommunityEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                    theme.colorScheme.secondary.withValues(alpha: 0.08),
                    AuraColors.lavender.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(icon, size: 44, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post action button (like, save, share, comment)
// ─────────────────────────────────────────────────────────────────────────────

class CommunityPostAction extends StatelessWidget {
  const CommunityPostAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? (activeColor ?? theme.colorScheme.primary)
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey(active),
                  size: 18,
                  color: color,
                ),
              ),
              if (label != null) ...[
                const SizedBox(width: 5),
                Text(
                  label!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
