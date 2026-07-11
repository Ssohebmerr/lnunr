'use strict';

const MAX_CONTEXT_CHARS = 12000;

function sanitizeContextValue(value, budget, depth = 0) {
  if (budget.remaining <= 0 || depth > 3 || value == null) return undefined;
  if (typeof value === 'string') {
    const text = value.substring(0, Math.min(500, budget.remaining));
    budget.remaining -= text.length;
    return text;
  }
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : undefined;
  }
  if (Array.isArray(value)) {
    const out = [];
    for (const item of value.slice(0, 16)) {
      const safe = sanitizeContextValue(item, budget, depth + 1);
      if (safe !== undefined) out.push(safe);
      if (budget.remaining <= 0) break;
    }
    return out;
  }
  if (typeof value === 'object') {
    const out = {};
    for (const [key, item] of Object.entries(value).slice(0, 32)) {
      const safeKey = String(key).substring(0, 80);
      const safe = sanitizeContextValue(item, budget, depth + 1);
      if (safe !== undefined) out[safeKey] = safe;
      if (budget.remaining <= 0) break;
    }
    return out;
  }
  return undefined;
}

function sanitizeCycleContext(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return {};
  return sanitizeContextValue(raw, { remaining: MAX_CONTEXT_CHARS }) || {};
}

module.exports = {
  MAX_CONTEXT_CHARS,
  sanitizeCycleContext,
};
