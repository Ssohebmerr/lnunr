// ============================================================================
// test/core/ai/ai_prompt_style_test.dart
// ----------------------------------------------------------------------------
// Tests the mode → prompt/config dispatch table that gates every Gemini call.
//
// What we cover:
//   - `forMode` returns a non-empty, distinct prompt for every known mode.
//   - `forMode` swaps to the pregnant variant when isPregnant is true (for
//     the chat/analyze fall-through).
//   - `configForMode` returns a positive maxTokens and a sane temperature
//     (0..1.5) — this is the table the AI gateway and Cloud Function both
//     consult, so a regression here would silently change every reply.
//   - `includesFullContext` keeps the lightweight modes lightweight.
//   - Doctor mode always returns the same prompt regardless of pregnancy.
//   - Unknown modes fall through to the default chat prompt.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_aura/core/ai/ai_prompt_style.dart';

void main() {
  group('AiPromptStyle.forMode', () {
    test('every known mode returns a non-empty prompt', () {
      const knownModes = [
        'chat',
        'briefing',
        'patterns',
        'emergency',
        'nutrition',
        'partner',
        'mood',
        'fertility',
        'weight',
        'intimacy',
        'recap',
        'weekly_recap',
        'doctor',
        'analyze',
      ];
      for (final mode in knownModes) {
        final prompt = AiPromptStyle.forMode(mode);
        expect(
          prompt,
          isNotEmpty,
          reason: 'mode "$mode" produced empty prompt',
        );
        expect(prompt.trim(), isNotEmpty);
      }
    });

    test('specialised modes produce DISTINCT prompts', () {
      // Lightweight modes skip the app-knowledge dump so they must be smaller
      // than the full chat prompt.
      const specialised = ['briefing', 'emergency', 'partner', 'mood'];
      final fullChat = AiPromptStyle.forMode('chat');
      for (final mode in specialised) {
        final p = AiPromptStyle.forMode(mode);
        expect(
          p,
          isNot(equals(fullChat)),
          reason: 'specialised mode "$mode" should not equal chat prompt',
        );
      }
    });

    test('recap and weekly_recap return the same prompt', () {
      expect(
        AiPromptStyle.forMode('recap'),
        equals(AiPromptStyle.forMode('weekly_recap')),
      );
    });

    test('isPregnant swaps the chat fall-through to the pregnant variant', () {
      final nonPregnant = AiPromptStyle.forMode('chat', isPregnant: false);
      final pregnant = AiPromptStyle.forMode('chat', isPregnant: true);
      expect(pregnant, isNot(equals(nonPregnant)));
      expect(pregnant.toLowerCase(), contains('pregnant'));
    });

    test('isPregnant swaps the analyze fall-through too', () {
      final nonPregnant = AiPromptStyle.forMode('analyze', isPregnant: false);
      final pregnant = AiPromptStyle.forMode('analyze', isPregnant: true);
      expect(pregnant, isNot(equals(nonPregnant)));
    });

    test('doctor mode ignores isPregnant (clinical template is fixed)', () {
      expect(
        AiPromptStyle.forMode('doctor', isPregnant: false),
        equals(AiPromptStyle.forMode('doctor', isPregnant: true)),
      );
    });

    test('unknown mode falls through to the default chat prompt', () {
      expect(
        AiPromptStyle.forMode('not-a-real-mode'),
        equals(AiPromptStyle.forMode('chat')),
      );
    });

    test('interactive chat adapts Arabic dialect only with clear evidence', () {
      for (final mode in ['chat', 'analyze']) {
        final prompt = AiPromptStyle.forMode(mode);
        expect(prompt, contains('ARABIC DIALECT ADAPTATION'));
        expect(prompt, contains('start with warm, natural'));
        expect(prompt, contains('clear, recurring wording'));
        expect(prompt, contains('Never infer it from the app locale'));
        expect(prompt, contains('Never announce, explain, or expose'));
      }
    });

    test('structured and specialised modes keep their existing style', () {
      for (final mode in ['doctor', 'briefing', 'emergency', 'mood']) {
        expect(
          AiPromptStyle.forMode(mode),
          isNot(contains('ARABIC DIALECT ADAPTATION')),
          reason: 'mode "$mode" should not receive free-form dialect rules',
        );
      }
    });

    test('every prompt that needs it contains the medical safety clause', () {
      // The medical safety block is the ONLY thing that must be strict —
      // but specialised modes like `briefing` and `partner` intentionally
      // omit it (they're too short / non-clinical to warrant the boilerplate).
      const modesWithSafety = [
        'chat',
        'emergency',
        'mood',
        'analyze',
        'doctor',
        'patterns',
        'nutrition',
        'fertility',
        'weight',
        'intimacy',
      ];
      for (final mode in modesWithSafety) {
        final prompt = AiPromptStyle.forMode(mode);
        expect(
          prompt.toLowerCase(),
          contains('medical safety'),
          reason: 'mode "$mode" is missing the medical safety block',
        );
      }
    });
  });

  group('AiPromptStyle.configForMode', () {
    test('returns positive maxTokens and a temperature in (0, 1.5]', () {
      const modes = [
        'chat',
        'briefing',
        'patterns',
        'emergency',
        'nutrition',
        'partner',
        'mood',
        'fertility',
        'weight',
        'intimacy',
        'recap',
        'doctor',
        'analyze',
        'unknown-thing',
      ];
      for (final mode in modes) {
        final cfg = AiPromptStyle.configForMode(mode);
        expect(
          cfg.maxTokens,
          greaterThan(0),
          reason: 'mode "$mode" gave non-positive maxTokens',
        );
        expect(
          cfg.temperature,
          greaterThan(0),
          reason: 'mode "$mode" gave non-positive temperature',
        );
        expect(
          cfg.temperature,
          lessThanOrEqualTo(1.5),
          reason: 'mode "$mode" gave implausibly high temperature',
        );
      }
    });

    test('doctor mode budget is at least 1000 tokens', () {
      // Doctor report is the only mode that needs to write 250-450 structured
      // words — it deserves the largest specialised budget. Default `chat`
      // is allowed to be even larger (it caps at 1500 to avoid runaway
      // tokens for unbounded conversation).
      final doctorCfg = AiPromptStyle.configForMode('doctor');
      expect(
        doctorCfg.maxTokens,
        greaterThanOrEqualTo(1000),
        reason: 'doctor budget regressed below 1000 — restore to 1200',
      );
    });

    test('lightweight modes (partner, intimacy, briefing) have smaller '
        'budgets than the default chat', () {
      final chat = AiPromptStyle.configForMode('chat');
      for (final mode in ['partner', 'intimacy', 'briefing']) {
        final cfg = AiPromptStyle.configForMode(mode);
        expect(
          cfg.maxTokens,
          lessThanOrEqualTo(chat.maxTokens),
          reason: 'lightweight mode "$mode" should not exceed chat budget',
        );
      }
    });

    test('temperature table regression snapshot', () {
      // Lock down the exact temperatures so any tweak has to update the
      // tests deliberately. This is the single source of truth for how
      // creative vs factual each mode is.
      final samples = <String, double>{
        'doctor': 0.45,
        'analyze': 0.55,
        'patterns': 0.55,
        'briefing': 0.7,
        'emergency': 0.55,
        'nutrition': 0.7,
        'partner': 0.85,
        'mood': 0.85,
      };
      for (final entry in samples.entries) {
        expect(
          AiPromptStyle.configForMode(entry.key).temperature,
          entry.value,
          reason: 'temperature for "${entry.key}" drifted',
        );
      }
    });
  });

  group('AiPromptStyle.includesFullContext', () {
    test('lightweight modes opt OUT of full context', () {
      expect(AiPromptStyle.includesFullContext('partner'), isFalse);
      expect(AiPromptStyle.includesFullContext('intimacy'), isFalse);
      expect(AiPromptStyle.includesFullContext('briefing'), isFalse);
    });

    test('chat/analyze/doctor/mood/patterns/etc. opt IN', () {
      const fullModes = [
        'chat',
        'analyze',
        'doctor',
        'mood',
        'patterns',
        'emergency',
        'nutrition',
        'fertility',
        'weight',
        'recap',
        'unknown-mode',
      ];
      for (final mode in fullModes) {
        expect(
          AiPromptStyle.includesFullContext(mode),
          isTrue,
          reason: 'mode "$mode" should include full context',
        );
      }
    });
  });
}
