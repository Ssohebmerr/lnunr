import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/core/config/app_secrets.dart';
import 'package:cycle_aura/features/community/data/community_constants.dart';

void main() {
  group('AppSecrets', () {
    test('cloudFunctionsUrl is configured', () {
      expect(AppSecrets.cloudFunctionsUrl, isNotEmpty);
      expect(AppSecrets.cloudFunctionsUrl, startsWith('https://'));
    });
  });

  group('communityAllowedBirthYears', () {
    test('returns non-empty list', () {
      final years = communityAllowedBirthYears();
      expect(years, isNotEmpty);
    });

    test('all years satisfy isCommunityAdultBirthYear', () {
      final years = communityAllowedBirthYears();
      for (final y in years) {
        expect(isCommunityAdultBirthYear(y), isTrue,
            reason: 'Year $y should be an adult year');
      }
    });

    test('first year is the max adult birth year', () {
      final years = communityAllowedBirthYears();
      expect(years.first, communityMaxAdultBirthYear());
    });

    test('years are in descending order', () {
      final years = communityAllowedBirthYears();
      for (var i = 0; i < years.length - 1; i++) {
        expect(years[i], greaterThan(years[i + 1]),
            reason: 'Years should be descending');
      }
    });

    test('years are within valid range', () {
      final years = communityAllowedBirthYears();
      for (final y in years) {
        expect(y, greaterThanOrEqualTo(kCommunityMinBirthYear));
        expect(y, lessThanOrEqualTo(kCommunityMaxBirthYearFirestore));
      }
    });
  });

  group('communityMaxAdultBirthYear', () {
    test('returns a year that makes user 18+', () {
      final maxYear = communityMaxAdultBirthYear();
      final age = DateTime.now().year - maxYear;
      expect(age, greaterThanOrEqualTo(18));
    });

    test('does not exceed kCommunityMaxBirthYearFirestore', () {
      final maxYear = communityMaxAdultBirthYear();
      expect(maxYear, lessThanOrEqualTo(kCommunityMaxBirthYearFirestore));
    });
  });

  group('isCommunityAdultBirthYear', () {
    test('returns true for valid adult years', () {
      final year = DateTime.now().year - 25;
      expect(isCommunityAdultBirthYear(year), isTrue);
    });

    test('returns false for years below minimum', () {
      expect(isCommunityAdultBirthYear(1939), isFalse);
    });

    test('returns false for minor years', () {
      final year = DateTime.now().year - 16;
      expect(isCommunityAdultBirthYear(year), isFalse);
    });

    test('returns false for future years', () {
      expect(isCommunityAdultBirthYear(2030), isFalse);
    });
  });
}
