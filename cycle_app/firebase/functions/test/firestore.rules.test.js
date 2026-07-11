'use strict';

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'lune-rules-test';
const RULES_PATH = path.resolve(__dirname, '../../../firestore.rules');

async function main() {
  const rules = fs.readFileSync(RULES_PATH, 'utf8');
  const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
  const firestoreConfig = { rules };
  if (emulatorHost) {
    const [host, port] = emulatorHost.split(':');
    firestoreConfig.host = host;
    firestoreConfig.port = Number(port);
  }

  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules,
      host: firestoreConfig.host || '127.0.0.1',
      port: firestoreConfig.port || 8080,
    },
  });

  try {
    const alice = testEnv.authenticatedContext('user_alice');
    const bobDb = alice.firestore();

    // Owner can read own user doc.
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('users').doc('user_alice').set({
        communityBirthYear: 1995,
        communitySetupComplete: true,
      });
    });

    await assertSucceeds(
      bobDb.collection('users').doc('user_alice').get(),
    );

    // Cannot read another user's private doc.
    await assertFails(
      bobDb.collection('users').doc('user_other').get(),
    );

    // Server-only rate limit docs are blocked for clients.
    await assertFails(
      bobDb.collection('communityRateLimits').doc('user_alice').set({
        serverHour: '2026-07-11T10',
        serverPostCount: 1,
      }),
    );

  // Posts must go through Cloud Functions (direct create denied).
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('users').doc('user_alice').set({
        communityBirthYear: 1995,
        communitySetupComplete: true,
        communityAlias: 'Luna',
      });
      await ctx.firestore()
        .collection('communities').doc('general-cycle')
        .collection('members').doc('user_alice')
        .set({ alias: 'Luna', joinedAt: new Date() });
    });

    await assertFails(
      bobDb.collection('communities').doc('general-cycle')
        .collection('posts').add({
          text: 'hello world test',
          authorUid: 'user_alice',
          moderationStatus: 'approved',
        }),
    );

    console.log('All firestore.rules tests passed.');
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
