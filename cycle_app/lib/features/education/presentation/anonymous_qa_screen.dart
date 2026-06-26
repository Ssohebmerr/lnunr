import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_design_tokens.dart';
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
    final text = _controller.text.trim();
    if (text.isEmpty || text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.storyPublished ?? 'Question submitted!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
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
      appBar: AppBar(
        title: Text(l10n.storyCreate), // Reuse existing string
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.question_answer_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Anonymous Health Q&A',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask your health question anonymously. A certified expert will answer it and the answer will be published in the Education section.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category selector
            Text(
              'Category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryItems.map((cat) {
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(_categoryLabel(cat)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Question input
            Text(
              'Your Question',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: l10n.healthQuestionHint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
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
                    'Your identity is 100% anonymous. No name, email, or ID is stored.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit button
            FilledButton.icon(
              onPressed: _submitting ? null : _submitQuestion,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_submitting ? 'Submitting...' : 'Submit Question'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String cat) {
    return switch (cat) {
      'general' => 'General',
      'cycle' => 'Cycle & Period',
      'pregnancy' => 'Pregnancy',
      'pcos' => 'PCOS',
      'contraception' => 'Contraception',
      'mental' => 'Mental Health',
      'nutrition' => 'Nutrition',
      _ => cat,
    };
  }
}
