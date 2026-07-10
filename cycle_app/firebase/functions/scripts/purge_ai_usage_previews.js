// One-time privacy migration for historical ai_usage records.
//
// Default is dry-run:
//   node scripts/purge_ai_usage_previews.js
// Apply only after deploying the no-text logging change:
//   node scripts/purge_ai_usage_previews.js --commit
//
// The script removes the legacy `message` preview field while preserving the
// non-sensitive fields used by the admin cost and usage dashboards.

'use strict';

const admin = require('firebase-admin');

admin.initializeApp();

const APPLY = process.argv.includes('--commit');
const PAGE_SIZE = 100;
const BATCH_SIZE = 400;

async function removeLegacyPreviewFields(messagesRef) {
  let changed = 0;
  let last = null;
  while (true) {
    let query = messagesRef.orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE_SIZE);
    if (last) query = query.startAfter(last);
    const snap = await query.get();
    if (snap.empty) break;

    const targets = snap.docs.filter((doc) => Object.hasOwn(doc.data(), 'message'));
    changed += targets.length;
    if (APPLY && targets.length > 0) {
      for (let start = 0; start < targets.length; start += BATCH_SIZE) {
        const batch = admin.firestore().batch();
        targets.slice(start, start + BATCH_SIZE).forEach((doc) => {
          batch.update(doc.ref, { message: admin.firestore.FieldValue.delete() });
        });
        await batch.commit();
      }
    }

    last = snap.docs[snap.docs.length - 1];
    if (snap.size < PAGE_SIZE) break;
  }
  return changed;
}

async function main() {
  const db = admin.firestore();
  let scannedUsers = 0;
  let changedMessages = 0;
  let last = null;

  while (true) {
    let query = db.collection('ai_usage')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE_SIZE);
    if (last) query = query.startAfter(last);
    const users = await query.get();
    if (users.empty) break;

    for (const user of users.docs) {
      scannedUsers += 1;
      changedMessages += await removeLegacyPreviewFields(
        user.ref.collection('messages'),
      );
    }

    last = users.docs[users.docs.length - 1];
    if (users.size < PAGE_SIZE) break;
  }

  console.log(
    `${APPLY ? 'Removed' : 'Would remove'} legacy AI previews from ` +
      `${changedMessages} messages across ${scannedUsers} user records.`,
  );
}

main().catch((error) => {
  console.error('Legacy AI preview purge failed:', error);
  process.exitCode = 1;
});
