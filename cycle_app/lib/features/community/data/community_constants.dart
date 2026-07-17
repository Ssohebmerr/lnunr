/// Community media uploads — enabled for stories, disabled for posts (Play safety).
const bool kCommunityMediaUploadsEnabled = true;

const int kCommunityStoryMaxMediaBytes = 15 * 1024 * 1024;

bool isCommunityStoryMediaSizeAllowed(int bytes) =>
    bytes > 0 && bytes <= kCommunityStoryMaxMediaBytes;

/// Matches Firestore `birthYearValid()` in firestore.rules.
const int kCommunityMinBirthYear = 1940;
const int kCommunityMaxBirthYearFirestore = 2010;

/// Latest birth year that satisfies the 18+ community gate.
int communityMaxAdultBirthYear() {
  final adultMax = DateTime.now().year - 18;
  return adultMax < kCommunityMaxBirthYearFirestore
      ? adultMax
      : kCommunityMaxBirthYearFirestore;
}

List<int> communityAllowedBirthYears() {
  final max = communityMaxAdultBirthYear();
  if (max < kCommunityMinBirthYear) return const [];
  return [for (var y = max; y >= kCommunityMinBirthYear; y--) y];
}

bool isCommunityAdultBirthYear(int year) {
  return year >= kCommunityMinBirthYear && year <= communityMaxAdultBirthYear();
}
