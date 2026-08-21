/**
 * Unique realistic covers via LoremFlickr (topical tags + unique lock per article).
 * Skips stems that already have a large webp. Converts to PNG+WebP.
 *
 * Usage: node scripts/generate-unique-realistic-covers.cjs
 */
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const vm = require('vm');
const crypto = require('crypto');

const OUT = path.resolve(__dirname, '../public/images/magazine/guides');
const ROOT = path.resolve(__dirname, '..');
const MIN_BYTES = 20000;
const DELAY_MS = 400;

function loadArticles() {
  const ctx = { window: {}, global: null };
  ctx.global = ctx;
  vm.createContext(ctx);
  vm.runInContext(fs.readFileSync(path.join(ROOT, 'public/magazine/long-articles-extra.js'), 'utf8'), ctx);
  vm.runInContext(fs.readFileSync(path.join(ROOT, 'public/magazine/long-articles.js'), 'utf8'), ctx);
  return ctx.window.LUNE_LONG_ARTICLES;
}

function tagsFor(article) {
  const t = `${article.titleEn} ${article.category}`.toLowerCase();
  if (/iron|anemia|nutrition|meal|snack|grocery|protein|magnesium|omega|vitamin|calcium|hydration|caffeine|bloating|dairy|plant|food|alcohol|sugar/.test(t)) {
    return 'healthy,food,vegetables';
  }
  if (/yoga|stretch|mobility|breathwork|meditation/.test(t)) return 'yoga,meditation,wellness';
  if (/strength|gym|hiit|cardio|running|sport|fitness|walk|movement|swim|dance|exercise|injury/.test(t)) {
    return 'fitness,training,wellness';
  }
  if (/sleep|bed|insomnia|fatigue|rest/.test(t)) return 'bedroom,sleep,cozy';
  if (/fertility|pregnancy|ovulation|conceive|baby|miscarriage|ivf|iui|egg|ttc|breastfeed/.test(t)) {
    return 'flowers,soft,pink';
  }
  if (/anxiety|mood|therapy|grief|mind|journal|calm|stress|pmdd|depression|burnout/.test(t)) {
    return 'journal,candle,calm';
  }
  if (/partner|intimacy|desire|sex|consent|relationship|tea|adult|libido|sti/.test(t)) {
    return 'tea,couple,warm';
  }
  if (/travel|jetlag|passport/.test(t)) return 'travel,coffee,window';
  if (/doctor|clinic|lab|hospital|medical|surgery|screening|emergency/.test(t)) {
    return 'clinic,plant,waiting';
  }
  if (/pill|medicine|contraception|iud/.test(t)) return 'medicine,water,glass';
  if (/teen|school|first period|calendar|tracking|diary|privacy|app/.test(t)) {
    return 'notebook,desk,morning';
  }
  const byCat = {
    basics: 'notebook,calendar,desk',
    health: 'plant,clinic,soft',
    nutrition: 'salad,bowl,healthy',
    mind: 'candle,journal,window',
    fertility: 'flowers,linen,soft',
    fitness: 'sneakers,gym,water',
    adult: 'silk,candle,warm',
  };
  return byCat[article.category] || 'wellness,nature,soft';
}

function stemOf(article) {
  return article.id.replace(/-complete-guide$/, '');
}

function lockOf(stem) {
  return parseInt(crypto.createHash('md5').update(stem).digest('hex').slice(0, 8), 16) % 100000;
}

function alreadyDone(stem) {
  const webp = path.join(OUT, `${stem}.webp`);
  return fs.existsSync(webp) && fs.statSync(webp).size >= MIN_BYTES;
}

async function download(tags, lock) {
  const url = `https://loremflickr.com/1200/800/${tags}/all?lock=${lock}`;
  const res = await fetch(url, { redirect: 'follow' });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.byteLength < 8000) throw new Error(`too small ${buf.byteLength}`);
  return buf;
}

async function writeCover(stem, jpegBuf) {
  // Soft unique color grade per stem so even similar stock photos feel distinct
  const hash = crypto.createHash('md5').update(stem).digest();
  const hue = hash[0] / 255;
  const sat = 0.85 + (hash[1] / 255) * 0.25;
  const bright = 0.97 + (hash[2] / 255) * 0.08;
  const buf = await sharp(jpegBuf)
    .resize(1200, 800, { fit: 'cover', position: hash[3] > 128 ? 'centre' : 'entropy' })
    .modulate({ brightness: bright, saturation: sat, hue: Math.round((hue - 0.5) * 24) })
    .toBuffer();
  await sharp(buf).png().toFile(path.join(OUT, `${stem}.png`));
  await sharp(buf).webp({ quality: 84 }).toFile(path.join(OUT, `${stem}.webp`));
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  // Install any GenerateImage assets already created into guides/
  const assetsDir = path.resolve(
    'C:/Users/soheb/.cursor/projects/c-Users-soheb-OneDrive-Desktop-menstrual-cycle-widget-master/assets',
  );
  if (fs.existsSync(assetsDir)) {
    for (const name of fs.readdirSync(assetsDir)) {
      if (!/\.(png|jpg|jpeg|webp)$/i.test(name)) continue;
      const stem = name.replace(/\.(png|jpg|jpeg|webp)$/i, '');
      const src = path.join(assetsDir, name);
      try {
        const buf = fs.readFileSync(src);
        await writeCover(stem, buf);
        console.log(`imported asset ${stem}`);
      } catch (err) {
        console.warn(`asset skip ${stem}: ${err.message}`);
      }
    }
  }

  const articles = loadArticles();
  const jobs = articles
    .map((article) => ({
      stem: stemOf(article),
      tags: tagsFor(article),
      lock: lockOf(stemOf(article)),
    }))
    .filter((j) => !alreadyDone(j.stem));

  console.log(`remaining ${jobs.length} / ${articles.length}`);
  let ok = 0;
  let fail = 0;

  for (let i = 0; i < jobs.length; i += 1) {
    const job = jobs[i];
    let success = false;
    for (let attempt = 1; attempt <= 4; attempt += 1) {
      try {
        const img = await download(job.tags, job.lock + attempt * 13);
        await writeCover(job.stem, img);
        ok += 1;
        success = true;
        console.log(`[${i + 1}/${jobs.length}] ok ${job.stem} (${job.tags})`);
        break;
      } catch (err) {
        console.warn(`  retry ${attempt} ${job.stem}: ${err.message}`);
        await sleep(800 * attempt);
      }
    }
    if (!success) {
      fail += 1;
      console.error(`FAIL ${job.stem}`);
    }
    await sleep(DELAY_MS);
  }

  console.log(`done ok=${ok} fail=${fail}`);
  if (fail > 0) process.exitCode = 1;
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
