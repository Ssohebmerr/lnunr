'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const functionsRoot = path.resolve(__dirname, '..');
const adminRoot = path.resolve(functionsRoot, '..', '..', 'public', 'admin');
const html = fs.readFileSync(path.join(adminRoot, 'index.html'), 'utf8');
const cms = fs.readFileSync(path.join(adminRoot, 'cms-panels.js'), 'utf8');
const server = fs.readFileSync(
  path.join(functionsRoot, 'endpoints', 'adminApi.js'),
  'utf8',
);

const ids = new Set(
  [...html.matchAll(/\bid=["']([^"']+)["']/g)].map((match) => match[1]),
);
// These two nodes are intentionally created by setupBroadcastPreview().
ids.add('npTitle');
ids.add('npText');

const domReferences = new Set(
  [...`${html}\n${cms}`.matchAll(/\$\(["']([^"']+)["']\)/g)]
    .map((match) => match[1]),
);
const missingIds = [...domReferences].filter((id) => !ids.has(id));
assert.deepStrictEqual(missingIds, [], `Missing admin DOM ids: ${missingIds.join(', ')}`);

const clientActions = new Set(
  [...`${html}\n${cms}`.matchAll(/admin\.api\(["']([^"']+)["']/g)]
    .map((match) => match[1]),
);
const serverActions = new Set(
  [...server.matchAll(/case ["']([^"']+)["']/g)].map((match) => match[1]),
);
const missingActions = [...clientActions].filter((action) => !serverActions.has(action));
assert.deepStrictEqual(
  missingActions,
  [],
  `Admin client actions missing on server: ${missingActions.join(', ')}`,
);

assert.match(
  cms,
  /JSON\.stringify\(\{ title, body, audience, segment \}\)/,
  'instant broadcasts must forward the selected segment',
);
assert.match(
  server,
  /title, body, audience, segment,/,
  'scheduled broadcasts must persist the selected segment',
);
assert.match(cms, /admin\.api\('moderateCommunityContent'/);
assert.match(html, /admin\.api\('handleAdminReport'/);

console.log('admin panel contract tests passed');
