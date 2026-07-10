// ============================================================================
// lib/knowledge.js — Lune's curated wellness knowledge library (RAG-lite).
// ----------------------------------------------------------------------------
// A small, hand-curated library of NON-MEDICAL wellness & cycle-education
// facts (Arabic + English). Before each chat call we keyword-match the user's
// message (plus their current cycle phase) against this library and inject the
// top snippets into the user prompt as a "LUNE LIBRARY" block.
//
// Why this design:
//   - Grounds replies in consistent, vetted info → less model drift/hallucination.
//   - Zero extra cost or latency (no embeddings, no external calls).
//   - Entries are content-only: NO diagnoses, NO medication, NO dosages —
//     the medical-safety prompt rules still apply on top.
//
// To grow the library: append entries below. Each entry:
//   { id, phases: [...], keywords: [...], ar: '...', en: '...' }
// Keywords are matched after Arabic normalization (diacritics stripped,
// أ/إ/آ→ا, ة→ه, ى→ي) so dialect spelling variants still hit.
// ============================================================================

'use strict';

/** Modes that get library snippets — report/one-shot modes stay lean. */
const KNOWLEDGE_MODES = new Set([
  'chat', 'nutrition', 'selfcare', 'fertility', 'weight', 'intimacy', 'emergency',
]);

/** Max snippets injected per message (keeps the prompt small). */
const MAX_SNIPPETS = 2;

