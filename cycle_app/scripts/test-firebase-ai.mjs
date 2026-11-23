/**
 * Live smoke tests for Firebase AI endpoints (chat, analyze, moderate).
 * Usage: node scripts/test-firebase-ai.mjs [email] [password]
 */
const API_KEY = process.env.FIREBASE_API_KEY || 'AIzaSy_REPLACE_WITH_YOUR_FIREBASE_API_KEY';
const BASE = 'https://us-central1-lune-7d956.cloudfunctions.net';

const email = process.argv[2] || process.env.LUNE_TEST_EMAIL;
const password = process.argv[3] || process.env.LUNE_TEST_PASSWORD;

if (!email || !password) {
  console.error('Usage: node scripts/test-firebase-ai.mjs <email> <password>');
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
  return data.idToken;
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
    data = { raw: text.slice(0, 300) };
  }
  return { status: res.status, data };
}

function ok(name, result, check) {
  const pass = check(result);
  console.log(`${pass ? 'PASS' : 'FAIL'}  ${name}`);
  if (!pass) {
    console.log('       status:', result.status);
    console.log('       body:', JSON.stringify(result.data).slice(0, 400));
  }
  return pass;
}

async function main() {
  console.log('Signing in...');
  const token = await signIn();
  console.log('Auth OK\n');

  const ctx = {
    userGoal: 'general',
    cycleLength: 28,
    currentPhase: 'follicular',
    currentCycleDay: 8,
    userLocale: 'ar',
  };

  const results = [];

  results.push(
    ok(
      'chat',
      await callFn('chat', token, {
        message: 'Say hello in one short Arabic sentence.',
        cycleContext: ctx,
        mode: 'chat',
      }),
      (r) =>
        r.status === 200 &&
        typeof r.data.reply === 'string' &&
        r.data.reply.length > 5 &&
        !r.data.reply.includes('لم أتمكن'),
    ),
  );

  results.push(
    ok(
      'analyze',
      await callFn('analyze', token, {
        message: 'Brief cycle wellness note.',
        cycleContext: ctx,
        mode: 'analyze',
      }),
      (r) =>
        r.status === 200 &&
        typeof r.data.reply === 'string' &&
        r.data.reply.length > 10,
    ),
  );

  results.push(
    ok(
      'moderate (safe)',
      await callFn('moderate', token, { text: 'شكراً على الدعم اليوم' }),
      (r) =>
        r.status === 200 &&
        (r.data.approved === true || r.data.result?.approved === true),
    ),
  );

  results.push(
    ok(
      'moderate (spam)',
      await callFn('moderate', token, {
        text: 'BUY VIAGRA NOW http://spam.example.com click here!!!',
      }),
      (r) => r.status === 200,
    ),
  );

  const passed = results.filter(Boolean).length;
  console.log(`\n${passed}/${results.length} endpoint checks passed`);
  process.exit(passed === results.length ? 0 : 1);
}

main().catch((e) => {
  console.error('Test run failed:', e.message || e);
  process.exit(1);
});
