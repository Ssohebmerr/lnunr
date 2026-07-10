/**
 * Generates features.html hub + 15 feature detail pages.
 */
import { writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const publicDir = join(__dirname, '../public');
const featuresDir = join(publicDir, 'features');
mkdirSync(featuresDir, { recursive: true });

const features = [
  {
    slug: 'calendar',
    image: 'calendar',
    category: 'تتبّع',
    tag: 'تقويم ذكي',
    title: 'تنبؤات مبنية على تاريخكِ الحقيقي',
    summary: 'فترة، تبويض، مراحل — تنبؤات تتحسن مع كل سجل.',
    paragraphs: [
      'سجّلي آخر فترة — والتقويم يتعلم من دورتكِ. شوفي مراحل الدورة، موعد التبويض، والأيام المتبقية بوضوح على شاشة عربية أنيقة.',
      'التتبع الأساسي يعمل بدون إنترنت: بياناتكِ تبقى على جهازكِ حتى بدون اتصال.',
    ],
    bullets: ['تتبع الفترة والتدفق والأعراض والمزاج', 'تنبؤات تتحسن كلما سجّلتِ أكثر', 'عرض مراحل الدورة والخصوبة', 'تقويم كامل من الشاشة الرئيسية', 'متوافق مع كل الأهداف الثمانية'],
    cta: { href: '/index.html#download', label: 'جرّبي مجاناً' },
  },
  {
    slug: 'daily-log',
    image: 'log',
    category: 'تتبّع',
    tag: 'تسجيل يومي',
    title: 'سجّلي يومكِ في ثوانٍ — وبني صورة صحية أوضح',
    summary: 'تدفق، أعراض، مزاج، ماء — في ثوانٍ.',
    paragraphs: [
      'من زر التسجيل المركزي: تدفق، أعراض، مزاج، شرب ماء، وأكثر. كل سجل يقوّي التنبؤات والتحليلات.',
      'تأكيد فوري عند الحفظ — وتذكير لطيف إذا فاتكِ يوم.',
    ],
    bullets: ['واجهة بسيطة للاستخدام اليومي', 'ربط السجل بمرحلة الدورة تلقائياً', 'سلسلة تسجيل للتحفيز اللطيف', 'يعمل محلياً بدون حساب', 'تصدير ضمن التقرير الشهري'],
    cta: { href: '/index.html#download', label: 'ابدئي التسجيل' },
  },
  {
    slug: 'ai',
    image: 'ai',
    category: 'ذكاء اصطناعي',
    tag: 'ذكاء اصطناعي',
    title: 'Lune AI — رفيقتكِ الخاصة للدورة (Premium)',
    summary: 'مساعد Premium — 30 رسالة/يوم بموافقتكِ.',
    paragraphs: [
      'اسألي عن الأعراض، مرحلة دورتكِ، أو نصائح العافية. المساعد يفهم سياق سجلاتكِ بعد موافقتكِ الصريحة.',
      '30 رسالة يومياً للمشتركات Premium — شفافية كاملة بدون مفاجآت.',
    ],
    bullets: ['محادثة مخصصة حسب هدفكِ ومرحلة دورتكِ', 'اقتراحات جاهزة للأسئلة الشائعة', 'ملخص يومي AI على الشاشة الرئيسية', 'ملاحظات AI اختيارية في تقرير الطبيب', 'تشخيص AI من الإعدادات للدعم'],
    cta: { href: '/index.html#premium', label: 'اعرفي Premium' },
  },
  {
    slug: 'analytics',
    image: 'analytics',
    category: 'افهمي',
    tag: 'تحليلات',
    title: 'افهمي جسمكِ بأرقام ورسوم واضحة',
    summary: 'CRS، PRS، رسوم بيانية، وأنماط أعراض.',
    paragraphs: [
      'انتظام الدورة (CRS) وانتظام الحيض (PRS)، رسوم بيانية للأعراض والمزاج، ومؤشرات هرمونية تفسيرية.',
      'تقارير تتكيّف مع هدفكِ: خصوبة، حماية، حمل، سن أمل، PCOS، أو استشفاء.',
    ],
    bullets: ['تحليلات كاملة من تبويب التقارير', 'جدول تاريخ الدورة ورسوم تفاعلية', 'أنماط الأعراض عبر الأسابيع', 'ملخص أسبوعي AI (Premium)', 'تصدير ومشاركة الرسوم'],
    cta: { href: '/index.html#download', label: 'شوفي تقاريركِ' },
  },
  {
    slug: 'doctor-report',
    image: 'doctor-report',
    category: 'افهمي',
    tag: 'تقرير صحي',
    title: 'شاركي مع طبيبتكِ بثقة — دون إرسال تلقائي',
    summary: 'PDF، QR، مشاركة — بقراركِ أنتِ.',
    paragraphs: [
      'ملخص شهري منسق: دورة، أعراض، مزاج، وتدفق — جاهز للزيارة.',
      'تصدير PDF، TXT، CSV، أو JSON. مشاركة، نسخ، أو QR — أنتِ من يقرر.',
    ],
    bullets: ['بيانات المريضة قابلة للتعديل', 'ملاحظات AI اختيارية (Premium)', 'لا يُرسل لأي جهة تلقائياً', 'مناسب لكل الأهداف', 'إخلاء: ليس تشخيصاً طبياً'],
    cta: { href: '/trust-hub.html', label: 'مركز الثقة' },
  },
  {
    slug: 'privacy-stealth',
    image: 'stealth',
    category: 'خصوصية',
    tag: 'خصوصية',
    title: 'بياناتكِ ملككِ — تشفير، تخفي، وحذف فوري',
    summary: 'AES-256، آلة حاسبة، حذف فوري.',
    paragraphs: [
      'AES-256 على الجهاز. لا إعلانات ولا بيع بيانات. وضع التخفي يحوّل التطبيق لآلة حاسبة بـ PIN.',
      'حذف الحساب فوري من مركز الخصوصية — بدون انتظار 30 يوماً.',
    ],
    bullets: ['وضع ضيف بدون إيميل', 'موافقات منفصلة للسحابة والAI والمجتمع', '21 سؤالاً في مركز الثقة', 'نسخ احتياطي محلي للتصدير', 'إخفاء التطبيق فوراً من الشاشة الرئيسية'],
    cta: { href: '/security.html', label: 'صفحة الأمان' },
  },
  {
    slug: 'community',
    image: 'community',
    category: 'تواصل',
    tag: 'مجتمع',
    title: 'مجتمعات صغيرة للدعم — 18+ وPremium',
    summary: 'مجموعات دعم — Premium مع مراجعة.',
    paragraphs: [
      'خلاصة، استكشاف، مجموعاتي، ومحفوظات. اسم مستعار — ليس حسابكِ الحقيقي.',
      'دعم جماعي فقط — ليس نصيحة طبية. إبلاغ وحظر للمحتوى غير الآمن.',
    ],
    bullets: ['منشورات، تعليقات، إعجابات، واستطلاعات', 'قصص (حسب الإعدادات)', 'صندوق نشاط للتفاعلات', 'بوابة عمر 18+', 'مراجعة محتوى وإشراف'],
    cta: { href: '/index.html#premium', label: 'Premium للمجتمع' },
  },
  {
    slug: 'self-care',
    image: 'self-care',
    category: 'عناية',
    tag: 'رعاية ذاتية',
    title: 'مساحة هادئة للعناية بنفسكِ كل يوم',
    summary: 'تنفس، يوميات، تأكيدات، تحديات.',
    paragraphs: [
      'تنفس مربع، تأكيدات (مع AI شخصي Premium)، يوميات مع تأمّل AI، حركة لطيفة، وطقوس يومية.',
      'مكتبة عناية حسب مرحلة الدورة وتحديات تحفيزية لطيفة.',
    ],
    bullets: ['فحص مزاج يومي', 'همسة اليوم (Premium)', 'دليل العناية حسب الدورة', 'سلسلة طقوس يومية', 'محتوى يتكيّف مع هدفكِ'],
    cta: { href: '/index.html#download', label: 'جرّبي الرعاية الذاتية' },
  },
  {
    slug: 'pregnancy',
    image: 'pregnancy',
    category: 'عناية',
    tag: 'حمل',
    title: 'متابعة حملكِ أسبوعاً بأسبوع',
    summary: 'أسبوع بأسبوع، ركلات، انقباضات.',
    paragraphs: [
      'حجم الجنين، قوائم الثلث، عداد الركلات، مؤقت الانقباضات، سجل الوزن، وعناية الحمل.',
      'وضع «أنا حامل» يغيّر الشاشة الرئيسية والتقارير بالكامل.',
    ],
    bullets: ['بطولة 3D تقريبية للجنين', 'قوائم تحقق لكل ثلث', 'تذكيرات ذكية للحمل', 'تقارير حمل مخصصة', 'ليس بديلاً عن المتابعة الطبية'],
    cta: { href: '/index.html#goals', label: 'اختاري هدف الحمل' },
  },
  {
    slug: 'magazine',
    image: 'magazine',
    category: 'تعلّم',
    tag: 'تعليم',
    title: 'مجلة Lune — تعلّمي بثقة',
    summary: 'مقالات تعليمية بالعربية والإنجليزية.',
    paragraphs: [
      'مقالات عن أساسيات الدورة، الصحة، التغذية، العقل، ومحتوى 18+ — بالعربية والإنجليزية.',
      'محتوى تعليمي فقط — ليس نصيحة طبية. متاح مجاناً داخل التطبيق.',
    ],
    bullets: ['قارئ مقالات أنيق', 'تصنيفات متعددة', 'أسئلة مجهولة صحية', 'ربط بالتعليم من الشاشة الرئيسية', 'تحديثات محتوى دورية'],
    cta: { href: '/index.html#download', label: 'اقرئي في التطبيق' },
  },
  {
    slug: 'partner',
    image: 'partner',
    category: 'تواصل',
    tag: 'شريك',
    title: 'وضع الشريك — دعم مشترك بلطف',
    summary: 'كود دعوة ونصائح دعم حسب المرحلة.',
    paragraphs: [
      'ادعي شريككِ بكود — يشوف فقط ما تختارين مشاركته: المرحلة، أيام للفترة، مستوى الألم.',
      'نصائح «كيف تدعمها اليوم» حسب مرحلة دورتكِ.',
    ],
    bullets: ['تحكم كامل بما يُشارك', 'قسم منفصل للشريك', 'نصائح داعمة غير طبية', 'خصوصية الطرفين', 'اختياري بالكامل'],
    cta: { href: '/partner.html', label: 'شراكات ووضع الشريك' },
  },
  {
    slug: 'wellness-hub',
    image: 'log',
    category: 'تتبّع',
    tag: 'مركز العناية',
    title: 'أدوات منع الحمل والعافية في مكان واحد',
    summary: 'حبوب، منتجات صحية، LARC، وسجل النشاط.',
    paragraphs: [
      'يوميات أعراض موسّعة، حبوب منع الحمل، منتجات صحية، سجل النشاط الجنسي، ووسائل LARC طويلة المفعول.',
      'مكمّل للتتبع الأساسي — خصوصياً لأهداف الصحة الجنسية وتجنب الحمل.',
    ],
    bullets: ['تذكير بالحبوب', 'تتبع المنتجات الصحية', 'سجل النشاط مع الحماية', 'واجهة عربية متكاملة', 'بيانات محلية مشفّرة'],
    cta: { href: '/features/daily-log.html', label: 'التسجيل اليومي' },
  },
  {
    slug: 'reminders',
    image: 'home',
    category: 'تتبّع',
    tag: 'تذكيرات',
    title: 'تذكيرات ذكية حسب مرحلة دورتكِ',
    summary: 'دورة، إباضة، ونصائح حسب المرحلة.',
    paragraphs: [
      'تذكير بالفترة والإباضة، مع نصائح مرحلية ذكية تتكيّف مع الحمل أو الدورة.',
      'تحكم كامل: فعّلي أو عطّلي من الإعدادات.',
    ],
    bullets: ['تذكير دورة وإباضة', 'نصائح حسب المرحلة', 'إشعارات محلية وFCM', 'إعدادات من الحساب', 'لا إزعاج بدون موافقتكِ'],
    cta: { href: '/index.html#download', label: 'فعّلي التذكيرات' },
  },
  {
    slug: 'cloud-backup',
    image: 'premium',
    category: 'خصوصية',
    tag: 'نسخ سحابي',
    title: 'نسخ احتياطي مشفّر — Premium',
    summary: 'نسخ احتياطي مشفّر — Premium.',
    paragraphs: [
      'مزامنة مشفّرة لسجلاتكِ عبر Firebase — فقط بعد موافقتكِ ومع اشتراك Premium.',
      'استعادة عند تغيير الجهاز. أو استخدمي التصدير المحلي مجاناً.',
    ],
    bullets: ['مزامنة يدوية «الآن»', 'استعادة من النسخة', 'تصدير/استيراد محلي مجاني', 'موافقة صريحة مطلوبة', 'لا تفعيل تلقائي'],
    cta: { href: '/index.html#premium', label: 'اشتركي في Premium' },
  },
  {
    slug: 'guest-mode',
    image: 'privacy',
    category: 'خصوصية',
    tag: 'وضع ضيف',
    title: 'ابدئي فوراً — بياناتكِ تبقى ملككِ',
    summary: 'بدون إيميل — ملف محلي خاص.',
    paragraphs: [
      'وضع ضيف خاص: ملف محلي بدون إيميل. تسجيل دخول اختياري للمزامنة السحابية فقط.',
      'تشفير AES-256 من أول يوم. حذف فوري متاح دائماً.',
    ],
    bullets: ['بدون حساب للتتبع الأساسي', 'جلسة Firebase مجهولة للضيف', 'ترقية لحساب لاحقاً', 'مركز خصوصية شامل', 'شفافية كاملة في مركز الثقة'],
    cta: { href: '/privacy-policy.html', label: 'سياسة الخصوصية' },
  },
];

function shotImg(image, alt) {
  return `<img src="/images/screenshots/${image}.png" alt="${alt}" loading="lazy" width="280" height="606" onerror="this.onerror=null;this.src='/images/screenshots/${image}.svg'" />`;
}

function navHtml(active = '') {
  return `<nav class="site-nav">
  <div class="container">
    <a href="/index.html" class="nav-brand"><img src="/images/logo.png" alt="" class="nav-logo" width="36" height="36" /><span>Lune</span></a>
    <div class="nav-links">
      <a href="/about.html">عن التطبيق</a>
      <a href="/features.html"${active === 'features' ? ' class="active"' : ''}>الميزات</a>
      <a href="/contact.html">اتصل بنا</a>
      <a href="/trust-hub.html">الثقة</a>
      <a href="/index.html#download" class="btn btn-primary btn-sm">حمّلي التطبيق</a>
    </div>
    <button class="nav-toggle" id="navToggle" aria-label="القائمة"><svg class="icon" viewBox="0 0 24 24"><path d="M4 7h16M4 12h16M4 17h16"/></svg></button>
  </div>
</nav>
<div class="nav-drawer" id="navDrawer">
  <div class="nav-drawer-panel">
    <button class="nav-drawer-close" id="navClose" aria-label="إغلاق">×</button>
    <a href="/index.html">الرئيسية</a>
    <a href="/features.html">كل الميزات</a>
    <a href="/about.html">عن Lune</a>
    <a href="/contact.html">اتصل بنا</a>
    <a href="/trust-hub.html">مركز الثقة</a>
    <a href="/index.html#download">حمّلي التطبيق</a>
  </div>
</div>`;
}

const footerHtml = `<footer class="site-footer">
  <div class="container">
    <div class="footer-grid">
      <div class="footer-col"><h4>معلومات</h4><a href="/about.html">عن Lune</a><a href="/features.html">الميزات</a><a href="/contact.html">اتصل بنا</a></div>
      <div class="footer-col"><h4>الثقة</h4><a href="/trust-hub.html">مركز الثقة</a><a href="/security.html">الأمان</a><a href="/privacy-faq.html">أسئلة شائعة</a></div>
      <div class="footer-col"><h4>قانوني</h4><a href="/privacy-policy.html">سياسة الخصوصية</a><a href="/terms-of-service.html">الشروط</a></div>
      <div class="footer-col"><h4>تواصل</h4><a href="mailto:merrsoheb@gmail.com">merrsoheb@gmail.com</a></div>
    </div>
    <div class="footer-bottom">&copy; 2026 Lune</div>
  </div>
</footer>
<script>
  const drawer = document.getElementById('navDrawer');
  document.getElementById('navToggle')?.addEventListener('click', () => drawer.classList.add('open'));
  document.getElementById('navClose')?.addEventListener('click', () => drawer.classList.remove('open'));
  drawer?.addEventListener('click', (e) => { if (e.target === drawer) drawer.classList.remove('open'); });
</script>`;

function pageShell({ title, desc, body }) {
  return `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8" />
<link rel="icon" href="/images/favicon.png" type="image/png" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>${title}</title>
<meta name="description" content="${desc}" />
<link rel="stylesheet" href="/site.css?v=8" />
<link rel="stylesheet" href="/features.css?v=8" />
</head>
<body>
${navHtml('features')}
${body}
${footerHtml}
</body>
</html>`;
}

// Hub page
const categories = [...new Set(features.map((f) => f.category))];
let hubBody = `<section class="page-hero features-hero">
  <div class="container">
    <a href="/index.html" class="breadcrumb">← Lune</a>
    <h1>اكتشفي ميزات Lune</h1>
    <p class="lead">15 أداة مفصّلة — كل ميزة بشرح كامل ولقطة من التطبيق.</p>
  </div>
</section>
<main class="page-main"><div class="content-wrap">`;

for (const cat of categories) {
  const items = features.filter((f) => f.category === cat);
  hubBody += `<h2 class="features-cat-title">${cat}</h2><div class="features-hub-grid">`;
  for (const f of items) {
    hubBody += `<a class="features-hub-card" href="/features/${f.slug}.html">
      <div class="features-hub-shot">${shotImg(f.image, f.tag)}</div>
      <span class="feature-tag">${f.tag}</span>
      <h3>${f.title.split('—')[0].trim()}</h3>
      <p>${f.summary}</p>
      <span class="features-hub-link">اقرئي المزيد ←</span>
    </a>`;
  }
  hubBody += `</div>`;
}
hubBody += `</div></main>`;

writeFileSync(join(publicDir, 'features.html'), pageShell({
  title: 'Lune — الميزات',
  desc: 'اكتشفي كل ميزات Lune: تقويم، AI، خصوصية، مجتمع، والمزيد.',
  body: hubBody,
}), 'utf8');

// Detail pages
features.forEach((f, i) => {
  const prev = i > 0 ? features[i - 1] : null;
  const next = i < features.length - 1 ? features[i + 1] : null;
  const bullets = f.bullets.map((b) => `<li>${b}</li>`).join('');
  const paras = f.paragraphs.map((p) => `<p>${p}</p>`).join('');

  let navLinks = '<div class="feature-nav-prev-next">';
  if (prev) navLinks += `<a href="/features/${prev.slug}.html">← ${prev.tag}</a>`;
  else navLinks += '<span></span>';
  if (next) navLinks += `<a href="/features/${next.slug}.html">${next.tag} →</a>`;
  navLinks += '</div>';

  const body = `<section class="feature-page-hero">
  <div class="container">
    <nav class="breadcrumb" aria-label="مسار"><a href="/index.html">Lune</a> ← <a href="/features.html">الميزات</a> ← <span>${f.tag}</span></nav>
    <div class="feature-page-grid">
      <div class="feature-page-copy">
        <span class="feature-tag">${f.tag}</span>
        <h1>${f.title}</h1>
        ${paras}
        <ul class="feature-list">${bullets}</ul>
        <div class="feature-page-actions">
          <a href="${f.cta.href}" class="btn btn-primary">${f.cta.label}</a>
          <a href="/features.html" class="btn btn-secondary">كل الميزات</a>
        </div>
      </div>
      <div class="feature-page-shot"><div class="screenshot-frame">${shotImg(f.image, f.tag)}</div></div>
    </div>
  </div>
</section>
<main class="page-main"><div class="content-wrap">${navLinks}</div></main>`;

  writeFileSync(join(featuresDir, `${f.slug}.html`), pageShell({
    title: `Lune — ${f.tag}`,
    desc: f.summary,
    body,
  }), 'utf8');
});

console.log('Generated features.html +', features.length, 'detail pages');
