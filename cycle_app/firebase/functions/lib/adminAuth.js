// ============================================================================
// lib/adminAuth.js — admin role checks + Firestore path + token helpers.
// ----------------------------------------------------------------------------
// Three groups of helpers that share the same domain (admin / Firestore
// payloads) so it makes sense to colocate them:
//
//   1. ROLE HIERARCHY
//      verifyCallerIsAdmin / getCallerRole / callerHasRole. The hierarchy is
//      owner > admin > moderator. Owners are recognised via a custom claim
//      (`decoded.admin === true`) set by `bootstrapAdmin`; admins and mods
//      via the `admins/{uid}` collection.
//
//   2. FIRESTORE PATH UTILS
//      refFromPath / collectionFromPath / docFromPath — used by the admin
//      API's "query a path the client provides" actions. The admin API lets
//      the client say `users/abc/cycle_logs` and we turn that into a typed
//      Firestore reference. Path validity is enforced (odd length =
//      collection, even length = document).
//
//   3. PAYLOAD ROUND-TRIP
//      serializeFirestoreValue / serializeDoc / applyServerTokens — used by
//      the admin API so that:
//        - Admin SDK writes can carry `serverTimestamp()` / `delete()` markers
//          in plain JSON (the client uses `__serverTimestamp: true` and
//          `__delete: true`).
//        - Admin SDK reads can return Timestamp values to the client in a
//          JSON-safe form (so `timestamp.toDate().toISOString()`).
// ============================================================================

'use strict';

const admin = require('firebase-admin');

const ROLE_RANK = { owner: 3, admin: 2, moderator: 1 };

const MAX_ADMIN_QUERY_LIMIT = 500;

const MODERATOR_QUERY_PREFIXES = [
  'communityReports',
  'aiReports',
  'anonymousQuestions',
  'educationArticles',
  'appBanners',
  'communityCatalog',
  'adminBroadcasts',
  'adminActivityLog',
];

const BLOCKED_WRITE_PREFIXES = [
  'admins',
  'communityPrivateAuth',
  'communityRateLimits',
  'communityContentHashes',
];

function pathSegments(path) {
  if (Array.isArray(path)) {
    return path
      .map((segment) => String(segment || '').trim())
      .filter(Boolean);
  }
  if (!path || typeof path !== 'string') return [];
  return path.split('/').map((segment) => segment.trim()).filter(Boolean);
}

function isBlockedWritePath(path) {
  const segments = pathSegments(path);
  if (segments.length === 0) return true;
  return BLOCKED_WRITE_PREFIXES.includes(segments[0]);
}

function isAllowedModeratorQueryPath(collectionPath, collectionGroup) {
  if (collectionGroup) {
    return ['posts', 'comments'].includes(collectionGroup);
  }
  const segments = Array.isArray(collectionPath)
    ? collectionPath
    : pathSegments(collectionPath);
  if (segments.length === 0) return false;
  return MODERATOR_QUERY_PREFIXES.includes(segments[0]);
}

function assertWritableAdminPath(path, role) {
  if (isBlockedWritePath(path)) {
    throw new Error('Writes to this path are not permitted.');
  }
  const segments = pathSegments(path);
  if (segments[0] === 'admins' && role !== 'owner') {
    throw new Error('Only owners may modify admin records.');
  }
}

// Action → minimum required role (for adminApi action gating)
const ACTION_MIN_ROLE = {
  // moderator can do these
  overview: 'moderator',
  query: 'moderator',
  count: 'moderator',
  get: 'moderator',
  analyticsHistory: 'moderator',
  aiUsageStats: 'moderator',
  aiCostStats: 'moderator',
  moderateCommunityContent: 'moderator',
  handleAdminReport: 'moderator',
  setCommunityUserBan: 'moderator',
  // admin and above
  set: 'admin',
  update: 'admin',
  delete: 'admin',
  add: 'admin',
  setUserPremium: 'admin',
  createPromoCode: 'admin',
  revokePromoCode: 'admin',
  scheduleBroadcast: 'admin',
  cancelScheduledBroadcast: 'admin',
  segmentPreview: 'admin',
  replyToFeedback: 'admin',
  runSnapshotNow: 'admin',
  translateText: 'admin',
  // owner only
  setAdminRole: 'owner',
  removeAdmin: 'owner',
};

// ---------------------------------------------------------------------------
// Role helpers
// ---------------------------------------------------------------------------

