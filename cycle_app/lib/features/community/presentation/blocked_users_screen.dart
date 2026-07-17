import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/community_repository.dart';
import '../data/models/blocked_user.dart';
import 'widgets/community_ui.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final repo = context.read<CommunityRepository>();

    return AuraSettingsScaffold(
      title: l10n.communityBlockedUsersTitle,
      body: uid == null
          ? Center(child: Text(l10n.communityLoginRequired))
          : StreamBuilder<List<BlockedUser>>(
              stream: repo.watchBlockedUsers(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final blocked = snap.data ?? [];
                if (blocked.isEmpty) {
                  return CommunityEmptyState(
                    icon: Icons.shield_outlined,
                    title: l10n.communityBlockedUsersTitle,
                    subtitle: l10n.communityBlockedUsersEmpty,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: blocked.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = blocked[index];
                    final label = user.authorAlias?.isNotEmpty == true
                        ? user.authorAlias!
                        : l10n.communityBlockedUserUnknown;

                    return CommunityMemberTile(
                      name: label,
                      uidSeed: user.uid,
                      since: user.blockedAt,
                      actionLabel: l10n.communityUnblockUser,
                      onAction: () async {
                        await repo.unblockUser(
                          uid: uid,
                          blockedUid: user.uid,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.communityUnblocked)),
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
