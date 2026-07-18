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
  const freeUid = 'free-member';
  const fileName = 'image.jpg';
  const objectPath = `community_media/${communityId}/${ownerUid}/${fileName}`;

  try {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      for (const uid of [ownerUid, 'member', 'outsider', freeUid]) {
        await ctx.firestore().collection('users').doc(uid).set({
          communityBirthYear: 1995,
          communitySetupComplete: true,
          isPremium: uid !== freeUid,
        });
      }
      for (const uid of [ownerUid, 'member', freeUid]) {
        await ctx.firestore().collection('communities').doc(communityId)
          .collection('members').doc(uid).set({ alias: uid });
      }
      await ctx.firestore().collection('admins').doc('editor').set({
        role: 'admin',
      });
      await ctx.storage().ref(objectPath)
        .put(new Uint8Array([0xff, 0xd8, 0xff]), { contentType: 'image/jpeg' });
    });

    const owner = testEnv.authenticatedContext(ownerUid);
    const member = testEnv.authenticatedContext('member');
    const outsider = testEnv.authenticatedContext('outsider');
    const freeMember = testEnv.authenticatedContext(freeUid);

    await assertSucceeds(
      freeMember.storage().ref(
        `community_media/${communityId}/${freeUid}/free-post.jpg`,
      ).put(
        new Uint8Array([0xff, 0xd8, 0xff]),
        { contentType: 'image/jpeg' },
      ),
    );
    console.log('Free members can upload post images.');
    await assertFails(
      outsider.storage().ref(
        `community_media/${communityId}/outsider/not-a-member.jpg`,
      ).put(
        new Uint8Array([0xff, 0xd8, 0xff]),
        { contentType: 'image/jpeg' },
      ),
    );
    console.log('Non-members cannot upload community images.');

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

    const magazinePath = 'magazine_covers/cycle_health/editor-cover.webp';
    const editor = testEnv.authenticatedContext('editor');
    await assertFails(
      outsider.storage().ref(magazinePath).put(
        new Uint8Array([0x52, 0x49, 0x46, 0x46]),
        { contentType: 'image/webp' },
      ),
    );
    await assertSucceeds(
      editor.storage().ref(magazinePath).put(
        new Uint8Array([0x52, 0x49, 0x46, 0x46]),
        { contentType: 'image/webp' },
      ),
    );
    await assertSucceeds(
      testEnv.unauthenticatedContext().storage().ref(magazinePath)
        .getDownloadURL(),
    );

    console.log('All storage.rules media and magazine cover tests passed.');
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
