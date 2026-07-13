import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart' as md;
import 'package:flutter/material.dart';

import '../core/widgets/aura_scaffold.dart';
import 'menstrudel_bootstrap.dart';

/// Wraps Menstrudel screens with localization + Cycle Aura app bar.
class MenstrudelScreenShell extends StatefulWidget {
  const MenstrudelScreenShell({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButtonBuilder,
  });

  final String title;
  final Widget body;
  final Widget? Function(BuildContext context)? floatingActionButtonBuilder;

  @override
  State<MenstrudelScreenShell> createState() => _MenstrudelScreenShellState();
}

class _MenstrudelScreenShellState extends State<MenstrudelScreenShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MenstrudelBootstrap.prepare(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Localizations.override(
      context: context,
      delegates: md.AppLocalizations.localizationsDelegates,
      locale: Localizations.localeOf(context),
      child: Builder(
        builder: (localizedContext) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            // Transparent bar over the mesh (same shell as the modern
            // account screens) — an opaque bar here left a visible seam
            // between the app bar and the gradient below it.
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: Text(widget.title),
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(localizedContext).pop(),
              ),
            ),
            body: AppMeshBackground(
              child: SafeArea(child: SizedBox.expand(child: widget.body)),
            ),
            floatingActionButton:
                widget.floatingActionButtonBuilder?.call(localizedContext),
          );
        },
      ),
    );
  }
}