/**
 * Returns true when the decoded token belongs to an admin/owner/moderator.
 *
 * Order of recognition (cheap → expensive):
 *   1. `decoded.admin === true` custom claim — set by bootstrapAdmin, never
 *      depends on Firestore.
 *   2. `admins/{uid}` document existence (any role). This collection is
 *      writable ONLY through the Admin SDK (rules: `allow write: if false`).
 *
 * SECURITY: `users/{uid}.isAdmin` is deliberately NOT consulted. Users can
 * update parts of their own document, so a self-writable flag must never be
 * a source of authority (privilege-escalation vector, fixed).
 */
async function verifyCallerIsAdmin(decoded) {
  if (decoded.admin === true) return true;
  const adminDoc = await admin.firestore().collection('admins').doc(decoded.uid).get();
  return adminDoc.exists;
}

/**
 * Returns the caller's effective role: 'owner' | 'admin' | 'moderator' | null.
 * Same trusted sources as verifyCallerIsAdmin — claim first, then admins/.
 */
async function getCallerRole(decoded) {
  if (decoded.admin === true) return 'owner';
  const adminDoc = await admin.firestore().collection('admins').doc(decoded.uid).get();
  if (adminDoc.exists) {
    const role = adminDoc.data()?.role;
    if (['owner', 'admin', 'moderator'].includes(role)) return role;
    return 'admin'; // default if doc exists without explicit role
  }
  return null;
}

/**
 * True when the caller's role rank is at least `requiredRole`'s rank.
 */
async function callerHasRole(decoded, requiredRole) {
  const role = await getCallerRole(decoded);
  if (!role) return false;
  return (ROLE_RANK[role] || 0) >= (ROLE_RANK[requiredRole] || 0);
}

// ---------------------------------------------------------------------------
// Firestore path helpers — turn ["users","abc","cycle_logs","x"] into a
// chained CollectionReference/DocumentReference.
// ---------------------------------------------------------------------------

function refFromPath(pathSegments) {
  let ref = admin.firestore();
  for (let i = 0; i < pathSegments.length; i += 1) {
    ref = (i % 2 === 0) ? ref.collection(pathSegments[i]) : ref.doc(pathSegments[i]);
  }
  return ref;
}

function collectionFromPath(pathSegments) {
  if (!pathSegments?.length || pathSegments.length % 2 !== 1) {
    throw new Error('Invalid collection path');
  }
  return refFromPath(pathSegments);
}

function docFromPath(pathSegments) {
  if (!pathSegments?.length || pathSegments.length % 2 !== 0) {
    throw new Error('Invalid document path');
  }
  return refFromPath(pathSegments);
}

// ---------------------------------------------------------------------------
// Payload round-trip — Admin SDK ↔ client JSON.
// ---------------------------------------------------------------------------

function serializeFirestoreValue(v) {
  if (v === null || v === undefined) return v;
  if (v instanceof admin.firestore.Timestamp) {
    return { __type: 'timestamp', iso: v.toDate().toISOString() };
  }
  if (Array.isArray(v)) return v.map(serializeFirestoreValue);
  if (typeof v === 'object' && v.constructor === Object) {
    const out = {};
    for (const [k, val] of Object.entries(v)) out[k] = serializeFirestoreValue(val);
    return out;
  }
  return v;
}

function serializeDoc(docSnap) {
  return {
    id: docSnap.id,
    path: docSnap.ref.path,
    ...serializeFirestoreValue(docSnap.data()),
  };
}

/**
 * Recursively walk a payload and convert `__serverTimestamp: true` /
 * `__delete: true` markers into FieldValue sentinels the Admin SDK can apply.
 */
function applyServerTokens(data) {
  if (data === null || data === undefined) return data;
  if (data.__serverTimestamp === true) return admin.firestore.FieldValue.serverTimestamp();
  if (data.__delete === true) return admin.firestore.FieldValue.delete();
  if (Array.isArray(data)) return data.map(applyServerTokens);
  if (typeof data === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(data)) out[k] = applyServerTokens(v);
    return out;
  }
  return data;
}

module.exports = {
  ROLE_RANK,
  ACTION_MIN_ROLE,
  verifyCallerIsAdmin,
  getCallerRole,
  callerHasRole,
  refFromPath,
  collectionFromPath,
  docFromPath,
  serializeFirestoreValue,
  serializeDoc,
  applyServerTokens,
  MAX_ADMIN_QUERY_LIMIT,
  isBlockedWritePath,
  isAllowedModeratorQueryPath,
  assertWritableAdminPath,
};
