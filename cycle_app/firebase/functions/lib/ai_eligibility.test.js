'use strict';

const {
  resolveAiAgeGroup,
  birthYearBlocksAdultAi,
  ageGroupFromBirthYear,
} = require('./ai_eligibility');

function assertEqual(actual, expected, label) {
  if (actual !== expected) {
    throw new Error(`${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

assertEqual(ageGroupFromBirthYear(1990), 'adult', 'adult birth year');
assertEqual(ageGroupFromBirthYear(2012), 'teen', 'teen birth year');
assertEqual(ageGroupFromBirthYear(2018), 'under13', 'child birth year');

assertEqual(
  resolveAiAgeGroup({ communityBirthYear: 1995 }, 'teen'),
  'adult',
  'birth year overrides declared teen',
);

assertEqual(
  resolveAiAgeGroup({}, 'adult'),
  'adult',
  'first write may set adult from age gate',
);

assertEqual(
  resolveAiAgeGroup({ aiAgeGroup: 'teen' }, 'adult'),
  'teen',
  'cannot elevate teen to adult without birth year',
);

assertEqual(
  resolveAiAgeGroup({ aiAgeGroup: 'adult' }, 'teen'),
  'teen',
  'downgrade allowed',
);

assertEqual(birthYearBlocksAdultAi({ communityBirthYear: 2012 }), true, 'teen blocks AI');
assertEqual(birthYearBlocksAdultAi({ communityBirthYear: 1990 }), false, 'adult allows AI');
assertEqual(birthYearBlocksAdultAi({}), false, 'no birth year does not block via birth path');

console.log('All ai_eligibility tests passed.');
