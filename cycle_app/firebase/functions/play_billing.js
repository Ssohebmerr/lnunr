/**
 * Google Play Billing helpers — subscription verify, RTDN, and Firestore sync.
 *
 * Product ID must match Play Console and `play_billing_service.dart`.
 */
const admin = require('firebase-admin');

const PREMIUM_PRODUCT_IDS = new Set(['premium_monthly']);
const DEFAULT_PACKAGE = 'com.lune.app';

/** @returns {import('googleapis').androidpublisher_v3.Androidpublisher} */
function getAndroidPublisher(serviceAccountJson) {
  const { google } = require('googleapis');
  const credentials =
    typeof serviceAccountJson === 'string'
      ? JSON.parse(serviceAccountJson)
      : serviceAccountJson;
  const auth = new google.auth.GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  return google.androidpublisher({ version: 'v3', auth });
}

async function fetchSubscription(androidPublisher, { packageName, productId, token }) {
  const res = await androidPublisher.purchases.subscriptions.get({
    packageName: packageName || DEFAULT_PACKAGE,
    productId,
    token,
  });
  return res.data;
}

function parseExpiryDate(purchase) {
  const raw = purchase?.expiryTimeMillis;
  if (!raw) return null;
  const ms = Number(raw);
  return Number.isFinite(ms) ? new Date(ms) : null;
}

/**
 * Whether the user should have premium access right now.
 * @param {import('googleapis').androidpublisher_v3.Schema$SubscriptionPurchase} purchase
 */
function isSubscriptionEntitled(purchase, now = new Date()) {
  if (!purchase) return false;

  const expiry = parseExpiryDate(purchase);
  if (expiry && expiry <= now) return false;

  const paymentState = purchase.paymentState;
  // 0=pending, 1=received, 2=free trial, 3=deferred upgrade/downgrade
  if (paymentState === 0) return false;
  if (paymentState === 1 || paymentState === 2 || paymentState === 3) {
    return expiry ? expiry > now : true;
  }

  if (expiry) return expiry > now;
  return purchase.autoRenewing === true;
}

async function acknowledgeSubscription(
  androidPublisher,
  { packageName, productId, token, developerPayload },
  purchase,
) {
  if (purchase?.acknowledgementState === 1) return;
  await androidPublisher.purchases.subscriptions.acknowledge({
    packageName: packageName || DEFAULT_PACKAGE,
    productId,
    token,
    requestBody: { developerPayload: developerPayload || '' },
  });
}

async function findUidByPurchaseToken(db, token) {
  if (!token) return null;
  const snap = await db
    .collection('users')
    .where('playPurchaseToken', '==', token)
    .limit(1)
    .get();
  if (snap.empty) return null;
  return snap.docs[0].id;
}

