import 'dart:convert';

import 'package:cycle_aura/core/ai/ai_response_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AiResponseCache.makeKey', () {
    test('is stable for the same inputs', () {
      final at = DateTime(2026, 7, 3, 12);
      final a = AiResponseCache.makeKey(
        mode: 'briefing',
        cycleDay: 4,
        phase: 'follicular',
        locale: 'ar',
        at: at,
      );
      final b = AiResponseCache.makeKey(
        mode: 'briefing',
        cycleDay: 4,
        phase: 'follicular',
        locale: 'ar',
        at: at,
      );
      expect(a, b);
    });

    test('changes when mode or date changes', () {
      final at = DateTime(2026, 7, 3);
      final base = AiResponseCache.makeKey(mode: 'briefing', at: at);
      final otherMode = AiResponseCache.makeKey(mode: 'recap', at: at);
      final otherDay = AiResponseCache.makeKey(
        mode: 'briefing',
        at: at.add(const Duration(days: 1)),
      );
      expect(otherMode, isNot(base));
      expect(otherDay, isNot(base));
    });
  });

  group('AiResponseCache get/set', () {
    test('round-trips a cached value', () async {
      const key = 'test-key';
      await AiResponseCache.set(key, 'مرحباً');
      expect(await AiResponseCache.get(key), 'مرحباً');
    });

    test('expires entries after ttl', () async {
      const key = 'ttl-key';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'ai_response_cache_v1',
        jsonEncode({
          key: {
            'v': 'old',
            't': DateTime.now()
                .subtract(const Duration(hours: 25))
                .millisecondsSinceEpoch,
          },
        }),
      );

      expect(
        await AiResponseCache.get(key, ttl: const Duration(hours: 24)),
        isNull,
      );
    });

    test('clear removes all cached values', () async {
      await AiResponseCache.set('a', '1');
      await AiResponseCache.set('b', '2');
      await AiResponseCache.clear();
      expect(await AiResponseCache.get('a'), isNull);
      expect(await AiResponseCache.get('b'), isNull);
    });
  });
}
