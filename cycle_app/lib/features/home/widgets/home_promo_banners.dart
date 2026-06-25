import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/cms/app_banners_repository.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';

class HomePromoBanners extends StatefulWidget {
  const HomePromoBanners({super.key});

  @override
  State<HomePromoBanners> createState() => _HomePromoBannersState();
}

class _HomePromoBannersState extends State<HomePromoBanners> {
  late Future<List<AppBanner>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppBannersRepository().fetchPublished();
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الرابط')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppBanner>>(
      future: _future,
      builder: (context, snapshot) {
        final banners = snapshot.data ?? [];
        if (banners.isEmpty) return const SizedBox.shrink();

        final lang = Localizations.localeOf(context).languageCode;
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final banner in banners) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppGlassCard(
                  blur: false,
                  padding: EdgeInsets.zero,
                  onTap: banner.actionUrl != null && banner.actionUrl!.isNotEmpty
                      ? () => _openUrl(context, banner.actionUrl!)
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      gradient: LinearGradient(
                        colors: [
                          banner.accent.withValues(alpha: 0.45),
                          banner.accent.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title(lang),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (banner.body(lang).trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            banner.body(lang),
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (banner.actionUrl != null &&
                            banner.actionUrl!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            lang == 'ar' ? 'اضغطي للمزيد ←' : 'Tap for more →',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
