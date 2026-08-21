/**
 * Generate unique covers + 5 inline images per article (resume-safe).
 * Usage: node scripts/generate-all-magazine-images.cjs
 */
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const crypto = require('crypto');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');
const GUIDES = path.join(ROOT, 'public/images/magazine/guides');
const INLINE = path.join(GUIDES, 'inline');
const MIN = 12000;
const DELAY = 350;

const TAGS = {
  1: 'journal,candle,calm',
  2: 'bedroom,sleep,cozy',
  3: 'notebook,desk,morning',
  4: 'tea,wellness,soft',
  5: 'clinic,plant,waiting',
  cover: {
    basics: 'notebook,calendar,desk',
    health: 'plant,clinic,soft',
    nutrition: 'healthy,food,vegetables',
    mind: 'candle,journal,window',
    fertility: 'flowers,soft,pink',
    fitness: 'sneakers,gym,water',
    adult: 'silk,candle,warm',
  },
};

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

function lockOf(key) {
  return parseInt(crypto.createHash('md5').update(key).digest('hex').slice(0, 8), 16) % 100000;
}

function done(file) {
  return fs.existsSync(file) && fs.statSync(file).size >= MIN;
}

async function download(tags, lock) {
  const url = `https://loremflickr.com/1200/800/${tags}/all?lock=${lock}`;
  const res = await fetch(url, { redirect: 'follow' });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.byteLength < 5000) throw new Error('too small');
  return buf;
}

async function writeWebp(fileBase, jpegBuf, gradeKey) {
  const hash = crypto.createHash('md5').update(gradeKey).digest();
  const buf = await sharp(jpegBuf)
    .resize(1200, 800, { fit: 'cover', position: hash[0] > 128 ? 'centre' : 'entropy' })
    .modulate({
      brightness: 0.97 + (hash[1] / 255) * 0.08,
      saturation: 0.88 + (hash[2] / 255) * 0.22,
      hue: Math.round(((hash[3] / 255) - 0.5) * 20),
    })
    .toBuffer();
  await sharp(buf).png().toFile(`${fileBase}.png`);
  await sharp(buf).webp({ quality: 82 }).toFile(`${fileBase}.webp`);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function ensureImage(fileBase, tags, lockKey) {
  if (done(`${fileBase}.webp`)) return false;
  let lastErr;
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    try {
      const img = await download(tags, lockOf(lockKey) + attempt * 19);
      await writeWebp(fileBase, img, lockKey);
      return true;
    } catch (err) {
      lastErr = err;
      await sleep(600 * attempt);
    }
  }
  throw lastErr || new Error('failed');
}

async function main() {
  fs.mkdirSync(INLINE, { recursive: true });
  const articles = loadArticles();
  console.log(`articles ${articles.length}`);
  let created = 0;
  let skipped = 0;
  let failed = 0;

  for (let i = 0; i < articles.length; i += 1) {
    const article = articles[i];
    const stem = stemOf(article.id);
    const coverBase = path.join(GUIDES, stem);
    const coverTags = TAGS.cover[article.category] || 'wellness,soft,nature';

    try {
      const made = await ensureImage(coverBase, coverTags, `cover:${stem}`);
      if (made) {
        created += 1;
        console.log(`[${i + 1}/${articles.length}] cover ${stem}`);
      } else skipped += 1;
    } catch (err) {
      failed += 1;
      console.error(`FAIL cover ${stem}: ${err.message}`);
    }
    await sleep(DELAY);

    const dir = path.join(INLINE, stem);
    fs.mkdirSync(dir, { recursive: true });
    for (let n = 1; n <= 5; n += 1) {
      const num = String(n).padStart(2, '0');
      const base = path.join(dir, num);
      try {
        const made = await ensureImage(base, TAGS[n], `inline:${stem}:${num}`);
        if (made) {
          created += 1;
          console.log(`[${i + 1}/${articles.length}] inline ${stem}/${num}`);
        } else skipped += 1;
      } catch (err) {
        failed += 1;
        console.error(`FAIL inline ${stem}/${num}: ${err.message}`);
      }
      await sleep(DELAY);
    }
  }

  console.log(`done created=${created} skipped=${skipped} failed=${failed}`);
  if (failed > 0) process.exitCode = 1;
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
