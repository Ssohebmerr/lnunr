// ============================================================================
// scheduled/cleanupStories.js — hourly janitor that deletes expired stories.
// ----------------------------------------------------------------------------
// Stories are 24-hour ephemeral content. The hourly schedule keeps Firestore
// storage bounded without us having to delete inline (which would slow down
// `onStoryCreated`). The check is per-community so a single hot community
// cannot exhaust function memory.
// ============================================================================

'use strict';

const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

exports.cleanupExpiredStories = onSchedule(
  { schedule: 'every 1 hours', timeoutSeconds: 120, memory: '256MiB' },
  async (event) => {
    const now = admin.firestore.Timestamp.now();
    const communitiesSnap = await admin.firestore().collection('communities').get();
    let totalDeleted = 0;

    for (const community of communitiesSnap.docs) {
      try {
        const expiredSnap = await community.ref
          .collection('stories')
          .where('expiresAt', '<=', now)
          .limit(100)
          .get();

        if (expiredSnap.empty) continue;

        const batch = admin.firestore().batch();
        expiredSnap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        totalDeleted += expiredSnap.size;
        console.log(`Cleaned ${expiredSnap.size} expired stories from community ${community.id}`);
      } catch (e) {
        console.error(`Error cleaning stories for community ${community.id}:`, e);
      }
    }

    console.log(`Story cleanup complete. Total deleted: ${totalDeleted}`);
  },
);