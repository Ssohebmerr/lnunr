/**
 * Lightweight unit checks for play_billing entitlement logic.
 * Run: node play_billing.test.js
 */
const assert = require('assert');
const { isSubscriptionEntitled, parseExpiryDate } = require('./play_billing');

function test(name, fn) {
  try {
    fn();
    console.log(`✓ ${name}`);
  } catch (e) {
    console.error(`✗ ${name}`);
    throw e;
  }
}

const future = Date.now() + 7 * 24 * 60 * 60 * 1000;
const past = Date.now() - 1000;

test('active paid subscription', () => {
  assert.strictEqual(
    isSubscriptionEntitled(
      { paymentState: 1, expiryTimeMillis: String(future) },
      new Date(),
    ),
    true,
  );
});

test('expired subscription', () => {
  assert.strictEqual(
    isSubscriptionEntitled(
      { paymentState: 1, expiryTimeMillis: String(past) },
      new Date(),
    ),
    false,
  );
});

test('free trial counts as entitled', () => {
  assert.strictEqual(
    isSubscriptionEntitled(
      { paymentState: 2, expiryTimeMillis: String(future) },
      new Date(),
    ),
    true,
  );
});

test('pending payment is not entitled', () => {
  assert.strictEqual(
    isSubscriptionEntitled(
      { paymentState: 0, expiryTimeMillis: String(future) },
      new Date(),
    ),
    false,
  );
});

test('parseExpiryDate', () => {
  const d = parseExpiryDate({ expiryTimeMillis: String(future) });
  assert.ok(d instanceof Date);
  assert.strictEqual(d.getTime(), future);
});

console.log('All play_billing tests passed.');
