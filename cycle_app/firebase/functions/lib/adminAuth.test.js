'use strict';

const assert = require('assert');

const {
  ACTION_MIN_ROLE,
  isBlockedWritePath,
  isAllowedModeratorQueryPath,
  assertWritableAdminPath,
} = require('./adminAuth');

assert.strictEqual(
  isBlockedWritePath(['educationArticles', 'cycle-basics']),
  false,
  'array document paths used by the web panel must remain writable',
);
assert.strictEqual(
  isBlockedWritePath(['admins', 'uid-1']),
  true,
  'protected collections must remain blocked for generic writes',
);
assert.doesNotThrow(() => {
  assertWritableAdminPath(['communities', 'general', 'posts', 'post-1'], 'admin');
});
assert.throws(
  () => assertWritableAdminPath(['communityPrivateAuth', 'general'], 'owner'),
  /not permitted/,
);

assert.strictEqual(isAllowedModeratorQueryPath(['communityReports'], null), true);
assert.strictEqual(isAllowedModeratorQueryPath(['aiReports'], null), true);
assert.strictEqual(isAllowedModeratorQueryPath(null, 'posts'), true);
assert.strictEqual(isAllowedModeratorQueryPath(['users'], null), false);

assert.strictEqual(ACTION_MIN_ROLE.moderateCommunityContent, 'moderator');
assert.strictEqual(ACTION_MIN_ROLE.handleAdminReport, 'moderator');
assert.strictEqual(ACTION_MIN_ROLE.setCommunityUserBan, 'moderator');

console.log('adminAuth tests passed');
