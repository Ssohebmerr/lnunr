import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/premium/premium_activation_service.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/premium/premium_status_notifier.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/chat_tab.dart';
import '../../premium/presentation/subscription_plans_screen.dart';
import '../bloc/chat_bloc.dart';
import '../data/chat_repository.dart';

/// Dedicated Lune AI chat screen — Premium + registered users only.
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  bool _ready = false;
  bool _premium = false;
  String? _uid;
  String? _error;

  @override
  void initState() {
    super.initState();
    PremiumStatusNotifier.instance.addListener(_onPremiumChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    PremiumStatusNotifier.instance.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    setState(() => _premium = PremiumStatusNotifier.instance.isPremium);
  }

  Future<void> _bootstrap() async {
    try {
      // Read the server-side premium flag for the CURRENT Firebase uid.
      // Entitlement lives in Firestore only — the client never grants it.
      final status = await PremiumActivationService.refreshPremiumStatus();
      final premium = status.ok || await PremiumGate.hasPremium();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        throw StateError('No Firebase session after registration');
      }

      if (mounted) {
        setState(() {
          _premium = premium;
          _uid = premium ? uid : null;
          _ready = true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _ready = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_premium) {
      return Scaffold(
        body: SafeArea(
          child: SubscriptionPlansScreen(
            onSubscribed: () {
              _bootstrap();
            },
          ),
        ),
      );
    }

    if (_uid == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? l10n.errorGeneric,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (c) => ChatBloc(
        repository: c.read<ChatRepository>(),
        uid: _uid!,
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
