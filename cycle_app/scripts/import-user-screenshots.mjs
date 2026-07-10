/**
 * Import JPG screenshots from Desktop/اب لهب → public/images/screenshots/*.png
 * Then run: node scripts/crop-screenshots.mjs
 */
import { copyFileSync, existsSync, mkdirSync, readdirSync, unlinkSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const srcDir = join(process.env.USERPROFILE || '', 'OneDrive', 'Desktop', 'اب لهب');
const outDir = join(__dirname, '../public/images/screenshots');

/** @type {Record<string, string>} */
const MAP = {
  'home.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٤-٣٣-٦٤٩_com.lune.app.jpg',
  'calendar.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٥-٤٨-٣٧٨_com.lune.app.jpg',
  'log.png': 'Screenshot_٢٠٢٦-٠٧-٠٧-١٤-٠١-٥٠-٢٤٨_com.lune.app.jpg',
  'goals.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٣-٥٦-٠٨٧_com.lune.app.jpg',
  'ai.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٣-١٤-٤٢١_com.lune.app.jpg',
  'analytics.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٥٩-٣٤-٧٧٣_com.lune.app.jpg',
  'doctor-report.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٥٦-٥٣-٠٣٩_com.lune.app.jpg',
  'self-care.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٢-٢١-٣٤٤_com.lune.app.jpg',
  'pregnancy.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٢-٠١-٧٢٥_com.lune.app.jpg',
  'community.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٢-١٠-٠٠١_com.lune.app.jpg',
  'magazine.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٦-١٣-٢٧٣_com.lune.app.jpg',
  'stealth.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٥٩-٥٧-١٣٤_com.lune.app.jpg',
  'premium.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٢-٢٨-١٥١_com.lune.app.jpg',
  'partner.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٦-١٨-٠٠١_com.lune.app.jpg',
  'privacy.png': 'Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٥٩-٥٧-١٣٤_com.lune.app.jpg',
};

if (!existsSync(srcDir)) {
  console.error('Source folder not found:', srcDir);
  process.exit(1);
}

let sharp;
try {
  sharp = (await import('sharp')).default;
} catch {
  execSync('npm install sharp --no-save', { cwd: join(__dirname, '..'), stdio: 'inherit' });
  sharp = (await import('sharp')).default;
}

mkdirSync(outDir, { recursive: true });

for (const [png, jpg] of Object.entries(MAP)) {
  const src = join(srcDir, jpg);
  const dest = join(outDir, png);
  if (!existsSync(src)) {
    console.error('Missing:', jpg);
    process.exit(1);
  }
  await sharp(src).png({ compressionLevel: 9 }).toFile(dest);
  console.log('Imported', png, '<-', jpg);
}

// Remove debug captures from earlier automation
for (const f of readdirSync(outDir)) {
  if (f.startsWith('_debug') || f.startsWith('_verify') || f.startsWith('_trim')) {
    unlinkSync(join(outDir, f));
    console.log('Removed', f);
  }
}

console.log('Done — run: node scripts/crop-screenshots.mjs');
