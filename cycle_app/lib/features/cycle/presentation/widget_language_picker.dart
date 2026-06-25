import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_cubit.dart';
import '../../../l10n/app_localizations.dart';
import '../data/cycle_bridge_service.dart';

/// Extended language picker using all 19 menstrual_cycle_widget languages.
class WidgetLanguagePicker extends StatelessWidget {
  const WidgetLanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().locale.languageCode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DropdownButtonFormField<String>(
          initialValue: CycleBridgeService.supportedLanguageCodes.contains(locale)
              ? locale
              : 'en',
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.widgetLanguageLabel,
            border: const OutlineInputBorder(),
          ),
          items: CycleBridgeService.supportedLanguageCodes
              .map(
                (code) => DropdownMenuItem(
                  value: code,
                  child: Text(CycleBridgeService.languageLabel(code)),
                ),
              )
              .toList(),
          onChanged: (code) async {
            if (code == null) return;
            await context.read<LocaleCubit>().setLocale(code);
            await CycleBridgeService().applyLocale(code);
          },
        ),
      ),
    );
  }
}
