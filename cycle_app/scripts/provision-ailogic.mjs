/**
 * Provisions Firebase AI Logic for the Lune Android app (non-interactive).
 * Uses the logged-in Firebase CLI credentials.
 *
 * Usage (from cycle_app):
 *   node scripts/provision-ailogic.mjs
 */
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const firebaseToolsRoot =
  process.env.FIREBASE_TOOLS_ROOT ||
  'C:/Users/soheb/AppData/Roaming/npm/node_modules/firebase-tools/';
const { provisionFirebaseApp } = require(`${firebaseToolsRoot}lib/management/provisioning/provision`);
const { AppPlatform } = require(`${firebaseToolsRoot}lib/management/apps`);
const { requireAuth } = require(`${firebaseToolsRoot}lib/requireAuth`);

const PROJECT_ID = 'lune-7d956';
const ANDROID_APP_ID = '1:113050193026:android:731eb6c6712ba42d10789b';

async function main() {
  const { configstore } = require(`${firebaseToolsRoot}lib/configstore`);
  const options = {
    project: PROJECT_ID,
    projectId: PROJECT_ID,
    user: configstore.get('user'),
    tokens: configstore.get('tokens'),
  };
  await requireAuth(options);
  console.log(`Provisioning Firebase AI Logic for ${PROJECT_ID} ...`);
  const result = await provisionFirebaseApp({
    project: {
      parent: { type: 'existing_project', projectId: PROJECT_ID },
    },
    app: {
      platform: AppPlatform.ANDROID,
      appId: ANDROID_APP_ID,
    },
    features: {
      firebaseAiLogicInput: {},
    },
  });
  console.log('Firebase AI Logic provisioned successfully.');
  if (result?.configData) {
    console.log('Config payload received (base64 length):', result.configData.length);
  }
}

main().catch((err) => {
  console.error('Provisioning failed:', err?.message || err);
  process.exit(1);
});
