/**
 * Safely adds Lune's long-form editorial guides to Firestore.
 *
 * Dry run: node firebase/functions/scripts/seed_long_articles.js
 * Commit:  node firebase/functions/scripts/seed_long_articles.js --commit
 *
 * Existing documents with other IDs are never listed, changed, or deleted.
 */
'use strict';

const path = require('path');
const { configstore } = require('../node_modules/firebase-tools/lib/configstore');
const auth = require('../node_modules/firebase-tools/lib/auth');

const PROJECT = 'lune-7d956';
const COMMIT = process.argv.includes('--commit');
const ARTICLES_FILE = path.resolve(__dirname, '../../../public/magazine/long-articles.js');

function firestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(firestoreValue) } };
  }
  if (typeof value === 'object') {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(value).map(([key, item]) => [key, firestoreValue(item)]),
        ),
      },
    };
  }
  throw new Error(`Unsupported Firestore value: ${typeof value}`);
}

function documentFields(data) {
  const fields = Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, firestoreValue(value)]),
  );
  fields.updatedAt = { timestampValue: new Date().toISOString() };
  return fields;
}

async function accessToken() {
  const refreshToken = configstore.get('tokens')?.refresh_token;
  if (!refreshToken) throw new Error('Firebase CLI is not logged in');
  const result = await auth.getAccessToken(refreshToken, []);
  const token = typeof result === 'string' ? result : result?.access_token;
  if (!token) throw new Error('Could not obtain a Firebase access token');
  return token;
}

async function writeArticle(article, token) {
  const { id, ...data } = article;
  const documentPath = `projects/${PROJECT}/databases/(default)/documents/educationArticles/${encodeURIComponent(id)}`;
  const response = await fetch(`https://firestore.googleapis.com/v1/${documentPath}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json; charset=utf-8',
    },
    body: JSON.stringify({ fields: documentFields(data) }),
  });
  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`${id}: ${response.status} ${detail.slice(0, 400)}`);
  }
  return id;
}

async function main() {
  global.window = global;
  require(path.resolve(__dirname, '../../../public/magazine/long-articles-extra.js'));
  require(ARTICLES_FILE);
  const articles = global.window.LUNE_LONG_ARTICLES;
  if (!Array.isArray(articles) || articles.length !== 1000) {
    throw new Error(`Expected exactly 1000 long guides, received ${articles?.length ?? 0}`);
  }
  const ids = new Set(articles.map((article) => article.id));
  if (ids.size !== articles.length) throw new Error('Article IDs must be unique');
  for (const article of articles) {
    const arWords = article.bodyAr.trim().split(/\s+/u).length;
    const enWords = article.bodyEn.trim().split(/\s+/u).length;
    if (arWords < 1000 || enWords < 1000) {
      throw new Error(
        `${article.id} is shorter than 1000 words (ar=${arWords}, en=${enWords})`,
      );
    }
  }
  console.log(`Validated ${articles.length} long guides. Commit: ${COMMIT ? 'YES' : 'NO'}`);
  if (!COMMIT) return;
  const token = await accessToken();
  let written = 0;
  for (const article of articles) {
    await writeArticle(article, token);
    written += 1;
    console.log(`[${written}/${articles.length}] ${article.id}`);
  }
  console.log(`Seeded ${written} guides without deleting any existing document.`);
}

main().catch((error) => {
  console.error('Long article seed failed:', error.message);
  process.exitCode = 1;
});
