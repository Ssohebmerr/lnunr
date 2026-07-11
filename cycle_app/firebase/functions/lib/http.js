'use strict';

const admin = require('firebase-admin');
const { clientIp, assertIpAllowed } = require('./ip_rate_limit');

const DEFAULT_ALLOWED_ORIGINS = [
  'https://lune-7d956.web.app',
  'https://lune-7d956.firebaseapp.com',
  'http://localhost:5000',
  'http://127.0.0.1:5000',
];

const APP_CHECK_ENFORCE = process.env.APP_CHECK_ENFORCE === 'true';

function allowedOrigins() {
  const raw = process.env.ALLOWED_ORIGINS || '';
  const fromEnv = raw
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  return fromEnv.length > 0 ? fromEnv : DEFAULT_ALLOWED_ORIGINS;
}

function resolveCorsOrigin(req) {
  const origin = req.headers.origin;
  if (!origin) return allowedOrigins()[0];
  return allowedOrigins().includes(origin) ? origin : allowedOrigins()[0];
}

const CORS_ALLOW_HEADERS = 'Authorization, Content-Type, X-Firebase-AppCheck';

/**
 * Handles a CORS preflight (OPTIONS) request. Returns true when the request
 * was a preflight and has already been answered — callers should `return`.
 *
 * @returns {boolean}
 */
function handleCors(req, res) {
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Origin', resolveCorsOrigin(req));
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', CORS_ALLOW_HEADERS);
    res.status(204).send('');
    return true;
  }
  return false;
}

/** Sets the CORS origin header on a real response. */
function setCors(res, req) {
  const origin = req ? resolveCorsOrigin(req) : allowedOrigins()[0];
  res.set('Access-Control-Allow-Origin', origin);
}

/**
 * Extracts the Bearer token from the Authorization header. On failure it
 * writes a 401 (with CORS) and returns null — callers should `return`.
 *
 * @returns {string|null}
 */
function bearerToken(req, res) {
  const authHeader = req.headers.authorization || '';
  if (!authHeader.startsWith('Bearer ')) {
    setCors(res, req);
    res.status(401).json({ error: 'Auth required.' });
    return null;
  }
  return authHeader.split('Bearer ')[1];
}

function isAppCheckEnforced() {
  return APP_CHECK_ENFORCE;
}

/**
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {{ enforce?: boolean }} [options]
 * @returns {Promise<boolean>}
 */
async function verifyAppCheckToken(req, res, options = {}) {
  const enforce = options.enforce === true;
  const token = req.header('X-Firebase-AppCheck');

  if (!token) {
    if (!enforce) {
      console.warn('app_check_missing', {
        path: req.path,
        ip: clientIp(req),
      });
      return true;
    }
    setCors(res, req);
    res.status(401).json({ error: 'app_check_required' });
    return false;
  }

  try {
    await admin.appCheck().verifyToken(token);
    return true;
  } catch (error) {
    console.warn('app_check_invalid', {
      path: req.path,
      ip: clientIp(req),
      message: error.message,
    });
    setCors(res, req);
    res.status(401).json({ error: 'app_check_invalid' });
    return false;
  }
}

/**
 * CORS preflight, IP rate limit, and optional App Check.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {{ bucket?: string, appCheck?: 'required'|'skip' }} [options]
 * @returns {Promise<boolean>} true when the handler should continue
 */
async function guardRequest(req, res, options = {}) {
  const { bucket = 'generic', appCheck = 'skip' } = options;

  if (handleCors(req, res)) return false;

  const ip = clientIp(req);
  try {
    const { allowed } = await assertIpAllowed(admin.firestore(), ip, bucket);
    if (!allowed) {
      setCors(res, req);
      res.status(429).json({ error: 'ip_rate_limited' });
      return false;
    }
  } catch (error) {
    console.error('ip_rate_limit_error', { bucket, ip, message: error.message });
    // Fail open on counter errors so a Firestore outage does not block users.
  }

  if (appCheck === 'required') {
    const enforce = isAppCheckEnforced();
    const ok = await verifyAppCheckToken(req, res, { enforce });
    if (!ok) return false;
  }

  return true;
}

module.exports = {
  handleCors,
  setCors,
  bearerToken,
  allowedOrigins,
  guardRequest,
  verifyAppCheckToken,
  isAppCheckEnforced,
  clientIp,
};
