/**
 * Flatten nested inline/{stem}/0N.webp → {stem}-fig-0N.webp next to covers.
 * Firebase Hosting was 404ing nested inline paths.
 */
const fs = require('fs');
const path = require('path');

const GUIDES = path.resolve(__dirname, '../public/images/magazine/guides');
const INLINE = path.join(GUIDES, 'inline');

function main() {
  if (!fs.existsSync(INLINE)) {
    console.log('no inline dir');
    return;
  }
  let copied = 0;
  let missing = 0;
  for (const stem of fs.readdirSync(INLINE)) {
    const dir = path.join(INLINE, stem);
    if (!fs.statSync(dir).isDirectory()) continue;
    for (let n = 1; n <= 5; n += 1) {
      const num = String(n).padStart(2, '0');
      const src = path.join(dir, `${num}.webp`);
      const dest = path.join(GUIDES, `${stem}-fig-${num}.webp`);
      if (!fs.existsSync(src)) {
        missing += 1;
        continue;
      }
      fs.copyFileSync(src, dest);
      copied += 1;
    }
  }
  console.log(`copied=${copied} missing=${missing}`);
}

main();
