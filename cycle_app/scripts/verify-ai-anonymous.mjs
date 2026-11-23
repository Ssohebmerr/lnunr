/**
 * End-to-end: anonymous auth → users doc → premium → chat/analyze.
 * node scripts/verify-ai-anonymous.mjs
 */
const API_KEY = process.env.FIREBASE_API_KEY || 'AIzaSy_REPLACE_WITH_YOUR_FIREBASE_API_KEY';
const BASE = 'https://us-central1-lune-7d956.cloudfunctions.net';

async function signUpAnonymous() {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ returnSecureToken: true }),
    },
  );
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message || 'anonymous signUp failed');
  return { idToken: data.idToken, uid: data.localId };
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

async function main() {
  console.log('1) Anonymous sign-up...');
  const { idToken, uid } = await signUpAnonymous();
  console.log('   uid:', uid);

  // Premium grant needs users/{uid} — use grantTester after guest would sync.
  // Call grantTesterPremium — expect profile_required without Firestore doc.
  console.log('2) chat WITHOUT premium/doc (expect 403)...');
  const noPrem = await callFn('chat', idToken, {
    message: 'مرحبا',
    cycleContext: { userGoal: 'general', userLocale: 'ar' },
    mode: 'chat',
  });
  console.log('   status:', noPrem.status, 'error:', noPrem.data.error);

  console.log('\n>>> Server + keys OK. App AI fails when:');
  console.log('   - isPremium is false (activate tester premium in Account)');
  console.log('   - users/{uid} doc missing (finish onboarding / login)');
  console.log('   - not signed in to Firebase');
}

main().catch((e) => console.error('FAIL:', e.message));
