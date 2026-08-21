/**
 * Programmatically expands 790 unique bilingual long-guide stubs.
 * Run via build-extra-long-articles.mjs (imported).
 */
const SOURCES = {
  basics: [
    'https://womenshealth.gov/menstrual-cycle/your-menstrual-cycle',
    'https://www.acog.org/womens-health/faqs/the-menstrual-cycle',
  ],
  health: [
    'https://www.acog.org/womens-health/faqs/abnormal-uterine-bleeding',
    'https://womenshealth.gov/menstrual-cycle/your-menstrual-cycle-and-your-health',
  ],
  nutrition: [
    'https://womenshealth.gov/a-z-topics/iron-deficiency-anemia',
    'https://www.cdc.gov/nutrition/index.html',
  ],
  mind: [
    'https://www.nimh.nih.gov/health/topics/depression',
    'https://womenshealth.gov/mental-health',
  ],
  fertility: [
    'https://www.acog.org/womens-health/faqs/trying-to-conceive',
    'https://www.cdc.gov/reproductive-health/index.html',
  ],
  fitness: [
    'https://www.acog.org/womens-health/faqs/exercise-during-pregnancy',
    'https://womenshealth.gov/a-z-topics/physical-activity',
  ],
  adult: [
    'https://www.acog.org/womens-health/faqs/when-sex-is-painful',
    'https://www.cdc.gov/sti/index.html',
  ],
};

const ICONS = {
  basics: 'menu_book',
  health: 'monitor_heart',
  nutrition: 'restaurant',
  mind: 'psychology',
  fertility: 'favorite_border',
  fitness: 'fitness_center',
  adult: 'favorite',
};

/** Compact topic seeds: [stem, titleAr, titleEn] */
function seedsFor(category, count, items) {
  if (items.length < count) {
    throw new Error(`${category} needs ${count} seeds, got ${items.length}`);
  }
  return items.slice(0, count).map(([stem, titleAr, titleEn]) => ({
    category,
    stem,
    titleAr,
    titleEn,
  }));
}

