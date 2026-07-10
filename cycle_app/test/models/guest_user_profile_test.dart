import 'package:cycle_aura/features/user/data/models/guest_user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GuestUserProfile.toCreatePayload', () {
    test('does not include communityBirthYear', () {
      final payload = const GuestUserProfile(
        uid: 'u1',
        name: 'Luna',
      ).toCreatePayload(
        name: 'Luna',
        birthDate: DateTime(1995, 6, 15),
        deviceId: 'device-1',
      );

      expect(payload.containsKey('communityBirthYear'), isFalse);
      expect(payload['birthDate'], isNotNull);
      expect(payload['name'], 'Luna');
    });
  });
}
