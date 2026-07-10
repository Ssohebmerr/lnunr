/**
 * Updates nav brand to use logo across public HTML pages.
 */
import { readFileSync, writeFileSync, readdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const publicDir = join(__dirname, '../public');

const brandOld = /<span class="nav-mark">L<\/span>/g;
const brandNew = '<img src="/images/logo.png" alt="" class="nav-logo" width="36" height="36" />';

const faviconSnippet = '<link rel="icon" href="/images/favicon.png" type="image/png" />\n  ';

for (const file of readdirSync(publicDir)) {
  if (!file.endsWith('.html')) continue;
  const path = join(publicDir, file);
  let html = readFileSync(path, 'utf8');
  if (!html.includes('nav-mark') && !html.includes('nav-logo')) continue;
  html = html.replace(brandOld, brandNew);
  if (!html.includes('favicon.png') && html.includes('<meta charset')) {
    html = html.replace(/<meta charset="[^"]*"\s*\/?>/, (m) => `${m}\n  ${faviconSnippet.trim()}`);
  }
  html = html.replace(/site\.css\?v=\d+/g, 'site.css?v=7');
  writeFileSync(path, html, 'utf8');
  console.log('updated', file);
}
