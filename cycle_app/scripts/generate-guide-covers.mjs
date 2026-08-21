/**
 * Fast atmospheric covers with sharp (soft gradients + blurred orbs).
 * For visual consistency with lifestyle photos, we also copy-tint from
 * existing guide photos when available as a photographic base.
 */
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

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

const COVERS = {
  'cycle-phases': { base: 0, tint: '#e8c4c8', opacity: 0.28 },
  spotting: { base: 1, tint: '#d4a0a5', opacity: 0.3 },
  'symptom-diary': { base: 0, tint: '#b8c4d8', opacity: 0.25 },
  'privacy-tracking': { base: 4, tint: '#9aa3b8', opacity: 0.28 },
  'lab-results': { base: 4, tint: '#a8c4b8', opacity: 0.26 },
  'ovarian-cysts': { base: 7, tint: '#c8a0c0', opacity: 0.28 },
  'pelvic-pain': { base: 1, tint: '#c89095', opacity: 0.3 },
  'vaginal-health': { base: 2, tint: '#98c4b0', opacity: 0.26 },
  migraine: { base: 3, tint: '#a0a8d0', opacity: 0.3 },
  anemia: { base: 1, tint: '#c87880', opacity: 0.28 },
  'endo-care': { base: 1, tint: '#c890a8', opacity: 0.3 },
  intermenstrual: { base: 0, tint: '#d0a898', opacity: 0.26 },
  amenorrhea: { base: 7, tint: '#b0a8c8', opacity: 0.28 },
  'breast-pain': { base: 7, tint: '#d0a0b0', opacity: 0.28 },
  'emergency-care': { base: 4, tint: '#d09088', opacity: 0.28 },
  'calcium-bones': { base: 2, tint: '#c8c0a8', opacity: 0.26 },
  hydration: { base: 2, tint: '#88b8d0', opacity: 0.28 },
  'diabetes-hormones': { base: 2, tint: '#98b898', opacity: 0.26 },
  'caffeine-mood': { base: 3, tint: '#c8a888', opacity: 0.28 },
  'meals-pain': { base: 2, tint: '#c8b088', opacity: 0.28 },
  'anxiety-cycle': { base: 3, tint: '#a098c8', opacity: 0.3 },
  'body-image': { base: 3, tint: '#c8a0b8', opacity: 0.28 },
  'partner-support': { base: 7, tint: '#b098c8', opacity: 0.28 },
  'fatigue-mood': { base: 3, tint: '#b0a898', opacity: 0.26 },
  'calming-practices': { base: 3, tint: '#88c0b8', opacity: 0.28 },
  'strength-cycle': { base: 6, tint: '#90a0c0', opacity: 0.28 },
  'yoga-cycle': { base: 6, tint: '#88c0a8', opacity: 0.28 },
  'postpartum-movement': { base: 6, tint: '#c8a898', opacity: 0.28 },
  'exercise-pcos': { base: 6, tint: '#98a8c8', opacity: 0.28 },
  'active-recovery': { base: 6, tint: '#88b8b0', opacity: 0.28 },
  'ttc-six-months': { base: 5, tint: '#d0a0b8', opacity: 0.28 },
  'early-loss': { base: 5, tint: '#b8a8b0', opacity: 0.26 },
  'fertility-tests': { base: 5, tint: '#98b0c8', opacity: 0.28 },
  'fam-limits': { base: 5, tint: '#b898c8', opacity: 0.28 },
  'early-pregnancy': { base: 5, tint: '#d0a8a0', opacity: 0.26 },
  'breastfeeding-fertility': { base: 7, tint: '#c8a898', opacity: 0.28 },
  'pain-sex': { base: 7, tint: '#c890a8', opacity: 0.28 },
  'discharge-sex': { base: 2, tint: '#98c0b0', opacity: 0.26 },
  'contraception-desire': { base: 5, tint: '#b098c8', opacity: 0.28 },
  'desire-boundaries': { base: 3, tint: '#c8a0b8', opacity: 0.28 },
};

function hexToRgba(hex, opacity) {
  const h = hex.replace('#', '');
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  const a = Math.round(opacity * 255);
  return { r, g, b, alpha: a };
}

async function makeCover(name, cfg) {
  const baseName = BASES[cfg.base];
  const basePath = path.join(OUT, baseName);
  const pngPath = path.join(OUT, `${name}.png`);
  const webpPath = path.join(OUT, `${name}.webp`);
  if (fs.existsSync(webpPath) && fs.existsSync(pngPath)) return false;

  const tint = hexToRgba(cfg.tint, cfg.opacity);
  const svg = Buffer.from(
    `<svg width="1200" height="800" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <radialGradient id="g1" cx="30%" cy="25%" r="55%">
          <stop offset="0%" stop-color="${cfg.tint}" stop-opacity="0.45"/>
          <stop offset="100%" stop-color="${cfg.tint}" stop-opacity="0"/>
        </radialGradient>
        <radialGradient id="g2" cx="75%" cy="70%" r="50%">
          <stop offset="0%" stop-color="#ffffff" stop-opacity="0.2"/>
          <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
        </radialGradient>
      </defs>
      <rect width="1200" height="800" fill="rgba(${tint.r},${tint.g},${tint.b},${cfg.opacity})"/>
      <rect width="1200" height="800" fill="url(#g1)"/>
      <rect width="1200" height="800" fill="url(#g2)"/>
    </svg>`,
  );

  const pipeline = sharp(basePath)
    .resize(1200, 800, { fit: 'cover' })
    .modulate({ brightness: 1.02, saturation: 0.92 })
    .composite([{ input: svg, blend: 'over' }]);

  await pipeline.clone().png().toFile(pngPath);
  await pipeline.webp({ quality: 82 }).toFile(webpPath);
  return true;
}

async function main() {
  let created = 0;
  for (const [name, cfg] of Object.entries(COVERS)) {
    const ok = await makeCover(name, cfg);
    if (ok) {
      created += 1;
      console.log('created', name);
    }
  }
  console.log(`done created=${created}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
