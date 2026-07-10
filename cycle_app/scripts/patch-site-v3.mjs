import fs from 'fs';
import path from 'path';

const publicDir = path.resolve('public');
const CSS_V = 'v=4';

const navLinksEn = `      <a href="about.html">About</a>
      <a href="contact.html">Contact</a>
      <a href="trust-hub.html">Trust</a>`;

const drawerEn = `    <a href="index.html">Home</a>
    <div class="drawer-label">Company</div>
    <a href="about.html">About Lune</a>
    <a href="contact.html">Contact</a>
    <a href="partner.html">Partners</a>
    <div class="drawer-label">Trust & Legal</div>
    <a href="trust-hub.html">Trust hub</a>
    <a href="privacy-policy.html">Privacy Policy</a>
    <a href="terms-of-service.html">Terms</a>`;

function walk(d, rel = '') {
  for (const f of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, f.name);
    const r = rel ? `${rel}/${f.name}` : f.name;
    if (f.isDirectory()) walk(p, r);
    else if (f.name.endsWith('.html') && !r.startsWith('admin/')) {
      let html = fs.readFileSync(p, 'utf8');
      const orig = html;

      html = html.replace(/href="(\.\.\/)*site\.css(\?v=\d+)?"/g, (m, up = '') => {
        const prefix = up || '';
        return `href="${prefix}site.css?${CSS_V}"`;
      });
      html = html.replace(/href="home\.css(\?v=\d+)?"/g, `href="home.css?${CSS_V}"`);

      if (r !== 'index.html' && !r.startsWith('premium/')) {
        html = html.replace(
          /<div class="nav-links">\s*<a href="index\.html">Home<\/a>\s*<a href="trust-hub\.html">Trust<\/a>\s*<a href="privacy-policy\.html">Privacy<\/a>/,
          `<div class="nav-links">\n${navLinksEn}`
        );
        html = html.replace(
          /<button class="nav-drawer-close[^>]*>×<\/button>\s*<a href="index\.html">Home<\/a>\s*<a href="trust-hub\.html">Trust hub<\/a>\s*<a href="privacy-policy\.html">Privacy Policy<\/a>\s*<a href="terms-of-service\.html">Terms<\/a>/,
          `<button class="nav-drawer-close" id="navClose" aria-label="Close">×</button>\n${drawerEn}`
        );
        // privacy-policy / terms simpler drawer
        html = html.replace(
          /<button class="nav-drawer-close" id="navClose" aria-label="Close">×<\/button>\s*<a href="index\.html">Home<\/a>\s*<a href="trust-hub\.html">Trust hub<\/a>\s*<a href="privacy-policy\.html">Privacy Policy<\/a>\s*<a href="terms-of-service\.html">Terms<\/a>/,
          `<button class="nav-drawer-close" id="navClose" aria-label="Close">×</button>\n${drawerEn}`
        );
      }

      if (html !== orig) {
        fs.writeFileSync(p, html);
        console.log('patched', r);
      }
    }
  }
}

walk(publicDir);
