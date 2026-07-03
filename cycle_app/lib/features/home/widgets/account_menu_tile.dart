import 'package:flutter/material.dart';

import '../../../core/widgets/aura_scaffold.dart';
import '../../../core/widgets/feminine_icon.dart';

/// Single row in the account hub menu (icon · title · chevron or trailing).
class AccountMenuTile extends StatelessWidget {
  const AccountMenuTile({
    super.key,
    this.icon,
    this.femIcon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  }) : assert(icon != null || femIcon != null,
            'Provide either icon or femIcon');

  final IconData? icon;
  final FeminineIcon? femIcon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: femIcon != null
                        ? FeminineIconView(
                            femIcon!,
                            size: 22,
                            color: theme.colorScheme.primary,
                          )
                        : Icon(icon,
                            size: 22, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_left_rounded,
                        color: theme.colorScheme.outline,
                      ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 16,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
      ],
    );
  }
}

/// Glass card grouping account menu rows.
class AccountMenuCard extends StatelessWidget {
  const AccountMenuCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
