import fs from 'fs';
import path from 'path';

const publicDir = path.resolve('public');
const files = [
  'security.html',
  'your-body-your-data.html',
  'your-data-ends.html',
  'privacy-faq.html',
  'cookies.html',
  'ip-address.html',
  'accessibility.html',
  'privacy-policy.html',
  'terms-of-service.html',
];

for (const name of files) {
  const file = path.join(publicDir, name);
  let html = fs.readFileSync(file, 'utf8');
  if (html.includes('<main class="page-main">')) continue;
  html = html.replace(
    '</section>\n\n<div class="content-wrap">',
    '</section>\n\n<main class="page-main">\n<div class="content-wrap">'
  );
  html = html.replace(
    '</div>\n\n<footer class="site-footer">',
    '</div>\n</main>\n\n<footer class="site-footer">'
  );
  fs.writeFileSync(file, html);
  console.log('wrapped', name);
}

// trust-hub
const hub = path.join(publicDir, 'trust-hub.html');
let hubHtml = fs.readFileSync(hub, 'utf8');
if (!hubHtml.includes('<main class="page-main">')) {
  hubHtml = hubHtml.replace(
    '</section>\n\n<div class="container">',
    '</section>\n\n<main class="page-main">\n<div class="container">'
  );
  hubHtml = hubHtml.replace(
    /<div class="hub-footer-card">/,
    '</div>\n</main>\n\n<div class="hub-footer-card">'
  );
  // Fix: hub-footer-card is outside container - need to read structure
  fs.writeFileSync(hub, hubHtml);
  console.log('wrapped trust-hub.html');
}
