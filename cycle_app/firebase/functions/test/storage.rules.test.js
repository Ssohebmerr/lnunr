'use strict';

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'lune-media-rules-test';

function emulator(name, defaultPort) {
  const value = process.env[name];
  if (!value) return { host: '127.0.0.1', port: defaultPort };
  const [host, port] = value.split(':');
  return { host, port: Number(port) };
}

async function main() {
  const firestoreRules = fs.readFileSync(
    path.resolve(__dirname, '../../../firestore.rules'),
    'utf8',
  );
  const storageRules = fs.readFileSync(
    path.resolve(__dirname, '../../../storage.rules'),
    'utf8',
  );
  const firestore = emulator('FIRESTORE_EMULATOR_HOST', 8080);
  const storage = emulator('FIREBASE_STORAGE_EMULATOR_HOST', 9199);
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: firestoreRules, ...firestore },
    storage: { rules: storageRules, ...storage },
  });

  const communityId = 'pcos';
  const ownerUid = 'owner';
  const fileName = 'image.jpg';
  const objectPath = `community_media/${communityId}/${ownerUid}/${fileName}`;

  try {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      for (const uid of [ownerUid, 'member', 'outsider']) {
        await ctx.firestore().collection('users').doc(uid).set({
          communityBirthYear: 1995,
          communitySetupComplete: true,
          isPremium: true,
        });
      }
      for (const uid of [ownerUid, 'member']) {
        await ctx.firestore().collection('communities').doc(communityId)
          .collection('members').doc(uid).set({ alias: uid });
      }
      await ctx.storage().ref(objectPath)
        .put(new Uint8Array([0xff, 0xd8, 0xff]), { contentType: 'image/jpeg' });
    });

    const owner = testEnv.authenticatedContext(ownerUid);
    const member = testEnv.authenticatedContext('member');
    const outsider = testEnv.authenticatedContext('outsider');

    await assertSucceeds(
      member.firestore().collection('users').doc('member').get(),
    );
    console.log('Seeded Firestore profiles and quarantined object.');
    await assertSucceeds(owner.storage().ref(objectPath).getDownloadURL());
    console.log('Owner can preview quarantined media.');
    await assertFails(member.storage().ref(objectPath).getDownloadURL());
    console.log('Member is blocked before server approval.');

    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('communityMediaApprovals').doc(communityId)
        .collection('owners').doc(ownerUid)
        .collection('files').doc(fileName).set({ approved: true });
    });

    await assertSucceeds(member.storage().ref(objectPath).getDownloadURL());
    console.log('Member can read after server approval.');
    await assertFails(outsider.storage().ref(objectPath).getDownloadURL());

    await assertFails(
      member.firestore().collection('communityMediaApprovals').doc(communityId)
        .collection('owners').doc(ownerUid)
        .collection('files').doc('forged.jpg').set({ approved: true }),
    );

    console.log('All storage.rules media quarantine tests passed.');
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
