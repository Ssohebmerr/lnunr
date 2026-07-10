/**
 * Crop emulator screenshots: trim black bars, resize to 390×844 for the website.
 * Run after capture-screenshots.ps1 or auto-capture-screenshots.ps1.
 */
import { readdirSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const shotsDir = join(__dirname, '../public/images/screenshots');
const TARGET_W = 390;
const TARGET_H = 844;

let sharp;
try {
  sharp = (await import('sharp')).default;
} catch {
  console.log('Installing sharp...');
  execSync('npm install sharp --no-save', { cwd: join(__dirname, '..'), stdio: 'inherit' });
  sharp = (await import('sharp')).default;
}

/** Trim uniform dark borders (emulator chrome / letterboxing). */
async function trimDarkBorders(inputPath) {
  const { data, info } = await sharp(inputPath)
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const { width, height, channels } = info;
  const isDark = (r, g, b) => r < 28 && g < 28 && b < 28;

  let top = 0;
  let bottom = height - 1;
  let left = 0;
  let right = width - 1;

  outerTop: for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * channels;
      if (!isDark(data[i], data[i + 1], data[i + 2])) {
        top = y;
        break outerTop;
      }
    }
  }

  outerBottom: for (let y = height - 1; y >= top; y--) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * channels;
      if (!isDark(data[i], data[i + 1], data[i + 2])) {
        bottom = y;
        break outerBottom;
      }
    }
  }

  outerLeft: for (let x = 0; x < width; x++) {
    for (let y = top; y <= bottom; y++) {
      const i = (y * width + x) * channels;
      if (!isDark(data[i], data[i + 1], data[i + 2])) {
        left = x;
        break outerLeft;
      }
    }
  }

  outerRight: for (let x = width - 1; x >= left; x--) {
    for (let y = top; y <= bottom; y++) {
      const i = (y * width + x) * channels;
      if (!isDark(data[i], data[i + 1], data[i + 2])) {
        right = x;
        break outerRight;
      }
    }
  }

  const cropW = Math.max(1, right - left + 1);
  const cropH = Math.max(1, bottom - top + 1);

  if (cropW === width && cropH === height) return inputPath;

  const trimmed = join(shotsDir, `_trim_${Date.now()}.png`);
  await sharp(inputPath)
    .extract({ left, top, width: cropW, height: cropH })
    .png()
    .toFile(trimmed);
  return trimmed;
}

const pngs = readdirSync(shotsDir).filter((f) => f.endsWith('.png') && !f.startsWith('_'));
if (pngs.length === 0) {
  console.error('No PNG files in', shotsDir);
  process.exit(1);
}

for (const file of pngs) {
  const src = join(shotsDir, file);
  const trimmed = await trimDarkBorders(src);
  await sharp(trimmed)
    .resize(TARGET_W, TARGET_H, {
      fit: 'cover',
      position: 'centre',
    })
    .png({ compressionLevel: 9 })
    .toFile(src + '.tmp');

  const { renameSync, unlinkSync } = await import('fs');
  renameSync(src + '.tmp', src);
  if (trimmed !== src && existsSync(trimmed)) unlinkSync(trimmed);
  console.log('Cropped:', file, `→ ${TARGET_W}×${TARGET_H}`);
}

console.log('Done —', pngs.length, 'files in', shotsDir);
