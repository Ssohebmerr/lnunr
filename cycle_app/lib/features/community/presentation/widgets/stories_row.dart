import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/community_seed.dart';
import '../../data/community_story_repository.dart';
import '../../data/models/community_story.dart';
import 'story_widgets.dart';

/// Horizontal scrollable row of story circles — shown at top of community feed.
class StoriesRow extends StatefulWidget {
  const StoriesRow({
    super.key,
    required this.joinedIds,
    required this.alias,
    required this.avatarIndex,
    required this.onCreateStory,
  });

  final List<String> joinedIds;
  final String? alias;
  final int avatarIndex;
  final VoidCallback onCreateStory;

  @override
  State<StoriesRow> createState() => _StoriesRowState();
}

class _StoriesRowState extends State<StoriesRow> {
  Stream<List<CommunityStory>>? _storiesStream;
  String _joinedKey = '';

  void _ensureStableStream(CommunityStoryRepository repo) {
    final ids = [...widget.joinedIds]..sort();
    final key = ids.join('|');
    if (_storiesStream == null || key != _joinedKey) {
      _joinedKey = key;
      _storiesStream = repo.watchJoinedStories(ids);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CommunityStoryRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _ensureStableStream(repo);

    return StreamBuilder<List<CommunityStory>>(
      stream: _storiesStream,
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('StoriesRow stream error: ${snap.error}');
          return SizedBox(
            height: 100,
            child: Semantics(
              label: 'Stories',
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  StoryRing(
                    group: StoryGroup(
                      authorUid: uid ?? '',
                      authorAlias: widget.alias ?? 'You',
                      authorAvatarIndex: widget.avatarIndex,
                      stories: const [],
                      currentUid: uid,
                    ),
                    isViewed: false,
                    isCurrentUser: true,
                    onTap: widget.onCreateStory,
                  ),
                ],
              ),
            ),
          );
        }

        final stories = snap.data ?? [];
        if (stories.isEmpty && widget.joinedIds.isEmpty) {
          return const SizedBox.shrink();
        }

        // Group by author
        final groupMap = <String, StoryGroup>{};
        for (final s in stories) {
          final existing = groupMap[s.authorUid];
          if (existing != null) {
            existing.stories.add(s);
          } else {
            final community = CommunitySeed.byId(s.communityId);
            final lang = Localizations.localeOf(context).languageCode;
            groupMap[s.authorUid] = StoryGroup(
              authorUid: s.authorUid,
              authorAlias: s.authorAlias,
              authorAvatarIndex: s.authorAvatarIndex,
              stories: [s],
              communityName: community?.nameForLocale(lang),
              currentUid: uid,
            );
          }
        }

        final groups = groupMap.values.toList()
          ..sort((a, b) {
            if (a.allViewed != b.allViewed) return a.allViewed ? 1 : -1;
            return b.latest.createdAt.compareTo(a.latest.createdAt);
          });

        final myGroupIndex = groups.indexWhere((g) => g.authorUid == uid);
        final hasMyStory = myGroupIndex >= 0;

        return SizedBox(
          height: 100,
          child: Semantics(
            label: 'Stories',
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: groups.length + (hasMyStory ? 0 : 1),
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                if (!hasMyStory && i == 0) {
                  return StoryRing(
                    group: StoryGroup(
                      authorUid: uid ?? '',
                      authorAlias: widget.alias ?? 'You',
                      authorAvatarIndex: widget.avatarIndex,
                      stories: const [],
                      currentUid: uid,
                    ),
                    isViewed: false,
                    isCurrentUser: true,
                    onTap: widget.onCreateStory,
                  );
                }

                final groupIndex = hasMyStory ? i : i - 1;
                final group = groups[groupIndex];
                final isOwn = group.authorUid == uid;
                final isViewed = isOwn ? false : group.allViewed;

                return StoryRing(
                  group: group,
                  isViewed: isViewed,
                  isCurrentUser: isOwn && group.stories.isEmpty,
                  onTap: () {
                    if (isOwn && group.stories.isEmpty) {
                      widget.onCreateStory();
                      return;
                    }
                    _openViewer(context, groups, groupIndex);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _openViewer(
    BuildContext context,
    List<StoryGroup> groups,
    int initialIndex,
  ) {
    final repo = context.read<CommunityStoryRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => StoryViewer(
          groups: groups,
          initialGroupIndex: initialIndex,
          currentUid: uid,
          onDelete: (communityId, storyId) =>
              repo.deleteStory(communityId, storyId),
          onMarkViewed: (communityId, storyId) =>
              repo.markViewed(communityId, storyId),
        ),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
