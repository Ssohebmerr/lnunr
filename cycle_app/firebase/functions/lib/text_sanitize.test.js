'use strict';

const assert = require('assert');
const {
  sanitizePostText,
  sanitizeCommentText,
} = require('../lib/text_sanitize');

assert.strictEqual(sanitizePostText('<b>hi</b>'), 'hi');
assert.strictEqual(sanitizePostText('a\x00b'), 'ab');
assert.strictEqual(sanitizePostText('x'.repeat(2500)).length, 2000);
assert.strictEqual(sanitizeCommentText('y'.repeat(1500)).length, 1000);

console.log('All text_sanitize tests passed.');
