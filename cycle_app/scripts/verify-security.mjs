/**
 * Live security smoke tests against deployed Cloud Functions.
 *
 * Usage:
 *   node scripts/verify-security.mjs
 *   LUNE_FUNCTIONS_BASE=https://us-central1-lune-7d956.cloudfunctions.net node scripts/verify-security.mjs
 *
 * Checks:
 *   - POST /chat without Authorization → 401
 *   - POST /chat without X-Firebase-AppCheck → 401 when enforced, or non-401 when monitoring
 *
 * Optional IP flood (disabled by default — set LUNE_IP_FLOOD=1):
 *   Sends 65 rapid /chat requests; expects at least one 429 when limits are active.
 */
const BASE =
  process.env.LUNE_FUNCTIONS_BASE ||
  'https://us-central1-lune-7d956.cloudfunctions.net';

const RUN_IP_FLOOD = process.env.LUNE_IP_FLOOD === '1';

async function postChat(headers = {}, body = { message: 'security probe' }) {
  const res = await fetch(`${BASE}/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });
  let data = {};
  try {
    data = await res.json();
  } catch {
    data = {};
  }
  return { status: res.status, data };
}

function pass(label) {
  console.log(`✓ ${label}`);
}

function fail(label, detail) {
  console.error(`✗ ${label}`);
  if (detail) console.error(`  ${detail}`);
  process.exitCode = 1;
}

async function checkNoAuth() {
  const { status, data } = await postChat();
  if (status === 401) {
    pass('/chat without Authorization returns 401');
    return;
  }
  fail('/chat without Authorization should return 401', `got ${status}: ${JSON.stringify(data)}`);
}

async function checkNoAppCheck() {
  const { status, data } = await postChat({
    Authorization: 'Bearer invalid-token-for-probe',
  });

  if (status === 401 && data.error === 'app_check_required') {
    pass('/chat without App Check returns 401 app_check_required (enforcement ON)');
    return;
  }

  if (status === 401) {
    pass(
      '/chat without App Check: got 401 (auth/app-check path) — monitoring or invalid token',
    );
    console.log(
      '  Note: If APP_CHECK_ENFORCE=false, missing App Check is logged server-side only.',
    );
    return;
  }

  console.warn(
    `? /chat without App Check returned ${status} — expected 401 when enforcement is on`,
  );
  console.warn(`  body: ${JSON.stringify(data)}`);
}

async function checkIpFlood() {
  if (!RUN_IP_FLOOD) {
    console.log('(skip IP flood — set LUNE_IP_FLOOD=1 to enable)');
    return;
  }

  let saw429 = false;
  for (let i = 0; i < 65; i++) {
    const { status } = await postChat();
    if (status === 429) {
      saw429 = true;
      break;
    }
  }
  if (saw429) {
    pass('IP rate limit triggered 429 after rapid /chat requests');
  } else {
    fail('IP flood test expected at least one 429', 'none seen in 65 requests');
  }
}

async function main() {
  console.log(`Security verify → ${BASE}\n`);
  await checkNoAuth();
  await checkNoAppCheck();
  await checkIpFlood();
  console.log('\nDone.');
  if (process.exitCode) process.exit(process.exitCode);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
