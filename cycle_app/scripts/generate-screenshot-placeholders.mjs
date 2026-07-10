/**
 * Generates branded Lune app screenshot placeholders (SVG → usable in <img>).
 * Replace with real adb captures when emulator is available.
 */
import { writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const outDir = join(__dirname, '../public/images/screenshots');
mkdirSync(outDir, { recursive: true });

const screens = [
  { file: 'home', title: 'الرئيسية', subtitle: 'يوم 14 · مرحلة التبويض', accent: '#E8A0BF', body: 'حلقة الدورة · تواريخ مهمة · ملخص اليوم' },
  { file: 'calendar', title: 'تقويم الدورة', subtitle: 'مارس 2026', accent: '#D484A8', body: 'فترة · تبويض · خصوبة · تنبؤات' },
  { file: 'log', title: 'التسجيل اليومي', subtitle: 'اليوم', accent: '#C9B8E8', body: 'تدفق · أعراض · مزاج · ماء' },
  { file: 'goals', title: 'ما هدفك؟', subtitle: '8 أوضاع', accent: '#E8A0BF', body: 'عام · حمل · تجنب · حامل · سن أمل · PCOS' },
  { file: 'ai', title: 'Lune AI', subtitle: 'Premium', accent: '#5C3D52', body: 'محادثة مخصصة · 30 رسالة/يوم' },
  { file: 'analytics', title: 'التحليلات', subtitle: 'تقاريرك', accent: '#D484A8', body: 'CRS · PRS · رسوم بيانية' },
  { file: 'doctor-report', title: 'تقرير الطبيب', subtitle: 'شهري', accent: '#5C3D52', body: 'PDF · QR · ملاحظات AI' },
  { file: 'self-care', title: 'رعاية ذاتية', subtitle: 'مساحتك', accent: '#FFB4A2', body: 'تنفس · يوميات · تأكيدات · حركة' },
  { file: 'pregnancy', title: 'متابعة الحمل', subtitle: 'الأسبوع 24', accent: '#E8A0BF', body: 'نمو الجنين · ركلات · انقباضات' },
  { file: 'community', title: 'المجتمع', subtitle: '18+ · Premium', accent: '#C9B8E8', body: 'مجموعات · منشورات · دعم جماعي' },
  { file: 'magazine', title: 'مجلة Lune', subtitle: 'تعلّمي', accent: '#D484A8', body: 'مقالات · دورة · خصوبة · عافية' },
  { file: 'stealth', title: 'وضع التخفي', subtitle: 'آلة حاسبة', accent: '#5C3D52', body: 'PIN · إخفاء فوري' },
  { file: 'premium', title: 'Lune Premium', subtitle: 'اشتراك', accent: '#E8A045', body: 'AI · نسخ سحابي · مجتمع' },
  { file: 'partner', title: 'وضع الشريك', subtitle: 'دعم مشترك', accent: '#E8A0BF', body: 'كود دعوة · نصائح حسب المرحلة' },
  { file: 'privacy', title: 'الخصوصية', subtitle: 'مركز الثقة', accent: '#5C3D52', body: 'تشفير · موافقات · حذف فوري' },
];

function svg({ title, subtitle, accent, body }) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="390" height="844" viewBox="0 0 390 844">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#FFF5F8"/>
      <stop offset="100%" style="stop-color:#F5F0FA"/>
    </linearGradient>
  </defs>
  <rect width="390" height="844" fill="url(#bg)"/>
  <rect x="0" y="0" width="390" height="54" fill="#fff" opacity="0.9"/>
  <text x="24" y="34" font-family="Segoe UI, Tahoma, sans-serif" font-size="14" fill="#5C3D52" font-weight="600">9:41</text>
  <text x="320" y="34" font-family="Segoe UI, Tahoma, sans-serif" font-size="14" fill="#5C3D52">Lune</text>
  <circle cx="195" cy="280" r="100" fill="none" stroke="${accent}" stroke-width="12" opacity="0.35"/>
  <circle cx="195" cy="280" r="100" fill="none" stroke="${accent}" stroke-width="12" stroke-dasharray="420 220" stroke-linecap="round" transform="rotate(-90 195 280)"/>
  <text x="195" y="272" text-anchor="middle" font-family="Segoe UI, Tahoma, sans-serif" font-size="28" fill="#5C3D52" font-weight="700">${title}</text>
  <text x="195" y="302" text-anchor="middle" font-family="Segoe UI, Tahoma, sans-serif" font-size="13" fill="#8B6B7A">${subtitle}</text>
  <rect x="32" y="420" width="326" height="120" rx="20" fill="#fff" opacity="0.95"/>
  <text x="52" y="460" font-family="Segoe UI, Tahoma, sans-serif" font-size="15" fill="#5C3D52" font-weight="600">${body}</text>
  <rect x="52" y="478" width="200" height="8" rx="4" fill="${accent}" opacity="0.4"/>
  <rect x="52" y="496" width="140" height="8" rx="4" fill="${accent}" opacity="0.25"/>
  <rect x="0" y="780" width="390" height="64" fill="#fff" opacity="0.95"/>
  <circle cx="78" cy="812" r="6" fill="${accent}"/>
  <circle cx="156" cy="812" r="6" fill="#C9B8E8"/>
  <circle cx="234" cy="812" r="6" fill="#C9B8E8"/>
  <circle cx="312" cy="812" r="6" fill="#C9B8E8"/>
</svg>`;
}

for (const s of screens) {
  writeFileSync(join(outDir, `${s.file}.svg`), svg(s), 'utf8');
  console.log('wrote', s.file + '.svg');
}

writeFileSync(
  join(__dirname, 'screenshot-checklist.md'),
  `# Lune screenshot checklist

Capture with emulator running:
\`\`\`powershell
& "$env:LOCALAPPDATA\\Android\\Sdk\\platform-tools\\adb.exe" exec-out screencap -p > public/images/screenshots/<name>.png
\`\`\`

| File | Screen |
|------|--------|
${screens.map((s) => `| ${s.file}.png | ${s.title} |`).join('\n')}

Until real PNGs exist, the site uses SVG placeholders from \`generate-screenshot-placeholders.mjs\`.
`,
  'utf8'
);

console.log('Done —', screens.length, 'screenshots');
