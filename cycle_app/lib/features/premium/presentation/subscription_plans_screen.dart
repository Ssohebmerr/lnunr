import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/premium/play_billing_coordinator.dart';
import '../../../core/premium/premium_badge.dart';
import '../../../core/premium/premium_status_notifier.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../features/user/data/guest_user_service.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen upsell when Lune AI requires Premium.
class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({
    super.key,
    this.embedded = false,
    this.onSubscribed,
  });

  final bool embedded;
  final VoidCallback? onSubscribed;

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    PremiumStatusNotifier.instance.addListener(_onPremiumChanged);
  }

  @override
  void dispose() {
    PremiumStatusNotifier.instance.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    if (PremiumStatusNotifier.instance.isPremium) {
      widget.onSubscribed?.call();
    }
  }

  Future<void> _subscribe() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await GuestUserService().ensureSession();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!Platform.isAndroid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.premiumPlayOnly)),
        );
      }
      return;
    }

    setState(() => _busy = true);
    final billing = PlayBillingCoordinator.instance.billing;
    final product = await billing.loadProduct();
    if (product == null) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.premiumProductUnavailable)),
        );
      }
      return;
    }

    final started = await billing.subscribe(product);
    if (mounted) {
      setState(() => _busy = false);
      if (!started) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    await PlayBillingCoordinator.instance.billing.restorePurchases();
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.restorePurchasesDone)),
      );
      widget.onSubscribed?.call();
    }
  }

  Future<void> _activateTestPremium() async {
    if (!kDebugMode) return;
    await UserPrefs.setPremium(true);
    await PremiumStatusNotifier.instance.applyRemote(true);
    widget.onSubscribed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final body = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        widget.embedded ? 8 : 24,
        20,
        widget.embedded ? 24 : 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AuraDecorations.primaryGradient,
                boxShadow: AppShadows.softRose(opacity: 0.35),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PremiumBadge(size: 28),
              const SizedBox(width: 10),
              Text(
                l10n.subscriptionPlansTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.subscriptionPlansHeadline,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.subscriptionPlansSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          AppGlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.premiumTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.premiumSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _PlanFeature(
                  icon: Icons.chat_bubble_rounded,
                  text: l10n.premiumFeature1,
                ),
                _PlanFeature(
                  icon: Icons.insights_rounded,
                  text: l10n.premiumFeature2,
                ),
                _PlanFeature(
                  icon: Icons.cloud_done_rounded,
                  text: l10n.premiumFeature3,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.premiumPlayHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppGradientButton(
            label: l10n.subscriptionPlansCta,
            icon: Icons.diamond_rounded,
            loading: _busy,
            onPressed: _busy ? null : _subscribe,
          ),
          const SizedBox(height: 10),
          if (Platform.isAndroid)
            TextButton.icon(
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore_rounded, size: 20),
              label: Text(l10n.restorePurchases),
            ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _activateTestPremium,
              child: const Text('Debug: activate Premium'),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => HomeShellActions.switchTab?.call(3),
            child: Text(l10n.subscriptionPlansAccountHint),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: SafeArea(child: body),
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
