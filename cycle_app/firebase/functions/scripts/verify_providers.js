/**
 * Run from firebase/functions:
 *   node scripts/verify_providers.js
 *
 * Uses Application Default Credentials (firebase login) to read secrets
 * and call the same DeepSeek/Gemini helpers as production.
 */
'use strict';

const { execFileSync } = require('child_process');
const { callDeepSeek } = require('../lib/deepseek');
const { callGemini } = require('../lib/gemini');

const PROJECT = 'lune-7d956';

async function getAccessToken() {
  if (process.env.FIREBASE_ACCESS_TOKEN) return process.env.FIREBASE_ACCESS_TOKEN;
  const firebaseCmd =
    process.platform === 'win32'
      ? `${process.env.APPDATA}\\npm\\firebase.cmd`
      : 'firebase';
  const raw = execFileSync(firebaseCmd, ['login:list', '--json'], {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: process.platform === 'win32',
  });
  const token = JSON.parse(raw)?.result?.[0]?.tokens?.access_token;
  if (!token) throw new Error('Firebase CLI not logged in');
  return token;
}

async function readSecret(name) {
  const token = await getAccessToken();
  const url = `https://secretmanager.googleapis.com/v1/projects/${PROJECT}/secrets/${name}/versions/latest:access`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const data = await res.json();
  if (!res.ok) {
    throw new Error(`Secret ${name}: ${res.status} ${JSON.stringify(data).slice(0, 200)}`);
  }
  const b64 = data.payload?.data;
  if (!b64) throw new Error(`Secret ${name} empty`);
  return Buffer.from(b64, 'base64').toString('utf8').trim();
}

function keyHint(key) {
  if (!key) return '(empty)';
  if (key.startsWith('sk-')) return `sk-…${key.slice(-4)} (${key.length} chars)`;
  if (key.startsWith('AIza')) return `AIza…${key.slice(-4)} (${key.length} chars)`;
  if (key.startsWith('AQ.')) return `AQ.…${key.slice(-4)} (${key.length} chars) ⚠️ ephemeral — use AIza from AI Studio`;
  return `…${key.slice(-4)} (${key.length} chars)`;
}

async function main() {
  console.log('Reading Firebase secrets (values not printed)...\n');

  let deepseekKey;
  let geminiKey;
  try {
    deepseekKey = await readSecret('DEEPSEEK_API_KEY');
    console.log('DEEPSEEK_API_KEY:', keyHint(deepseekKey));
  } catch (e) {
    console.log('DEEPSEEK_API_KEY: MISSING —', e.message);
  }
  try {
    geminiKey = await readSecret('GEMINI_API_KEY');
    console.log('GEMINI_API_KEY:', keyHint(geminiKey));
  } catch (e) {
    console.log('GEMINI_API_KEY: MISSING —', e.message);
  }

  const system = 'You are Lune, a warm wellness companion.';
  const user = 'Say one short Arabic greeting sentence only.';

  let deepseekOk = false;
  let geminiOk = false;

  if (deepseekKey) {
    try {
      const reply = await callDeepSeek(deepseekKey, system, user, 120, 0.85);
      deepseekOk = reply && reply.length > 8;
      console.log('\nDEEPSEEK live call:', deepseekOk ? 'PASS' : 'FAIL');
      console.log('  preview:', String(reply).slice(0, 150));
    } catch (e) {
      console.log('\nDEEPSEEK live call: FAIL —', e.message);
    }
  }

  if (geminiKey) {
    try {
      const reply = await callGemini(geminiKey, system, user, 120, 0.85);
      geminiOk =
        reply &&
        reply.length > 8 &&
        !String(reply).includes('لم أتمكن');
      console.log('\nGEMINI live call:', geminiOk ? 'PASS' : 'FAIL');
      console.log('  preview:', String(reply).slice(0, 150));
    } catch (e) {
      console.log('\nGEMINI live call: FAIL —', e.message);
    }
  }

  console.log('\n--- Summary ---');
  console.log('Primary (DeepSeek):', deepseekOk ? 'WORKING' : 'NOT WORKING');
  console.log('Fallback (Gemini):', geminiOk ? 'WORKING' : 'NOT WORKING');
  console.log(
    'Chat on server will work:',
    deepseekOk || geminiOk ? 'YES (if user is Premium + signed in)' : 'NO — fix keys first',
  );

  process.exit(deepseekOk || geminiOk ? 0 : 1);
}

main().catch((e) => {
  console.error('VERIFY_FAILED:', e.message);
  process.exit(1);
});
