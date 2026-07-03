import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../features/community/data/moderation_result.dart';
import 'ai_prompt_builder.dart';
import 'ai_prompt_style.dart';
import 'models/ai_turn.dart';

/// Firebase AI Logic service — primary AI provider for the app.
///
/// Uses Firebase AI Logic SDK to access Gemini models directly from the
/// client with built-in security (App Check) and no backend required.
class FirebaseAiService {
  static const _modelNames = ['gemini-2.5-flash', 'gemini-2.0-flash'];

  GenerativeModel? _moderationModel;

  GenerativeModel _getModel({
    required String modelName,
    required String systemPrompt,
    required int maxTokens,
    required double temperature,
  }) {
    return FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        maxOutputTokens: maxTokens,
        temperature: temperature,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium, null),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, null),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high, null),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium, null),
      ],
    );
  }

  /// Generate a response using Firebase AI Logic.
  Future<String?> generate({
    required String message,
    required Map<String, dynamic> cycleContext,
    String mode = 'chat',
    List<AiTurn> history = const [],
  }) async {
    try {
      final isPregnant = cycleContext['userGoal'] == 'pregnant';
      final systemPrompt = AiPromptStyle.forMode(mode, isPregnant: isPregnant);
      final cfg = AiPromptStyle.configForMode(mode);
      final userPrompt =
          AiPromptBuilder.buildUserPrompt(message, cycleContext, mode);
      final contents = _buildContents(history: history, userPrompt: userPrompt);

      for (final modelName in _modelNames) {
        try {
          final model = _getModel(
            modelName: modelName,
            systemPrompt: systemPrompt,
            maxTokens: cfg.maxTokens,
            temperature: cfg.temperature,
          );

          final response = await model.generateContent(contents);
          var text = response.text?.trim();
          if (text == null || text.isEmpty) continue;

          final finish = response.candidates.isNotEmpty
              ? response.candidates.first.finishReason
              : null;
          if (finish == FinishReason.maxTokens &&
              !text.endsWith('.') &&
              !text.endsWith('!') &&
              !text.endsWith('?') &&
              !text.endsWith('…')) {
            text = '$text…';
          }

          return text;
        } catch (e) {
          debugPrint('[FirebaseAiService] $modelName failed: $e');
        }
      }

      return null;
    } catch (e) {
      debugPrint('[FirebaseAiService] generate failed: $e');
      return null;
    }
  }

  /// Streaming generation using Firebase AI Logic.
  Stream<String> generateStream({
    required String message,
    required Map<String, dynamic> cycleContext,
    String mode = 'chat',
    List<AiTurn> history = const [],
  }) async* {
    final isPregnant = cycleContext['userGoal'] == 'pregnant';
    final systemPrompt = AiPromptStyle.forMode(mode, isPregnant: isPregnant);
    final cfg = AiPromptStyle.configForMode(mode);
    final userPrompt =
        AiPromptBuilder.buildUserPrompt(message, cycleContext, mode);
    final contents = _buildContents(history: history, userPrompt: userPrompt);

    for (final modelName in _modelNames) {
      try {
        final model = _getModel(
          modelName: modelName,
          systemPrompt: systemPrompt,
          maxTokens: cfg.maxTokens,
          temperature: cfg.temperature,
        );

        var yieldedSomething = false;
        await for (final chunk in model.generateContentStream(contents)) {
          final text = chunk.text;
          if (text != null && text.isNotEmpty) {
            yieldedSomething = true;
            yield text;
          }
        }
        if (yieldedSomething) return;
      } catch (e) {
        debugPrint('[FirebaseAiService.stream] $modelName failed: $e');
      }
    }
  }

  List<Content> _buildContents({
    required List<AiTurn> history,
    required String userPrompt,
  }) {
    final trimmed = history.length > 12
        ? history.sublist(history.length - 12)
        : history;

    final messages = <Content>[];
    for (final turn in trimmed) {
      messages.add(turn.role == AiTurnRole.user
          ? Content.text(turn.text)
          : Content('model', [TextPart(turn.text)]));
    }
    messages.add(Content.text(userPrompt));
    return messages;
  }

  /// Moderate community content using Firebase AI Logic.
  Future<ModerationResult?> moderateContent({required String text}) async {
    try {
      _moderationModel ??= FirebaseAI.googleAI().generativeModel(
        model: _modelNames.first,
        systemInstruction: Content.system(AiPromptStyle.moderationSystem),
      );

      final response = await _moderationModel!.generateContent([
        Content.text(text),
      ]);
      final raw = response.text?.trim();
      if (raw == null || raw.isEmpty) return null;

      final lower = raw.toLowerCase();
      if (lower.contains('"approved":true') ||
          lower.contains('"approved": true')) {
        return const ModerationResult(approved: true);
      }
      if (lower.contains('"approved":false') ||
          lower.contains('"approved": false')) {
        final reasonMatch =
            RegExp(r'"reason"\s*:\s*"([^"]+)"').firstMatch(raw);
        return ModerationResult(
          approved: false,
          reason: reasonMatch?.group(1) ??
              'Content not allowed in this community.',
        );
      }
    } catch (e) {
      debugPrint('[FirebaseAiService] moderate failed: $e');
    }
    return null;
  }
}
