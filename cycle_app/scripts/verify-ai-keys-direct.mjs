/**
 * Direct provider smoke test (run from firebase/functions with secrets in env).
 *
 *   cd firebase/functions
 *   $env:DEEPSEEK_API_KEY="sk-..."; $env:GEMINI_API_KEY="AIza..."; node ../../scripts/verify-ai-keys-direct.mjs
 */
const { callDeepSeek } = require('../firebase/functions/lib/deepseek');
const { callGemini } = require('../firebase/functions/lib/gemini');

const deepseekKey = process.env.DEEPSEEK_API_KEY || '';
const geminiKey = process.env.GEMINI_API_KEY || '';

const system = 'You are a helpful assistant.';
const user = 'Reply with exactly: OK_DEEPSEEK_TEST in Arabic greeting form.';

async function testDeepSeek() {
  if (!deepseekKey) {
    console.log('DEEPSEEK: SKIP (no DEEPSEEK_API_KEY in env)');
    return false;
  }
  try {
    const reply = await callDeepSeek(deepseekKey, system, user, 80, 0.7);
    const ok = reply && reply.length > 5;
    console.log('DEEPSEEK:', ok ? 'PASS' : 'FAIL', '-', String(reply).slice(0, 120));
    return ok;
  } catch (e) {
    console.log('DEEPSEEK: FAIL -', e.message);
    return false;
  }
}

async function testGemini() {
  if (!geminiKey) {
    console.log('GEMINI: SKIP (no GEMINI_API_KEY in env)');
    return false;
  }
  try {
    const reply = await callGemini(geminiKey, system, user, 80, 0.7);
    const ok =
      reply &&
      reply.length > 5 &&
      !reply.includes('لم أتمكن');
    console.log('GEMINI:', ok ? 'PASS' : 'FAIL', '-', String(reply).slice(0, 120));
    return ok;
  } catch (e) {
    console.log('GEMINI: FAIL -', e.message);
    return false;
  }
}

async function main() {
  console.log('Direct API key verification (same code as Cloud Functions)\n');
  const ds = await testDeepSeek();
  const gm = await testGemini();
  const any = ds || gm;
  console.log('\n>>> At least one provider works:', any ? 'YES' : 'NO');
  process.exit(any ? 0 : 1);
}

main();
