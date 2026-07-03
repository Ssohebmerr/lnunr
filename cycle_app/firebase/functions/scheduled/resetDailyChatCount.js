'use strict';

const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

/**
 * Resets daily_chat_count for all users at midnight (Asia/Riyadh).
 * Runs before the daily analytics snapshot so counts start fresh each day.
 */
exports.resetDailyChatCounts = onSchedule(
  {
    schedule: '0 0 * * *',
    timeZone: 'Asia/Riyadh',
  },
  async () => {
    const db = admin.firestore();
    const batchSize = 400;
    let lastDoc = null;
    let totalReset = 0;

    // Paginate users with a positive counter to avoid loading the whole collection.
    while (true) {
      let query = db.collection('users')
        .where('daily_chat_count', '>', 0)
        .orderBy('daily_chat_count')
        .limit(batchSize);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snap = await query.get();
      if (snap.empty) break;

      const batch = db.batch();
      for (const doc of snap.docs) {
        batch.update(doc.ref, {
          daily_chat_count: 0,
          dailyChatResetAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      totalReset += snap.size;
      lastDoc = snap.docs[snap.docs.length - 1];

      if (snap.size < batchSize) break;
    }

    console.log(`resetDailyChatCounts: reset ${totalReset} user(s)`);
  },
);
