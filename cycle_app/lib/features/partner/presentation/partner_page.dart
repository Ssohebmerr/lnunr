import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../auth/presentation/auth_navigation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../data/partner_service.dart';

/// Partner mode: owner side (invite code + privacy toggles) and partner
/// side (the limited shared card + supportive tips).
class PartnerPage extends StatefulWidget {
  const PartnerPage({super.key});

  @override
  State<PartnerPage> createState() => _PartnerPageState();
}

class _PartnerPageState extends State<PartnerPage> {
  final _service = PartnerService();
  final _codeController = TextEditingController();
  String? _linkedOwnerUid;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final engine = context.read<AiContextEngine>();
    final ownerUid = await _service.linkedOwnerUid();
    if (mounted) setState(() => _linkedOwnerUid = ownerUid);

    try {
      await _service.ensureLink();
      // Keep the partner's card fresh whenever the owner opens this page.
      await _service.publishStatus(engine);
    } catch (_) {}
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _joining = true);
    try {
      final ownerUid = await _service.joinWithCode(code);
      if (mounted) {
        setState(() => _linkedOwnerUid = ownerUid);
        _codeController.clear();
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.partnerJoinedOk)));
    } on PartnerCodeInvalidException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.partnerInvalidCode)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.partnerInvalidCode)));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _leave() async {
    await _service.leave();
    if (mounted) setState(() => _linkedOwnerUid = null);
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _service.publishStatus(context.read<AiContextEngine>());
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.partnerPublished : l10n.partnerNothingToPublish),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final signedIn = FirebaseAuth.instance.currentUser != null;

    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 8;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.partnerTitle),
      ),
      body: AppMeshBackground(
        child: !signedIn
            ? _SignInPrompt(l10n: l10n, theme: theme)
            : ListView(
                padding: EdgeInsets.fromLTRB(16, topInset, 16, 32),
                children: [
                  _IntroBanner(l10n: l10n, theme: theme),
                  const SizedBox(height: 16),
                  AppSectionHeader(title: l10n.partnerOwnerSection),
                  _OwnerCard(
                    service: _service,
                    l10n: l10n,
                    theme: theme,
                    onPublish: _publish,
                  ),
                  const SizedBox(height: 24),
                  AppSectionHeader(title: l10n.partnerPartnerSection),
                  if (_linkedOwnerUid != null)
                    _PartnerStatusCard(
                      service: _service,
                      ownerUid: _linkedOwnerUid!,
                      l10n: l10n,
                      theme: theme,
                      onLeave: _leave,
                    )
                  else
                    _JoinCard(
                      l10n: l10n,
                      controller: _codeController,
                      joining: _joining,
                      onJoin: _join,
                    ),
                ],
              ),
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.l10n, required this.theme});
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(l10n.partnerTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.partnerSignInPrompt, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => openLoginScreen(context),
              child: Text(l10n.signInOptionalTitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner({required this.l10n, required this.theme});
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AuraDecorations.heroSurface(isDark),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AuraColors.rose, AuraColors.lavenderSoft],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AuraColors.rose.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.partnerTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.partnerIntro,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({
    required this.service,
    required this.l10n,
    required this.theme,
    required this.onPublish,
  });

  final PartnerService service;
  final AppLocalizations l10n;
  final ThemeData theme;
  final Future<void> Function() onPublish;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PartnerLink?>(
      stream: service.watchLink(),
      builder: (context, snap) {
        final link = snap.data;
        if (link == null) {
          return const AppGlassCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return AppGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.partnerYourCode, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(
                          ClipboardData(text: link.inviteCode),
                        );
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.partnerCodeCopied)),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              link.inviteCode,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                letterSpacing: 4,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.copy,
                                size: 18, color: theme.colorScheme.outline),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.partnerRegenerate,
                    icon: const Icon(Icons.refresh),
                    onPressed: () => service.regenerateCode(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    link.isLinked ? Icons.favorite : Icons.favorite_outline,
                    size: 18,
                    color: link.isLinked
                        ? AuraColors.rose
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link.isLinked ? l10n.partnerLinked : l10n.partnerNotLinked,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(l10n.partnerShareWhat, style: theme.textTheme.labelLarge),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.partnerSharePhase),
                value: link.share.phase,
                onChanged: (v) =>
                    service.setShareFlags(link.share.copyWith(phase: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.partnerShareNextPeriod),
                value: link.share.nextPeriod,
                onChanged: (v) =>
                    service.setShareFlags(link.share.copyWith(nextPeriod: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.partnerSharePain),
                value: link.share.pain,
                onChanged: (v) =>
                    service.setShareFlags(link.share.copyWith(pain: v)),
              ),
              const SizedBox(height: 8),
              AppGradientButton(
                label: l10n.partnerPublishNow,
                onPressed: onPublish,
              ),
              if (link.isLinked)
                TextButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await service.unlinkPartner();
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.partnerUnlinked)),
                    );
                  },
                  icon: const Icon(Icons.link_off, size: 18),
                  label: Text(l10n.partnerUnlink),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    required this.l10n,
    required this.controller,
    required this.joining,
    required this.onJoin,
  });

  final AppLocalizations l10n;
  final TextEditingController controller;
  final bool joining;
  final Future<void> Function() onJoin;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.partnerEnterCode),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: l10n.partnerCodeHint,
              prefixIcon: const Icon(Icons.key_outlined),
            ),
          ),
          const SizedBox(height: 12),
          AppGradientButton(
            label: l10n.partnerJoin,
            loading: joining,
            onPressed: joining ? null : onJoin,
          ),
        ],
      ),
    );
  }
}