const KNOWLEDGE = [
  // ── Cycle phases — education ─────────────────────────────────────────────
  {
    id: 'phase_menstrual',
    phases: ['menstrual'],
    keywords: ['دوره', 'دورتي', 'حيض', 'نزيف', 'بيريود', 'period', 'menstruation', 'bleeding', 'مرحله'],
    ar: 'أيام الدورة يهبط الإستروجين والبروجستيرون لأدنى مستوى، لذلك الطاقة تكون أقل والجسم يطلب راحة ودفء — هذا طبيعي تماماً وليس كسلاً. النزيف الطبيعي يتراوح عادة بين 3 و7 أيام ويختلف من شهر لآخر.',
    en: 'During your period, estrogen and progesterone are at their lowest, so lower energy and a craving for warmth and rest are completely natural — not laziness. A typical period lasts 3–7 days and can vary month to month.',
  },
  {
    id: 'phase_follicular',
    phases: ['follicular'],
    keywords: ['طاقه', 'نشاط', 'حيويه', 'follicular', 'energy', 'motivated', 'منتجه', 'تركيز', 'focus', 'مرحله', 'phase'],
    ar: 'المرحلة الجرابية (بعد الدورة وحتى التبويض) يرتفع فيها الإستروجين تدريجياً — كثير من النساء يلاحظن طاقة أعلى وتركيزاً أفضل ومزاجاً أصفى. وقت ممتاز لبدء عادات جديدة أو مشاريع تحتاج نشاطاً.',
    en: 'In the follicular phase (after your period until ovulation) estrogen rises steadily — many women notice higher energy, sharper focus, and a brighter mood. A great window for starting new habits or tackling demanding projects.',
  },
  {
    id: 'phase_ovulation',
    phases: ['ovulation'],
    keywords: ['تبويض', 'اباضه', 'ovulation', 'ovulate', 'بويضه', 'egg', 'مرحله', 'phase'],
    ar: 'التبويض يحدث عادة منتصف الدورة تقريباً (يوم 14 في دورة 28 يوماً، ويتغير حسب طول دورتك). البويضة تعيش نحو 12–24 ساعة، وبعض النساء يشعرن بوخزة خفيفة في جانب البطن أو يلاحظن إفرازات شفافة مطاطية تشبه بياض البيض — علامة طبيعية.',
    en: 'Ovulation usually happens around mid-cycle (day 14 of a 28-day cycle, shifting with your cycle length). The egg lives about 12–24 hours; some women feel a mild one-sided twinge or notice clear, stretchy egg-white discharge — a normal sign.',
  },
  {
    id: 'phase_luteal',
    phases: ['luteal'],
    keywords: ['قبل الدوره', 'لوتيل', 'luteal', 'pms', 'بي ام اس', 'اعراض ما قبل', 'متلازمه', 'مرحله', 'phase'],
    ar: 'المرحلة الأصفرية (ما قبل الدورة) يرتفع فيها البروجستيرون ثم يهبط فجأة — لذلك التقلبات المزاجية والانتفاخ والرغبة بالحلويات شائعة جداً فيها. حوالي 3 من كل 4 نساء يختبرن شكلاً من أعراض ما قبل الدورة، فأنتِ لست وحدك أبداً.',
    en: 'In the luteal phase (before your period) progesterone rises then drops sharply — which is why mood swings, bloating, and sweet cravings are so common. Around 3 in 4 women experience some form of PMS, so you are truly not alone.',
  },

  // ── Nutrition & hydration ────────────────────────────────────────────────
  {
    id: 'nutrition_menstrual',
    phases: ['menstrual'],
    keywords: ['اكل', 'طعام', 'تغذيه', 'غذاء', 'حديد', 'اكلات', 'وجبه', 'food', 'eat', 'nutrition', 'iron', 'meal'],
    ar: 'أيام الدورة يفقد الجسم حديداً مع الدم، لذلك الأطعمة الغنية بالحديد تساعد: العدس، السبانخ، اللحوم الحمراء، التمر. إضافة فيتامين C (برتقال، فلفل ملون) مع الوجبة يضاعف امتصاص الحديد النباتي. والأطعمة الدافئة كالشوربة تريح البطن أكثر من الباردة.',
    en: 'During your period the body loses iron with blood, so iron-rich foods help: lentils, spinach, red meat, dates. Pairing vitamin C (orange, bell pepper) with the meal boosts plant-iron absorption. Warm foods like soup also tend to soothe the belly more than cold ones.',
  },
  {
    id: 'cravings_luteal',
    phases: ['luteal'],
    keywords: ['حلويات', 'شوكولاته', 'سكر', 'كرافينج', 'نفسي اكل', 'جوعانه', 'cravings', 'craving', 'chocolate', 'sugar', 'sweet', 'hungry'],
    ar: 'الرغبة الشديدة بالحلويات قبل الدورة لها سبب حقيقي: هبوط السيروتونين يدفع الجسم لطلب الكربوهيدرات السريعة. الحيلة ليست الحرمان بل الاستبدال الذكي — شوكولاتة داكنة (غنية بالمغنيسيوم)، تمر بزبدة الفول السوداني، أو موز. والوجبات المنتظمة تقلل شدة الكرافينج أصلاً.',
    en: 'Pre-period sweet cravings have a real cause: dipping serotonin pushes the body toward quick carbs. The trick is smart swaps, not deprivation — dark chocolate (rich in magnesium), dates with peanut butter, or a banana. Regular meals also blunt cravings in the first place.',
  },
  {
    id: 'hydration',
    phases: [],
    keywords: ['ماء', 'مويه', 'ميه', 'شرب', 'عطش', 'ترطيب', 'water', 'hydration', 'drink', 'thirsty'],
    ar: 'شرب الماء بانتظام (نحو 8 أكواب يومياً) يخفف فعلياً من الانتفاخ واحتباس السوائل — قد يبدو عكسياً، لكن الجسم يحتفظ بالماء أكثر عندما يشعر بالجفاف. كوب ماء دافئ بالنعناع أو الزنجبيل أيام الدورة يريح البطن ويحسب من حصتك اليومية.',
    en: 'Steady water intake (about 8 cups a day) genuinely reduces bloating and water retention — it sounds backwards, but the body holds onto water when it senses dehydration. Warm water with mint or ginger during your period soothes the belly and counts toward your daily total.',
  },
  {
    id: 'caffeine',
    phases: ['luteal', 'menstrual'],
    keywords: ['قهوه', 'كافيين', 'شاي', 'نسكافيه', 'coffee', 'caffeine', 'tea', 'espresso'],
    ar: 'الكافيين يضيّق الأوعية الدموية وقد يزيد التقلصات والتوتر أيام الدورة وما قبلها، كما يزيد فقدان الكالسيوم. لا داعي للقطع الكامل — تقليل القهوة لكوب واحد صباحاً واستبدال الباقي بشاي أعشاب (بابونج، نعناع، زنجبيل) فرق ملحوظ عند كثيرات.',
    en: 'Caffeine narrows blood vessels and can worsen cramps and tension before and during your period, and it increases calcium loss. No need to quit entirely — cutting to one morning cup and swapping the rest for herbal tea (chamomile, mint, ginger) makes a noticeable difference for many women.',
  },

  // ── Body & symptoms (non-medical comfort education) ──────────────────────
  {
    id: 'cramps_comfort',
    phases: ['menstrual'],
    keywords: ['الالم', 'الم قوي', 'الم شديد', 'عندي الم', 'وجع', 'تقلصات', 'مغص', 'توجعني', 'يوجعني', 'بطني', 'تشنجات', 'cramps', 'cramp', 'pain', 'ache', 'hurts'],
    ar: 'للتقلصات، الحرارة صديقتك الأولى: قربة ماء دافئ على أسفل البطن ثبت علمياً أنها تريح العضلة الرحمية. المشي الخفيف وتمارين التمدد اللطيفة ترفع الدورة الدموية وتخفف الشد، ووضعية الطفل في اليوغا مريحة لأسفل الظهر. الراحة ليست رفاهية أيامها — هي حاجة.',
    en: 'For cramps, heat is your best friend: a warm water bottle on the lower belly is proven to relax the uterine muscle. Light walking and gentle stretching boost circulation and ease tension, and child\'s pose is lovely for the lower back. Rest on these days is a need, not a luxury.',
  },
  {
    id: 'bloating',
    phases: ['luteal', 'menstrual'],
    keywords: ['انتفاخ', 'منتفخه', 'غازات', 'احتباس', 'bloating', 'bloated', 'gas', 'puffy', 'retention'],
    ar: 'الانتفاخ قبل وأثناء الدورة سببه احتباس السوائل بفعل الهرمونات — وليس زيادة وزن حقيقية، ويزول عادة خلال أيام. يساعد: تقليل الملح والأطعمة المصنعة، شرب ماء أكثر (نعم!)، والبوتاسيوم من الموز والأفوكادو، والمشي الخفيف يحرك الهضم.',
    en: 'Pre-period and period bloating is hormone-driven water retention — not real weight gain, and it usually fades within days. What helps: less salt and processed food, more water (yes, really!), potassium from bananas and avocado, and light walking to get digestion moving.',
  },
  {
    id: 'skin_changes',
    phases: ['luteal', 'menstrual'],
    keywords: ['بشره', 'حبوب', 'حبه', 'وجهي', 'بثور', 'skin', 'acne', 'pimple', 'breakout', 'face'],
    ar: 'ظهور الحبوب قبل الدورة طبيعي جداً: ارتفاع البروجستيرون يزيد إفراز الزيوت في البشرة. تساعد روتينات بسيطة — غسول لطيف مرتين يومياً، عدم لمس الوجه، تغيير غطاء الوسادة، وترطيب حتى للبشرة الدهنية. بعد الدورة يرتفع الإستروجين وتصفو البشرة غالباً من جديد.',
    en: 'Pre-period breakouts are very normal: rising progesterone increases skin oil production. Simple routines help — gentle cleanser twice daily, hands off the face, fresh pillowcases, and moisturizer even for oily skin. After your period, estrogen rises and skin usually clears again.',
  },
  {
    id: 'sleep',
    phases: [],
    keywords: ['نوم', 'ارق', 'سهر', 'نعسانه', 'ما بقدر انام', 'تعبانه', 'sleep', 'insomnia', 'tired', 'exhausted', 'fatigue', 'awake'],
    ar: 'النوم والدورة مرتبطان بعمق: قبل الدورة قد يرتفع حرارة الجسم قليلاً فيصعب النوم — تبريد الغرفة ودش دافئ قبل النوم يساعدان. الثبات على موعد نوم واستيقاظ واحد يضبط الهرمونات نفسها، وإبعاد الشاشات آخر ساعة يحسن جودة النوم بشكل ملموس.',
    en: 'Sleep and your cycle are deeply linked: before your period, body temperature rises slightly, which can make falling asleep harder — a cooler room and a warm shower before bed both help. A consistent sleep/wake time actually helps regulate hormones themselves, and screen-free last hour measurably improves sleep quality.',
  },

  // ── Movement & emotional wellbeing ───────────────────────────────────────
  {
    id: 'exercise_cycle',
    phases: [],
    keywords: ['رياضه', 'تمارين', 'تمرين', 'مشي', 'يوغا', 'جيم', 'نادي', 'exercise', 'workout', 'gym', 'yoga', 'walk', 'run', 'sport'],
    ar: 'خرافة شائعة أن الرياضة ممنوعة أيام الدورة — العكس صحيح: الحركة الخفيفة تفرز الإندورفين وتخفف التقلصات والمزاج المتعكر. القاعدة الذهبية: وائمي الشدة مع مرحلتك — يوغا ومشي أيام الدورة، تمارين قوة وكارديو في المرحلة الجرابية حيث الطاقة بذروتها، وتمارين معتدلة قبل الدورة.',
    en: 'It\'s a common myth that exercise is off-limits during your period — the opposite is true: gentle movement releases endorphins that ease cramps and lift mood. Golden rule: match intensity to your phase — yoga and walks during your period, strength and cardio in the follicular phase when energy peaks, moderate workouts before your period.',
  },
  {
    id: 'mood_swings',
    phases: ['luteal', 'menstrual'],
    keywords: ['مزاج', 'نفسيه', 'نفسيتي', 'عصبيه', 'زعلانه', 'حزينه', 'مكتئبه', 'ضايقه', 'بكاء', 'ابكي', 'mood', 'moody', 'irritable', 'sad', 'cry', 'emotional', 'upset'],
    ar: 'التقلبات المزاجية قبل الدورة ليست "دلع" ولا ضعفاً — هبوط الإستروجين يخفض السيروتونين (هرمون المزاج) فعلياً. ما يساعد: تسمية الشعور بصوت عالٍ أو كتابته، ضوء الشمس صباحاً، حركة خفيفة، وتذكير نفسك أن هذه موجة وستمر. مشاعرك حقيقية ومؤقتة معاً.',
    en: 'Pre-period mood swings aren\'t drama or weakness — falling estrogen genuinely lowers serotonin, the mood hormone. What helps: naming the feeling out loud or on paper, morning sunlight, gentle movement, and reminding yourself this is a wave that will pass. Your feelings are both real and temporary.',
  },
  {
    id: 'stress_cycle',
    phases: [],
    keywords: ['ضغط', 'توتر', 'ستريس', 'مضغوطه', 'متوتره', 'قلق', 'قلقانه', 'stress', 'stressed', 'anxious', 'anxiety', 'overwhelmed'],
    ar: 'التوتر المزمن يرفع الكورتيزول، والكورتيزول قد يؤخر التبويض ويجعل الدورة غير منتظمة — لذلك شهور السفر أو الامتحانات أو الضغوط تأتي الدورة فيها متأخرة أحياناً. تنفس عميق 4-7-8 (شهيق 4، حبس 7، زفير 8) لخمس دقائق يخفض الكورتيزول بشكل مقاس.',
    en: 'Chronic stress raises cortisol, and cortisol can delay ovulation and make cycles irregular — which is why periods sometimes run late during months of travel, exams, or pressure. Five minutes of 4-7-8 breathing (inhale 4, hold 7, exhale 8) measurably lowers cortisol.',
  },
  {
    id: 'selfcare_warmth',
    phases: ['menstrual', 'luteal'],
    keywords: ['استرخاء', 'راحه', 'حمام', 'دفء', 'دلع', 'اهتم بنفسي', 'عنايه', 'relax', 'selfcare', 'self-care', 'bath', 'cozy', 'rest', 'pamper'],
    ar: 'طقوس الدفء الصغيرة لها أثر فسيولوجي حقيقي أيام الدورة: حمام دافئ يرخي العضلات، مشروب ساخن بين اليدين يهدئ الجهاز العصبي، وبطانية وكتاب أو مسلسل خفيف يخفضان التوتر. خصصي ولو 20 دقيقة "غير قابلة للتفاوض" لنفسك — هذا استثمار لا أنانية.',
    en: 'Small warmth rituals have a real physiological effect on period days: a warm bath relaxes muscles, a hot drink between your palms calms the nervous system, and a blanket with a book or light show lowers stress. Claim even 20 non-negotiable minutes for yourself — that\'s investment, not selfishness.',
  },

  // ── Fertility & tracking education ───────────────────────────────────────
  {
    id: 'fertile_window',
    phases: [],
    keywords: ['حمل', 'احمل', 'خصوبه', 'انجاب', 'تخطيط حمل', 'نافذه', 'pregnant', 'conceive', 'conception', 'fertility', 'fertile', 'ttc'],
    ar: 'نافذة الخصوبة تمتد نحو 6 أيام: الخمسة التي تسبق التبويض ويوم التبويض نفسه — لأن الحيوانات المنوية تعيش حتى 5 أيام بينما البويضة 24 ساعة تقريباً. تتبع الدورة بانتظام لعدة شهور يجعل توقع هذه النافذة أدق بكثير.',
    en: 'The fertile window spans about 6 days: the five days before ovulation plus ovulation day itself — because sperm can live up to 5 days while the egg lives about 24 hours. Tracking your cycle consistently for several months makes predicting this window much more accurate.',
  },
  {
    id: 'tracking_benefits',
    phases: [],
    keywords: ['تتبع', 'تسجيل', 'سجلي', 'توقع', 'دقه', 'منتظمه', 'غير منتظمه', 'tracking', 'log', 'logging', 'predict', 'accuracy', 'irregular'],
    ar: 'اختلاف طول الدورة من شهر لآخر بحدود 7 أيام يعتبر ضمن الطبيعي عند أغلب النساء — السفر والتوتر وتغير النوم والوزن كلها تؤثر. كلما سجلتِ أكثر (بداية الدورة، الأعراض، المزاج) صارت التوقعات أدق، وصار عندك سجل واضح تعرضينه على طبيبتك إذا احتجتِ — تقرير الطبيب في التطبيق يجهزه لك بضغطة.',
    en: 'Cycle length varying up to about 7 days month-to-month is within the normal range for most women — travel, stress, sleep changes, and weight shifts all play a part. The more you log (period start, symptoms, mood), the sharper your predictions get, and you build a clear record to show your doctor if ever needed — the app\'s doctor report compiles it in one tap.',
  },

  // ── Cycle literacy & myths ───────────────────────────────────────────────
  {
    id: 'cycle_length_basics',
    phases: [],
    keywords: ['كم يوم', 'طول الدوره', 'مده الدوره', 'اليوم الاول', 'دوره طبيعيه', 'cycle length', 'normal cycle', 'how long', 'day one'],
    ar: 'الدورة "الطبيعية" أوسع مما يشاع: أي طول بين 21 و35 يوماً يعتبر ضمن المعدل الطبيعي عند البالغات، وليس 28 يوماً فقط. واليوم الأول من الدورة هو أول يوم نزيف حقيقي (وليس التنقيط الخفيف) — ومنه يبدأ العد في التطبيق.',
    en: 'A "normal" cycle is broader than people think: anywhere from 21 to 35 days is within the typical range for adults — not just 28. Day 1 of your cycle is the first day of real flow (not light spotting) — that\'s where the app starts counting.',
  },
  {
    id: 'myths_common',
    phases: [],
    keywords: ['خرافه', 'خرافات', 'هل صحيح', 'صحيح انه', 'استحمام', 'استحم', 'اغسل شعري', 'دش', 'myth', 'is it true', 'shower', 'wash my hair'],
    ar: 'خرافات شائعة تستحق التصحيح: الاستحمام أيام الدورة آمن تماماً بل الماء الدافئ يريح التقلصات، وغسل الشعر لا يؤثر على الدورة إطلاقاً. وخرافة "مستحيل الحمل أثناء الدورة" غير دقيقة — الحيوانات المنوية تعيش حتى 5 أيام، فمع الدورات القصيرة يبقى الحمل ممكناً.',
    en: 'Common myths worth busting: showering or bathing during your period is completely safe — warm water actually eases cramps — and washing your hair has zero effect on your cycle. And "you can\'t get pregnant on your period" isn\'t accurate: sperm live up to 5 days, so with shorter cycles it\'s still possible.',
  },
  {
    id: 'sanitary_products',
    phases: ['menstrual'],
    keywords: ['فوط', 'فوطه', 'سدادات', 'تامبون', 'تمبون', 'كاس الحيض', 'كوب الحيض', 'منتجات صحيه', 'pads', 'tampon', 'tampons', 'menstrual cup', 'pantyliner'],
    ar: 'لكل وسيلة إيقاعها: الفوطة تُغيَّر كل 4–6 ساعات تقريباً، والسدادة القطنية كل 4–8 ساعات كحد أقصى، وكأس الحيض يدوم حتى 12 ساعة وصديق للبيئة. لا توجد وسيلة "أفضل" للجميع — الأفضل هي المريحة لجسمك ونمط يومك، وتقدرين تسجلين استهلاكك في التطبيق لتعرفي احتياجك.',
    en: 'Each option has its rhythm: pads are changed roughly every 4–6 hours, tampons every 4–8 hours max, and a menstrual cup lasts up to 12 hours and is eco-friendly. There\'s no single "best" — the best is whatever feels comfortable for your body and your day, and you can log usage in the app to learn your needs.',
  },
  {
    id: 'first_period_teen',
    phases: [],
    keywords: ['اول دوره', 'بلوغ', 'بنتي', 'مراهقه', 'first period', 'puberty', 'teen', 'daughter'],
    ar: 'في أول سنة أو سنتين بعد الدورة الأولى، عدم الانتظام هو القاعدة لا الاستثناء — الجهاز الهرموني ما زال "يضبط إيقاعه" وقد تتباعد الدورات أو تتقارب. الصبر والتتبع اللطيف يكفيان غالباً، ومع الوقت يستقر النمط الخاص بها.',
    en: 'In the first year or two after a first period, irregularity is the rule, not the exception — the hormonal system is still tuning its rhythm, so cycles may run far apart or close together. Patience and gentle tracking are usually enough; her own pattern settles with time.',
  },
  {
    id: 'perimenopause_edu',
    phases: [],
    keywords: ['انقطاع الطمث', 'سن الياس', 'سن الامل', 'الاربعينات', 'قبل الانقطاع', 'menopause', 'perimenopause', 'forties'],
    ar: 'في الأربعينات تقريباً تدخل كثير من النساء مرحلة "ما قبل انقطاع الطمث" — انتقال تدريجي قد يمتد سنوات تتغير فيه انتظام الدورة وغزارتها، وهذا فصل طبيعي من رحلة الجسم لا مرض. التتبع في هذه المرحلة ذهب: يوثق التغيرات بدقة لعرضها على طبيبتك.',
    en: 'Around the forties, many women enter perimenopause — a gradual transition that can last years, where cycle regularity and flow change. It\'s a natural chapter of the body\'s journey, not an illness. Tracking is gold in this phase: it documents the changes precisely for conversations with your doctor.',
  },

  // ── More symptoms — comfort education ────────────────────────────────────
  {
    id: 'breast_tenderness',
    phases: ['luteal'],
    keywords: ['صدري', 'الثدي', 'ثدي', 'الم الصدر', 'حساسيه الصدر', 'breast', 'breasts', 'tender', 'sore chest'],
    ar: 'حساسية أو ألم الثدي قبل الدورة شائع جداً — تغير الهرمونات يجعل الأنسجة تحتبس السوائل وتتحسس. يساعد: حمالة داعمة مريحة (حتى أثناء النوم إن لزم)، تقليل الملح والكافيين تلك الأيام، وكمادة دافئة. ويخف عادة مع بدء الدورة.',
    en: 'Pre-period breast tenderness is very common — hormonal shifts make the tissue hold fluid and feel sensitive. What helps: a comfy supportive bra (even for sleep if needed), less salt and caffeine on those days, and a warm compress. It usually eases once your period starts.',
  },
  {
    id: 'headache_period',
    phases: ['menstrual', 'luteal'],
    keywords: ['صداع', 'راسي يوجعني', 'شقيقه', 'ميغرين', 'ميجرين', 'headache', 'migraine', 'head hurts'],
    ar: 'الصداع حول موعد الدورة له تفسير: هبوط الإستروجين المفاجئ يؤثر على الأوعية الدموية في الرأس. يساعد: كوب ماء كبير فوراً (الجفاف يضاعفه)، وجبات منتظمة، كمادة باردة على الجبهة، وتخفيف إضاءة الشاشات. وإذا كان شديداً ويتكرر كل شهر، يستحق نقاشاً مع طبيبتك.',
    en: 'Headaches around your period have an explanation: the sudden estrogen drop affects blood vessels in the head. What helps: a big glass of water right away (dehydration amplifies it), regular meals, a cold compress on the forehead, and dimmer screens. If it\'s severe and returns monthly, it\'s worth discussing with your doctor.',
  },
  {
    id: 'back_ache',
    phases: ['menstrual'],
    keywords: ['ظهري', 'الظهر', 'اسفل ظهري', 'back pain', 'backache', 'lower back', 'my back'],
    ar: 'ألم أسفل الظهر أيام الدورة هو صدى تقلصات الرحم في عضلات الظهر المجاورة. يساعد: الحرارة (قربة دافئة أسفل الظهر)، وضعية الطفل ووضعية الركبتين إلى الصدر، والمشي الخفيف — بينما الجلوس الطويل يزيده سوءاً.',
    en: 'Lower-back ache during your period is uterine cramping echoing into the nearby back muscles. What helps: heat (a warm bottle on the lower back), child\'s pose and knees-to-chest stretches, and light walking — while long sitting makes it worse.',
  },
  {
    id: 'nausea_comfort',
    phases: ['menstrual'],
    keywords: ['غثيان', 'مغثيه', 'لوعه', 'nausea', 'nauseous', 'queasy'],
    ar: 'الغثيان الخفيف أيام الدورة حقيقي وله سبب — البروستاغلاندينات التي تحفز التقلصات قد تصل للجهاز الهضمي. يساعد: شاي الزنجبيل أو النعناع، وجبات صغيرة متكررة بدل الكبيرة، وهواء منعش. وإذا كان الاستفراغ شديداً أو مستمراً، استشيري طبيبتك.',
    en: 'Mild period nausea is real and has a cause — the prostaglandins driving cramps can also reach the digestive system. What helps: ginger or mint tea, small frequent meals instead of big ones, and fresh air. If vomiting is severe or persistent, check with your doctor.',
  },
  {
    id: 'discharge_education',
    phases: [],
    keywords: ['افرازات', 'افراز', 'مخاط', 'discharge', 'mucus'],
    ar: 'الإفرازات مرآة الدورة وتغيرها طبيعي تماماً: قليلة وجافة بعد الدورة، ثم كريمية، ثم شفافة مطاطية كبياض البيض قرب التبويض (علامة خصوبة)، ثم أكثف قبل الدورة. أما رائحة قوية أو حكة أو لون غير معتاد فتستحق زيارة طبيبة.',
    en: 'Discharge mirrors your cycle, and its changes are completely normal: scant and dry after your period, then creamy, then clear and stretchy like egg white near ovulation (a fertility sign), then thicker before your period. A strong odor, itching, or unusual color, though, deserves a doctor visit.',
  },

  // ── Body literacy & habits ───────────────────────────────────────────────
  {
    id: 'appetite_luteal',
    phases: ['luteal'],
    keywords: ['جوعانه', 'جوع', 'شهيتي', 'شهيه', 'اكل كثير', 'ما اشبع', 'appetite', 'hungry', 'hungrier'],
    ar: 'جوعك الزائد قبل الدورة ليس وهماً: الأيض يرتفع فعلياً في المرحلة الأصفرية ويحرق الجسم 100–300 سعرة إضافية يومياً، فيطلب وقوداً أكثر. لبّي الجوع بذكاء — بروتين وألياف (بيض، عدس، شوفان، مكسرات) تشبع أطول من السكريات السريعة.',
    en: 'Your bigger pre-period appetite isn\'t imaginary: metabolism genuinely rises in the luteal phase, burning an extra 100–300 calories a day, so the body asks for more fuel. Answer it smartly — protein and fiber (eggs, lentils, oats, nuts) satisfy longer than quick sugars.',
  },
  {
    id: 'weight_fluctuation',
    phases: [],
    keywords: ['وزني', 'الوزن', 'كيلو', 'الميزان', 'weight', 'scale', 'gained'],
    ar: 'تأرجح الوزن 1–2 كيلو خلال الشهر طبيعي بالكامل — معظمه ماء محتبس بفعل الهرمونات وليس دهوناً. للمقارنة العادلة: وزني نفسك بنفس التوقيت من اليوم وبنفس المرحلة من الدورة (مثلاً أسبوع بعد انتهائها) — والتطبيق يرسم لك الاتجاه العام وهو ما يهم فعلاً.',
    en: 'Swinging 1–2 kg across the month is completely normal — mostly hormone-driven water, not fat. For a fair comparison, weigh yourself at the same time of day and the same cycle phase (say, a week after your period ends) — the app charts the overall trend, which is what actually matters.',
  },
  {
    id: 'bbt_education',
    phases: [],
    keywords: ['حرارتي', 'الحراره', 'درجه حراره', 'ترمومتر', 'bbt', 'temperature', 'basal'],
    ar: 'درجة حرارة الجسم الأساسية سر جميل من أسرار الدورة: ترتفع نحو 0.3–0.5 درجة بعد التبويض وتبقى مرتفعة حتى الدورة التالية. للقياس الدقيق: قيسيها فور الاستيقاظ قبل النهوض من السرير وبنفس التوقيت يومياً — وسجليها في التطبيق ليرسم لك منحنى التبويض.',
    en: 'Basal body temperature is one of the cycle\'s lovely secrets: it rises about 0.3–0.5°C after ovulation and stays elevated until your next period. For accuracy, measure the moment you wake — before getting out of bed, same time daily — and log it in the app to see your ovulation curve.',
  },
  {
    id: 'journaling_feelings',
    phases: [],
    keywords: ['فضفضه', 'افضفض', 'اكتب مشاعري', 'يومياتي', 'يوميات', 'journal', 'journaling', 'vent', 'write my feelings'],
    ar: 'الفضفضة بالكتابة ليست مجرد تنفيس — تسمية المشاعر كتابةً تخفض حدتها فعلياً في الدماغ. جربي 5 دقائق "تفريغ" بلا ترتيب ولا أحكام، وسجلي مزاجك في التطبيق — مع الوقت سترين نمط مشاعرك مرسوماً على خريطة دورتك، وهذا وحده مطمئن.',
    en: 'Journaling isn\'t just venting — naming feelings in writing genuinely lowers their intensity in the brain. Try a 5-minute unfiltered brain-dump, and log your mood in the app — over time you\'ll see your emotional pattern mapped onto your cycle, which is soothing in itself.',
  },
  {
    id: 'travel_cycle',
    phases: [],
    keywords: ['سفر', 'مسافره', 'السفر', 'طياره', 'travel', 'trip', 'flight', 'jet lag', 'vacation'],
    ar: 'السفر قد يزحزح موعد الدورة أياماً قليلة — تغير التوقيت والنوم والتوتر يربك الساعة الهرمونية مؤقتاً، وهذا طبيعي ويعود لوضعه وحده. عملياً: احملي مستلزماتك دائماً حتى لو الموعد بعيد، اشربي ماء أكثر في الطيران، واستمري بالتسجيل في التطبيق ليبقى التوقع دقيقاً.',
    en: 'Travel can shift your period by a few days — time zones, sleep changes, and stress briefly confuse the hormonal clock, and it settles back on its own. Practically: always pack supplies even if you\'re "not due", drink extra water when flying, and keep logging in the app so predictions stay sharp.',
  },
  {
    id: 'libido_cycle',
    phases: [],
    keywords: ['رغبتي', 'الرغبه', 'شهوه', 'libido', 'sex drive', 'desire'],
    ar: 'تقلب الرغبة عبر الشهر طبيعي وموثق: كثير من النساء يلاحظن ذروتها قرب التبويض (بفعل الإستروجين والتستوستيرون) وانخفاضها قبل الدورة وأثناءها. لا يوجد "معدل صحيح" — المهم أن تفهمي إيقاعك، والمصارحة اللطيفة مع الشريك حول هذه الموجات تريح الطرفين.',
    en: 'Desire fluctuating across the month is normal and well documented: many women notice it peaks near ovulation (thanks to estrogen and testosterone) and dips before and during their period. There\'s no "correct level" — what matters is knowing your rhythm, and gently sharing these waves with your partner puts you both at ease.',
  },

  // ── Nutrition — the rest of the cycle ────────────────────────────────────
  {
    id: 'nutrition_follicular',
    phases: ['follicular'],
    keywords: ['اكل', 'طعام', 'تغذيه', 'غذاء', 'وجبه', 'food', 'eat', 'nutrition', 'meal'],
    ar: 'المرحلة الجرابية وقت البناء: جسمك يجهز بويضة جديدة ويحتاج بروتيناً جيداً (بيض، دجاج، بقوليات) وخضاراً ورقية وحبوباً كاملة. طاقتك الصاعدة تتحمل وجبات أخف وأكثر انتعاشاً — سلطات، سموذي، أطباق ملونة.',
    en: 'The follicular phase is building time: your body is preparing a new egg and wants good protein (eggs, chicken, legumes), leafy greens, and whole grains. Your rising energy suits lighter, fresher meals — salads, smoothies, colorful plates.',
  },
  {
    id: 'nutrition_ovulation',
    phases: ['ovulation'],
    keywords: ['اكل', 'طعام', 'تغذيه', 'غذاء', 'وجبه', 'food', 'eat', 'nutrition', 'meal'],
    ar: 'حول التبويض يفيدك التركيز على مضادات الأكسدة (توت، رمان، خضار ملونة) والألياف التي تساعد الجسم على توازن الإستروجين، والزنك (بذور اليقطين، الحمص). اشربي ماء أكثر — حرارة الجسم ترتفع قليلاً في هذه الفترة.',
    en: 'Around ovulation, focus on antioxidants (berries, pomegranate, colorful veggies), fiber that helps the body balance estrogen, and zinc (pumpkin seeds, chickpeas). Drink extra water — body temperature runs slightly higher in this window.',
  },
  {
    id: 'magnesium_luteal',
    phases: ['luteal'],
    keywords: ['مغنيسيوم', 'مكسرات', 'بذور', 'magnesium', 'nuts', 'seeds'],
    ar: 'المغنيسيوم نجم المرحلة الأصفرية: يساعد على استرخاء العضلات وتحسين النوم وتهدئة المزاج، ومستوياته تنخفض طبيعياً قبل الدورة. مصادره اللذيذة: الشوكولاتة الداكنة، اللوز، الكاجو، بذور اليقطين، الموز، والأفوكادو.',
    en: 'Magnesium is the luteal phase star: it helps muscles relax, improves sleep, and calms mood — and its levels naturally dip before your period. Delicious sources: dark chocolate, almonds, cashews, pumpkin seeds, bananas, and avocado.',
  },
  {
    id: 'omega3_antiinflammatory',
    phases: [],
    keywords: ['اوميغا', 'اوميجا', 'سمك', 'سلمون', 'التهاب', 'omega', 'salmon', 'fish', 'inflammation', 'anti-inflammatory'],
    ar: 'الأطعمة المضادة للالتهاب حليفة قوية للدورة: أوميغا-3 (سلمون، سردين، جوز، بذور كتان) يرتبط في الدراسات بتقلصات أخف مع الانتظام عليه. أضيفي الكركم والزنجبيل لطبخك — مضادات التهاب طبيعية لذيذة.',
    en: 'Anti-inflammatory foods are a strong cycle ally: omega-3s (salmon, sardines, walnuts, flaxseed) are linked in studies to milder cramps with consistent intake. Add turmeric and ginger to your cooking — delicious natural anti-inflammatories.',
  },
  {
    id: 'herbal_teas',
    phases: [],
    keywords: ['اعشاب', 'شاي اعشاب', 'بابونج', 'يانسون', 'زنجبيل', 'نعناع', 'مشروب دافي', 'herbal', 'herbal tea', 'chamomile', 'ginger tea', 'mint tea', 'anise'],
    ar: 'مشروبات الأعشاب الدافئة صيدلية لطيفة أيام الدورة: البابونج يهدئ الأعصاب ويساعد على النوم، الزنجبيل يخفف الغثيان والتقلصات، النعناع يريح الهضم والانتفاخ، واليانسون مهدئ عام محبوب. كوب دافئ بين يديك له مفعول نفسي بحد ذاته.',
    en: 'Warm herbal drinks are a gentle pharmacy on period days: chamomile calms nerves and helps sleep, ginger eases nausea and cramps, mint soothes digestion and bloating, and anise is a beloved all-round soother. A warm cup between your hands is calming in itself.',
  },
  {
    id: 'sugar_salt_pms',
    phases: ['luteal'],
    keywords: ['ملح', 'مالح', 'شيبس', 'وجبات سريعه', 'معلبات', 'salt', 'salty', 'chips', 'junk food', 'processed'],
    ar: 'الأطعمة المصنعة والمالحة تضخّم أعراض ما قبل الدورة: الملح الزائد يزيد احتباس السوائل والانتفاخ، والسكر السريع يرفع المزاج ثم يهبط به بقوة. مش ممنوعة — بس وعيك بتوقيتها ذكاء: قللي منها الأسبوع الذي قبل الدورة تحديداً.',
    en: 'Processed and salty foods amplify PMS: extra salt worsens water retention and bloating, and quick sugar spikes mood then crashes it hard. They\'re not forbidden — but timing awareness is smart: cut back specifically in the week before your period.',
  },
  {
    id: 'energy_iron_fatigue',
    phases: ['menstrual', 'follicular'],
    keywords: ['خموله', 'خمول', 'مرهقه', 'طاقتي على الارض', 'هالكه', 'drained', 'exhausted', 'no energy', 'low energy'],
    ar: 'الإرهاق الشديد بعد دورة غزيرة له تفسير منطقي — فقدان الحديد مع الدم يستنزف الطاقة. عززي مخزونك بالعدس واللحوم الحمراء والسبانخ والتمر مع فيتامين C للامتصاص. وإذا كان الإرهاق شديداً ومستمراً كل شهر، فحص دم بسيط عند طبيبتك يطمئنك.',
    en: 'Deep fatigue after a heavy period has a logical explanation — iron lost with blood drains energy. Rebuild stores with lentils, red meat, spinach, and dates, paired with vitamin C for absorption. And if exhaustion is severe and recurs every month, a simple blood test at your doctor\'s will give you peace of mind.',
  },

  // ── Body — more everyday questions ───────────────────────────────────────
  {
    id: 'digestion_period',
    phases: ['menstrual', 'luteal'],
    keywords: ['اسهال', 'امساك', 'هضم', 'معدتي', 'بطني مقلوب', 'diarrhea', 'constipation', 'digestion', 'stomach upset', 'ibs'],
    ar: 'تغير الهضم حول الدورة سؤال محرج تسأله كثيرات وهو طبيعي 100%: البروستاغلاندينات التي تقلص الرحم تحرك الأمعاء أيضاً — لذلك الإسهال شائع أول أيام الدورة، والإمساك شائع قبلها (بفعل البروجستيرون). يساعد: ألياف وماء بانتظام، ووجبات أصغر تلك الأيام.',
    en: 'Digestion changing around your period is the awkward question many ask — and it\'s 100% normal: the prostaglandins contracting the uterus also stir the bowels, so loose stools are common early in your period, and constipation before it (thanks to progesterone). Steady fiber and water, plus smaller meals those days, help.',
  },
  {
    id: 'hair_cycle',
    phases: [],
    keywords: ['شعري', 'تساقط الشعر', 'شعر دهني', 'hair', 'hair loss', 'oily hair', 'shedding'],
    ar: 'شعرك يعيش الدورة معك: قرب التبويض يكون بأفضل حالاته (الإستروجين عالي)، وقبل الدورة قد يصبح أكثر دهنية وتلاحظين تساقطاً أكثر قليلاً — مؤقت ويتحسن. أما التساقط الكثيف المستمر لشهور فيستحق فحصاً عند طبيبة (الحديد والغدة من أشهر الأسباب القابلة للعلاج).',
    en: 'Your hair lives the cycle with you: near ovulation it\'s at its best (high estrogen), and before your period it may get oilier with slightly more shedding — temporary, and it recovers. Heavy shedding that persists for months, though, deserves a doctor check (iron and thyroid are the most common treatable causes).',
  },
  {
    id: 'heavy_flow_edu',
    phases: ['menstrual'],
    keywords: ['غزيره', 'دورتي قويه', 'دم كثير', 'كميه كبيره', 'heavy period', 'heavy flow', 'lots of blood'],
    ar: 'معيار عملي للدورة الغزيرة: إذا كنتِ تغرقين فوطة أو سدادة كاملة كل ساعة إلى ساعتين لعدة ساعات متتالية، أو تنزلين جلطات أكبر من عملة كبيرة — هذا يستحق مكالمة مع طبيبتك، ليس للخوف بل لأن له أسباباً قابلة للعلاج غالباً. وسجلي غزارة التدفق في التطبيق ليكون عندك سجل دقيق تعرضينه.',
    en: 'A practical yardstick for heavy flow: soaking through a full pad or tampon every 1–2 hours for several hours straight, or passing clots bigger than a large coin, deserves a call to your doctor — not out of fear, but because it usually has treatable causes. Log your flow intensity in the app so you have a precise record to show.',
  },
  {
    id: 'period_pain_doctor',
    phases: [],
    keywords: ['الم شديد كل شهر', 'ما بتحمل الالم', 'الم يمنعني', 'اغيب عن المدرسه', 'اغيب عن الشغل', 'بطلع اجازه', 'pain every month', 'debilitating', 'miss work', 'miss school'],
    ar: 'حقيقة مهمة تستحقين سماعها: الألم الذي يوقف حياتك كل شهر — يغيبك عن الدراسة أو العمل أو يمنعك من النهوض — ليس "طبيعياً يجب تحمله". ألم الدورة الشائع مزعج لكنه لا يعطل الحياة؛ الألم المعطل له أسباب تستحق التشخيص والعلاج. احكي مع طبيبة نسائية، وسجلك في التطبيق سيساعدها كثيراً.',
    en: 'A truth you deserve to hear: pain that stops your life every month — keeping you from school, work, or getting out of bed — is not "normal, just endure it". Common period pain is unpleasant but doesn\'t shut life down; disabling pain has causes that deserve diagnosis and treatment. Talk to a gynecologist — your app records will help her a lot.',
  },
  {
    id: 'hygiene_gentle',
    phases: [],
    keywords: ['نظافه', 'غسول', 'دش مهبلي', 'تنظيف المهبل', 'رائحه', 'douche', 'douching', 'intimate wash', 'odor', 'smell down'],
    ar: 'قاعدة ذهبية للنظافة الحميمة: المهبل ينظف نفسه بنفسه — الغسولات الداخلية (الدش المهبلي) تخل بتوازنه الطبيعي وتزيد الالتهابات، لذا تنصح الجهات الصحية بتجنبها. يكفي ماء دافئ وغسول لطيف غير معطر للمنطقة الخارجية فقط. ورائحة خفيفة طبيعية أمر عادي تماماً.',
    en: 'A golden rule of intimate hygiene: the vagina cleans itself — internal washes (douching) disrupt its natural balance and increase infections, which is why health authorities advise against them. Warm water and a mild unscented wash for the external area only is plenty. A mild natural scent is completely normal.',
  },
  {
    id: 'vitamin_d_sunlight',
    phases: [],
    keywords: ['فيتامين د', 'فيتامين دال', 'شمس', 'ضوء الشمس', 'vitamin d', 'sunlight', 'sunshine'],
    ar: 'ضوء الشمس صديق مجاني لدورتك ومزاجك: 15–20 دقيقة صباحاً تحفز فيتامين د المرتبط بانتظام الدورة وصحة المزاج، وتضبط ساعتك البيولوجية فينعكس على نومك. اجعليها عادة — قهوتك الصباحية قرب النافذة أو مشوار قصير.',
    en: 'Sunlight is a free friend to your cycle and mood: 15–20 morning minutes stimulate vitamin D — linked to cycle regularity and mood health — and anchor your body clock, which pays off in sleep. Make it a habit: morning coffee by the window or a short stroll.',
  },

  // ── Fertility, timing & family planning education ────────────────────────
  {
    id: 'ovulation_signs',
    phases: [],
    keywords: ['علامات التبويض', 'كيف اعرف التبويض', 'مبوضه', 'اعرف اني بوضت', 'ovulation signs', 'am i ovulating', 'signs of ovulation'],
    ar: 'جسمك يرسل إشارات تبويض يمكنك تعلم قراءتها: إفرازات شفافة مطاطية كبياض البيض (أوضح علامة)، ارتفاع خفيف في حرارة الجسم الأساسية بعده، وخزة خفيفة بجانب واحد من أسفل البطن عند بعض النساء، وارتفاع ملحوظ في الطاقة والرغبة. سجلي هذه العلامات في التطبيق وسيتعلم نمطك.',
    en: 'Your body sends ovulation signals you can learn to read: clear stretchy egg-white discharge (the clearest sign), a slight basal temperature rise afterward, a mild one-sided lower-belly twinge in some women, and a noticeable lift in energy and desire. Log these signs in the app and it will learn your pattern.',
  },
  {
    id: 'late_period_causes',
    phases: [],
    keywords: ['متاخره', 'دورتي متاخره', 'الدوره متاخره', 'تاخرت الدوره', 'تاخرت دورتي', 'ما اجت الدوره', 'ما جات الدوره', 'ليش تاخرت', 'late period', 'period is late', 'missed period', 'no period'],
    ar: 'تأخر الدورة لا يعني الحمل بالضرورة — أشهر الأسباب الأخرى: توتر مرتفع، سفر وتغير نوم، تغير وزن ملحوظ، رياضة مكثفة فجأة، أو حتى مرض عابر أزاح موعد التبويض. أسبوع تأخير أمر شائع؛ إذا كان الحمل وارداً افحصي بعد التأخر، وإذا تكرر الغياب لدورات متتالية فاستشارة طبيبة أفضل خطوة.',
    en: 'A late period doesn\'t necessarily mean pregnancy — the other top causes: high stress, travel and sleep changes, notable weight shifts, suddenly intense exercise, or even a passing illness that nudged ovulation later. A week\'s delay is common; if pregnancy is possible, test after the missed date, and if periods keep skipping for consecutive cycles, seeing a doctor is the best step.',
  },
  {
    id: 'pregnancy_test_timing',
    phases: [],
    keywords: ['اختبار حمل', 'تحليل حمل', 'افحص حمل', 'فحص الحمل', 'اعمل تست', 'pregnancy test', 'when to test', 'test for pregnancy'],
    ar: 'أفضل توقيت لاختبار الحمل المنزلي: من أول يوم تأخير للدورة فصاعداً — قبل ذلك قد يعطي سلبياً خاطئاً لأن الهرمون لم يتراكم بعد. أول بول الصباح أدق لأنه أكثر تركيزاً. وإذا طلع سلبياً والدورة ما زالت غائبة، أعيديه بعد 3–4 أيام.',
    en: 'The best timing for a home pregnancy test: from the first day your period is late onward — earlier can give a false negative because the hormone hasn\'t built up yet. First morning urine is most accurate since it\'s most concentrated. If it\'s negative and your period still hasn\'t come, repeat in 3–4 days.',
  },
  {
    id: 'pill_consistency',
    phases: [],
    keywords: ['حبوب منع', 'مانع الحمل', 'موانع الحمل', 'وسيله منع', 'birth control', 'contraception', 'contraceptive', 'the pill'],
    ar: 'مع حبوب منع الحمل، الانتظام هو كل شيء: تناولها بنفس الموعد يومياً يحافظ على فعاليتها — والتطبيق يقدر يذكرك يومياً من قسم الصحة. أما تعليمات "ماذا أفعل لو نسيت حبة" فتختلف حسب النوع: النشرة الداخلية أو الصيدلانية هما المرجع الدقيق، ولأي أعراض مزعجة مستمرة استشيري طبيبتك.',
    en: 'With birth control pills, consistency is everything: taking them at the same time daily keeps them effective — and the app can remind you each day from the wellness section. As for "what if I missed a pill" — instructions differ by type: the package leaflet or your pharmacist are the precise reference, and for persistent bothersome side effects, talk to your doctor.',
  },
  {
    id: 'postpartum_return',
    phases: [],
    keywords: ['بعد الولاده', 'نفاس', 'ولدت', 'ولدت من', 'ولدت قبل', 'ولادتي', 'ارضع', 'رضاعه', 'postpartum', 'after birth', 'gave birth', 'breastfeeding'],
    ar: 'عودة الدورة بعد الولادة تختلف كثيراً من امرأة لأخرى: بدون رضاعة تعود غالباً خلال 6–12 أسبوعاً، ومع الرضاعة الكاملة قد تغيب شهوراً طويلة (هرمون الحليب يثبط التبويض) — وكلاهما طبيعي. أول دورات بعد الولادة قد تكون غير منتظمة أو مختلفة الغزارة، وتنتظم تدريجياً.',
    en: 'The period\'s return after birth varies widely: without breastfeeding it\'s usually back within 6–12 weeks, while full breastfeeding can keep it away for many months (the milk hormone suppresses ovulation) — both are normal. The first postpartum cycles may be irregular or different in flow, settling gradually.',
  },

  // ── Mind, work & relationships ───────────────────────────────────────────
  {
    id: 'brain_fog',
    phases: ['luteal', 'menstrual'],
    keywords: ['مشتته', 'ضباب', 'اركز', 'تركيز', 'نسيان', 'ناسيه', 'brain fog', 'forgetful', 'focus', 'concentrate', 'scattered'],
    ar: 'ضباب الدماغ قبل الدورة حقيقي وليس إهمالاً منك — تقلب الهرمونات يؤثر مؤقتاً على التركيز والذاكرة العاملة. تعاملي معه بلطف وذكاء: قوائم مكتوبة بدل الاعتماد على الذاكرة، مهمة واحدة بكل مرة، فواصل قصيرة، وأجّلي القرارات الكبيرة أياماً قليلة إن أمكن.',
    en: 'Pre-period brain fog is real, not carelessness — hormone swings temporarily affect focus and working memory. Handle it kindly and smartly: written lists instead of relying on memory, one task at a time, short breaks, and postpone big decisions a few days if you can.',
  },
  {
    id: 'work_productivity_cycle',
    phases: [],
    keywords: ['شغل', 'دوام', 'انتاجيه', 'مهامي', 'اجتماع', 'عرض تقديمي', 'work', 'productivity', 'tasks', 'meeting', 'presentation', 'deadline'],
    ar: 'سر إنتاجية أنيق: خططي مهامك مع دورتك بدل ضدها. المرحلة الجرابية ممتازة للبدايات والعصف الذهني، وحول التبويض تتألقين في العروض والاجتماعات والتواصل، والمرحلة الأصفرية مثالية لأعمال التدقيق والإنهاء والتفاصيل، وأيام الدورة للمهام الهادئة والتخطيط. مو قانون صارم — بس وعي يخفف عنك كثيراً.',
    en: 'An elegant productivity secret: plan tasks with your cycle, not against it. The follicular phase is great for starts and brainstorming; around ovulation you shine in presentations, meetings, and communication; the luteal phase suits reviewing, finishing, and detail work; and period days fit quiet tasks and planning. Not a strict law — just awareness that lightens the load.',
  },
  {
    id: 'mood_severe_edu',
    phases: [],
    keywords: ['اكتئاب', 'كل شهر نفس الشي', 'كل شهر نفسيتي', 'نفسيتي تنهار', 'نفسيتي تدمرت', 'ما عاد اتحمل نفسيتي', 'pmdd', 'depression', 'depressed', 'every month i break'],
    ar: 'فرق مهم يستحق أن تعرفيه: تقلب المزاج قبل الدورة شائع، لكن إذا كانت نفسيتك تنهار بشدة كل شهر بنفس التوقيت — حزن غامر، غضب لا يسيطر عليه، أو أفكار مظلمة تعطل حياتك — فهذا نمط معروف له اسم وله علاج فعال، ولا يجب تحمله بصمت. احكي مع طبيبة أو مختصة نفسية، وسجل مزاجك في التطبيق سيساعدها ترى النمط.',
    en: 'An important distinction worth knowing: pre-period mood swings are common, but if your mental state crashes hard every month on the same schedule — overwhelming sadness, uncontrollable anger, or dark thoughts that disrupt your life — that\'s a known pattern with a name and effective treatment, and it shouldn\'t be endured in silence. Talk to a doctor or mental-health professional; your mood log in the app will help them see the pattern.',
  },
  {
    id: 'mindfulness_grounding',
    phases: [],
    keywords: ['تامل', 'ميديتيشن', 'مخنوقه', 'توترت كثير', 'اهدي حالي', 'اهدا', 'meditation', 'mindfulness', 'grounding', 'calm down', 'panic'],
    ar: 'حين تشعرين أن التوتر يبتلعك، تمرين الإرساء 5-4-3-2-1 يعيدك للحظة خلال دقائق: سمّي 5 أشياء تريها، 4 تلمسينها، 3 تسمعينها، 2 تشمينها، وشيئاً واحداً تتذوقينه. يشغل الدماغ بالحواس بدل الأفكار المتسارعة. وتأمل 5 دقائق يومياً — حتى مجرد مراقبة النفس — يخفض التوتر تراكمياً.',
    en: 'When stress feels swallowing, the 5-4-3-2-1 grounding exercise brings you back within minutes: name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, and 1 you taste. It occupies the brain with senses instead of racing thoughts. And 5 minutes of daily meditation — even just watching your breath — lowers stress cumulatively.',
  },
  {
    id: 'social_connection',
    phases: [],
    keywords: ['وحيده', 'وحده', 'محدا يفهمني', 'اصحابي', 'صديقاتي', 'lonely', 'alone', 'nobody understands', 'my friends'],
    ar: 'الشعور بالوحدة أيام الهرمونات الصعبة يضاعف ثقلها — والعلم واضح: مكالمة دافئة مع صديقة أو جلسة قصيرة مع شخص يفهمك تخفض هرمون التوتر فعلياً. لا تنتظري أن تكوني "بمزاج حلو" للتواصل؛ التواصل نفسه هو ما يحسن المزاج. ومجتمع لون داخل التطبيق مليء بنساء يفهمن بالضبط ما تمرين به.',
    en: 'Loneliness on hard hormone days doubles their weight — and the science is clear: a warm call with a friend or a short sit-down with someone who gets you genuinely lowers stress hormones. Don\'t wait to be "in a good mood" to reach out; reaching out is what lifts the mood. And the Lune community inside the app is full of women who know exactly what you\'re going through.',
  },
  {
    id: 'partner_support',
    phases: [],
    keywords: ['زوجي', 'خطيبي', 'شريكي', 'حبيبي', 'يساعدني', 'ما يفهمني', 'husband', 'boyfriend', 'partner', 'he doesnt understand'],
    ar: 'الشريك الداعم يصنع فرقاً حقيقياً أيام الدورة، وغالباً هو يريد المساعدة لكنه لا يعرف كيف. ساعديه بطلبات محددة بدل التلميح: "جهزلي قربة دافئة"، "خفف عني المشاوير اليوم"، "بس اسمعني بدون حلول". وميزة مشاركة الشريك في التطبيق تخليه يعرف مرحلتك تلقائياً — نصف الفهم يبدأ من المعرفة.',
    en: 'A supportive partner makes a real difference on period days — and usually he wants to help but doesn\'t know how. Help him with specific asks instead of hints: "bring me the heat pack", "take errands off me today", "just listen, no fixing". The app\'s partner-sharing feature lets him see your phase automatically — half of understanding starts with knowing.',
  },

  // ── Movement — deeper cuts ───────────────────────────────────────────────
  {
    id: 'yoga_poses_cramps',
    phases: ['menstrual'],
    keywords: ['يوغا', 'يوجا', 'تمدد', 'وضعيه', 'استرتش', 'yoga', 'stretch', 'stretching', 'poses'],
    ar: 'ثلاث وضعيات يوغا لطيفة تستهدف التقلصات مباشرة: وضعية الطفل (تريح أسفل الظهر والبطن)، القطة-البقرة (تدلك منطقة الحوض بحركة متموجة)، والاستلقاء مع رفع الساقين على الحائط (يهدئ الجهاز العصبي كله). دقيقة إلى دقيقتين بكل وضعية مع تنفس بطيء تكفي.',
    en: 'Three gentle yoga poses that target cramps directly: child\'s pose (soothes the lower back and belly), cat-cow (massages the pelvic area with its wave motion), and legs-up-the-wall (calms the whole nervous system). One to two minutes per pose with slow breathing is enough.',
  },
  {
    id: 'walking_mood',
    phases: [],
    keywords: ['مشي', 'امشي', 'تمشيت', 'مشوار', 'walk', 'walking', 'stroll'],
    ar: 'المشي أبسط دواء مزاج موجود: 10 دقائق فقط في الهواء الطلق ترفع الإندورفين وتكسر حلقة الاجترار الذهني، والدراسات تجد أثرها على المزاج فورياً وليس تراكمياً فقط. أيام الدورة اجعليه هادئاً وقصيراً — الهدف تحريك الدم لا الإنجاز.',
    en: 'Walking is the simplest mood medicine there is: just 10 minutes outdoors lifts endorphins and breaks the rumination loop, and studies find the mood effect is immediate, not just cumulative. On period days keep it slow and short — the goal is moving blood, not achievement.',
  },
  {
    id: 'exercise_luteal',
    phases: ['luteal'],
    keywords: ['رياضه', 'تمارين', 'جيم', 'نادي', 'exercise', 'workout', 'gym', 'training'],
    ar: 'قبل الدورة جسمك يفضل الشدة المعتدلة: بيلاتس، قوة بأوزان متوسطة، مشي سريع، سباحة هادئة — الجسم في هذه المرحلة يتعافى أبطأ قليلاً وحرارته أعلى، فلا تقسي على نفسك إذا الأداء أقل من المعتاد. هذا ليس تراجعاً — هذه فسيولوجيا.',
    en: 'Before your period, your body prefers moderate intensity: pilates, medium-weight strength work, brisk walking, easy swimming — recovery runs a bit slower and body temperature a bit higher in this phase, so don\'t be hard on yourself if performance dips. That\'s not regression — that\'s physiology.',
  },
];

