// Removes community media and its Storage approval when the owning post or
// story is deleted (including hourly story expiry cleanup).

'use strict';

const { onDocumentDeleted } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

const {
  parseFirebaseMediaUrl,
  deleteMediaAndApproval,
} = require('../lib/mediaModeration');

async function cleanup(event) {
  const data = event.data?.data();
  const mediaUrl = data?.mediaUrl;
  if (!mediaUrl) return;

  const communityId = event.params.communityId;
  const media = parseFirebaseMediaUrl(mediaUrl, communityId);
  if (!media) {
    console.warn(`Skipping malformed media URL for deleted content in ${communityId}`);
    return;
  }
  await deleteMediaAndApproval(admin.firestore(), media);
  console.log(`Deleted community media ${media.objectPath}`);
}

exports.onCommunityPostDeleted = onDocumentDeleted(
  'communities/{communityId}/posts/{postId}',
  cleanup,
);

exports.onCommunityStoryDeleted = onDocumentDeleted(
  'communities/{communityId}/stories/{storyId}',
  cleanup,
);
