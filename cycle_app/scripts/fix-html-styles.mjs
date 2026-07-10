import fs from 'fs';
import path from 'path';

const dir = path.resolve('public');

function walk(d) {
  for (const f of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, f.name);
    if (f.isDirectory()) walk(p);
    else if (f.name.endsWith('.html')) {
      let c = fs.readFileSync(p, 'utf8');
      const o = c;
      c = c.replace(
        /class="btn btn-primary" style="padding:10px 20px;font-size:0\.85rem;"/g,
        'class="btn btn-primary btn-sm"'
      );
      c = c.replace(/ style="color:var\(--primary\)"/g, '');
      if (c !== o) {
        fs.writeFileSync(p, c);
        console.log('updated', path.relative(dir, p));
      }
    }
  }
}

walk(dir);
