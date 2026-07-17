// ============================================================================
// Firebase Cloud Functions entry point for the Lune app.
// ----------------------------------------------------------------------------
// This file is intentionally tiny. It declares the shared secrets, initialises
// the Admin SDK once, and re-exports every function from its focused module.
//
// File map (post-refactor):
//
//   lib/
//     gemini.js          Gemini REST client + safety settings + callGemini
//     prompts.js         every system prompt + mode/token table
//     moderation.js      moderateContent + buildContextString
//     adminAuth.js       role helpers + path helpers + payload round-trip
//     broadcast.js       sendBroadcastInternal (shared by endpoint + cron)
//
//   endpoints/           HTTP / callable entry points
//     chat.js            POST /chat
//     analyze.js         POST /analyze
//     moderate.js        POST /moderate
//     adminApi.js        POST /adminApi  (action-routed)
//     reprocessModeration.js   POST /reprocessPendingModeration
//     users.js           syncUsersFromAuth + bootstrapAdmin + deleteUserAccount
//     subscriptions.js   verifyPlayPurchase + redeemPromoCode
//                        + grantTesterPremium (QA-gated) + googlePlayWebhook
//                        + syncExpiredPlayPremium
//     broadcast.js       POST /adminBroadcast
//     feedback.js        POST /submitFeedback
//
//   triggers/
//     moderationTriggers.js  onStoryCreated + onPostCreated
//                            + onCommentCreated + onReportCreated
//
//   scheduled/
//     cleanupStories.js       every 1h — prune expired stories
//     drainModeration.js      every 30m — AI-resolve any pending_review content
//     analytics.js            processScheduledBroadcasts (5m)
//                            + dailyAnalyticsSnapshot (00:30 UTC)
//                            + processScheduledContent (15m)
//
// External:
//   play_billing.js      Google Play Android Publisher wrapper + RTDN handler
// ============================================================================

const admin = require('firebase-admin');
const { setGlobalOptions } = require('firebase-functions/v2');

admin.initializeApp();

// ---------------------------------------------------------------------------
// Cost blast-radius cap ("denial of wallet" guard).
// ---------------------------------------------------------------------------
// Without a ceiling, Cloud Functions v2 autoscale to ~1000 instances, so a
// flood can't take the service DOWN (Google absorbs that) but it CAN explode
// the bill. Capping the fleet bounds the worst-case spend. Each v2 instance
// still serves many concurrent requests, so this ceiling comfortably handles
// large legitimate spikes. Raise it only if real traffic ever needs more.
// MUST run before the endpoint modules are required (that's when the functions
// are actually defined), so keep this above the require() calls below.
setGlobalOptions({ maxInstances: 20 });

// ---------------------------------------------------------------------------
// HTTP / callable endpoints
// ---------------------------------------------------------------------------
const chat = require('./endpoints/chat');
const analyze = require('./endpoints/analyze');
const moderate = require('./endpoints/moderate');
const adminApi = require('./endpoints/adminApi');
const reprocessModeration = require('./endpoints/reprocessModeration');
const users = require('./endpoints/users');
const subscriptions = require('./endpoints/subscriptions');
const broadcast = require('./endpoints/broadcast');
const feedback = require('./endpoints/feedback');
const community = require('./endpoints/community');

exports.chat = chat.chat;
exports.analyze = analyze.analyze;
exports.moderate = moderate.moderate;
exports.adminApi = adminApi.adminApi;
exports.reprocessPendingModeration = reprocessModeration.reprocessPendingModeration;
exports.syncUsersFromAuth = users.syncUsersFromAuth;
exports.bootstrapAdmin = users.bootstrapAdmin;
exports.deleteUserAccount = users.deleteUserAccount;
exports.purgeAiData = users.purgeAiData;
exports.verifyPlayPurchase = subscriptions.verifyPlayPurchase;
exports.redeemPromoCode = subscriptions.redeemPromoCode;
exports.grantTesterPremium = subscriptions.grantTesterPremium;
exports.googlePlayWebhook = subscriptions.googlePlayWebhook;
exports.syncExpiredPlayPremium = subscriptions.syncExpiredPlayPremium;
exports.adminBroadcast = broadcast.adminBroadcast;
exports.submitFeedback = feedback.submitFeedback;
exports.submitCommunity = community.submitCommunity;

// ---------------------------------------------------------------------------
// Firestore triggers
// ---------------------------------------------------------------------------
const moderationTriggers = require('./triggers/moderationTriggers');
const communityNotifications = require('./triggers/communityNotifications');
const communityMediaCleanup = require('./triggers/communityMediaCleanup');

exports.onStoryCreated = moderationTriggers.onStoryCreated;
exports.onPostCreated = moderationTriggers.onPostCreated;
exports.onCommentCreated = moderationTriggers.onCommentCreated;
exports.onReportCreated = moderationTriggers.onReportCreated;
exports.onCommentApproved = communityNotifications.onCommentApproved;
exports.onCommentPublished = communityNotifications.onCommentPublished;
exports.onCommentDeleted = communityNotifications.onCommentDeleted;
exports.onPostLiked = communityNotifications.onPostLiked;
exports.onCommentLiked = communityNotifications.onCommentLiked;
exports.onCommentUnliked = communityNotifications.onCommentUnliked;
exports.onUserFollowed = communityNotifications.onUserFollowed;
exports.onCommunityPostDeleted = communityMediaCleanup.onCommunityPostDeleted;
exports.onCommunityStoryDeleted = communityMediaCleanup.onCommunityStoryDeleted;

// ---------------------------------------------------------------------------
// Scheduled jobs
// ---------------------------------------------------------------------------
const cleanupStories = require('./scheduled/cleanupStories');
const analytics = require('./scheduled/analytics');
const resetDailyChatCount = require('./scheduled/resetDailyChatCount');
const drainModeration = require('./scheduled/drainModeration');

exports.cleanupExpiredStories = cleanupStories.cleanupExpiredStories;
exports.processScheduledBroadcasts = analytics.processScheduledBroadcasts;
exports.dailyAnalyticsSnapshot = analytics.dailyAnalyticsSnapshot;
exports.processScheduledContent = analytics.processScheduledContent;
exports.resetDailyChatCounts = resetDailyChatCount.resetDailyChatCounts;
exports.drainPendingModeration = drainModeration.drainPendingModeration;
