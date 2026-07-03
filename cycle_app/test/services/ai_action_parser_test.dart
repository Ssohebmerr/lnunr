import 'package:cycle_aura/core/ai/ai_action_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiActionParser', () {
    test('returns plain text when no tags present', () {
      final result = AiActionParser.parse('Hello, how are you today?');
      expect(result.cleanText, 'Hello, how are you today?');
      expect(result.actions, isEmpty);
    });

    test('strips tags from text and returns one action', () {
      final result = AiActionParser.parse(
        'Sounds like you have cramps. [[log_symptom:cramps]]',
      );
      expect(result.cleanText, 'Sounds like you have cramps.');
      expect(result.actions, hasLength(1));
      expect(result.actions.first.type, AiActionType.logSymptom);
      expect(result.actions.first.value, 'cramps');
    });

    test('parses multiple tags up to 3 unique actions', () {
      final result = AiActionParser.parse(
        'Quick wins for today:\n[[log_mood:tired]] [[log_water:3]] [[log_pain:6]] [[open_log]]',
      );
      expect(result.cleanText, 'Quick wins for today:');
      expect(result.actions, hasLength(3));
      expect(result.actions[0].type, AiActionType.logMood);
      expect(result.actions[1].type, AiActionType.logWater);
      expect(result.actions[2].type, AiActionType.logPain);
    });

    test('strips bare open_log tag and exposes navigation action', () {
      final result = AiActionParser.parse(
        'سجّلي مزاجك اليوم. [[open_log]] [[log_mood:calm]]',
      );
      expect(result.cleanText, 'سجّلي مزاجك اليوم.');
      expect(result.actions, hasLength(2));
      expect(result.actions[0].type, AiActionType.openLog);
      expect(result.actions[1].type, AiActionType.logMood);
      expect(result.actions[1].value, 'calm');
    });

    test('deduplicates identical tags', () {
      final result = AiActionParser.parse(
        '[[log_mood:happy]] [[log_mood:happy]] [[log_mood:tired]]',
      );
      expect(result.actions, hasLength(2));
      expect(result.actions[0].value, 'happy');
      expect(result.actions[1].value, 'tired');
    });

    test('supports custom button labels', () {
      final result = AiActionParser.parse(
        '[[log_symptom:cramps|Log my cramps]]',
      );
      expect(result.actions.first.label, 'Log my cramps');
      expect(result.actions.first.value, 'cramps');
    });

    test('ignores unknown tag keys', () {
      final result = AiActionParser.parse(
        '[[unknown_key:foo]] [[log_mood:calm]]',
      );
      expect(result.actions, hasLength(1));
      expect(result.actions.first.type, AiActionType.logMood);
    });

    test('sanitizeForDisplay removes truncation meta suffix', () {
      const raw = 'صباح الخير يا جميلة! اليوم هو اليوم الرابع من دورتك\n\n... [response truncated]';
      expect(
        AiActionParser.sanitizeForDisplay(raw),
        'صباح الخير يا جميلة! اليوم هو اليوم الرابع من دورتك',
      );
    });

    test('sanitizeForDisplay removes truncation marker anywhere in text', () {
      const raw = 'نص [RESPONSE TRUNCATED] في الوسط';
      expect(
        AiActionParser.sanitizeForDisplay(raw),
        'نص في الوسط',
      );
    });

    test('sanitizeForDisplay strips unknown double-bracket tags', () {
      expect(
        AiActionParser.sanitizeForDisplay('مرحباً [[unknown:foo]] نص'),
        'مرحباً نص',
      );
    });

    test('sanitizeForDisplay strips lone open_log bracket tag', () {
      expect(
        AiActionParser.sanitizeForDisplay('سجّلي مزاجك. [open_log]'),
        'سجّلي مزاجك.',
      );
    });

    test('sanitizeForDisplay removes response stopped suffix', () {
      const raw = 'نصيحة لليوم.\n\n[response stopped: SAFETY]';
      expect(AiActionParser.sanitizeForDisplay(raw), 'نصيحة لليوم.');
    });

    test('sanitizeForDisplay strips incomplete trailing tag while streaming', () {
      expect(
        AiActionParser.sanitizeForDisplay('مرحباً [[open_lo'),
        'مرحباً',
      );
    });
  });
}
