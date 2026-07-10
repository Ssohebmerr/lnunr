/**
 * Shortens index.html: removes #discover, fixes duplicate #features, links to feature pages.
 */
import { readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const indexPath = join(__dirname, '../public/index.html');
let html = readFileSync(indexPath, 'utf8');

const featureLinks = [
  { href: '/features/calendar.html', icon: 'calendar', title: 'تقويم الدورة', desc: 'فترة، تبويض، مراحل، وتنبؤات تتحسن مع كل سجل.' },
  { href: '/features/daily-log.html', icon: 'log', title: 'التسجيل اليومي', desc: 'تدفق، أعراض، مزاج، ماء، وأكثر في ثوانٍ.' },
  { href: '/features/ai.html', icon: 'ai', title: 'Lune AI', desc: 'مساعد ذكي Premium — 30 رسالة/يوم بموافقتكِ.' },
  { href: '/features/analytics.html', icon: 'analytics', title: 'تحليلات ورؤى', desc: 'CRS، PRS، رسوم بيانية، وأنماط أعراض.' },
  { href: '/features/doctor-report.html', icon: 'report', title: 'تقرير الطبيب', desc: 'PDF، QR، مشاركة — بقراركِ أنتِ.' },
  { href: '/features/privacy-stealth.html', icon: 'shield', title: 'خصوصية وتخفي', desc: 'AES-256، آلة حاسبة، حذف فوري.' },
  { href: '/features/community.html', icon: 'people', title: 'مجتمع 18+', desc: 'مجموعات دعم — Premium مع مراجعة.' },
  { href: '/features/self-care.html', icon: 'heart', title: 'رعاية ذاتية', desc: 'تنفس، يوميات، تأكيدات، تحديات.' },
  { href: '/features/pregnancy.html', icon: 'baby', title: 'متابعة الحمل', desc: 'أسبوع بأسبوع، ركلات، انقباضات.' },
  { href: '/features/magazine.html', icon: 'book', title: 'مجلة Lune', desc: 'مقالات تعليمية بالعربية والإنجليزية.' },
  { href: '/features/partner.html', icon: 'partner', title: 'وضع الشريك', desc: 'كود دعوة ونصائح دعم حسب المرحلة.' },
  { href: '/features/wellness-hub.html', icon: 'wellness', title: 'مركز العناية', desc: 'حبوب، منتجات صحية، LARC، وسجل النشاط.' },
  { href: '/features/reminders.html', icon: 'bell', title: 'تذكيرات ذكية', desc: 'دورة، إباضة، ونصائح حسب المرحلة.' },
  { href: '/features/guest-mode.html', icon: 'guest', title: 'وضع الضيف', desc: 'بدون إيميل — ملف محلي خاص.' },
  { href: '/features/cloud-backup.html', icon: 'cloud', title: 'نسخ سحابي', desc: 'نسخ احتياطي مشفّر — Premium.' },
];

const icons = {
  calendar: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
  log: '<path d="M12 20h9M12 4v16M4 4h16"/>',
  ai: '<path d="M12 3a5 5 0 0 0-5 5v2a5 5 0 0 0 10 0V8a5 5 0 0 0-5-5z"/>',
  analytics: '<path d="M3 3v18h18"/><path d="M7 16l4-6 4 3 5-8"/>',
  report: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>',
  shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
  people: '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/>',
  heart: '<path d="M12 2a10 10 0 0 1 10 10c0 5-4 9-10 12C6 21 2 17 2 12A10 10 0 0 1 12 2z"/>',
  baby: '<circle cx="12" cy="7" r="4"/><path d="M6 21v-2a6 6 0 0 1 12 0v2"/>',
  book: '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>',
  partner: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 11l-3 3-2-2"/>',
  wellness: '<path d="M12 2l3 7h7l-5.5 4.5 2 7L12 17l-6.5 3.5 2-7L2 9h7z"/>',
  bell: '<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/>',
  guest: '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  cloud: '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/>',
};

const featuresSection = `<!-- Features overview -->
<section class="section" id="features">
  <div class="container">
    <div class="section-header">
      <h2>كل الميزات — اختاري واقرئي بالتفصيل</h2>
      <p>15 أداة أساسية — كل ميزة لها صفحة خاصة بشرح كامل ولقطة من التطبيق.</p>
    </div>
    <div class="features features--expanded">
${featureLinks.map((f) => `      <a class="feature feature-card-link" href="${f.href}">
        <div class="feature-icon"><svg class="icon" viewBox="0 0 24 24">${icons[f.icon]}</svg></div>
        <h3>${f.title}</h3>
        <p>${f.desc}</p>
      </a>`).join('\n')}
    </div>
    <div class="features-more-cta">
      <a href="/features.html" class="btn btn-primary">استكشفي كل الميزات ←</a>
    </div>
  </div>
</section>`;

// Remove #discover section
html = html.replace(
  /<!-- Deep feature dives -->[\s\S]*?<\/section>\n\n\n<!-- Visual showcase -->/,
  '<!-- Visual showcase -->'
);

// Replace both duplicate features sections with single linked section
html = html.replace(
  /<!-- Features overview -->[\s\S]*?<\/section>\n\n\n<section class="section" id="features">[\s\S]*?<\/section>\n\n/,
  featuresSection + '\n\n'
);

// Nav updates
html = html.replace(/<a href="#discover">اكتشفي<\/a>\n/g, '');
html = html.replace(
  /<a href="#features">الميزات<\/a>/g,
  '<a href="/features.html">الميزات</a>'
);
html = html.replace(
  /<a href="#discover">اكتشفي<\/a>/g,
  '<a href="/features.html">الميزات</a>'
);

// Can-do links
const canDoMap = {
  '#feat-calendar': '/features/calendar.html',
  '#feat-analytics': '/features/analytics.html',
  '#feat-selfcare': '/features/self-care.html',
  '#feat-magazine': '/features/magazine.html',
  '#feat-community': '/features/community.html',
  '#feat-privacy': '/features/privacy-stealth.html',
};
for (const [from, to] of Object.entries(canDoMap)) {
  html = html.replaceAll(`href="${from}"`, `href="${to}"`);
}

// PNG images with fallback
html = html.replace(
  /src="\/images\/screenshots\/([^"]+)\.svg"/g,
  'src="/images/screenshots/$1.png" onerror="this.onerror=null;this.src=\'/images/screenshots/$1.svg\'"'
);

