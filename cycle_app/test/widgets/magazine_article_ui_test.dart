import 'package:cycle_aura/core/theme/app_design_tokens.dart';
import 'package:cycle_aura/features/education/data/education_content.dart';
import 'package:cycle_aura/features/education/presentation/article_screen.dart';
import 'package:cycle_aura/features/education/presentation/widgets/magazine_article_card.dart';
import 'package:cycle_aura/features/education/presentation/widgets/magazine_ui.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _article = Article(
  id: 'magazine_ui_test',
  category: ArticleCategory.basics,
  icon: Icons.loop_rounded,
  titleEn: 'A gentle guide to your cycle',
  titleAr: 'دليل لطيف لفهم دورتك',
  excerptEn: 'Clear, calm information for understanding your own rhythm.',
  excerptAr: 'معلومات واضحة وهادئة تساعدك على فهم إيقاع جسمك.',
  bodyEn:
      'Your cycle has its own rhythm. Tracking it helps you understand it.\n\n'
      '1. Notice your usual pattern.\n\n'
      '2. Be gentle with yourself.',
  bodyAr:
      'لدورتك إيقاعها الخاص، ومتابعتها تساعدك على فهم جسمك بهدوء.\n\n'
      '1. لاحظي نمطك المعتاد.\n\n'
      '2. كوني لطيفة مع نفسك.',
  minutes: 3,
  featured: true,
);

void main() {
  void configurePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app(Widget home) {
    return MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AuraColors.roseDeep,
        fontFamily: 'Cairo',
      ),
      home: home,
    );
  }

  testWidgets('featured magazine card uses branded cover without overflow', (
    tester,
  ) async {
    configurePhone(tester);

    await tester.pumpWidget(
      app(
        const Scaffold(
          body: SingleChildScrollView(
            child: MagazineArticleCard(
              article: _article,
              lang: 'ar',
              hero: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MagazineArticleCover), findsOneWidget);
    expect(find.text('دليل لطيف لفهم دورتك'), findsOneWidget);
    expect(find.byType(MagazineBrandBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact magazine card stays readable on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        const Scaffold(
          body: SingleChildScrollView(
            child: MagazineArticleCard(article: _article, lang: 'ar'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('دليل لطيف لفهم دورتك'), findsOneWidget);
    expect(find.byType(MagazineReadingTime), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('article reader separates Arabic numbered paragraphs', (
    tester,
  ) async {
    configurePhone(tester);

    await tester.pumpWidget(app(const ArticleScreen(article: _article)));
    await tester.pumpAndSettle();

    expect(find.text('دليل لطيف لفهم دورتك'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('لاحظي نمطك المعتاد.'), findsOneWidget);
    expect(find.byType(MagazineArticleCover), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
