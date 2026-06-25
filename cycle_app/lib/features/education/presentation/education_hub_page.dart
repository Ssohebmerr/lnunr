import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/ai_education_service.dart';
import '../../../core/ai/ai_gateway.dart';
import 'ai_education_screen.dart';

/// AI-powered educational hub that provides personalized content
/// based on the user's cycle phase and questions.
class EducationHubPage extends StatelessWidget {
  const EducationHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => AiEducationService(
        contextEngine: context.read<AiContextEngine>(),
        gateway: context.read<AiGateway>(),
      ),
      child: const AiEducationScreen(),
    );
  }
}