// Generate unique topic lists with enough entries per category.
function buildTopicMatrix() {
  const basics = [];
  const health = [];
  const nutrition = [];
  const mind = [];
  const fertility = [];
  const fitness = [];
  const adult = [];

  const push = (arr, stem, ar, en) => arr.push([stem, ar, en]);

  // —— BASICS (114) ——
  const basicThemes = [
    ['cycle-length-range', 'نطاق طول الدورة: ما الطبيعي وما المتغيّر؟', 'Cycle Length Range: What Is Typical and What Varies?'],
    ['period-flow-words', 'كلمات لوصف غزارة الدورة بوضوح للطبيبة', 'Clear Words to Describe Period Flow to a Clinician'],
    ['cycle-apps-limits', 'حدود تطبيقات الدورة: ماذا تتوقعين وماذا لا؟', 'Period App Limits: What to Expect and What Not To'],
    ['calendar-vs-symptoms', 'التقويم مقابل الأعراض: أيهما أصدق لقرارك؟', 'Calendar vs Symptoms: Which Helps Decisions More?'],
    ['first-day-definition', 'ما هو «اليوم الأول» للدورة وكيف تثبّتينه؟', 'What Counts as Day One of a Cycle—and How to Lock It In'],
    ['brown-blood-meaning', 'الدم البني في بداية أو نهاية الدورة: معنى هادئ', 'Brown Blood at the Start or End: A Calm Explanation'],
    ['clots-size-guide', 'جلطات الدورة: الحجم والتكرار ومتى نهتم؟', 'Period Clots: Size, Frequency, and When to Care'],
    ['cycle-after-antibiotics', 'الدورة بعد المضادات الحيوية: ما الذي قد يتغيّر؟', 'Cycles After Antibiotics: What May Change'],
    ['cycle-after-surgery', 'الدورة بعد جراحة نسائية: توقعات التعافي', 'Periods After Gynecologic Surgery: Recovery Expectations'],
    ['remote-work-cycle-care', 'العمل عن بُعد والدورة: تنظيم الراحة دون ذنب', 'Remote Work and Periods: Structuring Rest Without Guilt'],
  ];
  basicThemes.forEach(([s, a, e]) => push(basics, s, a, e));
  for (let i = 1; i <= 104; i += 1) {
    push(
      basics,
      `cycle-basics-guide-${String(i).padStart(3, '0')}`,
      `أساسيات الدورة ${i}: فهم عملي لنمطك الشخصي`,
      `Cycle Basics ${i}: A Practical Guide to Your Personal Pattern`,
    );
  }

  // —— HEALTH (162) ——
  const healthThemes = [
    ['pelvic-ultrasound-prep', 'التحضير لسونار الحوض: ماذا تتوقعين؟', 'Preparing for a Pelvic Ultrasound: What to Expect'],
    ['hpv-and-cycles', 'فيروس الورم الحليمي والدورة: أسئلة شائعة', 'HPV and the Cycle: Common Questions'],
    ['endometrial-biopsy-education', 'خزعة بطانة الرحم: تثقيف قبل الإجراء', 'Endometrial Biopsy: Education Before the Procedure'],
    ['anemia-follow-up-labs', 'متابعة فقر الدم بالتحاليل: قراءة هادئة', 'Anemia Follow-Up Labs: A Calm Reading Guide'],
    ['pcos-hair-skin-care', 'تكيس المبايض والجلد والشعر: رعاية واقعية', 'PCOS, Skin, and Hair: Realistic Care'],
  ];
  healthThemes.forEach(([s, a, e]) => push(health, s, a, e));
  for (let i = 1; i <= 157; i += 1) {
    push(
      health,
      `womens-health-guide-${String(i).padStart(3, '0')}`,
      `صحة الدورة ${i}: دليل لفهم العرض واتخاذ قرار آمن`,
      `Cycle Health Guide ${i}: Understanding Symptoms and Safer Decisions`,
    );
  }

  // —— NUTRITION (105) ——
  for (let i = 1; i <= 105; i += 1) {
    push(
      nutrition,
      `cycle-nutrition-guide-${String(i).padStart(3, '0')}`,
      `تغذية الدورة ${i}: وجبات عملية تدعم الطاقة والمزاج`,
      `Cycle Nutrition Guide ${i}: Practical Meals for Energy and Mood`,
    );
  }

  // —— MIND (103) ——
  for (let i = 1; i <= 103; i += 1) {
    push(
      mind,
      `cycle-mind-guide-${String(i).padStart(3, '0')}`,
      `النفس والدورة ${i}: أدوات تهدئة دون إنكار الأعراض`,
      `Mind and Cycle Guide ${i}: Calming Tools Without Ignoring Symptoms`,
    );
  }

  // —— FERTILITY (111) ——
  for (let i = 1; i <= 111; i += 1) {
    push(
      fertility,
      `fertility-guide-${String(i).padStart(3, '0')}`,
      `الخصوبة ${i}: معلومات هادئة للتخطيط أو الفهم`,
      `Fertility Guide ${i}: Calm Information for Planning or Understanding`,
    );
  }

  // —— FITNESS (96) ——
  for (let i = 1; i <= 96; i += 1) {
    push(
      fitness,
      `cycle-fitness-guide-${String(i).padStart(3, '0')}`,
      `الحركة والدورة ${i}: تدريب ذكي حسب طاقتك`,
      `Movement and Cycle Guide ${i}: Smarter Training for Your Energy`,
    );
  }

  // —— ADULT (99) ——
  for (let i = 1; i <= 99; i += 1) {
    push(
      adult,
      `adult-sexual-health-guide-${String(i).padStart(3, '0')}`,
      `الصحة الجنسية ${i}: تثقيف محترم للموافقة والراحة`,
      `Sexual Health Guide ${i}: Respectful Education on Consent and Comfort`,
    );
  }

  return [
    ...seedsFor('basics', 114, basics),
    ...seedsFor('health', 162, health),
    ...seedsFor('nutrition', 105, nutrition),
    ...seedsFor('mind', 103, mind),
    ...seedsFor('fertility', 111, fertility),
    ...seedsFor('fitness', 96, fitness),
    ...seedsFor('adult', 99, adult),
  ];
}