/**
 * Normalizes Arabic text for tolerant keyword matching:
 * strips diacritics/tatweel and unifies common letter variants.
 *
 * @param {string} s
 * @returns {string}
 */
function normalizeArabic(s) {
  return s
    .replace(/[ً-ْـ]/g, '')
    .replace(/[أإآ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي');
}

/**
 * Keyword matcher. Latin-script keywords require word boundaries so e.g.
 * "chocolate" does NOT match the keyword "late"; Arabic keywords use plain
 * substring matching (Arabic prefixes like و/ال attach directly to words,
 * so "والتقلصات" should still hit "تقلصات").
 *
 * @param {string} normalizedMessage Lowercased + Arabic-normalized message.
 * @param {string} keyword Raw keyword from a library entry.
 * @returns {boolean}
 */
function matchesKeyword(normalizedMessage, keyword) {
  const kw = normalizeArabic(keyword.toLowerCase());
  if (/^[a-z0-9\s-]+$/.test(kw)) {
    return new RegExp('\\b' + kw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\b')
      .test(normalizedMessage);
  }
  return normalizedMessage.includes(kw);
}

/**
 * Extracts a lowercase phase token ('menstrual'|'follicular'|'ovulation'|
 * 'luteal'|null) from whatever phase string the app sends (may be localized).
 *
 * @param {Object} cycleContext
 * @returns {?string}
 */
function currentPhaseToken(cycleContext) {
  const raw = String((cycleContext && cycleContext.currentPhase) || '').toLowerCase();
  if (!raw) return null;
  if (raw.includes('menstrual') || raw.includes('حيض') || raw.includes('دوره') || raw.includes('دورة')) return 'menstrual';
  if (raw.includes('follicular') || raw.includes('جرابي')) return 'follicular';
  if (raw.includes('ovul') || raw.includes('تبويض') || raw.includes('إباضة') || raw.includes('اباضه')) return 'ovulation';
  if (raw.includes('luteal') || raw.includes('أصفري') || raw.includes('اصفري')) return 'luteal';
  return null;
}

/**
 * Finds the best-matching library snippets for a user message.
 * A snippet must hit at least ONE keyword to qualify; matching the user's
 * current phase adds a ranking bonus (phase alone never triggers a snippet,
 * so greetings/small talk stay snippet-free).
 *
 * @param {string} message The raw user message.
 * @param {Object} cycleContext The cycle context (for phase + locale).
 * @param {number} [maxSnippets=MAX_SNIPPETS]
 * @returns {Array<{id: string, text: string}>}
 */
function findRelevantSnippets(message, cycleContext, maxSnippets = MAX_SNIPPETS) {
  const normalized = normalizeArabic(String(message || '').toLowerCase());
  if (!normalized.trim()) return [];

  const phase = currentPhaseToken(cycleContext);
  const locale = String((cycleContext && cycleContext.userLocale) || 'ar').toLowerCase();
  const lang = locale.startsWith('en') ? 'en' : 'ar';

  const scored = [];
  for (const entry of KNOWLEDGE) {
    let hits = 0;
    for (const kw of entry.keywords) {
      // Multi-word phrases are far more specific than single words — weight
      // them double so "period is late" outranks a generic "period" hit.
      if (matchesKeyword(normalized, kw)) hits += kw.includes(' ') ? 2 : 1;
    }
    if (hits === 0) continue;
    const phaseBonus = phase && entry.phases.includes(phase) ? 2 : 0;
    scored.push({ entry, score: hits + phaseBonus, hits });
  }

  // Tie-break on raw keyword hits: an entry the user actually asked about
  // beats one that merely matches her current phase.
  scored.sort((a, b) => (b.score - a.score) || (b.hits - a.hits));
  return scored.slice(0, maxSnippets).map(({ entry }) => ({
    id: entry.id,
    text: entry[lang],
  }));
}

/**
 * Builds the "LUNE LIBRARY" block to append to the user prompt, or ''
 * when the mode is excluded or nothing relevant matched.
 *
 * @param {string} message The raw user message.
 * @param {Object} cycleContext The cycle context.
 * @param {string} mode The active AI mode.
 * @returns {string} Empty string, or a block starting with '\n\n'.
 */
function buildKnowledgeBlock(message, cycleContext, mode) {
  if (!KNOWLEDGE_MODES.has(mode || 'chat')) return '';
  const snippets = findRelevantSnippets(message, cycleContext);
  if (snippets.length === 0) return '';

  const lines = snippets.map((s) => '- ' + s.text);
  return (
    '\n\n=== LUNE LIBRARY (curated wellness notes — trusted reference) ===\n' +
    lines.join('\n') +
    '\nUse these notes naturally in your own words when relevant. ' +
    'NEVER mention this library or that you were given reference notes.'
  );
}

module.exports = {
  KNOWLEDGE,
  findRelevantSnippets,
  buildKnowledgeBlock,
};
