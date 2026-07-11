/**
 * Lightweight unit checks for play_billing entitlement logic.
 * Run: node play_billing.test.js
 */
const assert = require('assert');
const {
  isSubscriptionEntitled,
  parseExpiryDate,
  assertTokenNotClaimedByOther,
  decodePubSubBody,
} = require('./play_billing');

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

test('decodePubSubBody accepts Pub/Sub envelope only', () => {
  const payload = { subscriptionNotification: { purchaseToken: 'tok' } };
  const encoded = Buffer.from(JSON.stringify(payload)).toString('base64');
  const decoded = decodePubSubBody({ message: { data: encoded } });
  assert.deepStrictEqual(decoded, payload);
});

test('decodePubSubBody rejects raw JSON', () => {
  assert.strictEqual(
    decodePubSubBody({ subscriptionNotification: { purchaseToken: 'tok' } }),
    null,
  );
});

test('assertTokenNotClaimedByOther allows unclaimed token', async () => {
  const db = {
    collection: () => ({
      where: () => ({
        limit: () => ({
          get: async () => ({ empty: true }),
        }),
      }),
    }),
  };
  await assertTokenNotClaimedByOther(db, 'user-a', 'token-1');
});

test('assertTokenNotClaimedByOther allows same owner', async () => {
  const db = {
    collection: () => ({
      where: () => ({
        limit: () => ({
          get: async () => ({ empty: false, docs: [{ id: 'user-a' }] }),
        }),
      }),
    }),
  };
  await assertTokenNotClaimedByOther(db, 'user-a', 'token-1');
});

test('assertTokenNotClaimedByOther rejects other owner', async () => {
  const db = {
    collection: () => ({
      where: () => ({
        limit: () => ({
          get: async () => ({ empty: false, docs: [{ id: 'user-b' }] }),
        }),
      }),
    }),
  };
  await assert.rejects(
    () => assertTokenNotClaimedByOther(db, 'user-a', 'token-1'),
    (err) => err.code === 'token_already_claimed',
  );
});

console.log('All play_billing tests passed.');
