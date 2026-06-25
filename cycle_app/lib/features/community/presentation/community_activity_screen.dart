import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
      _ => l10n.communityActivityComment(alias),
    };
  }

  IconData _iconFor(String type) => switch (type) {
        'like' => Icons.favorite_rounded,
        'reply' => Icons.reply_rounded,
        _ => Icons.chat_bubble_rounded,
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
      return Scaffold(
        appBar: AppBar(title: Text(l10n.communityActivityTitle)),
        body: Center(child: Text(l10n.communityLoginRequired)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.communityActivityTitle),
        actions: [
          TextButton(
            onPressed: () => repo.markAllInboxRead(uid),
            child: Text(l10n.communityMarkAllRead),
          ),
        ],
      ),
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
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              final time = DateFormat.MMMd().add_Hm().format(item.createdAt);
              final community = CommunitySeed.byId(item.communityId);
              final lang = Localizations.localeOf(context).languageCode;

              return Material(
                color: item.read
                    ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                    : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    child: Icon(
                      _iconFor(item.type),
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _titleFor(item, l10n),
                    style: TextStyle(
                      fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.preview.isNotEmpty)
                        Text(
                          item.preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${community?.nameForLocale(lang) ?? item.communityId} · $time',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
