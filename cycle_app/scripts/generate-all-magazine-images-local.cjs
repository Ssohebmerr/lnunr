/**
 * Fast unique covers + inline images from local photo pool (no network).
 * Resume-safe. Usage: node scripts/generate-all-magazine-images-local.cjs
 */
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const crypto = require('crypto');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');
const GUIDES = path.join(ROOT, 'public/images/magazine/guides');
const INLINE = path.join(GUIDES, 'inline');
const MIN = 8000;

const BASE_POOL = [
  'cycle-tracking.png',
  'period-pain.png',
  'nutrition.png',
  'sleep.png',
  'doctor-visit.png',
  'fertility-awareness.png',
  'movement.png',
  'life-stages.png',
].map((name) => path.join(GUIDES, name));

function loadArticles() {
  const ctx = { window: {}, global: null };
  ctx.global = ctx;
  vm.createContext(ctx);
  vm.runInContext(fs.readFileSync(path.join(ROOT, 'public/magazine/long-articles-extra.js'), 'utf8'), ctx);
  vm.runInContext(fs.readFileSync(path.join(ROOT, 'public/magazine/long-articles.js'), 'utf8'), ctx);
  return ctx.window.LUNE_LONG_ARTICLES;
}

function stemOf(id) {
  return id.replace(/-complete-guide$/, '');
}

function hashBytes(key) {
  return crypto.createHash('md5').update(key).digest();
}

function done(file) {
  return fs.existsSync(file) && fs.statSync(file).size >= MIN;
}

function tintSvg(r, g, b, opacity) {
  return Buffer.from(
    `<svg width="1200" height="800" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <radialGradient id="g1" cx="${20 + (r % 50)}%" cy="${20 + (g % 40)}%" r="60%">
          <stop offset="0%" stop-color="rgb(${r},${g},${b})" stop-opacity="0.45"/>
          <stop offset="100%" stop-color="rgb(${r},${g},${b})" stop-opacity="0"/>
        </radialGradient>
      </defs>
      <rect width="1200" height="800" fill="rgba(${r},${g},${b},${opacity})"/>
      <rect width="1200" height="800" fill="url(#g1)"/>
    </svg>`,
  );
}

async function makeUnique(fileBase, key) {
  if (done(`${fileBase}.webp`)) return false;
  const h = hashBytes(key);
  const base = BASE_POOL[h[0] % BASE_POOL.length];
  const positions = ['centre', 'north', 'south', 'east', 'west', 'entropy', 'attention'];
  const position = positions[h[1] % positions.length];
  const r = 120 + (h[4] % 100);
  const g = 100 + (h[5] % 110);
  const b = 110 + (h[6] % 120);
  const opacity = 0.18 + (h[7] / 255) * 0.18;

  const extracted = await sharp(base)
    .resize(1200, 800, { fit: 'cover', position })
    .modulate({
      brightness: 0.96 + (h[8] / 255) * 0.1,
      saturation: 0.85 + (h[9] / 255) * 0.3,
      hue: Math.round(((h[10] / 255) - 0.5) * 28),
    })
    .composite([{ input: tintSvg(r, g, b, opacity), blend: 'over' }])
    .toBuffer();

  await sharp(extracted).png().toFile(`${fileBase}.png`);
  await sharp(extracted).webp({ quality: 82 }).toFile(`${fileBase}.webp`);
  return true;
}

async function mapLimit(items, limit, fn) {
  let i = 0;
  async function worker() {
    while (i < items.length) {
      const idx = i;
      i += 1;
      await fn(items[idx], idx);
    }
  }
  await Promise.all(Array.from({ length: limit }, () => worker()));
}

async function main() {
  for (const base of BASE_POOL) {
    if (!fs.existsSync(base)) throw new Error(`Missing base ${base}`);
  }
  fs.mkdirSync(INLINE, { recursive: true });
  const articles = loadArticles();
  const jobs = [];
  for (const article of articles) {
    const stem = stemOf(article.id);
    jobs.push({ type: 'cover', stem, fileBase: path.join(GUIDES, stem), key: `cover:${stem}` });
    const dir = path.join(INLINE, stem);
    fs.mkdirSync(dir, { recursive: true });
    for (let n = 1; n <= 5; n += 1) {
      const num = String(n).padStart(2, '0');
      jobs.push({
        type: 'inline',
        stem,
        fileBase: path.join(dir, num),
        key: `inline:${stem}:${num}`,
      });
    }
  }

  let created = 0;
  let skipped = 0;
  let failed = 0;
  await mapLimit(jobs, 8, async (job) => {
    try {
      const made = await makeUnique(job.fileBase, job.key);
      if (made) {
        created += 1;
        if (created % 100 === 0) console.log(`created ${created}`);
      } else skipped += 1;
    } catch (err) {
      failed += 1;
      console.error(`FAIL ${job.key}: ${err.message}`);
    }
  });

  console.log(`done jobs=${jobs.length} created=${created} skipped=${skipped} failed=${failed}`);
  if (failed > 0) process.exitCode = 1;
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
