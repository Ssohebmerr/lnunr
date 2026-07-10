/**
 * Rasterize SVG screenshots to PNG (fallback when emulator unavailable).
 * Real captures: run scripts/capture-screenshots.ps1 with emulator running.
 */
import { readdirSync, readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const shotsDir = join(__dirname, '../public/images/screenshots');

let sharp;
try {
  sharp = (await import('sharp')).default;
} catch {
  console.log('Installing sharp...');
  execSync('npm install sharp --no-save', { cwd: join(__dirname, '..'), stdio: 'inherit' });
  sharp = (await import('sharp')).default;
}

const svgs = readdirSync(shotsDir).filter((f) => f.endsWith('.svg'));
for (const svg of svgs) {
  const base = svg.replace('.svg', '');
  const pngPath = join(shotsDir, `${base}.png`);
  const svgPath = join(shotsDir, svg);
  const buf = readFileSync(svgPath);
  await sharp(buf, { density: 150 })
    .resize(390, 844, { fit: 'contain', background: { r: 255, g: 245, b: 248, alpha: 1 } })
    .png()
    .toFile(pngPath);
  console.log('PNG:', base + '.png');
}

console.log('Done —', svgs.length, 'PNG files in', shotsDir);
