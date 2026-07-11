'use strict';

const crypto = require('crypto');
const admin = require('firebase-admin');

/** @type {Record<string, { max: number, windowMs: number }>} */
const BUCKET_LIMITS = {
  // Higher than a single user needs (chat is capped at 30/day server-side) so
  // that many users behind one carrier-grade NAT IP don't trip a false 429.
  ai: { max: 150, windowMs: 60 * 60 * 1000 },
  community: { max: 120, windowMs: 60 * 60 * 1000 },
  auth_heavy: { max: 30, windowMs: 60 * 60 * 1000 },
  feedback: { max: 20, windowMs: 60 * 60 * 1000 },
  // Admin endpoints are already role-gated server-side; a busy moderator
  // fires many queries per session, so keep this generous — it's only an
  // anti-flood backstop, not the real access control.
  admin: { max: 300, windowMs: 60 * 60 * 1000 },
  generic: { max: 100, windowMs: 60 * 60 * 1000 },
};

/**
 * @param {import('express').Request} req
 * @returns {string}
 */
function clientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  if (Array.isArray(forwarded) && forwarded.length > 0) {
    return String(forwarded[0]).trim();
  }
  return req.ip || req.socket?.remoteAddress || 'unknown';
}

/**
 * @param {string} ip
 * @param {string} bucket
 * @returns {string}
 */
function ipDocId(ip, bucket) {
  const hash = crypto.createHash('sha256').update(ip).digest('hex').slice(0, 32);
  return `${hash}_${bucket}`;
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} ip
 * @param {string} bucket
 * @returns {Promise<{ allowed: boolean }>}
 */
async function assertIpAllowed(db, ip, bucket) {
  const config = BUCKET_LIMITS[bucket] || BUCKET_LIMITS.generic;
  const ref = db.collection('ipRateLimits').doc(ipDocId(ip, bucket));
  const now = Date.now();

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() || {};
    const windowStartMs = Number(data.windowStartMs) || 0;
    const count = Number(data.count) || 0;

    if (!windowStartMs || now - windowStartMs >= config.windowMs) {
      tx.set(ref, {
        windowStartMs: now,
        count: 1,
        bucket,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return { allowed: true };
    }

    if (count >= config.max) {
      return { allowed: false };
    }

    tx.set(ref, {
      count: count + 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { allowed: true };
  });
}

module.exports = {
  BUCKET_LIMITS,
  clientIp,
  ipDocId,
  assertIpAllowed,
};
