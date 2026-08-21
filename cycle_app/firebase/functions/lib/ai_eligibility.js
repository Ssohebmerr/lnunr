'use strict';

const AGE_RANK = {
  unknown: 0,
  under13: 1,
  teen: 2,
  adult: 3,
};

/**
 * Approximate age from community birth year (self-attested but write-once
 * in Firestore rules — stronger than a mutable SharedPreferences mirror).
 */
function ageFromBirthYear(birthYear) {
  if (typeof birthYear !== 'number' || birthYear < 1940 || birthYear > 2100) {
    return null;
  }
  const yearNow = new Date().getUTCFullYear();
  return yearNow - birthYear;
}

function ageGroupFromBirthYear(birthYear) {
  const age = ageFromBirthYear(birthYear);
  if (age == null) return null;
  if (age >= 18) return 'adult';
  if (age >= 13) return 'teen';
  return 'under13';
}

/**
 * Resolve the age group the server will persist.
 *
 * Priority:
 *   1. communityBirthYear (authoritative when present)
 *   2. Existing server aiAgeGroup with no elevation from client declaration
 *   3. First-write declaredAgeGroup from the age gate (write-once)
 *
 * Declared "adult" without a birth year is allowed only as the initial value
 * (age-gate attestation). Later elevation teen→adult requires birth year.
 *
 * @param {object} existing users/{uid} data
 * @param {string|undefined} declaredAgeGroup from client age gate
 * @returns {string}
 */
function resolveAiAgeGroup(existing, declaredAgeGroup) {
  const fromBirth = ageGroupFromBirthYear(existing.communityBirthYear);
  if (fromBirth) return fromBirth;

  const existingGroup =
    typeof existing.aiAgeGroup === 'string' ? existing.aiAgeGroup : 'unknown';
  const declared =
    typeof declaredAgeGroup === 'string' ? declaredAgeGroup : 'unknown';
  const allowed = new Set(['unknown', 'under13', 'teen', 'adult']);
  const next = allowed.has(declared) ? declared : 'unknown';

  if (!existingGroup || existingGroup === 'unknown') {
    return next;
  }

  // Never elevate without birth-year proof.
  if ((AGE_RANK[next] || 0) > (AGE_RANK[existingGroup] || 0)) {
    return existingGroup;
  }
  return next;
}

/**
 * Extra gate used by chat quota: if a birth year exists, it must prove adult.
 */
function birthYearBlocksAdultAi(data) {
  const fromBirth = ageGroupFromBirthYear(data.communityBirthYear);
  return fromBirth != null && fromBirth !== 'adult';
}

module.exports = {
  ageFromBirthYear,
  ageGroupFromBirthYear,
  resolveAiAgeGroup,
  birthYearBlocksAdultAi,
  AGE_RANK,
};
