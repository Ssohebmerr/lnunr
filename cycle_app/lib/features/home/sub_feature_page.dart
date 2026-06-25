import 'package:flutter/material.dart';

import '../../core/theme/app_design_tokens.dart';
import '../../core/widgets/aura_scaffold.dart';

/// Full-screen wrapper for secondary features opened from Home.
class SubFeaturePage extends StatelessWidget {
  const SubFeaturePage({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: AppGlassCard(
            radius: AppRadius.pill,
            padding: const EdgeInsets.all(8),
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
          ),
        ),
        title: Text(title),
      ),
      body: AppMeshBackground(
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}
