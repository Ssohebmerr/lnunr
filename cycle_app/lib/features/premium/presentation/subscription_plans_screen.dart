import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/premium/play_billing_coordinator.dart';
import '../../../core/premium/premium_activation_service.dart';
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
    final products = await PlayBillingCoordinator.instance.billing
        .loadProducts();
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

  String? _yearlyMonthlyEquivalent(BuildContext context) {
    final yearly = _products[PlayBillingService.yearlyProductId];
    if (yearly == null || yearly.rawPrice <= 0) return null;
    try {
      return NumberFormat.simpleCurrency(
        locale: Localizations.localeOf(context).toLanguageTag(),
        name: yearly.currencyCode,
      ).format(yearly.rawPrice / 12);
    } catch (_) {
      return null;
    }
  }

  Future<void> _retryPlans() async {
    setState(() => _loadingPlans = true);
    await _loadPlans();
  }

  Future<void> _subscribe() async {
    final l10n = AppLocalizations.of(context)!;

    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.premiumPlayOnly)));
      return;
    }

    setState(() => _busy = true);
    try {
      await GuestUserService().ensureSession();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
      return;
    }

    final billing = PlayBillingCoordinator.instance.billing;
    final product = _products[_selectedSku] ?? await billing.loadProduct();
    if (product == null) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.premiumProductUnavailable)));
      }
      return;
    }

    final started = await billing.subscribe(product);
    if (mounted) {
      setState(() => _busy = false);
      if (!started) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.restorePurchasesChecking)));
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
        content: Text(result.ok ? l10n.premiumActivated : l10n.errorGeneric),
      ),
    );
    if (result.ok) widget.onSubscribed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final savings = _yearlySavingsPercent();
    final yearly = _products[PlayBillingService.yearlyProductId];
    final monthly = _products[PlayBillingService.monthlyProductId];
    final yearlyEquivalent = _yearlyMonthlyEquivalent(context);
    final selectedPlanName = _selectedSku == PlayBillingService.yearlyProductId
        ? l10n.planYearlyTitle
        : l10n.planMonthlyTitle;
    final selectedPlanAvailable = _products.containsKey(_selectedSku);

    final body = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        widget.embedded ? 8 : 12,
        16,
        widget.embedded ? 24 : 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded)
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    l10n.subscriptionPlansTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          const SizedBox(height: 12),

          // Premium hero: value first, then the plan choice. This keeps the
          // paywall understandable even before Play returns localized prices.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              gradient: const LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  Color(0xFF8F2F62),
                  AuraColors.accentDeep,
                  Color(0xFF7652A8),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: AuraColors.accent.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 31,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        l10n.subscriptionPlansTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.subscriptionPlansHeadline,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  l10n.subscriptionPlansSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                _PlanFeature(
                  icon: Icons.chat_bubble_rounded,
                  text: l10n.premiumFeature1,
                  onDark: true,
                ),
                _PlanFeature(
                  icon: Icons.cloud_done_rounded,
                  text: l10n.premiumFeature2,
                  onDark: true,
                ),
                _PlanFeature(
                  icon: Icons.support_agent_rounded,
                  text: l10n.premiumFeature3,
                  onDark: true,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            l10n.subscriptionChoosePlanTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.subscriptionChoosePlanSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // Both choices remain visible while loading or temporarily
          // unavailable. Prices are never hard-coded: Google Play supplies the
          // localized amount/currency configured for the user's country.
          if (Platform.isAndroid) ...[
            _PlanCard(
              title: l10n.planYearlyTitle,
              price:
                  yearly?.price ??
                  (_loadingPlans
                      ? l10n.subscriptionLoadingPrice
                      : l10n.planUnavailable),
              period: l10n.planPerYear,
              supportingText: yearlyEquivalent == null
                  ? null
                  : l10n.planMonthlyEquivalent(yearlyEquivalent),
              badge: savings != null
                  ? '${l10n.planBestValue} · ${l10n.planSaveBadge(savings)}'
                  : l10n.planBestValue,
              selected:
                  yearly != null &&
                  _selectedSku == PlayBillingService.yearlyProductId,
              enabled: yearly != null && !_busy,
              onTap: () => setState(
                () => _selectedSku = PlayBillingService.yearlyProductId,
              ),
            ),
            _PlanCard(
              title: l10n.planMonthlyTitle,
              price:
                  monthly?.price ??
                  (_loadingPlans
                      ? l10n.subscriptionLoadingPrice
                      : l10n.planUnavailable),
              period: l10n.planPerMonth,
              selected:
                  monthly != null &&
                  _selectedSku == PlayBillingService.monthlyProductId,
              enabled: monthly != null && !_busy,
              onTap: () => setState(
                () => _selectedSku = PlayBillingService.monthlyProductId,
              ),
            ),
            if (!_loadingPlans && _products.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 2, bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.42,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.premiumProductUnavailable,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onErrorContainer,
                      ),
                      onPressed: _retryPlans,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: selectedPlanAvailable ? 1 : 0.45,
              child: AppGradientButton(
                label: selectedPlanAvailable
                    ? l10n.subscriptionSelectedCta(selectedPlanName)
                    : l10n.subscriptionPlansCta,
                icon: Icons.lock_rounded,
                loading: _busy,
                onPressed: (_busy || !selectedPlanAvailable)
                    ? null
                    : _subscribe,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.subscriptionSecurePayment,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore_rounded, size: 20),
              label: Text(l10n.restorePurchases),
            ),
            Text(
              l10n.premiumPlayHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                l10n.premiumPlayOnly,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
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
              Color.alphaBlend(
                theme.colorScheme.primary.withValues(alpha: 0.06),
                theme.colorScheme.surface,
              ),
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
    required this.enabled,
    required this.onTap,
    this.badge,
    this.supportingText,
  });

  final String title;
  final String price;
  final String period;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final String? badge;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '$title, $price, $period',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: enabled ? 1 : 0.62,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.09)
                      : theme.colorScheme.surface.withValues(alpha: 0.82),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? AppShadows.softRose(opacity: 0.09)
                      : AppShadows.softPlum(opacity: 0.035),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          size: 23,
                        ),
                      ],
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 9),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: AuraDecorations.ctaGradient,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            badge!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            price,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: enabled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            period,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (supportingText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        supportingText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({
    required this.icon,
    required this.text,
    this.onDark = false,
    this.isLast = false,
  });

  final IconData icon;
  final String text;
  final bool onDark;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: onDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 17,
              color: onDark ? Colors.white : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onDark ? Colors.white : null,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