class _PartnerStatusCard extends StatelessWidget {
  const _PartnerStatusCard({
    required this.service,
    required this.ownerUid,
    required this.l10n,
    required this.theme,
    required this.onLeave,
  });

  final PartnerService service;
  final String ownerUid;
  final AppLocalizations l10n;
  final ThemeData theme;
  final Future<void> Function() onLeave;

  String _tipForPhase(String? phase) {
    final p = (phase ?? '').toLowerCase();
    final isAr = l10n.localeName.startsWith('ar');

    if (p.contains('menopause') || p.contains('انقطاع') || p.contains('أمل')) {
      return isAr
          ? 'قد تشعر بهبات ساخنة أو تقلبات مزاجية سريعة. يرجى توفير جو مريح وهادئ ودعم تفهمك الكامل لها.'
          : 'She might experience hot flashes or sudden mood shifts. Provide a cool, comfortable environment and be understanding.';
    }
    if (p.contains('pcos') || p.contains('تكيس') || p.contains('مبايض')) {
      return isAr
          ? 'إدارة متلازمة تكيس المبايض تتطلب تشجيعاً على نمط حياة صحي. شاركها وجباتها الصحية وشجعها على الاسترخاء.'
          : 'Managing PCOS symptoms benefits from lifestyle support. Share healthy meals and encourage stress reduction.';
    }
    if (p.contains('postpartum') || p.contains('ولادة') || p.contains('نفاس')) {
      return isAr
          ? 'مرحلة ما بعد الولادة تتطلب رعاية فائقة للأم والطفل. ساعدها في الواجبات المنزلية والاعتناء بالرضيع.'
          : 'Postpartum recovery needs extra care. Help with chores and baby care to let her rest.';
    }

    if (p.contains('menstr') || p.contains('حيض') || p.contains('دورة')) {
      return l10n.partnerTipMenstruation;
    }
    if (p.contains('follic') || p.contains('جريبية') || p.contains('جُريبية')) {
      return l10n.partnerTipFollicular;
    }
    if (p.contains('ovul') || p.contains('إباضة') || p.contains('اباضة')) {
      return l10n.partnerTipOvulation;
    }
    if (p.contains('luteal') || p.contains('أصفرية') || p.contains('اصفرية')) {
      return l10n.partnerTipLuteal;
    }
    return l10n.partnerTipDefault;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PartnerStatus?>(
      stream: service.watchPartnerStatus(ownerUid),
      builder: (context, snap) {
        final status = snap.data;

        return AppGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: AuraColors.rose, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.partnerStatusTitle,
                      style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              if (status == null)
                Text(l10n.partnerStatusEmpty, style: theme.textTheme.bodySmall)
              else ...[
                if (status.isPeriodActive == true)
                  _StatusRow(
                    icon: Icons.water_drop,
                    text: l10n.partnerStatusPeriodActive,
                    theme: theme,
                  ),
                if (status.phase != null)
                  _StatusRow(
                    icon: Icons.donut_large_outlined,
                    text: '${l10n.partnerStatusPhase}: ${status.phase}',
                    theme: theme,
                  ),
                if (status.cycleDay != null)
                  _StatusRow(
                    icon: Icons.today_outlined,
                    text: '${l10n.partnerStatusCycleDay}: ${status.cycleDay}',
                    theme: theme,
                  ),
                if (status.daysUntilNextPeriod != null)
                  _StatusRow(
                    icon: Icons.event_outlined,
                    text: l10n
                        .partnerStatusNextPeriod(status.daysUntilNextPeriod!),
                    theme: theme,
                  ),
                if (status.averagePainLevel != null)
                  _StatusRow(
                    icon: Icons.healing_outlined,
                    text:
                        '${l10n.partnerStatusPain}: ${status.averagePainLevel!.toStringAsFixed(1)}/10',
                    theme: theme,
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.partnerTipTitle,
                          style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(_tipForPhase(status.phase),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (status.updatedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.partnerStatusUpdated(
                      DateFormat.MMMd().add_Hm().format(status.updatedAt!),
                    ),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ],
              TextButton.icon(
                onPressed: onLeave,
                icon: const Icon(Icons.link_off, size: 18),
                label: Text(l10n.partnerLeave),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.text,
    required this.theme,
  });

  final IconData icon;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
