import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// Screen for users to anonymously submit health questions to experts.
class AnonymousQAScreen extends StatefulWidget {
  const AnonymousQAScreen({super.key});

  @override
  State<AnonymousQAScreen> createState() => _AnonymousQAScreenState();
}

class _AnonymousQAScreenState extends State<AnonymousQAScreen> {
  final _controller = TextEditingController();
  final _categoryItems = [
    'general',
    'cycle',
    'pregnancy',
    'pcos',
    'contraception',
    'mental',
    'nutrition',
  ];
  String _selectedCategory = 'general';
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final text = _controller.text.trim();
    if (text.length < 10) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.anonymousQaTooShort)),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await FirebaseFirestore.instance.collection('anonymousQuestions').add({
        'question': text,
        'category': _selectedCategory,
        'status': 'pending', // pending | answered | rejected
        'answer': null,
        'answeredBy': null,
        'answeredAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        // No userId stored — fully anonymous
      });

      _controller.clear();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.anonymousQaSubmitted),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.anonymousQaError)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: AppGlassCard(
            radius: AppRadius.pill,
            padding: const EdgeInsets.all(8),
            onTap: () => context.pop(),
            child: Icon(
              Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        title: Text(
          l10n.anonymousQa,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                AppGlassCard(
                  radius: AppRadius.lg,
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AuraDecorations.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.softRose(opacity: 0.3),
                        ),
                        child: const Icon(
                          Icons.question_answer_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.anonymousQaTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.anonymousQaIntro,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Simple purpose explanation (user clarity + Play Store)
                AppGlassCard(
                  radius: AppRadius.lg,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.anonymousQaPurposeTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _QaStepRow(
                        number: '1',
                        text: l10n.anonymousQaStep1,
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _QaStepRow(
                        number: '2',
                        text: l10n.anonymousQaStep2,
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _QaStepRow(
                        number: '3',
                        text: l10n.anonymousQaStep3,
                        theme: theme,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.medical_information_outlined,
                              size: 18,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.anonymousQaDisclaimer,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category selector
                Text(
                  l10n.anonymousQaCategoryLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoryItems.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return ChoiceChip(
                      label: Text(_categoryLabel(l10n, cat)),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Question input
                Text(
                  l10n.anonymousQaQuestionLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                AppGlassCard(
                  radius: AppRadius.lg,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _controller,
                    maxLines: 6,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: l10n.healthQuestionHint,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      counterStyle: theme.textTheme.labelSmall,
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 8),

                // Privacy notice
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.anonymousQaPrivacyNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Submit button
                AppGradientButton(
                  label: _submitting
                      ? l10n.anonymousQaSubmitting
                      : l10n.anonymousQaSubmit,
                  icon: Icons.send_rounded,
                  loading: _submitting,
                  onPressed: _submitting ? null : _submitQuestion,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _categoryLabel(AppLocalizations l10n, String cat) {
    return switch (cat) {
      'general' => l10n.qaCatGeneral,
      'cycle' => l10n.qaCatCycle,
      'pregnancy' => l10n.qaCatPregnancy,
      'pcos' => l10n.qaCatPcos,
      'contraception' => l10n.qaCatContraception,
      'mental' => l10n.qaCatMental,
      'nutrition' => l10n.qaCatNutrition,
      _ => cat,
    };
  }
}

class _QaStepRow extends StatelessWidget {
  const _QaStepRow({
    required this.number,
    required this.text,
    required this.theme,
  });

  final String number;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
