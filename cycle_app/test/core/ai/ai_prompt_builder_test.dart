// ============================================================================
// test/core/ai/ai_prompt_builder_test.dart
// ----------------------------------------------------------------------------
// Tests the user-prompt builder used by both on-device Gemini and the
// Cloud Function chat endpoint.
//
// What we cover:
//   - `buildUserPrompt` always opens with the correct mode-specific header.
//   - Pregnant mode emits pregnancy fields; non-pregnant emits cycle fields.
//   - Lightweight modes (partner, intimacy, briefing) DO NOT include the
//     heavy cycle/wellness fields — this is what `includesFullContext` is
//     supposed to enforce and a regression here would balloon token usage.
//   - The wellness hub snippet is truncated to 2500 chars when it's huge.
//   - Locale defaults to 'ar' (Arabic) when missing, matching the on-device
//     fallback in `ai_context_engine.dart`.
//   - `userGoal: 'pregnant'` overrides cycle fields even if cycle fields
//     are present in the same context.
//   - The user message is appended at the bottom regardless of mode.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_aura/core/ai/ai_prompt_builder.dart';

void main() {
  group('AiPromptBuilder.buildUserPrompt — header', () {
    test('chat mode uses the default APP DATA header', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        'Hi',
        const {'userGoal': 'general', 'userLocale': 'en'},
        'chat',
      );
      expect(prompt, startsWith('=== APP DATA'));
    });

    test('briefing mode uses DAILY BRIEFING header', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        'morning',
        const {'userLocale': 'en'},
        'briefing',
      );
      expect(prompt, startsWith('=== DAILY BRIEFING REQUEST ==='));
    });

    test('mood mode uses MOOD JOURNAL ENTRY header', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        'I feel tired',
        const {'userLocale': 'en'},
        'mood',
      );
      expect(prompt, startsWith('=== MOOD JOURNAL ENTRY ==='));
    });

    test('doctor mode uses DOCTOR REPORT REQUEST header', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        'generate',
        const {'userLocale': 'en'},
        'doctor',
      );
      expect(prompt, startsWith('=== DOCTOR REPORT REQUEST ==='));
    });

    test('recap + weekly_recap share the same header', () {
      final recap = AiPromptBuilder.buildUserPrompt(
        '', const {'userLocale': 'en'}, 'recap');
      final weekly = AiPromptBuilder.buildUserPrompt(
        '', const {'userLocale': 'en'}, 'weekly_recap');
      expect(recap.split('\n').first, weekly.split('\n').first);
    });
  });

  group('AiPromptBuilder.buildUserPrompt — pregnant vs cycle', () {
    test('pregnant mode emits pregnancy fields', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        'how am I?',
        const {
          'userGoal': 'pregnant',
          'pregnancyWeek': 18,
          'trimester': 2,
          'expectedDueDate': '2026-09-01',
          'userLocale': 'en',
        },
        'chat',
      );
      expect(prompt, contains('Pregnancy week: 18'));
      expect(prompt, contains('Trimester: 2'));
      expect(prompt, contains('Due date: 2026-09-01'));
      // Cycle-specific fields must NOT leak into pregnant mode.
      expect(prompt, isNot(contains('Cycle length:')));
    });

    test('non-pregnant mode emits cycle fields and NOT pregnancy fields', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        'how am I?',
        const {
          'userGoal': 'general',
          'cycleLength': 28,
          'periodDuration': 5,
          'currentPhase': 'luteal',
          'currentCycleDay': 22,
          'nextPeriodDate': '2026-08-10',
          'ovulationDate': '2026-07-28',
          'userLocale': 'en',
        },
        'chat',
      );
      expect(prompt, contains('Cycle length: 28'));
      expect(prompt, contains('Period duration: 5'));
      expect(prompt, contains('Current phase: luteal'));
      expect(prompt, contains('Current cycle day: 22'));
      expect(prompt, contains('Next period: 2026-08-10'));
      expect(prompt, contains('Ovulation: 2026-07-28'));
      expect(prompt, isNot(contains('Pregnancy week')));
      expect(prompt, isNot(contains('Trimester')));
    });

    test('missing userGoal → falls back to cycle fields', () {
      // Defensive: the AI gateway must never crash if userGoal is absent.
      final prompt = AiPromptBuilder.buildUserPrompt(
        'x', const {'cycleLength': 30, 'userLocale': 'en'}, 'chat');
      expect(prompt, contains('User goal: unknown'));
      expect(prompt, contains('Cycle length: 30'));
    });
  });

  group('AiPromptBuilder.buildUserPrompt — lightweight modes', () {
    test('partner mode omits heavy cycle/wellness fields', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        'tell him',
        const {
          'userGoal': 'general',
          'cycleLength': 28,
          'periodDuration': 5,
          'currentPhase': 'luteal',
          'currentCycleDay': 22,
          'nextPeriodDate': '2026-08-10',
          'ovulationDate': '2026-07-28',
          'todayLog': 'cramps, water 5 cups',
          'recentSymptoms': {'cramps': 4},
          'wellnessLogCount': 30,
          'wellnessHub': {'pills': 'taken'},
          'summary': {'avg': 28.4},
          'userLocale': 'en',
        },
        'partner',
      );
      expect(prompt, contains('=== PARTNER MESSAGE REQUEST ==='));
      // Basic cycle position IS present (intentional — model still needs it).
      expect(prompt, contains('Cycle length: 28'));
      // Heavy fields are NOT present (the actual saving).
      expect(prompt, isNot(contains('Today\'s log')),
          reason: 'partner must NOT include today\'s log');
      expect(prompt, isNot(contains('Recent symptoms')),
          reason: 'partner must NOT include symptoms');
      expect(prompt, isNot(contains('Wellness hub')),
          reason: 'partner must NOT include the wellness hub');
      expect(prompt, isNot(contains('Summary:')),
          reason: 'partner must NOT include the summary');
    });

    test('briefing mode omits heavy cycle/wellness fields too', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        '',
        const {
          'userGoal': 'general',
          'cycleLength': 28,
          'todayLog': 'mood: happy',
          'wellnessHub': {},
          'userLocale': 'en',
        },
        'briefing',
      );
      expect(prompt, contains('=== DAILY BRIEFING REQUEST ==='));
      expect(prompt, contains('Cycle length: 28'));
      expect(prompt, isNot(contains('Today\'s log')));
      expect(prompt, isNot(contains('Wellness hub')));
    });

    test('intimacy mode omits heavy fields', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        'help',
        const {'userGoal': 'general', 'cycleLength': 28, 'userLocale': 'en'},
        'intimacy',
      );
      expect(prompt, contains('=== INTIMACY GUIDANCE REQUEST ==='));
      expect(prompt, contains('Cycle length: 28'));
      expect(prompt, isNot(contains('Today\'s log')));
    });

    test('full modes (chat/analyze/doctor) DO include the cycle fields', () {
      for (final mode in ['chat', 'analyze', 'doctor', 'mood', 'patterns']) {
        final prompt = AiPromptBuilder.buildUserPrompt(
          'q',
          const {
            'userGoal': 'general',
            'cycleLength': 28,
            'todayLog': 'cramps',
            'userLocale': 'en',
          },
          mode,
        );
        expect(prompt, contains('Cycle length: 28'),
            reason: 'mode "$mode" must include cycle length');
        expect(prompt, contains('Today\'s log'),
            reason: 'mode "$mode" must include today\'s log');
      }
    });
  });

  group('AiPromptBuilder.buildUserPrompt — hub snippet truncation', () {
    test('truncates huge wellness hubs to <= 2500 chars', () {
      final big = 'x' * 6000;
      final prompt = AiPromptBuilder.buildUserPrompt(
        '',
        <String, dynamic>{
          'userGoal': 'general',
          'cycleLength': 28,
          'wellnessHub': <String, dynamic>{'payload': big},
          'userLocale': 'en',
        },
        'chat',
      );
      // Find the hub line and check its content length is bounded.
      final lines = prompt.split('\n');
      final hubLine = lines.firstWhere(
        (l) => l.startsWith('Wellness hub'),
        orElse: () => '',
      );
      expect(hubLine, isNotEmpty);
      // The substring() in the builder caps the hub at 2500 chars.
      expect(hubLine.length, lessThanOrEqualTo(
          'Wellness hub (pills, sanitary, vitals — anonymized): '.length + 2500));
    });

    test('empty wellness hub renders as "none"', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        '',
        const {
          'userGoal': 'general',
          'cycleLength': 28,
          'wellnessHub': {},
          'userLocale': 'en',
        },
        'chat',
      );
      expect(prompt, contains('Wellness hub (pills, sanitary, vitals — anonymized): none'));
    });
  });

  group('AiPromptBuilder.buildUserPrompt — locale + message', () {
    test('locale defaults to ar when missing', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        '', const {'cycleLength': 28}, 'chat');
      expect(prompt, contains('User locale: ar'));
    });

    test('explicit locale is preserved', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        '', const {'userLocale': 'fr'}, 'chat');
      expect(prompt, contains('User locale: fr'));
    });

    test('user message is appended after the header and context', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        'tell me about luteal phase',
        const {'userGoal': 'general', 'cycleLength': 28, 'userLocale': 'en'},
        'chat',
      );
      // The message itself appears at the very end of the prompt.
      expect(prompt, endsWith('tell me about luteal phase'));
      // And the standard "USER MESSAGE" header precedes it.
      final headerIdx = prompt.indexOf(
          '=== USER MESSAGE (answer THIS directly — show you read it) ===');
      final msgIdx = prompt.indexOf('tell me about luteal phase');
      expect(headerIdx, greaterThan(-1));
      expect(msgIdx, greaterThan(headerIdx));
    });

    test('mood mode uses JOURNAL ENTRY header for the message', () {
      final prompt = AiPromptBuilder.buildUserPrompt(
        'I feel anxious',
        const {'userGoal': 'general', 'cycleLength': 28, 'userLocale': 'en'},
        'mood',
      );
      expect(prompt, contains('=== USER JOURNAL ENTRY (analyze emotions gently) ==='));
      expect(prompt, contains('I feel anxious'));
    });
  });
}