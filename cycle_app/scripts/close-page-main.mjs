import fs from 'fs';
import path from 'path';

const publicDir = path.resolve('public');
const files = fs.readdirSync(publicDir).filter((f) => f.endsWith('.html'));

for (const name of files) {
  const file = path.join(publicDir, name);
  let html = fs.readFileSync(file, 'utf8');
  if (!html.includes('<main class="page-main">') || html.includes('</main>')) continue;
  html = html.replace(/\n\s*<footer class="site-footer">/, '\n</main>\n\n<footer class="site-footer">');
  fs.writeFileSync(file, html);
  console.log('closed main in', name);
}
