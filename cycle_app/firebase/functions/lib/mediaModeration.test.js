'use strict';

const assert = require('assert');
const {
  parseFirebaseMediaUrl,
  classifyVisionSignals,
} = require('./mediaModeration');

const encodedUrl =
  'https://firebasestorage.googleapis.com/v0/b/lune.appspot.com/o/' +
  'community_media%2Fpcos%2Fuser-1%2F1700000000000.jpg?alt=media&token=x';

const parsed = parseFirebaseMediaUrl(encodedUrl, 'pcos', 'user-1');
assert(parsed, 'valid owned media URL should parse');
assert.strictEqual(parsed.bucket, 'lune.appspot.com');
assert.strictEqual(parsed.objectPath, 'community_media/pcos/user-1/1700000000000.jpg');
assert.strictEqual(parsed.fileName, '1700000000000.jpg');
assert.strictEqual(parseFirebaseMediaUrl(encodedUrl, 'pcos', 'other-user'), null);
assert.strictEqual(
  parseFirebaseMediaUrl('https://evil.example/image.jpg', 'pcos', 'user-1'),
  null,
);

const safe = classifyVisionSignals({
  safeSearchAnnotation: {
    adult: 'VERY_UNLIKELY',
    racy: 'UNLIKELY',
    violence: 'VERY_UNLIKELY',
    medical: 'LIKELY',
  },
  labelAnnotations: [{ description: 'Ultrasound' }],
});
assert.strictEqual(safe.reject, false);
assert.strictEqual(safe.needsContext, false);

const explicit = classifyVisionSignals({
  safeSearchAnnotation: { adult: 'LIKELY', racy: 'VERY_LIKELY' },
});
assert.strictEqual(explicit.reject, true);

const ambiguous = classifyVisionSignals({
  safeSearchAnnotation: { violence: 'POSSIBLE' },
  fullTextAnnotation: { text: 'A health discussion' },
});
assert.strictEqual(ambiguous.reject, false);
assert.strictEqual(ambiguous.needsContext, true);
assert.strictEqual(ambiguous.detectedText, 'A health discussion');

console.log('mediaModeration tests passed');
