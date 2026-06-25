import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/features/community/data/models/post_type.dart';

void main() {
  group('PostType', () {
    test('fromValue returns correct type for known values', () {
      expect(PostType.fromValue('support'), PostType.support);
      expect(PostType.fromValue('question'), PostType.question);
      expect(PostType.fromValue('tip'), PostType.tip);
      expect(PostType.fromValue('vent'), PostType.vent);
    });

    test('fromValue defaults to support for unknown values', () {
      expect(PostType.fromValue('unknown'), PostType.support);
      expect(PostType.fromValue(null), PostType.support);
      expect(PostType.fromValue(''), PostType.support);
    });

    test('value matches enum name', () {
      expect(PostType.support.value, 'support');
      expect(PostType.question.value, 'question');
      expect(PostType.tip.value, 'tip');
      expect(PostType.vent.value, 'vent');
    });

    test('all values are covered by fromValue', () {
      for (final type in PostType.values) {
        expect(PostType.fromValue(type.value), type);
      }
    });
  });
}
