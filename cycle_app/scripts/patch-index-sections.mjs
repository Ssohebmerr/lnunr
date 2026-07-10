/**
 * Patches index.html with expanded goals, features, discover sections.
 */
import { readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const indexPath = join(__dirname, '../public/index.html');
let html = readFileSync(indexPath, 'utf8');

const shot = (name, alt) =>
  `<div class="screenshot-frame"><img src="/images/screenshots/${name}.svg" alt="${alt}" loading="lazy" width="280" height="606" /></div>`;

const positioning = `
<!-- Positioning -->
<section class="section" id="positioning">
  <div class="container positioning-block">
    <div class="positioning-copy">
      <h2>ليس مجرد تطبيق دورة — منصة عافية نسائية عربية</h2>
      <p>Lune صُمّم من الصفر بالعربية: واجهة RTL كاملة، محتوى يحترم سياقكِ الثقافي، وأدوات تتكيّف مع مرحلة حياتكِ — من التتبع اليومي إلى الحمل وسنّ الأمل وما بعد الولادة.</p>
      <p>بياناتكِ تبقى على جهازكِ افتراضياً مع تشفير AES-256. لا إعلانات، لا بيع بيانات، ولا مفاجآت في الاشتراك: Premium اختياري ويفتح الذكاء الاصطناعي (30 رسالة/يوم)، المجتمع (18+)، والنسخ السحابي المشفّر.</p>
      <ul class="positioning-points">
        <li>8 أوضاع هدف تغيّر الشاشة الرئيسية والتقارير والرعاية الذاتية</li>
        <li>تتبع أساسي مجاني دائماً — يعمل بدون إنترنت</li>
        <li>مركز ثقة بـ 21 سؤالاً و7 صفحات شفافية</li>
        <li>حذف فوري للحساب — بدون انتظار 30 يوماً</li>
      </ul>
    </div>
    <div class="positioning-visual">${shot('goals', 'أهداف Lune')}</div>
  </div>
</section>

<!-- What you can do -->
<section class="section section-alt" id="cando">
  <div class="container">
    <div class="section-header">
      <h2>ما الذي يمكنكِ فعله مع Lune؟</h2>
      <p>ست مجالات — كل واحدة بأدوات مفصّلة وشرح كامل أدناه.</p>
    </div>
    <div class="can-do-grid">
      <a class="can-do-card" href="#feat-calendar">
        <div class="can-do-icon"><svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></svg></div>
        <h3>تتبّعي</h3>
        <p>تقويم، سجل يومي، تنبؤات، وتذكيرات ذكية حسب مرحلة دورتكِ.</p>
      </a>
      <a class="can-do-card" href="#feat-analytics">
        <div class="can-do-icon"><svg viewBox="0 0 24 24"><path d="M3 3v18h18"/><path d="M7 16l4-6 4 3 5-8"/></svg></div>
        <h3>افهمي</h3>
        <p>تحليلات، أنماط أعراض، مؤشرات هرمونية، وتقارير جاهزة للطبيب.</p>
      </a>
      <a class="can-do-card" href="#feat-selfcare">
        <div class="can-do-icon"><svg viewBox="0 0 24 24"><path d="M12 2a10 10 0 0 1 10 10c0 5-4 9-10 12C6 21 2 17 2 12A10 10 0 0 1 12 2z"/></svg></div>
        <h3>اعتنِ بنفسكِ</h3>
        <p>تنفس، يوميات، تأكيدات، حركة لطيفة، وتحديات يومية.</p>
      </a>
      <a class="can-do-card" href="#feat-magazine">
        <div class="can-do-icon"><svg viewBox="0 0 24 24"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg></div>
        <h3>تعلّمي</h3>
        <p>مجلة Lune، مقالات تعليمية، وأسئلة صحية مجهولة.</p>
      </a>
      <a class="can-do-card" href="#feat-community">
        <div class="can-do-icon"><svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></svg></div>
        <h3>تواصلي</h3>
        <p>مجتمعات صغيرة آمنة للبالغات 18+ — Premium مع مراجعة محتوى.</p>
      </a>
      <a class="can-do-card" href="#feat-privacy">
        <div class="can-do-icon"><svg viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div>
        <h3>احمي خصوصيتكِ</h3>
        <p>تشفير محلي، وضع تخفي، وضع ضيف، وحذف فوري للحساب.</p>
      </a>
    </div>
  </div>
</section>
`;

const goals = `
<!-- Goals -->
<section class="section section-alt" id="goals">
  <div class="container">
    <div class="section-header">
      <h2>اختاري هدفكِ — 8 أوضاع تغيّر التطبيق بالكامل</h2>
      <p>من الصحة العامة إلى الحمل وسنّ الأمل — Lune يكيّف الشاشة الرئيسية، التقارير، قوائم الرعاية، والنصائح اليومية.</p>
    </div>
    <div class="goals-grid goals-grid--8">
      <article class="goal-card goal-card--expanded">
        <div class="goal-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M12 2l3 7h7l-5.5 4.5 2 7L12 17l-6.5 3.5 2-7L2 9h7z"/></svg></div>
        <h3>الصحة العامة</h3>
        <p class="goal-desc">افهمي دورتكِ، لاحظي الأنماط، واعتني بنفسكِ في كل المراحل — تقويم، تنبؤات، ورؤى يومية.</p>
        <ul class="goal-checklist">
          <li>تقويم وتنبؤات مبنية على سجلاتكِ</li>
          <li>رؤى يومية حسب مرحلة الدورة</li>
          <li>عناية شاملة لجسمكِ في كل المراحل</li>
          <li>تقارير «نظرة على الدورة»</li>
        </ul>
      </article>
      <article class="goal-card goal-card--expanded">
        <div class="goal-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M12 21s-6-4.35-6-10a6 6 0 0 1 12 0c0 5.65-6 10-6 10z"/></svg></div>
        <h3>الصحة الجنسية</h3>
        <p class="goal-desc">تتبّعي العلاقة والحماية — بيانات واضحة تساعدكِ على قرارات أفضل لصحتكِ الجنسية.</p>
        <ul class="goal-checklist">
          <li>سجل النشاط الجنسي والحماية</li>
          <li>ربط البيانات بمرحلة الدورة</li>
          <li>مركز العناية: حبوب، LARC، منتجات صحية</li>
          <li>خصوصية كاملة — بياناتكِ على جهازكِ</li>
        </ul>
      </article>
      <article class="goal-card goal-card--expanded">
        <div class="goal-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M12 2a7 7 0 0 0-4 12.7V22l4-2 4 2v-7.3A7 7 0 0 0 12 2z"/></svg></div>
        <h3>محاولة الحمل</h3>
        <p class="goal-desc">تتبّعي نافذة الخصوبة ووقّتي العلاقة بثقة — مع نصائح يومية لدعم محاولتكِ.</p>
        <ul class="goal-checklist">
          <li>فيتامينات الحمل / حمض الفوليك</li>
          <li>علامات الإباضة (إفرازات، حرارة)</li>
          <li>توقيت العلاقة خلال نافذة الخصوبة</li>
          <li>تقرير «نظرة على الخصوبة»</li>
        </ul>
      </article>
      <article class="goal-card goal-card--expanded">
        <div class="goal-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div>
        <h3>تجنب الحمل</h3>
        <p class="goal-desc">اعرفي أيام الخصوبة وابقي واعية — <strong>ليس بديلاً عن وسيلة منع حمل موثوقة.</strong></p>
        <ul class="goal-checklist">
          <li>استخدمي وسيلة منع الحمل بانتظام</li>
          <li>اعرفي أيام الخصوبة على التقويم</li>
          <li>حماية إضافية في أيام الخصوبة العالية</li>
          <li>تقرير «نظرة على الحماية»</li>
        </ul>
      </article>
      <article class="goal-card goal-card--expanded">
        <div class="goal-icon"><svg class="icon" viewBox="0 0 24 24"><circle cx="12" cy="7" r="4"/><path d="M6 21v-2a6 6 0 0 1 12 0v2"/></svg></div>
        <h3>أنا حامل</h3>
        <p class="goal-desc">تابعي كل خطوة أسبوعياً — نمو الجنين، قوائم الثلث، عداد الركلات، ومؤقت الانقباضات.</p>
        <ul class="goal-checklist">
          <li>فيتامينات الحمل يومياً</li>
          <li>الترطيب — 8 أكواب ماء على الأقل</li>
          <li>سجّلي حركة الجنين في المساء</li>
          <li>احجزي موعد المتابعة في وقته</li>
        </ul>
      </article>
      <article class="goal-card goal-card--expanded">
        <div class="goal-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M6 2v6M18 2v6M4 10h16M4 22h16a2 2 0 0 0 2-2V10H2v10a2 2 0 0 0 2 2z"/></svg></div>
        <h3>تتبع سنّ الأمل</h3>
        <p class="goal-desc">الدورات غير المنتظمة طبيعية — تتبّعي الهبّات الساخنة والنوم والمزاج ولستِ وحدكِ.</p>
        <ul class="goal-checklist">
          <li>سجّلي الهبّات الساخنة (الوقت، المدة، المحفّزات)</li>
          <li>تابعي جودة النوم والتعرّق الليلي</li>
          <li>تحرّكي بلطف — مشي، تمدّد، تقوية</li>
          <li>ناقشي الأعراض المزعجة مع طبيبتكِ</li>
        </ul>
      </article>
      <article class="goal-card goal-card--expanded">
        <div class="goal-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/></svg></div>
        <h3>إدارة تكيّس المبايض</h3>
        <p class="goal-desc">تابعي انتظام الدورة، البشرة الهرمونية وتقلّبات المزاج — الأنماط ترشد الرعاية.</p>
        <ul class="goal-checklist">
          <li>سجّلي طول الدورة والتدفق شهرياً</li>
          <li>لاحظي تغيّرات البشرة والشعر</li>
          <li>وجبات غنية بالألياف وقليلة السكر</li>
          <li>ناقشي التحاليل مع طبيبة الغدد</li>
        </ul>
      </article>
      <article class="goal-card goal-card--expanded">
        <div class="goal-icon"><svg class="icon" viewBox="0 0 24 24"><rect x="3" y="8" width="18" height="12" rx="2"/><path d="M7 8V6a5 5 0 0 1 10 0v2"/></svg></div>
        <h3>الاستشفاء بعد الولادة</h3>
        <p class="goal-desc">الشفاء يأخذ وقتاً — سجّلي الراحة والمزاج والرضاعة في خطوات يومية صغيرة.</p>
        <ul class="goal-checklist">
          <li>نامي عندما ينام طفلكِ</li>
          <li>اشربي ماءً مع كل رضعة</li>
          <li>كلّمي نفسكِ بلطف اليوم</li>
          <li>تقرير «نظرة على الاستشفاء»</li>
        </ul>
      </article>
    </div>
  </div>
</section>
`;

// Features grid + discover rows - continue in part 2
const featuresGrid = `
<!-- Features overview -->
<section class="section" id="features">
  <div class="container">
    <div class="section-header">
      <h2>كل الميزات — شرح سريع</h2>
      <p>15 أداة أساسية — اقرئي الشرح المفصّل مع صور التطبيق في القسم التالي.</p>
    </div>
    <div class="features features--expanded">
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></svg></div><h3>تقويم الدورة</h3><p>فترة، تبويض، مراحل، وتنبؤات تتحسن مع كل سجل.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M12 20h9M12 4v16M4 4h16"/></svg></div><h3>التسجيل اليومي</h3><p>تدفق، أعراض، مزاج، ماء، وأكثر في ثوانٍ.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M12 3a5 5 0 0 0-5 5v2a5 5 0 0 0 10 0V8a5 5 0 0 0-5-5z"/></svg></div><h3>Lune AI</h3><p>مساعد ذكي Premium — 30 رسالة/يوم بموافقتكِ.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M3 3v18h18"/><path d="M7 16l4-6 4 3 5-8"/></svg></div><h3>تحليلات ورؤى</h3><p>CRS، PRS، رسوم بيانية، وأنماط أعراض.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/></svg></div><h3>تقرير الطبيب</h3><p>PDF، QR، مشاركة — بقراركِ أنتِ.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div><h3>خصوصية وتخفي</h3><p>AES-256، آلة حاسبة، حذف فوري.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg></div><h3>مجتمع 18+</h3><p>مجموعات دعم — Premium مع مراجعة.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M12 2a10 10 0 0 1 10 10c0 5-4 9-10 12C6 21 2 17 2 12A10 10 0 0 1 12 2z"/></svg></div><h3>رعاية ذاتية</h3><p>تنفس، يوميات، تأكيدات، تحديات.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><circle cx="12" cy="7" r="4"/><path d="M6 21v-2a6 6 0 0 1 12 0v2"/></svg></div><h3>متابعة الحمل</h3><p>أسبوع بأسبوع، ركلات، انقباضات.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg></div><h3>مجلة Lune</h3><p>مقالات تعليمية بالعربية والإنجليزية.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 11l-3 3-2-2"/></svg></div><h3>وضع الشريك</h3><p>كود دعوة ونصائح دعم حسب المرحلة.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg></div><h3>تذكيرات ذكية</h3><p>دورة، إباضة، ونصائح حسب المرحلة.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg></div><h3>وضع الضيف</h3><p>بدون إيميل — ملف محلي خاص.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><circle cx="12" cy="12" r="7"/><path d="M12 9v3l2 2"/></svg></div><h3>ساعة وويدجت</h3><p>حلقة الدورة على الشاشة والساعة.</p></div>
      <div class="feature"><div class="feature-icon"><svg class="icon" viewBox="0 0 24 24"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg></div><h3>نسخ سحابي</h3><p>نسخ احتياطي مشفّر — Premium.</p></div>
    </div>
  </div>
</section>
`;

function featureRow(id, tag, title, paras, bullets, ctaHref, ctaText, shotName, alt, reverse) {
  const list = bullets.map((b) => `<li>${b}</li>`).join('');
  const p = paras.map((x) => `<p>${x}</p>`).join('');
  return `
    <div class="feature-row reveal-ready${reverse ? ' reverse' : ''}" id="${id}">
      <div class="feature-row-media">${shot(shotName, alt)}</div>
      <div class="feature-row-text">
        <span class="feature-tag">${tag}</span>
        <h2>${title}</h2>
        ${p}
        <ul class="feature-list">${list}</ul>
        ${ctaHref ? `<a href="${ctaHref}" class="btn btn-primary btn-sm">${ctaText}</a>` : ''}
      </div>
    </div>`;
}

const discover = `
<!-- Deep feature dives -->
<section class="section" id="discover">
  <div class="container">
    <div class="section-header">
      <h2>اكتشفي Lune بالتفصيل — مع صور من التطبيق</h2>
      <p>كل ميزة بشرح كامل: ماذا تفعل، لمن تناسب، وكيف تحمي خصوصيتكِ.</p>
    </div>
    ${featureRow('feat-calendar', 'تقويم ذكي', 'تنبؤات مبنية على تاريخكِ الحقيقي', [
      'سجّلي آخر فترة — والتقويم يتعلم من دورتكِ. شوفي مراحل الدورة، موعد التبويض، والأيام المتبقية بوضوح على شاشة عربية أنيقة.',
      'التتبع الأساسي يعمل بدون إنترنت: بياناتكِ تبقى على جهازكِ حتى بدون اتصال.'
    ], ['تتبع الفترة والتدفق والأعراض والمزاج', 'تنبؤات تتحسن كلما سجّلتِ أكثر', 'عرض مراحل الدورة والخصوبة', 'تقويم كامل من الشاشة الرئيسية', 'متوافق مع كل الأهداف الثمانية'], '#download', 'جرّبي مجاناً', 'calendar', 'تقويم الدورة', false)}
    ${featureRow('feat-log', 'تسجيل يومي', 'سجّلي يومكِ في ثوانٍ — وبني صورة صحية أوضح', [
      'من زر التسجيل المركزي: تدفق، أعراض، مزاج، شرب ماء، وأكثر. كل سجل يقوّي التنبؤات والتحليلات.',
      'تأكيد فوري عند الحفظ — وتذكير لطيف إذا فاتكِ يوم.'
    ], ['واجهة بسيطة للاستخدام اليومي', 'ربط السجل بمرحلة الدورة تلقائياً', 'سلسلة تسجيل (streak) للتحفيز اللطيف', 'يعمل محلياً بدون حساب', 'تصدير ضمن التقرير الشهري'], '#download', 'ابدئي التسجيل', 'log', 'التسجيل اليومي', true)}
    ${featureRow('feat-ai', 'ذكاء اصطناعي', 'Lune AI — رفيقتكِ الخاصة للدورة (Premium)', [
      'اسألي عن الأعراض، مرحلة دورتكِ، أو نصائح العافية. المساعد يفهم سياق سجلاتكِ بعد موافقتكِ الصريحة.',
      '30 رسالة يومياً للمشتركات Premium — شفافية كاملة بدون مفاجآت.'
    ], ['محادثة مخصصة حسب هدفكِ ومرحلة دورتكِ', 'اقتراحات جاهزة للأسئلة الشائعة', 'ملخص يومي AI على الشاشة الرئيسية', 'ملاحظات AI اختيارية في تقرير الطبيب', 'تشخيص AI من الإعدادات للدعم'], '#premium', 'اعرفي Premium', 'ai', 'Lune AI', false)}
    ${featureRow('feat-analytics', 'تحليلات', 'افهمي جسمكِ بأرقام ورسوم واضحة', [
      'انتظام الدورة (CRS) وانتظام الحيض (PRS)، رسوم بيانية للأعراض والمزاج، ومؤشرات هرمونية تفسيرية.',
      'تقارير تتكيّف مع هدفكِ: خصوبة، حماية، حمل، سن أمل، PCOS، أو استشفاء.'
    ], ['تحليلات كاملة من تبويب التقارير', 'جدول تاريخ الدورة ورسوم تفاعلية', 'أنماط الأعراض عبر الأسابيع', 'ملخص أسبوعي AI (Premium)', 'تصدير ومشاركة الرسوم'], '#download', 'شوفي تقاريركِ', 'analytics', 'التحليلات', true)}
    ${featureRow('feat-doctor', 'تقرير صحي', 'شاركي مع طبيبتكِ بثقة — دون إرسال تلقائي', [
      'ملخص شهري منسق: دورة، أعراض، مزاج، وتدفق — جاهز للزيارة.',
      'تصدير PDF، TXT، CSV، أو JSON. مشاركة، نسخ، أو QR — أنتِ من يقرر.'
    ], ['بيانات المريضة قابلة للتعديل', 'ملاحظات AI اختيارية (Premium)', 'لا يُرسل لأي جهة تلقائياً', 'مناسب لكل الأهداف', 'إخلاء: ليس تشخيصاً طبياً'], '/trust-hub.html', 'مركز الثقة', 'doctor-report', 'تقرير الطبيب', false)}
    ${featureRow('feat-privacy', 'خصوصية', 'بياناتكِ ملككِ — تشفير، تخفي، وحذف فوري', [
      'AES-256 على الجهاز. لا إعلانات ولا بيع بيانات. وضع التخفي يحوّل التطبيق لآلة حاسبة بـ PIN.',
      'حذف الحساب فوري من مركز الخصوصية — بدون انتظار 30 يوماً.'
    ], ['وضع ضيف بدون إيميل', 'موافقات منفصلة للسحابة والAI والمجتمع', '21 سؤالاً في مركز الثقة', 'نسخ احتياطي محلي للتصدير', 'إخفاء التطبيق فوراً من الشاشة الرئيسية'], '/security.html', 'صفحة الأمان', 'stealth', 'الخصوصية والتخفي', true)}
    ${featureRow('feat-community', 'مجتمع', 'مجتمعات صغيرة للدعم — 18+ وPremium', [
      'خلاصة، استكشاف، مجموعاتي، ومحفوظات. اسم مستعار — ليس حسابكِ الحقيقي.',
      'دعم جماعي فقط — ليس نصيحة طبية. إبلاغ وحظر للمحتوى غير الآمن.'
    ], ['منشورات، تعليقات، إعجابات، واستطلاعات', 'قصص (حسب الإعدادات)', 'صندوق نشاط للتفاعلات', 'بوابة عمر 18+', 'مراجعة محتوى وإشراف'], '#premium', 'Premium للمجتمع', 'community', 'المجتمع', false)}
    ${featureRow('feat-selfcare', 'رعاية ذاتية', 'مساحة هادئة للعناية بنفسكِ كل يوم', [
      'تنفس مربع، تأكيدات (مع AI شخصي Premium)، يوميات مع تأمّل AI، حركة لطيفة، وطقوس يومية.',
      'مكتبة عناية حسب مرحلة الدورة وتحديات تحفيزية لطيفة.'
    ], ['فحص مزاج يومي', 'همسة اليوم (Premium)', 'دليل العناية حسب الدورة', 'سلسلة طقوس يومية', 'محتوى يتكيّف مع هدفكِ'], '#download', 'جرّبي الرعاية الذاتية', 'self-care', 'رعاية ذاتية', true)}
    ${featureRow('feat-pregnancy', 'حمل', 'متابعة حملكِ أسبوعاً بأسبوع', [
      'حجم الجنين، قوائم الثلث، عداد الركلات، مؤقت الانقباضات، سجل الوزن، وعناية الحمل.',
      'وضع «أنا حامل» يغيّر الشاشة الرئيسية والتقارير بالكامل.'
    ], ['بطولة 3D تقريبية للجنين', 'قوائم تحقق لكل ثلث', 'تذكيرات ذكية للحمل', 'تقارير حمل مخصصة', 'ليس بديلاً عن المتابعة الطبية'], '#goals', 'اختاري هدف الحمل', 'pregnancy', 'متابعة الحمل', false)}
    ${featureRow('feat-magazine', 'تعليم', 'مجلة Lune — تعلّمي بثقة', [
      'مقالات عن أساسيات الدورة، الصحة، التغذية، العقل، ومحتوى 18+ — بالعربية والإنجليزية.',
      'محتوى تعليمي فقط — ليس نصيحة طبية. متاح مجاناً داخل التطبيق.'
    ], ['قارئ مقالات أنيق', 'تصنيفات متعددة', 'أسئلة مجهولة صحية', 'ربط بالتعليم من الشاشة الرئيسية', 'تحديثات محتوى دورية'], '#download', 'اقرئي في التطبيق', 'magazine', 'مجلة Lune', true)}
    ${featureRow('feat-partner', 'شريك', 'وضع الشريك — دعم مشترك بلطف', [
      'ادعي شريككِ بكود — يشوف فقط ما تختارين مشاركته: المرحلة، أيام للفترة، مستوى الألم.',
      'نصائح «كيف تدعمها اليوم» حسب مرحلة دورتكِ.'
    ], ['تحكم كامل بما يُشارك', 'قسم منفصل للشريك', 'نصائح داعمة غير طبية', 'خصوصية الطرفين', 'اختياري بالكامل'], '/partner.html', 'شراكات ووضع الشريك', 'partner', 'وضع الشريك', false)}
    ${featureRow('feat-wellness', 'مركز العناية', 'أدوات منع الحمل والعافية في مكان واحد', [
      'يوميات أعراض موسّعة، حبوب منع الحمل، منتجات صحية، سجل النشاط الجنسي، ووسائل LARC طويلة المفعول.',
      'مكمّل للتتبع الأساسي — خصوصياً لأهداف الصحة الجنسية وتجنب الحمل.'
    ], ['تذكير بالحبوب', 'تتبع المنتجات الصحية', 'سجل النشاط مع الحماية', 'واجهة عربية متكاملة', 'بيانات محلية مشفّرة'], '#feat-log', 'التسجيل اليومي', 'log', 'مركز العناية', true)}
    ${featureRow('feat-reminders', 'تذكيرات', 'تذكيرات ذكية حسب مرحلة دورتكِ', [
      'تذكير بالفترة والإباضة، مع نصائح مرحلية ذكية تتكيّف مع الحمل أو الدورة.',
      'تحكم كامل: فعّلي أو عطّلي من الإعدادات.'
    ], ['تذكير دورة وإباضة', 'نصائح حسب المرحلة', 'إشعارات محلية وFCM', 'إعدادات من الحساب', 'لا إزعاج بدون موافقتكِ'], '#download', 'فعّلي التذكيرات', 'home', 'التذكيرات', false)}
    ${featureRow('feat-cloud', 'نسخ سحابي', 'نسخ احتياطي مشفّر — Premium', [
      'مزامنة مشفّرة لسجلاتكِ عبر Firebase — فقط بعد موافقتكِ ومع اشتراك Premium.',
      'استعادة عند تغيير الجهاز. أو استخدمي التصدير المحلي مجاناً.'
    ], ['مزامنة يدوية «الآن»', 'استعادة من النسخة', 'تصدير/استيراد محلي مجاني', 'موافقة صريحة مطلوبة', 'لا تفعيل تلقائي'], '#premium', 'اشتركي في Premium', 'premium', 'Lune Premium', true)}
    ${featureRow('feat-guest', 'وضع ضيف', 'ابدئي فوراً — بياناتكِ تبقى ملككِ', [
      'وضع ضيف خاص: ملف محلي بدون إيميل. تسجيل دخول اختياري للمزامنة السحابية فقط.',
      'تشفير AES-256 من أول يوم. حذف فوري متاح دائماً.'
    ], ['بدون حساب للتتبع الأساسي', 'جلسة Firebase مجهولة للضيف', 'ترقية لحساب لاحقاً', 'مركز خصوصية شامل', 'شفافية كاملة في مركز الثقة'], '/privacy-policy.html', 'سياسة الخصوصية', 'privacy', 'الخصوصية', false)}
  </div>
</section>
`;

// Insert positioning before goals
html = html.replace(
  /<!-- Goals \(Flo-style modes\) -->[\s\S]*?<\/section>\n\n<!-- Features -->/,
  positioning + goals + '\n' + featuresGrid + '\n'
);

// Replace discover section
html = html.replace(
  /<!-- Deep feature dives \(Flo-style zigzag\) -->[\s\S]*?<\/section>\n\n<!-- Visual showcase -->/,
  discover + '\n\n<!-- Visual showcase -->'
);

writeFileSync(indexPath, html, 'utf8');
console.log('Patched goals, features, discover sections');
