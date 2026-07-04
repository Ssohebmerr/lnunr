// ============================================================================
// lib/http.js — shared HTTP helpers for onRequest endpoints.
// ----------------------------------------------------------------------------
// Every HTTP endpoint used to re-declare the same CORS preflight handling,
// the `Access-Control-Allow-Origin` header, and the Bearer-token parsing.
// These helpers centralise that boilerplate so each endpoint focuses on its
// own logic. Behaviour is identical to the previous inline copies.
// ============================================================================

'use strict';

/**
 * Handles a CORS preflight (OPTIONS) request. Returns true when the request
 * was a preflight and has already been answered — callers should `return`.
 *
 * @returns {boolean}
 */
function handleCors(req, res) {
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    res.status(204).send('');
    return true;
  }
  return false;
}

/** Sets the permissive CORS origin header on a real response. */
function setCors(res) {
  res.set('Access-Control-Allow-Origin', '*');
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
    setCors(res);
    res.status(401).json({ error: 'Auth required.' });
    return null;
  }
  return authHeader.split('Bearer ')[1];
}

module.exports = {
  handleCors,
  setCors,
  bearerToken,
};
