import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/community_repository.dart';
import '../data/community_seed.dart';
import '../data/models/community_inbox_item.dart';
import 'community_detail_screen.dart';
import 'widgets/community_ui.dart';

class CommunityActivityScreen extends StatelessWidget {
  const CommunityActivityScreen({super.key});

  String _titleFor(CommunityInboxItem item, AppLocalizations l10n) {
    final alias = item.fromAlias.isNotEmpty ? item.fromAlias : '—';
    return switch (item.type) {
      'like' => l10n.communityActivityLike(alias),
      'reply' => l10n.communityActivityReply(alias),
      'follow' => l10n.communityActivityFollow(alias),
      'mention' => l10n.communityActivityMention(alias),
      _ => l10n.communityActivityComment(alias),
    };
  }

  /// The small action badge that overlays the sender's avatar — icon + the
  /// on-brand colour for each activity kind.
  ({IconData icon, Color color}) _badgeFor(String type, ColorScheme scheme) =>
      switch (type) {
        'like' => (icon: Icons.favorite_rounded, color: AuraColors.accent),
        'reply' => (icon: Icons.reply_rounded, color: scheme.primary),
        'follow' => (
          icon: Icons.person_add_alt_1_rounded,
          color: AuraColors.success,
        ),
        'mention' => (
          icon: Icons.alternate_email_rounded,
          color: const Color(0xFF7B5EA7),
        ),
        _ => (icon: Icons.chat_bubble_rounded, color: scheme.primary),
      };

  Future<void> _openItem(
    BuildContext context,
    CommunityInboxItem item,
    String uid,
    String alias,
  ) async {
    final repo = context.read<CommunityRepository>();
    await repo.markInboxItemRead(uid, item.id);
    final community = CommunitySeed.byId(item.communityId);
    if (community == null || !context.mounted) return;
    final joined = await repo.isMember(uid, item.communityId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          community: community,
          alias: alias,
          isJoined: joined,
          initialPostId: item.postId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final repo = context.read<CommunityRepository>();

    if (uid == null) {
      return AuraSettingsScaffold(
        title: l10n.communityActivityTitle,
        body: Center(child: Text(l10n.communityLoginRequired)),
      );
    }

    return AuraSettingsScaffold(
      title: l10n.communityActivityTitle,
      actions: [
        StreamBuilder<List<CommunityInboxItem>>(
          stream: repo.watchInbox(uid),
          builder: (context, snap) {
            final hasUnread = (snap.data ?? []).any((i) => !i.read);
            return TextButton(
              onPressed: hasUnread ? () => repo.markAllInboxRead(uid) : null,
              child: Text(l10n.communityMarkAllRead),
            );
          },
        ),
      ],
      body: StreamBuilder<List<CommunityInboxItem>>(
        stream: repo.watchInbox(uid),
        builder: (context, snap) {
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return CommunityEmptyState(
              icon: Icons.notifications_none_rounded,
              title: l10n.communityActivityTitle,
              subtitle: l10n.communityActivityEmpty,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = items[i];
              final community = CommunitySeed.byId(item.communityId);
              final lang = Localizations.localeOf(context).languageCode;
              final source =
                  '${community?.nameForLocale(lang) ?? item.communityId} · '
                  '${DateFormat.MMMd().add_Hm().format(item.createdAt)}';

              return _ActivityCard(
                title: _titleFor(item, l10n),
                preview: item.preview,
                source: source,
                fromAlias: item.fromAlias,
                badge: _badgeFor(item.type, Theme.of(context).colorScheme),
                unread: !item.read,
                onTap: () async {
                  final profile = await repo.resolveProfile(uid);
                  if (!context.mounted) return;
                  await _openItem(
                    context,
                    item,
                    uid,
                    profile.alias.isNotEmpty ? profile.alias : 'User',
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// A single activity row rendered as a soft community glass card: the
/// sender's avatar carries a coloured action badge, the message reads as the
/// title, and unread items get an accent tint plus a trailing dot.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.preview,
    required this.source,
    required this.fromAlias,
    required this.badge,
    required this.unread,
    required this.onTap,
  });

  final String title;
  final String preview;
  final String source;
  final String fromAlias;
  final ({IconData icon, Color color}) badge;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color fill = unread
        ? scheme.primary.withValues(alpha: isDark ? 0.15 : 0.09)
        : (isDark
              ? AuraColors.darkCard.withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.82));
    final Color borderColor = unread
        ? scheme.primary.withValues(alpha: 0.30)
        : (isDark ? Colors.white : scheme.outline).withValues(
            alpha: isDark ? 0.06 : 0.08,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarWithBadge(seed: fromAlias, badge: badge, isDark: isDark),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        source,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    margin: const EdgeInsetsDirectional.only(start: 8, top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
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

class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({
    required this.seed,
    required this.badge,
    required this.isDark,
  });

  final String seed;
  final ({IconData icon, Color color}) badge;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppAvatar(radius: 23, uidSeed: seed.isNotEmpty ? seed : null),
        PositionedDirectional(
          bottom: -2,
          end: -3,
          child: Container(
            width: 21,
            height: 21,
            decoration: BoxDecoration(
              color: badge.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF241827) : Colors.white,
                width: 2,
              ),
            ),
            child: Icon(badge.icon, size: 11, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