async function revokeGooglePlayPremium(db, uid, token) {
  const userRef = db.collection('users').doc(uid);
  const existing = (await userRef.get()).data() || {};
  if (
    existing.premiumSource &&
    existing.premiumSource !== 'google_play' &&
    existing.playPurchaseToken !== token
  ) {
    return { revoked: false, skipped: true };
  }

  await userRef.set(
    {
      isPremium: false,
      premiumPending: false,
      premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return { revoked: true };
}

async function applyGooglePlayPremium(db, uid, { productId, token, purchase }) {
  const entitled = isSubscriptionEntitled(purchase);
  const expiry = parseExpiryDate(purchase);
  const userRef = db.collection('users').doc(uid);
  const existing = (await userRef.get()).data() || {};

  if (entitled) {
    await userRef.set(
      {
        isPremium: true,
        premiumSource: 'google_play',
        premiumProductId: productId,
        playPurchaseToken: token,
        playOrderId: purchase.orderId || null,
        premiumExpiry: expiry
          ? admin.firestore.Timestamp.fromDate(expiry)
          : null,
        premiumSince: existing.premiumSince || new Date().toISOString(),
        premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        premiumPending: false,
      },
      { merge: true },
    );
    return { entitled: true, uid, expiryMillis: expiry?.getTime() ?? null };
  }

  if (
    !existing.premiumSource ||
    existing.premiumSource === 'google_play' ||
    existing.playPurchaseToken === token
  ) {
    await userRef.set(
      {
        isPremium: false,
        premiumPending: false,
        premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  return { entitled: false, uid };
}

/**
 * Verify a subscription with Play Developer API and sync Firestore.
 */
async function processPlaySubscription(
  db,
  androidPublisher,
  { uid, productId, token, packageName },
) {
  if (!PREMIUM_PRODUCT_IDS.has(productId)) {
    throw new Error(`Unknown subscription product: ${productId}`);
  }
  if (!token) {
    throw new Error('Missing purchase token');
  }

  let purchase;
  try {
    purchase = await fetchSubscription(androidPublisher, {
      packageName,
      productId,
      token,
    });
  } catch (error) {
    if (error?.code === 410 || error?.response?.status === 410) {
      const resolvedUid = uid || (await findUidByPurchaseToken(db, token));
      if (resolvedUid) {
        await revokeGooglePlayPremium(db, resolvedUid, token);
      }
      return { entitled: false, expired: true, uid: resolvedUid };
    }
    throw error;
  }

  const resolvedUid = uid || (await findUidByPurchaseToken(db, token));

  if (isSubscriptionEntitled(purchase)) {
    await acknowledgeSubscription(
      androidPublisher,
      {
        packageName,
        productId,
        token,
        developerPayload: resolvedUid || '',
      },
      purchase,
    );
  }

  if (!resolvedUid) {
    console.warn(
      'Play billing: verified subscription but no Firebase uid yet for token',
      token.slice(0, 10),
    );
    return {
      entitled: isSubscriptionEntitled(purchase),
      uid: null,
      pendingUidLink: true,
    };
  }

  return applyGooglePlayPremium(db, resolvedUid, {
    productId,
    token,
    purchase,
  });
}

/** RTDN notificationType values that revoke access immediately. */
const RTDN_REVOKE_TYPES = new Set([
  12, // SUBSCRIPTION_REVOKED (refund)
  13, // SUBSCRIPTION_EXPIRED
]);

/**
 * Handle a decoded Real-Time Developer Notification payload.
 */
async function handleRtdnMessage(db, androidPublisher, envelope) {
  if (envelope?.testNotification) {
    console.log('Play RTDN test notification received');
    return { ok: true, test: true };
  }

  const sub = envelope?.subscriptionNotification;
  if (!sub) {
    console.log('Play RTDN: ignored non-subscription message');
    return { ok: true, skipped: true };
  }

  const { notificationType, purchaseToken, subscriptionId } = sub;
  const packageName = envelope.packageName || DEFAULT_PACKAGE;
  const uid = await findUidByPurchaseToken(db, purchaseToken);

  if (RTDN_REVOKE_TYPES.has(notificationType)) {
    if (uid) {
      await revokeGooglePlayPremium(db, uid, purchaseToken);
    }
    return { ok: true, revoked: true, uid, notificationType };
  }

  const result = await processPlaySubscription(db, androidPublisher, {
    uid,
    productId: subscriptionId,
    token: purchaseToken,
    packageName,
  });
  return { ok: true, notificationType, ...result };
}

/**
 * Decode Pub/Sub push envelope or raw JSON body from googlePlayWebhook.
 */
function decodePubSubBody(body) {
  if (!body || typeof body !== 'object') return null;

  if (body.message?.data) {
    const json = Buffer.from(body.message.data, 'base64').toString('utf8');
    return JSON.parse(json);
  }

  if (body.subscriptionNotification || body.testNotification) {
    return body;
  }

  return null;
}

/**
 * Nightly safety net: revoke Play premium past expiry.
 */
async function revokeExpiredPlayPremium(db, limit = 200) {
  const now = admin.firestore.Timestamp.now();
  const snap = await db
    .collection('users')
    .where('premiumSource', '==', 'google_play')
    .where('isPremium', '==', true)
    .where('premiumExpiry', '<', now)
    .limit(limit)
    .get();

  if (snap.empty) return { revoked: 0 };

  const batch = db.batch();
  for (const doc of snap.docs) {
    batch.set(
      doc.ref,
      {
        isPremium: false,
        premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  await batch.commit();
  return { revoked: snap.size };
}

module.exports = {
  PREMIUM_PRODUCT_IDS,
  DEFAULT_PACKAGE,
  getAndroidPublisher,
  fetchSubscription,
  isSubscriptionEntitled,
  parseExpiryDate,
  processPlaySubscription,
  handleRtdnMessage,
  decodePubSubBody,
  revokeExpiredPlayPremium,
  findUidByPurchaseToken,
};
