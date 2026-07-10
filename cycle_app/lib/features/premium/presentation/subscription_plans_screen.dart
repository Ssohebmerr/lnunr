import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/premium/play_billing_coordinator.dart';
import '../../../core/premium/premium_activation_service.dart';
import '../../../core/premium/premium_badge.dart';
import '../../../core/premium/premium_status_notifier.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../features/premium/data/play_billing_service.dart';
import '../../../features/user/data/guest_user_service.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen upsell when Lune AI requires Premium.
///
/// Shows the monthly + yearly plans (prices pulled live from Play), a savings
/// badge on the annual plan, and a single CTA that subscribes to the selected
/// plan. Premium is applied by the app-wide Firestore listener once the server
/// verifies the purchase — this screen never writes entitlement itself.
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
  bool _loadingPlans = true;

  Map<String, ProductDetails> _products = const {};
  String _selectedSku = PlayBillingService.yearlyProductId;

  @override
  void initState() {
    super.initState();
    PremiumStatusNotifier.instance.addListener(_onPremiumChanged);
    _loadPlans();
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

  Future<void> _loadPlans() async {
    if (!Platform.isAndroid) {
      if (mounted) setState(() => _loadingPlans = false);
      return;
    }
    final products =
        await PlayBillingCoordinator.instance.billing.loadProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      // Prefer the annual plan (best value) when available.
      if (!products.containsKey(_selectedSku) && products.isNotEmpty) {
        _selectedSku = products.containsKey(PlayBillingService.monthlyProductId)
            ? PlayBillingService.monthlyProductId
            : products.keys.first;
      }
      _loadingPlans = false;
    });
  }

  /// Percentage saved by the yearly plan vs. 12× the monthly price.
  /// Returns null when either price is missing.
  int? _yearlySavingsPercent() {
    final monthly = _products[PlayBillingService.monthlyProductId];
    final yearly = _products[PlayBillingService.yearlyProductId];
    if (monthly == null || yearly == null) return null;
    final yearlyIfMonthly = monthly.rawPrice * 12;
    if (yearlyIfMonthly <= 0) return null;
    final saved = (yearlyIfMonthly - yearly.rawPrice) / yearlyIfMonthly;
    final pct = (saved * 100).round();
    return pct > 0 ? pct : null;
  }

  Future<void> _subscribe() async {
    final l10n = AppLocalizations.of(context)!;

    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.premiumPlayOnly)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await GuestUserService().ensureSession();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
      return;
    }

    final billing = PlayBillingCoordinator.instance.billing;
    final product = _products[_selectedSku] ?? await billing.loadProduct();
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
      // On success the Play sheet takes over; the app-wide purchase listener
      // verifies + flips premium, which fires [_onPremiumChanged].
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    await PlayBillingCoordinator.instance.billing.restorePurchases();
    if (!mounted) return;
    setState(() => _busy = false);
    // Do NOT claim success — restore results arrive asynchronously through the
    // purchase stream, which flips premium via the app-wide listener. We only
    // acknowledge the request; if a subscription is found, the paywall closes
    // automatically via [_onPremiumChanged].
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.restorePurchasesChecking)),
    );
  }

  /// DEBUG builds only — grants premium via the QA-gated server endpoint so
  /// the developer can exercise the premium experience without Play Console.
  Future<void> _activateTestPremium() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final result = await PremiumActivationService.activateTesterPremium();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.ok ? l10n.premiumActivated : l10n.errorGeneric,
        ),
      ),
    );
    if (result.ok) widget.onSubscribed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final savings = _yearlySavingsPercent();

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

          // ── Benefits ────────────────────────────────────────────────────
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Plan selector ───────────────────────────────────────────────
          if (Platform.isAndroid) ...[
            if (_loadingPlans)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.premiumProductUnavailable,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              if (_products.containsKey(PlayBillingService.yearlyProductId))
                _PlanCard(
                  title: l10n.planYearlyTitle,
                  price: _products[PlayBillingService.yearlyProductId]!.price,
                  period: l10n.planPerYear,
                  badge: savings != null ? l10n.planSaveBadge(savings) : null,
                  selected: _selectedSku == PlayBillingService.yearlyProductId,
                  onTap: () => setState(
                    () => _selectedSku = PlayBillingService.yearlyProductId,
                  ),
                ),
              if (_products.containsKey(PlayBillingService.monthlyProductId))
                _PlanCard(
                  title: l10n.planMonthlyTitle,
                  price: _products[PlayBillingService.monthlyProductId]!.price,
                  period: l10n.planPerMonth,
                  selected: _selectedSku == PlayBillingService.monthlyProductId,
                  onTap: () => setState(
                    () => _selectedSku = PlayBillingService.monthlyProductId,
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.premiumPlayHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                TextButton(
                  onPressed: openPrivacyPolicy,
                  child: Text(l10n.privacyPolicyLink),
                ),
                Text(
                  '·',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: openTermsOfService,
                  child: Text(l10n.termsOfServiceLink),
                ),
              ],
            ),
          ] else
            Text(
              l10n.premiumPlayOnly,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

          const SizedBox(height: 20),
          AppGradientButton(
            label: l10n.subscriptionPlansCta,
            icon: Icons.diamond_rounded,
            loading: _busy,
            onPressed:
                (_busy || (Platform.isAndroid && _products.isEmpty))
                    ? null
                    : _subscribe,
          ),
          const SizedBox(height: 10),
          if (Platform.isAndroid)
            TextButton.icon(
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore_rounded, size: 20),
              label: Text(l10n.restorePurchases),
            ),

          // Debug-only tester activation (never present in release builds).
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _activateTestPremium,
              icon: const Icon(Icons.bug_report_outlined, size: 20),
              label: Text(l10n.activatePremiumTest),
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String period;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : theme.colorScheme.surface.withValues(alpha: 0.5),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: AuraDecorations.primaryGradient,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                badge!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        period,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
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
