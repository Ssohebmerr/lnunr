part of 'admin_screen.dart';

// ---------------------------------------------------------------------------
// Q&A Tab — Anonymous health questions from users
// ---------------------------------------------------------------------------
class _QATab extends StatefulWidget {
  const _QATab();

  @override
  State<_QATab> createState() => _QATabState();
}

class _QATabState extends State<_QATab> {
  String _filter = 'pending'; // pending | answered | all

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final filters = <(String, String, IconData)>[
      ('pending', l10n.adminFilterPending, Icons.hourglass_top_rounded),
      ('answered', l10n.adminFilterAnswered, Icons.check_circle_rounded),
      ('all', l10n.adminFilterAll, Icons.list_alt_rounded),
    ];
    final selectedLabel =
        filters.firstWhere((f) => f.$1 == _filter, orElse: () => filters[0]).$2;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: filters.map((f) {
              final selected = f.$1 == _filter;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = f.$1);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? AuraDecorations.primaryGradient
                              : null,
                          color: selected
                              ? null
                              : theme.colorScheme.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : theme.colorScheme.outline
                                    .withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              f.$3,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                f.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _queryStream(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('${l10n.adminError} ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.question_answer_outlined,
                          size: 56, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        l10n.adminQuestionsEmpty(selectedLabel.toLowerCase()),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QuestionCard(
                      docId: docs[i].id,
                      data: data,
                      theme: theme,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _queryStream() {
    final ref = FirebaseFirestore.instance.collection('anonymousQuestions');
    if (_filter == 'all') {
      return ref.orderBy('createdAt', descending: true).snapshots();
    }
    return ref
        .where('status', isEqualTo: _filter)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({
    required this.docId,
    required this.data,
    required this.theme,
  });

  final String docId;
  final Map<String, dynamic> data;
  final ThemeData theme;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  final _answerController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _answer() async {
    final l10n = AppLocalizations.of(context)!;
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('anonymousQuestions')
          .doc(widget.docId)
          .update({
        'status': 'answered',
        'answer': answer,
        'answeredBy': 'admin',
        'answeredAt': FieldValue.serverTimestamp(),
      });
      _answerController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.adminError} $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await FirebaseFirestore.instance
          .collection('anonymousQuestions')
          .doc(widget.docId)
          .update({'status': 'rejected'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminQuestionRejected)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.adminError} $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.data;
    final theme = widget.theme;
    final question = data['question'] ?? '';
    final category = data['category'] ?? 'general';
    final status = data['status'] ?? 'pending';
    final answer = data['answer'];
    final createdAt = data['createdAt'] as Timestamp?;

    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category.toString().toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (createdAt != null)
                Text(
                  _ago(createdAt.toDate(), l10n),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                status == 'answered'
                    ? Icons.check_circle
                    : status == 'rejected'
                        ? Icons.cancel
                        : Icons.hourglass_top,
                size: 18,
                color: status == 'answered'
                    ? Colors.green
                    : status == 'rejected'
                        ? Colors.red
                        : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question
          Text(
            question,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          // Existing answer
          if (answer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medical_services_outlined,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(l10n.adminQAExpertAnswer,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(answer, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],

          // Answer input (only for pending)
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.adminExpertAnswerHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _answer,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(l10n.adminPublishAnswer),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _reject,
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  tooltip: l10n.adminReject,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

