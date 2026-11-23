/**
 * Live verification: DeepSeek primary + Gemini fallback via Cloud Functions.
 *
 * Usage:
 *   node scripts/verify-ai-live.mjs <email> <password>
 *   LUNE_TEST_EMAIL=... LUNE_TEST_PASSWORD=... node scripts/verify-ai-live.mjs
 *
 * Steps: sign in → ensure users/{uid} exists → grant tester premium → chat + analyze.
 */
const API_KEY = process.env.FIREBASE_API_KEY || 'AIzaSy_REPLACE_WITH_YOUR_FIREBASE_API_KEY';
const BASE = 'https://us-central1-lune-7d956.cloudfunctions.net';
const FIRESTORE_BASE =
  'https://firestore.googleapis.com/v1/projects/lune-7d956/databases/(default)/documents';

const email = process.argv[2] || process.env.LUNE_TEST_EMAIL;
const password = process.argv[3] || process.env.LUNE_TEST_PASSWORD;

if (!email || !password) {
  console.error('Usage: node scripts/verify-ai-live.mjs <email> <password>');
  process.exit(1);
}

async function signIn() {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );
  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.error?.message || `Auth failed (${res.status})`);
  }
  return { idToken: data.idToken, uid: data.localId, refreshToken: data.refreshToken };
}

async function ensureUserDoc(idToken, uid) {
  const url = `${FIRESTORE_BASE}/users/${uid}`;
  const getRes = await fetch(url, {
    headers: { Authorization: `Bearer ${idToken}` },
  });
  if (getRes.ok) return true;

  const patchRes = await fetch(
    `${url}?updateMask.fieldPaths=name&updateMask.fieldPaths=isPremium`,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${idToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        fields: {
          name: { stringValue: 'AI Test User' },
          isPremium: { booleanValue: false },
        },
      }),
    },
  );
  return patchRes.ok;
}

async function grantPremium(idToken) {
  const res = await fetch(`${BASE}/grantTesterPremium`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: '{}',
  });
  const text = await res.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    data = { raw: text.slice(0, 200) };
  }
  if (res.status === 200 && data.ok === true) return 'granted';
  if (res.status === 400 && data.error === 'already_granted') return 'already_premium';
  if (res.status === 403 && data.error === 'profile_required') {
    throw new Error('profile_required — users/{uid} missing in Firestore');
  }
  throw new Error(`grantTesterPremium ${res.status}: ${JSON.stringify(data)}`);
}

async function callFn(name, token, body) {
  const res = await fetch(`${BASE}/${name}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    data = { raw: text.slice(0, 400) };
  }
  return { status: res.status, data };
}

const ctx = {
  userGoal: 'general',
  cycleLength: 28,
  currentPhase: 'follicular',
  currentCycleDay: 8,
  userLocale: 'ar',
};

function report(label, result) {
  const { status, data } = result;
  const reply = data.reply;
  const provider = data.provider;
  const err = data.error;
  const msg = data.message;

  console.log(`\n=== ${label} ===`);
  console.log('HTTP', status);
  if (provider) console.log('provider:', provider);
  if (err) console.log('error:', err, msg || '');
  if (reply) {
    console.log('reply preview:', String(reply).slice(0, 200));
    const ok =
      status === 200 &&
      String(reply).length > 20 &&
      !String(reply).includes('لم أتمكن') &&
      !String(reply).startsWith('عذراً، حدث خطأ');
    console.log(ok ? 'RESULT: PASS' : 'RESULT: FAIL (bad reply)');
    return ok;
  }
  console.log('body:', JSON.stringify(data).slice(0, 300));
  console.log('RESULT: FAIL');
  return false;
}

async function main() {
  console.log('1) Sign in...');
  const { idToken, uid } = await signIn();
  console.log('   uid:', uid);

  console.log('2) Ensure Firestore users doc...');
  const hasDoc = await ensureUserDoc(idToken, uid);
  console.log('   users doc:', hasDoc ? 'ok' : 'could not create (rules may block REST)');

  console.log('3) Grant tester premium...');
  try {
    const prem = await grantPremium(idToken);
    console.log('   premium:', prem);
  } catch (e) {
    console.log('   premium grant skipped/failed:', e.message);
    console.log('   (If account already has isPremium:true in Firestore, chat may still work.)');
  }

  const results = [];

  results.push(
    report(
      'chat (DeepSeek primary expected)',
      await callFn('chat', idToken, {
        message: 'قل لي جملة ترحيب قصيرة بالعربية فقط.',
        cycleContext: ctx,
        mode: 'chat',
        personality: 'friend',
      }),
    ),
  );

  results.push(
    report(
      'analyze',
      await callFn('analyze', idToken, {
        message: 'ملخص قصير عن مرحلة الجسم اليوم.',
        cycleContext: ctx,
        mode: 'analyze',
      }),
    ),
  );

  results.push(
    report(
      'briefing via chat mode',
      await callFn('chat', idToken, {
        message: 'ترحيب صباحي قصير لليوم الثامن من الدورة.',
        cycleContext: ctx,
        mode: 'briefing',
      }),
    ),
  );

  const passed = results.filter(Boolean).length;
  console.log(`\n>>> ${passed}/${results.length} live AI checks passed`);
  if (passed === results.length) {
    console.log('>>> DeepSeek/Gemini pipeline is WORKING on server.');
  } else {
    console.log('>>> AI pipeline has failures — check premium, keys, or provider errors above.');
  }
  process.exit(passed === results.length ? 0 : 1);
}

main().catch((e) => {
  console.error('VERIFY_FAILED:', e.message || e);
  process.exit(1);
});
