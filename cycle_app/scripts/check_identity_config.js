const { execFileSync } = require('child_process');

const PROJECT = 'lune-7d956';

async function getAccessToken() {
  if (process.env.FIREBASE_ACCESS_TOKEN) {
    return process.env.FIREBASE_ACCESS_TOKEN;
  }
  const firebaseCmd = process.platform === 'win32'
    ? `${process.env.APPDATA}\\npm\\firebase.cmd`
    : 'firebase';
  const raw = execFileSync(firebaseCmd, ['login:list', '--json'], {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: process.platform === 'win32',
  });
  const parsed = JSON.parse(raw);
  const token = parsed?.result?.[0]?.tokens?.access_token;
  if (!token) throw new Error('Firebase CLI not logged in');
  return token;
}

async function api(token, method, url, body) {
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    json = { raw: text };
  }
  return { ok: res.ok, status: res.status, json };
}

async function main() {
  const mode = process.argv[2] || 'check';
  const token = await getAccessToken();
  const base = `https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT}/config`;

  if (mode === 'check') {
    const { ok, status, json } = await api(token, 'GET', base);
    if (!ok) {
      console.log('GET_CONFIG_FAILED', status, JSON.stringify(json));
      process.exit(1);
    }
    const anonymous = json.signIn?.anonymous?.enabled === true;
    const signupDisabled = json.client?.permissions?.disabledUserSignup === true;
    console.log('anonymous_enabled:', anonymous);
    console.log('disabled_user_signup:', signupDisabled);
    console.log('autodelete_anonymous_users:', json.autodeleteAnonymousUsers === true);
    process.exit(anonymous && !signupDisabled ? 0 : 2);
  }

  if (mode === 'fix') {
    const mask = [
      'signIn.anonymous',
      'client.permissions.disabledUserSignup',
    ].join(',');
    const body = {
      signIn: {
        anonymous: { enabled: true },
      },
      client: {
        permissions: {
          disabledUserSignup: false,
        },
      },
    };
    const { ok, status, json } = await api(
      token,
      'PATCH',
      `${base}?updateMask=${encodeURIComponent(mask)}`,
      body,
    );
    if (!ok) {
      console.log('PATCH_CONFIG_FAILED', status, JSON.stringify(json));
      process.exit(1);
    }
    console.log('PATCH_OK');
    process.exit(0);
  }

  console.log('Usage: node check_identity_config.js [check|fix]');
  process.exit(1);
}

main().catch((e) => {
  console.log('ERROR', e.message);
  process.exit(1);
});
