import 'package:cycle_aura/core/theme/app_theme.dart';
import 'package:cycle_aura/features/community/data/community_seed.dart';
import 'package:cycle_aura/features/community/presentation/widgets/community_recommended_row.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('recommended communities fit a narrow Arabic viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const locale = Locale('ar');
    final communities = CommunitySeed.defaults.take(2).toList();

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark(locale),
        home: Scaffold(
          body: SafeArea(
            child: CommunityRecommendedRow(
              communities: communities,
              languageCode: 'ar',
              joinedIds: const [],
              onOpen: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(communities.first.nameForLocale('ar')), findsOneWidget);
  });
}
