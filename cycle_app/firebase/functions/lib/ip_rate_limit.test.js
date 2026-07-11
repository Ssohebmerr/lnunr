/**
 * Unit checks for IP rate-limit helpers.
 * Run: node lib/ip_rate_limit.test.js
 */
const assert = require('assert');
const {
  clientIp,
  ipDocId,
  BUCKET_LIMITS,
} = require('./ip_rate_limit');

function test(name, fn) {
  try {
    fn();
    console.log(`✓ ${name}`);
  } catch (e) {
    console.error(`✗ ${name}`);
    throw e;
  }
}

test('clientIp prefers x-forwarded-for first hop', () => {
  const ip = clientIp({
    headers: { 'x-forwarded-for': '203.0.113.5, 10.0.0.1' },
    ip: '127.0.0.1',
  });
  assert.strictEqual(ip, '203.0.113.5');
});

test('clientIp falls back to req.ip', () => {
  const ip = clientIp({ headers: {}, ip: '198.51.100.9' });
  assert.strictEqual(ip, '198.51.100.9');
});

test('ipDocId is stable and bucket-scoped', () => {
  const a = ipDocId('203.0.113.5', 'ai');
  const b = ipDocId('203.0.113.5', 'ai');
  const c = ipDocId('203.0.113.5', 'community');
  assert.strictEqual(a, b);
  assert.notStrictEqual(a, c);
  assert.match(a, /^[a-f0-9]{32}_ai$/);
});

test('bucket limits include ai and generic', () => {
  assert.strictEqual(BUCKET_LIMITS.ai.max, 150);
  assert.strictEqual(BUCKET_LIMITS.generic.max, 100);
});

console.log('\nAll ip_rate_limit tests passed.');
