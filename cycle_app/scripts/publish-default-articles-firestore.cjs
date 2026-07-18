'use strict';

const fs = require('fs');
const path = require('path');
const auth = require('../firebase/functions/node_modules/firebase-tools/lib/auth');
const { Client } = require('../firebase/functions/node_modules/firebase-tools/lib/apiv2');

const projectId = process.argv[2] || 'lune-7d956';
const projectRoot = path.resolve(__dirname, '..');
const seedPath = path.join(projectRoot, 'public', 'admin', 'default-articles.json');

function firestoreValue(value) {
  if (value && typeof value === 'object' && value.__timestamp) {
    return { timestampValue: value.__timestamp };
  }
  if (value === null) return { nullValue: null };
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
  if (value && typeof value === 'object') {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(value).map(([key, item]) => [key, firestoreValue(item)]),
        ),
      },
    };
  }
  throw new TypeError(`Unsupported Firestore value: ${typeof value}`);
}

function firestoreFields(data) {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, firestoreValue(value)]),
  );
}

async function main() {
  const articles = JSON.parse(fs.readFileSync(seedPath, 'utf8'));
  if (!Array.isArray(articles) || articles.length === 0) {
    throw new Error('Article seed is empty.');
  }
  for (const article of articles) {
    if (!article.id || !article.titleAr || !article.titleEn) {
      throw new Error('Every article needs an id and bilingual titles.');
    }
    if (!/^https:\/\//.test(article.coverImageUrl || '')) {
      throw new Error(`Article ${article.id} is missing an HTTPS cover.`);
    }
  }

  const account = auth.getProjectDefaultAccount(projectRoot)
    || auth.getGlobalDefaultAccount();
  if (!account) {
    throw new Error('Firebase CLI is not signed in. Run firebase login first.');
  }
  auth.setActiveAccount({}, account);

  const client = new Client({ urlPrefix: 'https://firestore.googleapis.com/v1' });
  const databasePath = `/projects/${projectId}/databases/(default)/documents`;
  const now = new Date().toISOString();
  const writes = articles.map(({ id, ...article }) => {
    const data = {
      ...article,
      updatedAt: { __timestamp: now },
      publishedAt: { __timestamp: now },
    };
    return {
      update: {
        name: `projects/${projectId}/databases/(default)/documents/educationArticles/${id}`,
        fields: firestoreFields(data),
      },
      // Merge the editorial fields so unrelated operational fields are kept.
      updateMask: { fieldPaths: Object.keys(data) },
    };
  });

  await client.post(`${databasePath}:batchWrite`, { writes });

  const response = await client.get(`${databasePath}/educationArticles`, {
    queryParams: { pageSize: 100 },
  });
  const liveArticles = response.body.documents || [];
  const withCovers = liveArticles.filter((doc) =>
    doc.fields?.coverImageUrl?.stringValue?.startsWith('https://'),
  );
  const published = liveArticles.filter((doc) => doc.fields?.published?.booleanValue);
  if (liveArticles.length < articles.length
      || withCovers.length < articles.length
      || published.length < articles.length) {
    throw new Error(
      `Verification failed: ${liveArticles.length} docs, ${withCovers.length} covers, ${published.length} published.`,
    );
  }
  console.log(
    `Published ${articles.length} articles; verified ${liveArticles.length} server documents with ${withCovers.length} HTTPS covers.`,
  );
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
