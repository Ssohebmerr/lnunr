'use strict';

const assert = require('node:assert/strict');
const { assertAiEligibility, QuotaError } = require('./chat_quota');

function expectQuotaError(data, code) {
  assert.throws(
    () => assertAiEligibility(data),
    (error) => error instanceof QuotaError
      && error.code === code
      && error.status === 403,
  );
}

expectQuotaError({}, 'adult_required');
expectQuotaError({ aiAgeGroup: 'teen', aiConsentGranted: true }, 'adult_required');
expectQuotaError({ aiAgeGroup: 'adult' }, 'consent_required');
expectQuotaError({
  aiAgeGroup: 'adult',
  aiConsentGranted: true,
  aiConsentVersion: 2,
}, 'consent_required');

assert.doesNotThrow(() => assertAiEligibility({
  aiAgeGroup: 'adult',
  aiConsentGranted: true,
  aiConsentVersion: 1,
}));

expectQuotaError({
  aiAgeGroup: 'adult',
  aiConsentGranted: true,
  aiConsentVersion: 1,
  communityBirthYear: 2012,
}, 'adult_required');

console.log('chat_quota eligibility tests passed');
