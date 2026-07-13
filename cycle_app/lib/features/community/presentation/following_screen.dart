import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../data/community_repository.dart';
import '../data/models/followed_user.dart';

class FollowingScreen extends StatelessWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final repo = context.read<CommunityRepository>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.communityFollowingTitle)),
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.communityFollowingEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: following.length,
                  itemBuilder: (context, index) {
                    final user = following[index];
                    final label = user.alias?.isNotEmpty == true
                        ? user.alias!
                        : l10n.communityBlockedUserUnknown;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AuraColors.darkCard.withValues(alpha: 0.72)
                            : Colors.white.withValues(alpha: 0.82),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.07),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: AppAvatar(
                            radius: 20,
                            avatarIndex: user.avatarIndex,
                            uidSeed: user.uid,
                          ),
                          title: Text(label),
                          trailing: TextButton(
                            onPressed: () async {
                              await repo.unfollowUser(
                                uid: uid,
                                followedUid: user.uid,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.communityUnfollowed),
                                  ),
                                );
                              }
                            },
                            child: Text(l10n.communityUnfollow),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
