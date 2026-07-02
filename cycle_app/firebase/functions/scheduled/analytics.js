// ============================================================================
// scheduled/analytics.js — three cron jobs sharing the analytics domain.
// ----------------------------------------------------------------------------
//   - processScheduledBroadcasts  every 5 min  — drain `scheduledBroadcasts`
//                                                whose `scheduledFor` is past.
//   - dailyAnalyticsSnapshot      daily 00:30 UTC — write `analyticsDaily/{date}`.
//   - processScheduledContent     every 15 min  — publish articles/banners
//                                                whose `scheduledPublishAt` is past.
//
// Sharing a file is fine because:
//   - All three are pure-server background work (no user input).
//   - All three touch similar `analyticsDaily` / `scheduled*` collections.
//   - Combined they're well under 200 lines.
// ============================================================================

'use strict';

const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

const { sendBroadcastInternal } = require('../lib/broadcast');

// ---------------------------------------------------------------------------
// processScheduledBroadcasts — every 5 minutes.
// ---------------------------------------------------------------------------
exports.processScheduledBroadcasts = onSchedule(
  'every 5 minutes',
  async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const snap = await db.collection('scheduledBroadcasts')
      .where('sent', '==', false)
      .where('scheduledFor', '<=', now)
      .limit(20)
      .get();
    if (snap.empty) {
      console.log('processScheduledBroadcasts: nothing due');
      return;
    }
    for (const doc of snap.docs) {
      const data = doc.data();
      try {
        const result = await sendBroadcastInternal({
          title: data.title,
          body: data.body,
          audience: data.audience || 'all',
          segment: data.segment,
          country: data.country,
          sentBy: data.createdBy || 'scheduler',
        });
        await doc.ref.update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          result,
        });
        console.log('Sent scheduled broadcast', doc.id, result);
      } catch (e) {
        console.error('Failed to send scheduled broadcast', doc.id, e);
        await doc.ref.update({
          error: e.message || String(e),
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
  },
);

// ---------------------------------------------------------------------------
// dailyAnalyticsSnapshot — every day at 00:30 UTC.
// Mirrors the body of the adminApi `runSnapshotNow` action so the
// dashboard and the cron agree on the snapshot shape.
// ---------------------------------------------------------------------------
exports.dailyAnalyticsSnapshot = onSchedule(
  '30 0 * * *',
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const dayKey = now.toISOString().slice(0, 10);
    const dayStart = new Date(`${dayKey}T00:00:00Z`);
    const dayPrev = new Date(dayStart.getTime() - 24 * 3600 * 1000);
    const sevenDaysAgo = new Date(dayStart.getTime() - 7 * 24 * 3600 * 1000);

    const [users, premium, posts, articles, pending, newToday, newPremiumToday, signups7d, dauApprox] = await Promise.all([
      db.collection('users').count().get(),
      db.collection('users').where('isPremium', '==', true).count().get(),
      db.collectionGroup('posts').count().get(),
      db.collection('educationArticles').where('published', '==', true).count().get(),
      db.collection('communityReports').where('status', '==', 'pending').count().get(),
      db.collection('users')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(dayPrev))
        .count().get().catch(() => ({ data: () => ({ count: 0 }) })),
      db.collection('users')
        .where('premiumSince', '>=', dayPrev.toISOString())
        .count().get().catch(() => ({ data: () => ({ count: 0 }) })),
      db.collection('users')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
        .count().get().catch(() => ({ data: () => ({ count: 0 }) })),
      db.collection('users')
        .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(dayPrev))
        .count().get().catch(() => ({ data: () => ({ count: 0 }) })),
    ]);

    const snapshot = {
      date: dayKey,
      users: users.data().count,
      premium: premium.data().count,
      posts: posts.data().count,
      articles: articles.data().count,
      pendingReports: pending.data().count,
      newUsersToday: newToday.data().count,
      newPremiumToday: newPremiumToday.data().count,
      newUsers7d: signups7d.data().count,
      dau: dauApprox.data().count,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await db.collection('analyticsDaily').doc(dayKey).set(snapshot, { merge: true });
    console.log('analyticsDaily saved', dayKey, snapshot);
  },
);

// ---------------------------------------------------------------------------
// processScheduledContent — every 15 minutes.
// Publishes articles and banners whose `scheduledPublishAt` is now or past.
// ---------------------------------------------------------------------------
exports.processScheduledContent = onSchedule(
  'every 15 minutes',
  async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const articles = await db.collection('educationArticles')
      .where('published', '==', false)
      .where('scheduledPublishAt', '<=', now)
      .limit(50).get();

    for (const doc of articles.docs) {
      try {
        await doc.ref.update({
          published: true,
          publishedAt: admin.firestore.FieldValue.serverTimestamp(),
          scheduledPublishAt: admin.firestore.FieldValue.delete(),
        });
        console.log('Published scheduled article', doc.id);
      } catch (e) {
        console.warn('Failed to publish article', doc.id, e.message);
      }
    }

    const banners = await db.collection('appBanners')
      .where('published', '==', false)
      .where('scheduledPublishAt', '<=', now)
      .limit(50).get();
    for (const doc of banners.docs) {
      try {
        await doc.ref.update({
          published: true,
          publishedAt: admin.firestore.FieldValue.serverTimestamp(),
          scheduledPublishAt: admin.firestore.FieldValue.delete(),
        });
        console.log('Published scheduled banner', doc.id);
      } catch (e) {
        console.warn('Failed to publish banner', doc.id, e.message);
      }
    }
  },
);