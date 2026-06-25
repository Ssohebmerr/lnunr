import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/chat_tab.dart';
import '../bloc/chat_bloc.dart';
import '../data/chat_repository.dart';

/// Dedicated Lune AI chat screen with its own [ChatBloc] instance.
class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? UserPrefs.localChatUid;

    return BlocProvider(
      create: (c) => ChatBloc(
        repository: c.read<ChatRepository>(),
        uid: uid,
        contextEngine: c.read<AiContextEngine>(),
      )..add(LoadChatMessages()),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.homeAiCardTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          centerTitle: true,
        ),
        body: AppMeshBackground(
          child: const SafeArea(child: ChatTab()),
        ),
      ),
    );
  }
}