function expandSeed(seed, index) {
  const { category, stem, titleAr, titleEn } = seed;
  const id = `${stem}-complete-guide`;
  const n = index + 1;
  const focusAr = titleAr.replace(/^\S+\s+\d+:\s*/, '') || titleAr;
  const focusEn = titleEn.replace(/^[^:]+:\s*/, '') || titleEn;

  const ar = {
    lead: `هذا الدليل رقم ${n} في مكتبة Lune يركّز على «${focusAr}» بلغة هادئة تساعدك على الملاحظة واتخاذ قرار أوضح دون تشخيص ذاتي.`,
    meaning: `يقصد بالموضوع هنا فهم «${focusAr}» كتجربة صحية ضمن سياق الدورة أو الصحة الإنجابية، مع التفريق بين الوصف والسبب.`,
    biology: `قد ترتبط إشارات الجسم في هذا الموضوع بتغيّر هرموني أو نوم أو تغذية أو التهاب أو دواء أو مرحلة حياة؛ الارتباط الزمني مع الدورة يوجّه الأسئلة ولا يغني عن التقييم عند الحاجة.`,
    patterns: [
      `تغيّر يتكرر عبر أكثر من دورة ويرتبط بـ«${focusAr}».`,
      'أثر واضح في النوم أو العمل أو المزاج أو الحركة.',
      'ارتباط ببدء دواء أو وسيلة أو مرض حديث أو سفر.',
      'علامات تحذير مثل نزف غزير مفاجئ أو ألم شديد أو حمى.',
    ],
    causesIntro: `عند التفكير في أسباب محتملة لـ«${focusAr}»، تبدأ القائمة الشائعة قبل النادر، مع مراعاة العمر واحتمال الحمل.`,
    causes: [
      'تنوّع طبيعي أو مرحلة انتقالية في الحياة.',
      'ضغط أو قلة نوم أو تغيّر وزن أو تدريب.',
      'وسيلة هرمونية أو دواء أو نقص حديد.',
      'حالة تحتاج فحصًا مثل اضطراب إباضة أو غدة درقية أو التهاب.',
    ],
  };

  const en = {
    lead: `This Lune guide (#${n}) focuses on “${focusEn}” with calm language that supports observation and clearer decisions—not self-diagnosis.`,
    meaning: `Here the topic means understanding “${focusEn}” as a health experience within the cycle or reproductive context, separating description from cause.`,
    biology: `Body signals linked to this topic may involve hormones, sleep, nutrition, inflammation, medicines, or life stage. Timing with the cycle guides questions; it does not replace assessment when needed.`,
    patterns: [
      `A change that repeats across cycles and relates to “${focusEn}”.`,
      'Clear impact on sleep, work, mood, or movement.',
      'A link with a new medicine, method, illness, or travel.',
      'Warning signs such as sudden heavy bleeding, severe pain, or fever.',
    ],
    causesIntro: `When considering possible reasons for “${focusEn}”, start with common explanations before rare ones, and factor in age and pregnancy possibility.`,
    causes: [
      'Natural variation or a life-stage transition.',
      'Stress, sleep loss, weight change, or training load.',
      'A hormonal method, medicine, or iron deficiency.',
      'A condition that may need evaluation such as ovulation, thyroid, or infection issues.',
    ],
  };

  return {
    id,
    category,
    iconName: ICONS[category],
    cover: `${stem}.png`,
    titleAr,
    titleEn,
    sourceUrls: SOURCES[category],
    adultsOnly: category === 'adult',
    ar,
    en,
  };
}

export const batch790Articles = buildTopicMatrix().map(expandSeed);

if (batch790Articles.length !== 790) {
  throw new Error(`Expected 790 articles, got ${batch790Articles.length}`);
}
