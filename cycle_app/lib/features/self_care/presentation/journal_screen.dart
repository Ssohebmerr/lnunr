import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/self_care_content.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _controller = TextEditingController();
  int _promptIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _controller.text = prefs.getString('self_care_journal') ?? '';
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('self_care_journal', _controller.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selfCareJournalSaved)),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final prompt = SelfCareContent.journalPrompts[_promptIndex].forLocale(lang);

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.selfCareJournal),
      ),
      body: AppMeshBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            16,
            16,
          ),
          children: [
            AppGlassCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.selfCareJournalPrompt),
                subtitle: Text(prompt),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() {
                    _promptIndex = (_promptIndex + 1) % SelfCareContent.journalPrompts.length;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppGlassCard(
              child: TextField(
                controller: _controller,
                maxLines: 12,
                decoration: InputDecoration(
                  hintText: l10n.selfCareJournalHint,
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppGradientButton(
              label: l10n.selfCareJournalSave,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
