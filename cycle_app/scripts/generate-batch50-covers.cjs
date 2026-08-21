/**
 * Generate covers for batch50 article stems from lifestyle photo bases.
 */
const path = require('path');
const sharp = require('sharp');
const { pathToFileURL } = require('url');

const OUT = path.resolve(__dirname, '../public/images/magazine/guides');
const BASES = [
  'cycle-tracking.png',
  'period-pain.png',
  'nutrition.png',
  'sleep.png',
  'doctor-visit.png',
  'fertility-awareness.png',
  'movement.png',
  'life-stages.png',
];

const CATEGORY_BASE = {
  basics: 0,
  health: 1,
  nutrition: 2,
  mind: 3,
  fertility: 5,
  fitness: 6,
  adult: 7,
};

const TINTS = [
  '#e8c4c8', '#d4a0a5', '#b8c4d8', '#9aa3b8', '#a8c4b8', '#c8a0c0', '#c89095',
  '#98c4b0', '#a0a8d0', '#c87880', '#c890a8', '#d0a898', '#b0a8c8', '#d0a0b0',
  '#d09088', '#c8c0a8', '#88b8d0', '#98b898', '#c8a888', '#c8b088', '#a098c8',
  '#c8a0b8', '#b098c8', '#b0a898', '#88c0b8', '#90a0c0', '#88c0a8', '#c8a898',
  '#98a8c8', '#88b8b0', '#d0a0b8', '#b8a8b0', '#98b0c8', '#b898c8', '#d0a8a0',
  '#c890a8', '#98c0b0', '#b8a0d0', '#d0b0a0', '#a8c0d0', '#c0b898', '#b0c8a8',
  '#d8a8b8', '#a8b0c8', '#c8b0c0', '#b8c8c0', '#d0c0a8', '#c0a8c8', '#a8d0c8',
  '#d0b8c8',
];

function hexToRgb(hex) {
  const h = hex.replace('#', '');
  return { r: parseInt(h.slice(0, 2), 16), g: parseInt(h.slice(2, 4), 16), b: parseInt(h.slice(4, 6), 16) };
}

async function makeCover(stem, baseIdx, tint, opacity = 0.28) {
  const basePath = path.join(OUT, BASES[baseIdx]);
  const pngPath = path.join(OUT, `${stem}.png`);
  const webpPath = path.join(OUT, `${stem}.webp`);
  const { r, g, b } = hexToRgb(tint);
  const svg = Buffer.from(
    `<svg width="1200" height="800" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <radialGradient id="g1" cx="28%" cy="22%" r="58%">
          <stop offset="0%" stop-color="${tint}" stop-opacity="0.5"/>
          <stop offset="100%" stop-color="${tint}" stop-opacity="0"/>
        </radialGradient>
        <radialGradient id="g2" cx="78%" cy="72%" r="48%">
          <stop offset="0%" stop-color="#ffffff" stop-opacity="0.22"/>
          <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
        </radialGradient>
      </defs>
      <rect width="1200" height="800" fill="rgba(${r},${g},${b},${opacity})"/>
      <rect width="1200" height="800" fill="url(#g1)"/>
      <rect width="1200" height="800" fill="url(#g2)"/>
    </svg>`,
  );
  const buf = await sharp(basePath)
    .resize(1200, 800, { fit: 'cover' })
    .modulate({ brightness: 1.03, saturation: 0.9 })
    .composite([{ input: svg, blend: 'over' }])
    .toBuffer();
  await sharp(buf).png().toFile(pngPath);
  await sharp(buf).webp({ quality: 82 }).toFile(webpPath);
  console.log('created', stem);
}

async function main() {
  const mod = await import(pathToFileURL(path.join(__dirname, 'extra-articles-batch50.mjs')).href);
  const articles = mod.batch50Articles;
  for (let i = 0; i < articles.length; i += 1) {
    const a = articles[i];
    const stem = a.cover.replace(/\.png$/, '');
    const baseIdx = CATEGORY_BASE[a.category] ?? 0;
    await makeCover(stem, baseIdx, TINTS[i % TINTS.length]);
  }
  console.log('done', articles.length);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
