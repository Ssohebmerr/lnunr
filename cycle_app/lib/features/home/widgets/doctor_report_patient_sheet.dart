import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/doctor_report_patient.dart';

/// Bottom sheet to edit the optional patient header (name / age / note).
/// Returns the saved [PatientInfo] (also persisted) or null on dismiss.
class DoctorReportPatientSheet extends StatefulWidget {
  const DoctorReportPatientSheet({super.key, required this.initial});

  final PatientInfo initial;

  static Future<PatientInfo?> show(
    BuildContext context,
    PatientInfo initial,
  ) {
    return showModalBottomSheet<PatientInfo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DoctorReportPatientSheet(initial: initial),
    );
  }

  @override
  State<DoctorReportPatientSheet> createState() =>
      _DoctorReportPatientSheetState();
}

class _DoctorReportPatientSheetState extends State<DoctorReportPatientSheet> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.name ?? '');
    _age = TextEditingController(
      text: widget.initial.age?.toString() ?? '',
    );
    _note = TextEditingController(text: widget.initial.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final age = int.tryParse(_age.text.trim());
    final info = PatientInfo(
      name: _name.text.trim().isEmpty ? null : _name.text.trim(),
      age: (age != null && age > 0 && age < 120) ? age : null,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    await DoctorReportPatientStore.save(info);
    if (mounted) navigator.pop(info);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.doctorReportPatientTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AuraColors.plum,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.doctorReportPatientSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.doctorReportPatientName,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                labelText: l10n.doctorReportPatientAge,
                prefixIcon: const Icon(Icons.cake_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.doctorReportPatientNote,
                hintText: l10n.doctorReportPatientNoteHint,
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.notes_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(l10n.doctorReportPatientSave),
              style: FilledButton.styleFrom(
                backgroundColor: AuraColors.roseDeep,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
