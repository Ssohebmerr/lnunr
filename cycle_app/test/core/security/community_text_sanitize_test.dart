import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/core/security/community_text_sanitize.dart';

void main() {
  group('CommunityTextSanitize', () {
    test('strips HTML tags', () {
      expect(
        CommunityTextSanitize.post('<b>hello</b> world'),
        'hello world',
      );
    });

    test('removes control characters', () {
      expect(
        CommunityTextSanitize.post('hi\x00there'),
        'hithere',
      );
    });

    test('caps post length at 2000', () {
      final raw = 'a' * 2500;
      expect(CommunityTextSanitize.post(raw).length, 2000);
    });

    test('caps comment length at 1000', () {
      final raw = 'b' * 1500;
      expect(CommunityTextSanitize.comment(raw).length, 1000);
    });
  });
}
