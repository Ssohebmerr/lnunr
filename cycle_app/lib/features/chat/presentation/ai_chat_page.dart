import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/lune_personality.dart';
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
import 'personality_picker.dart';

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
    setState(() {
      _premium = PremiumStatusNotifier.instance.isPremium;
      // If premium just flipped on (e.g. right after a purchase), make sure
      // the chat has a uid to load with instead of falling to the error view.
      _uid ??= FirebaseAuth.instance.currentUser?.uid;
    });
  }

  Future<void> _bootstrap() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // Fast path: the locally cached entitlement renders the chat instantly.
      // The authoritative server check still runs, but in the background —
      // it only downgrades the UI if the entitlement was actually revoked.
      if (uid != null && uid.isNotEmpty && await PremiumGate.hasPremium()) {
        if (mounted) {
          setState(() {
            _premium = true;
            _uid = uid;
            _ready = true;
            _error = null;
          });
        }
        unawaited(_revalidateEntitlement());
        return;
      }

      // No local entitlement — confirm with the server (Firestore is the
      // authority; the client never grants premium) before deciding.
      final status = await PremiumActivationService.refreshPremiumStatus();
      final premium = status.ok || await PremiumGate.hasPremium();

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

  Future<void> _revalidateEntitlement() async {
    try {
      final status = await PremiumActivationService.refreshPremiumStatus();
      final premium = status.ok || await PremiumGate.hasPremium();
      if (mounted && !premium) {
        setState(() => _premium = false);
      }
    } catch (_) {
      // Network hiccup — keep trusting the locally cached entitlement.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 48,
          // The persona picker lives INSIDE the banner so the header reads as
          // one clean glass unit instead of a bar with a pill floating below.
          bottom: PreferredSize(
            // 52 pill (42 segment + 4×2 padding + 1×2 border) + 2/8 outer pad.
            preferredSize: const Size.fromHeight(62),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
              child: ValueListenableBuilder<LunePersonality>(
                valueListenable: LunePersonalityPrefs.notifier,
                builder: (context, current, _) => LunePersonalityPicker(
                  current: current,
                  onSelect: (p) {
                    if (p == current) return;
                    HapticFeedback.selectionClick();
                    LunePersonalityPrefs.set(p);
                  },
                ),
              ),
            ),
          ),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AuraColors.darkCard.withValues(alpha: 0.64),
                            AuraColors.darkCard.withValues(alpha: 0.38),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.58),
                            Colors.white.withValues(alpha: 0.28),
                          ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.12 : 0.54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AuraDecorations.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                l10n.homeAiCardTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