// Remove unsplash hero photo, keep device frame only
html = html.replace(
  /<img\s+class="hero-photo"[\s\S]*?loading="eager"\s*\/>/,
  ''
);

// CSS v8 + features.css
html = html.replace(/\?v=7/g, '?v=8');
if (!html.includes('features.css')) {
  html = html.replace(
    '<link rel="stylesheet" href="home-content.css?v=8" />',
    '<link rel="stylesheet" href="home-content.css?v=8" />\n<link rel="stylesheet" href="features.css?v=8" />'
  );
}

// Remove scroll reveal script for discover rows (optional keep - no harm)
// Footer link to features
html = html.replace(
  '<a href="/about.html">عن التطبيق</a>',
  '<a href="/about.html">عن التطبيق</a>\n      <a href="/features.html">الميزات</a>'
);
// Avoid duplicate in nav if already there - fix double الميزات in nav
html = html.replace(
  /<a href="\/features\.html">الميزات<\/a>\n      <a href="\/contact\.html">اتصل بنا<\/a>\n      <a href="#cando">ما يمكنك فعله<\/a>\n      <a href="#goals">أهدافك<\/a>\n      <a href="\/features\.html">الميزات<\/a>/,
  '<a href="/contact.html">اتصل بنا</a>\n      <a href="#cando">ما يمكنك فعله</a>\n      <a href="#goals">أهدافك</a>\n      <a href="/features.html">الميزات</a>'
);

writeFileSync(indexPath, html, 'utf8');
console.log('index.html shortened and linked to feature pages');
