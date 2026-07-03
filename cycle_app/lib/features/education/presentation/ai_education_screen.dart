import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/education_articles_repository.dart';
import '../data/education_content.dart';
import 'article_screen.dart';

/// Education hub — browse articles by category + AI Q&A.
class AiEducationScreen extends StatefulWidget {
  const AiEducationScreen({super.key});

  @override
  State<AiEducationScreen> createState() => _AiEducationScreenState();
}

class _AiEducationScreenState extends State<AiEducationScreen> {
  List<Article> _articles = [];
  ArticleCategory? _selectedCategory;
  bool _loading = true;
  bool _showAiChat = false;
  final _questionController = TextEditingController();
  final _chatScroll = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    try {
      final repo = EducationArticlesRepository();
      final articles = await repo.fetchPublished(includeAdult: false);
      if (mounted) {
        setState(() {
          _articles = articles;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _articles = EducationContent.visible(includeAdult: false);
          _loading = false;
        });
      }
    }
  }

  List<Article> get _filtered {
    if (_selectedCategory == null) return _articles;
    return _articles.where((a) => a.category == _selectedCategory).toList();
  }

  Future<void> _askAi(String question) async {
    if (question.trim().isEmpty || _aiLoading) return;

    setState(() {
      _aiLoading = true;
      _messages.add(_ChatMessage(text: question, isUser: true));
      _questionController.clear();
    });
    _scrollChatToBottom();

    try {
      final engine = AiContextEngine();
      final context = await engine.buildAnonymizedContext();
      final gateway = AiGateway();
      final reply = await gateway.request(
        message: question,
        context: context,
        mode: 'chat',
      );

      if (mounted) {
        setState(() {
          _aiLoading = false;
          _messages.add(_ChatMessage(
            text: reply ?? 'عذراً، لم أتمكن من الإجابة حالياً.',
            isUser: false,
          ));
        });
        _scrollChatToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiLoading = false;
          _messages.add(const _ChatMessage(
            text: 'حدث خطأ. حاول مرة أخرى.',
            isUser: false,
          ));
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
        title: Text(l10n.educationTitle),
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
  Widget _buildArticleHub(
      AppLocalizations l10n, ThemeData theme, String lang) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.only(top: _topInset),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

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
    ];

    return Column(
      children: [
        SizedBox(height: _topInset),
        // Category chips
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = categories[i];
              final selected = _selectedCategory == cat.category;
              return FilterChip(
                avatar: Icon(cat.icon,
                    size: 16,
                    color: selected ? Colors.white : cat.color),
                label: Text(cat.label),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _selectedCategory = cat.category),
                selectedColor: cat.color,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
                backgroundColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                side: BorderSide.none,
                showCheckmark: false,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Article count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_filtered.length} ${l10n.educationArticles}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const Spacer(),
              Text(
                l10n.educationPoweredByAi,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Article list
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    l10n.educationNoArticles,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) =>
                      _ArticleCard(article: _filtered[i], lang: lang),
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // AI chat — ask health questions
  // ---------------------------------------------------------------------------
  Widget _buildAiChat(
      AppLocalizations l10n, ThemeData theme, String lang) {
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
                      Icon(Icons.school_outlined,
                          size: 56,
                          color: theme.colorScheme.primary.withValues(alpha: 0.4)),
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
                    decoration: InputDecoration(
                      hintText: l10n.educationAskHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.78),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
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
// Article card
// ---------------------------------------------------------------------------
class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.lang});

  final Article article;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final categoryColor = switch (article.category) {
      ArticleCategory.basics => const Color(0xFF6B7FE8),
      ArticleCategory.health => const Color(0xFFE85D75),
      ArticleCategory.nutrition => const Color(0xFF3D9A78),
      ArticleCategory.mind => const Color(0xFF9B59B6),
      ArticleCategory.adult => const Color(0xFFE85D75),
    };

    final categoryLabel = switch (article.category) {
      ArticleCategory.basics => l10n.educationCatBasics,
      ArticleCategory.health => l10n.educationCatHealth,
      ArticleCategory.nutrition => l10n.educationCatNutrition,
      ArticleCategory.mind => l10n.educationCatMind,
      ArticleCategory.adult => l10n.educationCatAdult,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppGlassCard(
        blur: false,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArticleScreen(article: article),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(article.icon, color: categoryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title(lang),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                categoryLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: categoryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.schedule_rounded,
                                size: 12,
                                color: theme.colorScheme.outline),
                            const SizedBox(width: 3),
                            Text(
                              l10n.educationMinutes(article.minutes),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: theme.colorScheme.outline),
                ],
              ),
            ),
          ),
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
    return ActionChip(
      avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.5),
      side: BorderSide.none,
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
      alignment:
          isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
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
