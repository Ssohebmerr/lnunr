import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/education_articles_repository.dart';
import '../data/education_content.dart';
import 'widgets/magazine_article_card.dart';
import 'widgets/magazine_ui.dart';

/// Education hub — browse articles by category + AI Q&A.
class AiEducationScreen extends StatefulWidget {
  const AiEducationScreen({super.key});

  @override
  State<AiEducationScreen> createState() => _AiEducationScreenState();
}

class _AiEducationScreenState extends State<AiEducationScreen> {
  final _repo = EducationArticlesRepository();
  ArticleCategory? _selectedCategory;
  bool _showAiChat = false;
  final _questionController = TextEditingController();
  final _chatScroll = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Article? _featuredArticle(List<Article> articles) {
    if (_selectedCategory != null) return null;
    for (final a in articles) {
      if (a.featured) return a;
    }
    return null;
  }

  List<Article> _filteredList(List<Article> articles) {
    final hero = _featuredArticle(articles);
    var list = _selectedCategory == null
        ? articles
        : articles.where((a) => a.category == _selectedCategory).toList();
    if (hero != null) {
      list = list.where((a) => a.id != hero.id).toList();
    }
    return list;
  }

  Future<void> _askAi(String question) async {
    if (question.trim().isEmpty || _aiLoading) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final access = await PremiumGate.checkAiChat();
    if (!mounted) return;
    if (access == PremiumAiAccess.needsAdult) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.aiAdultsOnly)));
      return;
    }
    if (access == PremiumAiAccess.needsPremium ||
        access == PremiumAiAccess.limitReached) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.premiumRequiredAi)));
      return;
    }
    if (access == PremiumAiAccess.needsConsent) {
      final accepted = await showAiConsentDialog(context);
      if (!accepted || !mounted) return;
    }

    setState(() {
      _aiLoading = true;
      _messages.add(_ChatMessage(text: question, isUser: true));
      _questionController.clear();
    });
    _scrollChatToBottom();

    try {
      final engine = AiContextEngine();
      final ctx = await engine.buildAnonymizedContext();
      final gateway = AiGateway();
      final reply = await gateway.request(
        message: question,
        context: ctx,
        mode: 'chat',
      );

      if (mounted) {
        setState(() {
          _aiLoading = false;
          _messages.add(
            _ChatMessage(text: reply ?? l10n.errorGeneric, isUser: false),
          );
        });
        _scrollChatToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiLoading = false;
          _messages.add(_ChatMessage(text: l10n.errorGeneric, isUser: false));
        });
      }
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.44 : 0.48,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.11 : 0.50,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: MagazineBrandBadge(label: l10n.magazineTitle, compact: true),
        actions: [
          IconButton(
            tooltip: l10n.anonymousQaTooltip,
            onPressed: () => context.push('/ask'),
            icon: const Icon(Icons.question_answer_rounded),
          ),
          IconButton(
            tooltip: l10n.educationAskAi,
            onPressed: () => setState(() => _showAiChat = !_showAiChat),
            icon: Icon(
              _showAiChat ? Icons.article_outlined : Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      body: AppMeshBackground(
        child: _showAiChat
            ? _buildAiChat(l10n, theme, lang)
            : _buildArticleHub(l10n, theme, lang),
      ),
    );
  }

  /// Top inset so content clears the transparent, body-behind app bar.
  double get _topInset =>
      MediaQuery.of(context).padding.top + kToolbarHeight + 8;

  // ---------------------------------------------------------------------------
  // Article hub — browse by category
  // ---------------------------------------------------------------------------
  Widget _buildArticleHub(AppLocalizations l10n, ThemeData theme, String lang) {
    final categories = <_CategoryItem>[
      _CategoryItem(
        icon: Icons.all_inclusive_rounded,
        label: l10n.educationCatAll,
        color: theme.colorScheme.primary,
        category: null,
      ),
      _CategoryItem(
        icon: Icons.loop_outlined,
        label: l10n.educationCatBasics,
        color: const Color(0xFF6B7FE8),
        category: ArticleCategory.basics,
      ),
      _CategoryItem(
        icon: Icons.favorite_outline,
        label: l10n.educationCatHealth,
        color: const Color(0xFFE85D75),
        category: ArticleCategory.health,
      ),
      _CategoryItem(
        icon: Icons.restaurant_outlined,
        label: l10n.educationCatNutrition,
        color: const Color(0xFF3D9A78),
        category: ArticleCategory.nutrition,
      ),
      _CategoryItem(
        icon: Icons.psychology_outlined,
        label: l10n.educationCatMind,
        color: const Color(0xFF9B59B6),
        category: ArticleCategory.mind,
      ),
      _CategoryItem(
        icon: Icons.spa_outlined,
        label: l10n.educationCatFertility,
        color: const Color(0xFFD4849A),
        category: ArticleCategory.fertility,
      ),
      _CategoryItem(
        icon: Icons.directions_walk_outlined,
        label: l10n.educationCatFitness,
        color: const Color(0xFF4A90A4),
        category: ArticleCategory.fitness,
      ),
      _CategoryItem(
        icon: Icons.lock_outline,
        label: l10n.educationCatAdult,
        color: const Color(0xFFE85D75),
        category: ArticleCategory.adult,
      ),
    ];

    return Column(
      children: [
        SizedBox(height: _topInset),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: AppGlassCard(
            blur: false,
            radius: AppRadius.xl,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 4,
                      end: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MagazineBrandBadge(
                          label: l10n.magazineFromLune,
                          compact: true,
                        ),
                        const SizedBox(height: 9),
                        Text(
                          l10n.magazineTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.educationSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const _MagazineMastheadArt(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppFloatingGlassPanel(
            padding: const EdgeInsets.all(5),
            radius: AppRadius.pill,
            blurSigma: 18,
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  return _MagazineCategoryChip(
                    item: cat,
                    selected: _selectedCategory == cat.category,
                    onTap: () =>
                        setState(() => _selectedCategory = cat.category),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<List<Article>>(
            stream: _repo.watchPublished(includeAdult: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const _MagazineLoadingState();
              }
              final articles = snapshot.data ?? const <Article>[];
              final filtered = _filteredList(articles);
              final featured = _featuredArticle(articles);

              return RefreshIndicator(
                onRefresh: () => _repo
                    .watchPublished(includeAdult: false)
                    .first
                    .then((_) {}),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                '${filtered.length} ${l10n.educationArticles}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.educationSubtitle,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.7,
                                  ),
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (featured != null)
                      SliverToBoxAdapter(
                        child: MagazineArticleCard(
                          article: featured,
                          lang: lang,
                          hero: true,
                        ),
                      ),
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                          child: Center(
                            child: AppGlassCard(
                              blur: false,
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_stories_outlined,
                                    size: 38,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.educationNoArticles,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => MagazineArticleCard(
                            article: filtered[i],
                            lang: lang,
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // AI chat — ask health questions
  // ---------------------------------------------------------------------------
  Widget _buildAiChat(AppLocalizations l10n, ThemeData theme, String lang) {
    return Column(
      children: [
        SizedBox(height: _topInset),
        // Quick topics (only when empty)
        if (_messages.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickTopic(
                  icon: Icons.info_outline,
                  label: l10n.educationTopicPhase,
                  onTap: () => _askAi(l10n.educationTopicPhasePrompt),
                ),
                _QuickTopic(
                  icon: Icons.restaurant_outlined,
                  label: l10n.educationTopicNutrition,
                  onTap: () => _askAi(l10n.educationTopicNutritionPrompt),
                ),
                _QuickTopic(
                  icon: Icons.fitness_center_outlined,
                  label: l10n.educationTopicExercise,
                  onTap: () => _askAi(l10n.educationTopicExercisePrompt),
                ),
                _QuickTopic(
                  icon: Icons.healing_outlined,
                  label: l10n.educationTopicPain,
                  onTap: () => _askAi(l10n.educationTopicPainPrompt),
                ),
                _QuickTopic(
                  icon: Icons.bedtime_outlined,
                  label: l10n.educationTopicSleep,
                  onTap: () => _askAi(l10n.educationTopicSleepPrompt),
                ),
                _QuickTopic(
                  icon: Icons.psychology_outlined,
                  label: l10n.educationTopicMood,
                  onTap: () => _askAi(l10n.educationTopicMoodPrompt),
                ),
              ],
            ),
          ),

        // Messages
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 56,
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.educationAskAnything,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _chatScroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_aiLoading ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _messages.length) {
                      return _AiTypingBubble(theme: theme);
                    }
                    return _ChatBubble(message: _messages[i], theme: theme);
                  },
                ),
        ),

        // Input
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: l10n.educationAskHint,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.78),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.1,
                                ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.4,
                          ),
                          width: 1.5,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _askAi,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: AuraDecorations.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => _askAi(_questionController.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Magazine loading state
// ---------------------------------------------------------------------------
class _MagazineMastheadArt extends StatelessWidget {
  const _MagazineMastheadArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 108,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AuraColors.rose, AuraColors.lavenderSoft],
        ),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -20,
            end: -18,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          const Center(
            child: Icon(
              Icons.auto_stories_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
          const PositionedDirectional(
            end: 10,
            bottom: 9,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MagazineLoadingState extends StatelessWidget {
  const _MagazineLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = theme.colorScheme.onSurface.withValues(alpha: 0.07);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => AppGlassCard(
        blur: false,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 106,
              height: 128,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LoadingLine(widthFactor: 0.35, color: fill),
                  const SizedBox(height: 12),
                  _LoadingLine(widthFactor: 0.92, color: fill, height: 14),
                  const SizedBox(height: 8),
                  _LoadingLine(widthFactor: 0.70, color: fill, height: 14),
                  const SizedBox(height: 14),
                  _LoadingLine(widthFactor: 0.82, color: fill),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({
    required this.widthFactor,
    required this.color,
    this.height = 10,
  });

  final double widthFactor;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category item model
// ---------------------------------------------------------------------------
class _CategoryItem {
  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.category,
  });

  final IconData icon;
  final String label;
  final Color color;
  final ArticleCategory? category;
}

// ---------------------------------------------------------------------------
// Category chip — segmented pill inside the glass filter panel. Matches the
// app's chip language (transparent when idle, filled in its category colour
// when selected) instead of a raw Material FilterChip.
// ---------------------------------------------------------------------------
class _MagazineCategoryChip extends StatelessWidget {
  const _MagazineCategoryChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _CategoryItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? item.color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.26),
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 16,
                color: selected ? Colors.white : item.color,
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick topic chip for AI chat
// ---------------------------------------------------------------------------
class _QuickTopic extends StatelessWidget {
  const _QuickTopic({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : theme.colorScheme.surface)
                .withValues(alpha: isDark ? 0.06 : 0.7),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: (isDark ? Colors.white : theme.colorScheme.outline)
                  .withValues(alpha: isDark ? 0.08 : 0.1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 7),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat message model
// ---------------------------------------------------------------------------
class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

// ---------------------------------------------------------------------------
// Chat bubble
// ---------------------------------------------------------------------------
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.theme});

  final _ChatMessage message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = theme.brightness == Brightness.dark;
    final maxW = MediaQuery.of(context).size.width * 0.8;

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: maxW),
        decoration: BoxDecoration(
          gradient: isUser ? AuraDecorations.primaryGradient : null,
          color: isUser
              ? null
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.78)),
          border: isUser
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.65),
                ),
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(16),
            topEnd: const Radius.circular(16),
            bottomStart: Radius.circular(isUser ? 16 : 4),
            bottomEnd: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: SelectableText(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : theme.colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI typing indicator
// ---------------------------------------------------------------------------
class _AiTypingBubble extends StatelessWidget {
  const _AiTypingBubble({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.78),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.65),
          ),
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(16),
            topEnd: Radius.circular(16),
            bottomEnd: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.educationThinking,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
