import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/community_repository.dart';
import '../data/models/followed_user.dart';
import 'widgets/community_ui.dart';

class FollowingScreen extends StatelessWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final repo = context.read<CommunityRepository>();

    return AuraSettingsScaffold(
      title: l10n.communityFollowingTitle,
      body: uid == null
          ? Center(child: Text(l10n.communityLoginRequired))
          : StreamBuilder<List<FollowedUser>>(
              stream: repo.watchFollowing(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final following = snap.data ?? [];
                if (following.isEmpty) {
                  return CommunityEmptyState(
                    icon: Icons.group_outlined,
                    title: l10n.communityFollowingTitle,
                    subtitle: l10n.communityFollowingEmpty,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: following.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = following[index];
                    final label = user.alias?.isNotEmpty == true
                        ? user.alias!
                        : l10n.communityBlockedUserUnknown;

                    return CommunityMemberTile(
                      name: label,
                      uidSeed: user.uid,
                      avatarIndex: user.avatarIndex,
                      since: user.followedAt,
                      actionLabel: l10n.communityUnfollow,
                      onAction: () async {
                        await repo.unfollowUser(
                          uid: uid,
                          followedUid: user.uid,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.communityUnfollowed)),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
