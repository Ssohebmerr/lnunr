import fs from 'fs';
import path from 'path';

const publicDir = path.resolve('public');
const companyCol = `      <div class="footer-col"><h4>Company</h4><a href="about.html">About</a><a href="contact.html">Contact</a><a href="partner.html">Partners</a></div>\n`;

const skip = new Set(['about.html', 'contact.html', 'partner.html', 'index.html', 'admin/index.html', 'admin/preview.html']);

function walk(d, rel = '') {
  for (const f of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, f.name);
    const r = rel ? `${rel}/${f.name}` : f.name;
    if (f.isDirectory()) walk(p, r);
    else if (f.name.endsWith('.html') && !skip.has(r) && !r.startsWith('admin/') && !r.startsWith('premium/')) {
      let html = fs.readFileSync(p, 'utf8');
      if (html.includes('about.html">About</a>')) continue;
      const replaced = html.replace(
        /<div class="footer-grid">\s*\n\s*<div class="footer-col">/,
        `<div class="footer-grid">\n${companyCol}      <div class="footer-col">`
      );
      if (replaced !== html) {
        fs.writeFileSync(p, replaced);
        console.log('patched footer:', r);
      }
    }
  }
}

walk(publicDir);
