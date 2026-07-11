'use strict';

const MAX_POST_LENGTH = 2000;
const MAX_COMMENT_LENGTH = 1000;

const HTML_TAG = /<[^>]*>/g;
const CONTROL_CHARS = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g;
const MULTI_SPACE = /[ \t]{2,}/g;
const MULTI_NEWLINE = /\n{3,}/g;

/**
 * @param {string} raw
 * @param {number} maxLength
 * @returns {string}
 */
function sanitizeCommunityText(raw, maxLength) {
  if (typeof raw !== 'string') return '';
  let value = raw.replace(CONTROL_CHARS, '');
  value = value.replace(HTML_TAG, '');
  value = value.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
  value = value.replace(MULTI_SPACE, ' ');
  value = value.replace(MULTI_NEWLINE, '\n\n');
  value = value.trim();
  if (value.length > maxLength) {
    value = value.substring(0, maxLength).trimEnd();
  }
  return value;
}

function sanitizePostText(raw) {
  return sanitizeCommunityText(raw, MAX_POST_LENGTH);
}

function sanitizeCommentText(raw) {
  return sanitizeCommunityText(raw, MAX_COMMENT_LENGTH);
}

module.exports = {
  MAX_POST_LENGTH,
  MAX_COMMENT_LENGTH,
  sanitizeCommunityText,
  sanitizePostText,
  sanitizeCommentText,
};
