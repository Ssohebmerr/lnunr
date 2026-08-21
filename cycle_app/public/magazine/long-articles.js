/*
 * Lune long-form editorial library.
 *
 * This file is shared by the public magazine and the Firebase admin importer.
 * Bodies are assembled from a medically cautious editorial framework plus
 * topic-specific facts. No personal cycle data is read or used here.
 */
(function () {
  'use strict';

  const AR_SAFETY = `## قبل أن تعتمدي على أي معلومة

هذا الدليل للتثقيف الصحي العام، وليس تشخيصًا أو وصفة علاجية. قد تتشابه الأعراض بين حالات كثيرة، وقد يتغير معناها بحسب العمر، واحتمال الحمل، والأدوية، والأمراض المزمنة، والتاريخ العائلي. لا توقفي دواءً موصوفًا، ولا تبدئي هرمونات أو مكملات أو مسكنات بجرعات منتظمة، ولا تؤخري فحصًا طبيًا اعتمادًا على مقال. إذا شعرتِ أن جسمك يرسل إشارة جديدة أو شديدة أو مستمرة، فطلب الرعاية قرار حكيم حتى لو لم تنطبق عليك قائمة جاهزة.

استخدمي التتبّع كوسيلة للملاحظة لا للحكم على نفسك. سجّلي ما حدث بلغة بسيطة، واكتبي أثره في النوم والعمل والدراسة والحركة، واحتفظي بأي نتائج تحاليل أو أسماء أدوية. لا تعني دورة مختلفة واحدة وجود مرض، كما أن انتظام الدورة لا يستبعد كل مشكلة. الهدف هو بناء صورة أوضح تساعدك أنتِ والطبيبة على اتخاذ قرار مناسب، مع احترام خصوصيتك وحدودك وحقك في طرح الأسئلة.`;

  const EN_SAFETY = `## Before relying on any health information

This guide is for general health education, not diagnosis or a personal treatment plan. Similar symptoms can have many causes, and their meaning can change with age, pregnancy possibility, medicines, chronic conditions, and family history. Do not stop prescribed medicine, start hormones or supplements, take pain medicines regularly, or postpone an examination because of an article. If your body is showing a new, severe, persistent, or worrying change, seeking care is reasonable even when you do not match a checklist.

Use tracking as observation, not as a grade for your body. Record what happened in plain language, note how it affected sleep, work, study, movement, or relationships, and keep the names of medicines and test results. One different cycle does not automatically mean disease, and regular cycles do not rule out every condition. The purpose is to create a clearer picture that helps you and a qualified clinician make an informed decision while protecting your privacy and your right to ask questions.`;

  function bullets(items) {
    return items.map((item) => `• ${item}`).join('\n');
  }

  function articleStem(articleId) {
    return String(articleId || 'guide').replace(/-complete-guide$/u, '');
  }

  function figure(articleId, n, caption) {
    const stem = articleStem(articleId);
    const num = String(n).padStart(2, '0');
    // Flat path — nested /inline/{stem}/ folders failed to deploy reliably on Hosting.
    return `\n\n![${caption}](https://lune-7d956.web.app/images/magazine/guides/${stem}-fig-${num}.webp)\n\n`;
  }

  function buildArabic(topic, articleId) {
    return `## لماذا يستحق هذا الموضوع فهمًا هادئًا؟

${topic.lead} لا يوجد جسم يعمل كساعة دقيقة طوال العمر؛ فالدورة تتأثر بمرحلة الحياة والصحة العامة والنوم والضغط النفسي والأدوية وغيرها. الفائدة الحقيقية ليست في مطاردة رقم مثالي، بل في معرفة النمط المعتاد لكِ والانتباه إلى التغيرات التي تؤثر في راحتك أو حياتك اليومية. هذا الدليل يضع المعلومات في سياق عملي حتى تميّزي بين ما يمكن مراقبته، وما يستحق موعدًا عاديًا، وما يحتاج مساعدة عاجلة.

## ما المقصود بالموضوع؟

${topic.meaning} من المفيد التفريق بين وصف العرض وبين معرفة سببه: كلمة مثل «غير منتظمة» أو «مؤلمة» تصف تجربة، لكنها لا تحدد التشخيص وحدها. التشخيص يعتمد على القصة كاملة، والفحص عند الحاجة، وأحيانًا تحاليل أو تصوير. لذلك ستجدين هنا لغة تساعدك على وصف التجربة بدقة من دون تضخيم أو تقليل.
${figure(articleId, 1, 'لحظة هدوء للتأمل في إشارات الجسم دون استعجال الحكم')}
## ماذا قد يحدث داخل الجسم؟

${topic.biology} الهرمونات لا تعمل منفردة؛ فهي تتواصل مع الدماغ والمبيضين والرحم والغدة الدرقية والاستقلاب والنوم. لهذا قد يظهر التغير في أكثر من مكان في الوقت نفسه، مثل النزف والطاقة والمزاج والجلد. وجود ارتباط زمني لا يثبت دائمًا أن الهرمونات هي السبب الوحيد، لكنه يمنح الطبيبة نقطة بداية أفضل عندما يكون التتبع واضحًا.
${figure(articleId, 2, 'صورة معبّرة عن العناية اليومية الهادئة والنوم المنتظم')}
## أنماط وعلامات تستحق الملاحظة

راقبي النمط بدل التركيز على يوم واحد. اسألي: هل يتكرر؟ هل بدأ فجأة؟ هل يزداد؟ وهل يمنعك من نشاط معتاد؟ اكتبي أيضًا ما إذا كان مختلفًا عن المعتاد لكِ، لأن المقارنة الشخصية كثيرًا ما تكون أهم من مقارنة نفسك بالآخرين.

${bullets(topic.patterns)}

ليس مطلوبًا أن تحسبي كل تفصيل أو تقيسي كل شيء. اختاري المعلومات التي تغيّر القرار: بداية العرض ونهايته، شدته، وتكراره، وما الذي يحسّنه أو يزيده. إذا كانت الملاحظة نفسها تسبب قلقًا مستمرًا، خففي التتبع وناقشي هذا القلق مع مختصة.

## أسباب محتملة وكيف نفكر فيها

${topic.causesIntro} الاحتمالات لا تعني أن أحدها موجود لديكِ، ولا يمكن ترتيبها بدقة من دون تاريخ صحي. عادة تبدأ الطبيبة بالأسباب الشائعة والقابلة للفحص، مع مراعاة العمر واحتمال الحمل والأدوية والتغيرات الحديثة.

${bullets(topic.causes)}

قد يجتمع أكثر من عامل، مثل ضغط نفسي مع نقص نوم أو دواء جديد مع حالة سابقة. ولهذا فإن العلاج الجيد لا يركز فقط على إخفاء العرض؛ بل يحاول فهم ما إذا كان هناك سبب يحتاج معالجة، وما إذا كان العرض نفسه يحتاج تخفيفًا لحماية جودة الحياة.
${figure(articleId, 3, 'دفتر يوميات بسيط يساعد على رؤية النمط بدل القلق من يوم واحد')}
## خطة تتبّع عملية لدورتين أو ثلاث

ابدئي بتاريخ أول يوم نزف واضح، وليس مجرد بقعة خفيفة، ثم سجّلي مدة النزف والفاصل حتى الدورة التالية. استخدمي أوصافًا ثابتة تستطيعين تكرارها: خفيف، متوسط، غزير؛ ألم بسيط، متوسط، شديد؛ وتأثير محدود أو واضح أو معطّل. سجّلي الأدوية في وقتها الصحيح، والنوم التقريبي، وأي مرض أو سفر أو ضغط كبير. لا تحتاجين إلى مشاركة يومياتك كاملة؛ يمكنك عرض ملخص تختارينه.

${bullets(topic.track)}

بعد عدة أسابيع، ابحثي عن نمط واحد أو اثنين بدل عشرات الارتباطات. هل يظهر العرض في الأيام نفسها من كل دورة؟ هل يتزامن مع نزف غزير أو تأخر؟ هل تغيّر بعد بدء دواء أو وسيلة منع حمل؟ اكتبي ثلاث جمل تلخص النمط، فهذا غالبًا أكثر فائدة من شاشة مليئة بالأرقام.

## خطوات عناية واقعية وآمنة

العناية الذاتية لا تعني تجاهل المشكلة. معناها دعم الجسم وتقليل العبء أثناء انتظار التحسن أو الموعد الطبي. اختاري خطوة صغيرة قابلة للاستمرار، ثم قيّمي أثرها. تجنبي الوعود التي تدّعي «موازنة الهرمونات» بسرعة أو علاج حالة معقدة بطعام واحد أو مكمل واحد. ما يناسب شخصًا قد لا يناسب آخر، خصوصًا مع الحمل المحتمل أو أمراض المعدة والكلى والكبد أو التداخلات الدوائية.

${bullets(topic.care)}

إذا استخدمتِ مسكنًا أو مكملًا متاحًا دون وصفة، اقرئي النشرة واسألي صيدلانية عن الملاءمة والتداخلات، ولا تتجاوزي الجرعة المكتوبة. الراحة والحرارة والحركة اللطيفة والنوم المنتظم قد تكون أدوات مساعدة لبعض الأعراض، لكنها ليست بديلًا عن تقييم سبب النزف أو الألم أو غياب الدورة.
${figure(articleId, 4, 'خطوات عناية بسيطة: راحة، ترطيب، وحركة لطيفة تناسب يومك')}
## متى أحجز موعدًا غير طارئ؟

احجزي موعدًا عندما يستمر التغير عدة دورات، أو يتكرر، أو يزداد، أو يؤثر في العمل أو الدراسة أو النوم أو العلاقة مع الطعام والجسم. الموعد مناسب أيضًا إذا كنتِ تحاولين الحمل ولديكِ دورات متباعدة أو غائبة، أو إذا ظهر عرض جديد بعد دواء أو وسيلة منع حمل. التفاصيل التالية تجعل الحوار أوضح:

${bullets(topic.visit)}

قد يشمل التقييم أسئلة عن الدورة والحمل المحتمل والأدوية والتاريخ العائلي، ثم فحصًا أو تحليل دم أو اختبار حمل أو فحص للغدة الدرقية أو تصويرًا بحسب الأعراض. ليس كل شخص يحتاج كل الفحوص. اسألي لماذا يُقترح كل فحص، وما الذي ستغيّره النتيجة، وما الخيارات إذا رغبتِ في تأجيل فحص معين.

## علامات لا تنتظر

اطلبي مساعدة عاجلة عند وجود نزف شديد جدًا مع دوخة أو إغماء أو ضيق نفس أو ألم صدر، أو ألم مفاجئ وقوي خصوصًا مع احتمال حمل، أو حمى مع تدهور عام، أو أفكار بإيذاء النفس. لا تقودي السيارة إذا كنتِ على وشك الإغماء، واطلبي من شخص موثوق البقاء معك إن أمكن.

${bullets(topic.urgent)}

القائمة ليست شاملة. ثقي بإحساسك عندما يكون الأمر مختلفًا بوضوح عن المعتاد، واستخدمي خدمات الطوارئ المحلية إذا كان التأخير قد يعرضك للخطر.
${figure(articleId, 5, 'متى تطلبين المساعدة: موعد هادئ أو رعاية عاجلة حسب شدة الإشارة')}
## أفكار شائعة تحتاج تصحيحًا

${bullets(topic.myths)}

المعلومة الصحية الجيدة لا تلومك ولا تعدك بنتيجة مضمونة. ابحثي عن مصدر يذكر حدود المعرفة، ويفرق بين الارتباط والسبب، ويشجع على الرعاية المناسبة. التجارب الشخصية قد تمنح شعورًا بالدعم، لكنها لا تثبت فعالية علاج ولا تحدد ما يناسب تاريخك الصحي.

## أسئلة مفيدة في الزيارة

اكتبي قبل الموعد أهم هدف لكِ: تخفيف الألم، فهم النزف، تنظيم الدورة، حماية الخصوبة، أو الاطمئنان إلى سبب التغير. ثم اسألي: ما الاحتمالات الأكثر منطقية؟ هل أحتاج اختبار حمل أو تعداد دم وحديد أو فحص غدة درقية؟ ما الخيارات غير الدوائية والدوائية؟ متى نتوقع تحسنًا؟ ما الآثار الجانبية؟ ومتى أعود أو أطلب مساعدة عاجلة؟

${topic.takeaway}

${AR_SAFETY}`;
  }

  function buildEnglish(topic, articleId) {
    return `## Why this topic deserves a calm, practical look

${topic.lead} Bodies do not behave like perfect clocks across an entire lifetime. Cycles can respond to life stage, general health, sleep, stress, medicines, and many other influences. The useful goal is not to chase an ideal number. It is to learn your usual pattern and notice changes that affect comfort or daily function. This guide puts information into a practical sequence: what you can observe, what deserves a routine appointment, and what should not wait.

## What does the term actually mean?

${topic.meaning} It helps to separate the description of a symptom from its cause. Words such as “irregular,” “heavy,” or “painful” describe an experience, but they do not establish a diagnosis by themselves. Diagnosis depends on the full history, an examination when appropriate, and sometimes tests or imaging. The aim here is to give you accurate language for describing what is happening without minimizing it or assuming the worst.
${figure(articleId, 1, 'A calm pause to notice body signals without rushing to judgment')}
## What may be happening in the body?

${topic.biology} Hormones do not operate alone. They communicate with the brain, ovaries, uterus, thyroid, metabolism, and sleep systems. A change can therefore appear in several areas at once, such as bleeding, energy, mood, or skin. A timing pattern does not prove that hormones are the only cause, but a clear pattern gives a clinician a better starting point.
${figure(articleId, 2, 'Gentle daily care and steadier sleep support clearer observation')}
## Patterns worth noticing

Look for a pattern rather than judging one day. Ask whether it repeats, began suddenly, is getting stronger, or stops you from doing something you normally do. Note whether it is different from your own baseline; your personal change is often more informative than comparison with someone else.

${bullets(topic.patterns)}

You do not need to measure every detail. Choose information that can change a decision: when the symptom started and ended, how intense it was, how often it happened, and what improved or worsened it. If tracking itself creates constant anxiety, simplify it and discuss that anxiety with a qualified professional.

## Possible reasons and how to think about them

${topic.causesIntro} A list of possibilities does not mean that any one diagnosis is present. Without your history, the causes cannot be ranked accurately. Clinicians usually begin with common and testable explanations while considering age, pregnancy possibility, medicines, and recent changes.

${bullets(topic.causes)}

More than one influence can be present, such as stress plus sleep loss, or a new medicine alongside an existing condition. Good care therefore does more than hide a symptom. It asks whether an underlying cause needs treatment and whether the symptom itself needs relief to protect quality of life.
${figure(articleId, 3, 'A simple diary helps reveal patterns instead of worrying about one day')}
## A useful two- or three-cycle tracking plan

Start with the first day of clear menstrual flow rather than a single faint spot, then record bleeding duration and the interval to the next period. Use repeatable descriptions: light, moderate, or heavy flow; mild, moderate, or severe pain; and limited, noticeable, or disabling impact. Record medicines at the time you take them, approximate sleep, illness, travel, and major stress. You control what you share; a concise summary is usually enough.

${bullets(topic.track)}

After several weeks, look for one or two patterns instead of dozens of correlations. Does the symptom appear at the same point in each cycle? Does it occur with heavier bleeding or a delayed period? Did it change after a medicine or contraceptive method? Write three sentences that summarize the pattern. Those sentences can be more useful than a crowded chart.

## Realistic and safer self-care

Self-care is not the same as ignoring a problem. It means supporting your body and reducing the burden while you monitor improvement or wait for care. Choose one small step you can sustain and then judge its effect. Be cautious with products that promise to “balance hormones” quickly or cure a complex condition with one food or supplement. What is safe for one person may not be safe with pregnancy, stomach, kidney, or liver conditions, or medicine interactions.

${bullets(topic.care)}

If you use an over-the-counter pain medicine or supplement, read the label, ask a pharmacist about safety and interactions, and never exceed the stated dose. Rest, heat, gentle movement, and a consistent sleep routine can support some symptoms, but they are not substitutes for evaluating the cause of significant bleeding, pain, or absent periods.
${figure(articleId, 4, 'Practical comfort: rest, fluids, and gentle movement that fit your day')}
## When to arrange a routine appointment

Book a visit when a change lasts for several cycles, repeats, worsens, or affects work, school, sleep, movement, relationships, or eating. A visit is also appropriate when you are trying to conceive and cycles are widely spaced or absent, or when a new symptom begins after a medicine or contraceptive method. Bring details such as:

${bullets(topic.visit)}

Assessment may include questions about cycles, pregnancy possibility, medicines, and family history, followed by an examination, blood work, pregnancy testing, thyroid testing, or imaging depending on symptoms. Not everyone needs every test. Ask why a test is recommended, what its result would change, and what alternatives exist if you are not comfortable with part of an examination.

## Red flags that should not wait

Seek urgent help for extremely heavy bleeding with dizziness, fainting, shortness of breath, or chest pain; sudden severe pain, especially when pregnancy is possible; fever with a rapidly worsening condition; or thoughts of self-harm. Do not drive if you feel close to fainting. Ask a trusted person to stay with you if possible.

${bullets(topic.urgent)}

No list can cover every emergency. Trust the signal that something is clearly different from your normal, and use local emergency services when delay may place you at risk.
${figure(articleId, 5, 'Knowing when a calm visit is enough and when care should not wait')}
## Common ideas that need correction

${bullets(topic.myths)}

Good health information does not blame you or promise guaranteed results. Prefer sources that explain uncertainty, distinguish association from cause, and encourage appropriate care. Personal experiences can offer emotional support, but they cannot prove that a treatment works or determine what is safe for your medical history.

## Useful questions for a health visit

Before the appointment, write your most important goal: reducing pain, understanding bleeding, making cycles more predictable, protecting fertility, or getting reassurance about a change. Ask which explanations are most likely, whether pregnancy testing, a blood count, iron studies, or thyroid testing make sense, what non-drug and medication options exist, how soon improvement should occur, what side effects matter, and when you should return or seek urgent care.

${topic.takeaway}

${EN_SAFETY}`;
  }

  const AR_DEFAULTS = {
    track: ['سجلي البداية والنهاية والشدة والأثر في النشاط اليومي.', 'اكتبي الأدوية أو الوسائل الهرمونية وأي تغيير حديث.', 'قارني النمط خلال دورتين أو ثلاث بدل الحكم من يوم واحد.', 'احتفظي بملخص قصير يمكنك عرضه في الزيارة.'],
    care: ['حافظي على نوم ووجبات وسوائل منتظمة قدر الإمكان.', 'اختاري حركة لطيفة ووسائل راحة آمنة تناسب جسمك.', 'تجنبي الخلطات أو الهرمونات والمكملات غير الموصوفة.', 'اطلبي مساعدة عملية عندما تؤثر الأعراض في يومك.'],
    visit: ['تاريخ بدء التغير ومدته وتكراره.', 'تأثير الأعراض في النوم والعمل أو الدراسة.', 'الأدوية والمكملات ووسائل منع الحمل.', 'احتمال الحمل والتاريخ الصحي والعائلي المرتبط.'],
    urgent: ['نزف شديد مع دوخة أو إغماء أو ضيق نفس.', 'ألم مفاجئ شديد، خصوصًا مع احتمال حمل.', 'حمى أو تدهور سريع أو عدم القدرة على البقاء بأمان.'],
    myths: ['وجود عرض واحد لا يثبت تشخيصًا محددًا.', 'الانتظام وحده لا يعني أن كل شيء طبيعي دائمًا.', 'الوصفات الشعبية ليست بديلًا عن تقييم سبب مستمر.', 'طلب المساعدة مبكرًا ليس مبالغة أو ضعفًا.'],
    takeaway: 'الخلاصة: راقبي النمط والأثر، واطلبي تقييمًا عندما يستمر التغير أو يعطّل حياتك، واستخدمي المعلومات لطرح أسئلة أوضح لا لتشخيص نفسك.'
  };

  const EN_DEFAULTS = {
    track: ['Record onset, duration, intensity, and effect on daily activities.', 'List medicines, hormonal methods, and any recent change.', 'Compare two or three cycles instead of judging one day.', 'Keep a short summary you can bring to an appointment.'],
    care: ['Support regular sleep, meals, and fluids where possible.', 'Choose gentle movement and comfort measures that are safe for you.', 'Avoid unprescribed hormones, supplements, and unverified mixtures.', 'Ask for practical help when symptoms interfere with your day.'],
    visit: ['When the change began, how long it lasts, and how often it repeats.', 'Its impact on sleep, work, school, movement, or relationships.', 'Medicines, supplements, and contraceptive methods.', 'Pregnancy possibility and relevant personal or family history.'],
    urgent: ['Heavy bleeding with dizziness, fainting, or breathlessness.', 'Sudden severe pain, especially when pregnancy is possible.', 'Fever, rapid deterioration, or inability to remain safe.'],
    myths: ['One symptom alone does not establish a diagnosis.', 'Regular timing does not guarantee that every symptom is harmless.', 'Home remedies do not replace evaluation of a persistent cause.', 'Seeking help early is not weakness or overreaction.'],
    takeaway: 'The practical conclusion is to track pattern and impact, arrange assessment for persistent or disabling change, and use information to ask clearer questions rather than diagnose yourself.'
  };

  function completeTopic(topic, defaults) {
    return Object.assign({}, defaults, topic);
  }

  const rawArticles = [
    {
      id: 'menstrual-cycle-tracking-complete-guide', category: 'basics', iconName: 'calendar_month', cover: 'cycle-tracking.png',
      titleAr: 'الدليل الكامل لفهم الدورة الشهرية وتتبعها بذكاء', titleEn: 'The Complete Guide to Understanding and Tracking Your Menstrual Cycle',
      sourceUrls: ['https://womenshealth.gov/menstrual-cycle/your-menstrual-cycle', 'https://womenshealth.gov/menstrual-cycle/your-menstrual-cycle-and-your-health'],
      ar: {
        lead: 'تتبّع الدورة ليس سباقًا للوصول إلى رقم مثالي، بل طريقة هادئة لفهم توقيت النزف والأعراض وما يتغير مع الوقت.',
        meaning: 'تبدأ الدورة في اليوم الأول من نزف الحيض الواضح وتنتهي قبل بداية الدورة التالية، وتشمل تغيرات في المبيض وبطانة الرحم تقودها إشارات هرمونية متتابعة.',
        biology: 'في النصف الأول تنمو حويصلات المبيض وتتهيأ بطانة الرحم، وقد تحدث الإباضة لاحقًا، ثم تتغير مستويات الهرمونات حتى يبدأ الحيض إذا لم يحدث حمل.',
        patterns: ['تاريخ أول يوم نزف واضح ومدة النزف.', 'الفاصل من بداية دورة إلى بداية التالية ومدى تغيره.', 'الألم والطاقة والمزاج والإفرازات والنوم وأثرها في يومك.', 'نزف بين الدورات أو بعد العلاقة أو تغير جديد مستمر.'],
        causesIntro: 'قد يتغير التوقيت طبيعيًا في بعض المراحل، وقد يعكس أحيانًا عاملًا صحيًا يحتاج فحصًا.',
        causes: ['سنوات البلوغ الأولى أو الاقتراب من سن انقطاع الطمث.', 'الضغط أو المرض أو السفر أو تغير النوم والوزن.', 'الحمل والرضاعة ووسائل منع الحمل وبعض الأدوية.', 'اضطرابات الغدة الدرقية أو تكيس المبايض أو أسباب أخرى.']
      },
      en: {
        lead: 'Cycle tracking is not a contest to reach a perfect number. It is a calm way to understand bleeding, symptoms, timing, and meaningful changes over time.',
        meaning: 'A cycle begins on the first day of clear menstrual bleeding and ends before the next period. It includes coordinated changes in the ovaries and uterine lining.',
        biology: 'Follicles develop and the uterine lining grows earlier in the cycle, ovulation may occur later, and hormone levels then change until menstruation begins if pregnancy has not occurred.',
        patterns: ['The first day of clear flow and number of bleeding days.', 'The interval from one period start to the next and how much it varies.', 'Pain, energy, mood, discharge, sleep, and impact on normal activities.', 'Bleeding between periods, after sex, or any persistent new change.'],
        causesIntro: 'Timing may change normally at some life stages, while a persistent shift can reflect a health factor worth assessing.',
        causes: ['The first years after periods begin or transition toward menopause.', 'Stress, illness, travel, or major changes in sleep or weight.', 'Pregnancy, breastfeeding, contraception, and some medicines.', 'Thyroid conditions, polycystic ovary syndrome, and other causes.']
      }
    },
    {
      id: 'irregular-periods-complete-guide', category: 'health', iconName: 'date_range', cover: 'cycle-tracking.png',
      titleAr: 'الدورة غير المنتظمة: الأسباب والتتبع ومتى تحتاج فحصًا', titleEn: 'Irregular Periods: Causes, Tracking, and When to Seek Care',
      sourceUrls: ['https://womenshealth.gov/menstrual-cycle/your-menstrual-cycle', 'https://www.acog.org/womens-health/faqs/amenorrhea-absence-of-periods'],
      ar: {
        lead: 'عدم الانتظام وصف لنمط متغير، وليس تشخيصًا واحدًا؛ وقد يكون مؤقتًا أو مرتبطًا بمرحلة حياة أو دواء أو حالة تستحق التقييم.',
        meaning: 'قد يعني أن الفواصل تتغير كثيرًا، أو أن الحيض يتباعد أو يغيب، أو أن النزف يأتي في أوقات غير متوقعة مقارنة بنمطك السابق.',
        biology: 'يعتمد التوقيت على تواصل الدماغ والغدة النخامية والمبيضين والرحم، وأي تغير في السلسلة قد يؤثر في الإباضة والنزف.',
        patterns: ['دورات متقاربة جدًا أو متباعدة عن نمطك.', 'غياب الحيض ثلاثة أشهر أو أكثر بعد أن كان موجودًا.', 'نزف بين الدورات أو تغير واضح بعد دواء جديد.', 'تغير الوزن أو نمو شعر جديد أو إفراز الحليب أو صداع غير معتاد.'],
        causesIntro: 'التاريخ الزمني يساعد على التفريق بين اختلاف عابر ونمط يحتاج فحصًا.',
        causes: ['الحمل والرضاعة والبلوغ والمرحلة السابقة لانقطاع الطمث.', 'الضغط الشديد أو تغذية غير كافية أو تدريب مكثف.', 'تكيس المبايض أو اضطرابات الغدة الدرقية وهرمونات أخرى.', 'وسائل منع الحمل وبعض الأدوية وحالات صحية مزمنة.']
      },
      en: {
        lead: 'Irregularity describes a changing pattern rather than one diagnosis. It may be temporary, linked to a life stage or medicine, or connected to a condition worth assessing.',
        meaning: 'It can mean widely changing cycle intervals, periods that become far apart or absent, or bleeding that arrives at unexpected times compared with your baseline.',
        biology: 'Timing depends on communication among the brain, pituitary gland, ovaries, and uterus. Changes anywhere in that chain can influence ovulation and bleeding.',
        patterns: ['Cycles much closer together or farther apart than your baseline.', 'No period for three months or longer after periods had been present.', 'Bleeding between cycles or a clear change after a new medicine.', 'Weight change, new hair growth, milk discharge, or unusual headaches.'],
        causesIntro: 'The timeline helps separate short-lived variation from a pattern that needs investigation.',
        causes: ['Pregnancy, breastfeeding, puberty, and transition toward menopause.', 'Severe stress, low energy intake, or intense training.', 'Polycystic ovary syndrome, thyroid conditions, and other hormone changes.', 'Contraception, some medicines, and chronic conditions.']
      }
    },
    {
      id: 'painful-periods-complete-guide', category: 'health', iconName: 'healing', cover: 'period-pain.png',
      titleAr: 'ألم الدورة: ما الشائع وما الذي لا ينبغي تحمله بصمت؟', titleEn: 'Period Pain: What Is Common and What Should Not Be Endured Silently?',
      sourceUrls: ['https://www.acog.org/womens-health/faqs/dysmenorrhea-painful-periods', 'https://www.acog.org/womens-health/faqs/painful-periods'],
      ar: {
        lead: 'التقلصات شائعة، لكن الألم الذي يعطل الدراسة أو العمل أو يزداد مع الوقت ليس شيئًا يجب تطبيعه أو تحمله بلا تقييم.',
        meaning: 'عسر الطمث ألم مرتبط بالحيض، وقد يكون أوليًا من تقلصات الرحم أو ثانويًا لحالة مثل بطانة الرحم المهاجرة أو سبب حوضي آخر.',
        biology: 'تساعد البروستاغلاندينات الرحم على الانقباض لطرد البطانة، وقد ترتبط زيادتها بتقلصات وغثيان أو إسهال أو صداع.',
        patterns: ['وقت بدء الألم بالنسبة للنزف ومدة استمراره.', 'تعطيله للنوم أو الحركة أو الحضور اليومي.', 'ألم بين الدورات أو أثناء العلاقة أو التبول أو التبرز.', 'زيادة الشدة أو فقدان استجابة ما كان يساعد.'],
        causesIntro: 'نوع الألم وتوقيته وتطوره يساعد في تمييز النمط الأولي من سبب آخر.',
        causes: ['تقلصات الحيض الأولية.', 'بطانة الرحم المهاجرة أو العضال الغدي أو الأورام الليفية.', 'التهاب الحوض أو كيس مبيضي أو أسباب بولية وهضمية وعضلية.', 'وسيلة داخل الرحم أو إجراء حديث في بعض الحالات.']
      },
      en: {
        lead: 'Cramps are common, but pain that disrupts school, work, sleep, or movement, or worsens over time, should not be normalized or endured without assessment.',
        meaning: 'Dysmenorrhea is pain linked with menstruation. It may be primary uterine cramping or secondary to endometriosis or another pelvic condition.',
        biology: 'Prostaglandins help the uterus contract and shed its lining. Higher activity may accompany stronger cramps, nausea, diarrhea, or headache.',
        patterns: ['When pain starts in relation to bleeding and how long it lasts.', 'Whether it limits sleep, movement, attendance, or responsibilities.', 'Pain between periods, during sex, urination, or bowel movements.', 'Increasing severity or loss of response to measures that once helped.'],
        causesIntro: 'The type, timing, and progression help distinguish a primary pattern from pain requiring investigation.',
        causes: ['Primary menstrual cramping.', 'Endometriosis, adenomyosis, or fibroids.', 'Pelvic infection, an ovarian cyst, or urinary, bowel, and muscular causes.', 'An intrauterine device or recent procedure in some cases.']
      }
    },
    {
      id: 'heavy-periods-and-iron-complete-guide', category: 'health', iconName: 'water_drop', cover: 'nutrition.png',
      titleAr: 'غزارة الدورة ونقص الحديد: كيف تلاحظينهما وتحمي طاقتك؟', titleEn: 'Heavy Periods and Iron Deficiency: Recognizing Both and Protecting Your Energy',
      sourceUrls: ['https://www.cdc.gov/female-blood-disorders/about/heavy-menstrual-bleeding.html', 'https://womenshealth.gov/healthy-eating/how-eat-health/vitamins-and-minerals-women'],
      ar: { lead: 'غزارة الحيض لا تقاس بالانطباع وحده؛ أثرها في المنتجات والنوم والنشاط والطاقة مهم، وقد تقود بمرور الوقت إلى نقص الحديد.', meaning: 'هو نزف أكثر أو أطول من المعتاد يؤثر في الحياة أو يرفع احتمال فقر الدم، وقد يظهر كتغيير متكرر أو تسرب أو كتل كبيرة.', biology: 'يفقد الجسم الحديد مع الدم، وهو ضروري لصنع الهيموغلوبين الذي ينقل الأكسجين. قد تنخفض مخازنه قبل ظهور فقر دم واضح.', patterns: ['تغيير المنتج كل ساعة أو حماية مزدوجة باستمرار.', 'نزف يوقظك أو يستمر أطول كثيرًا من المعتاد.', 'تعب أو دوخة أو خفقان أو ضيق نفس أو شحوب.', 'كدمات سهلة أو نزف لثة وأنف أو تاريخ عائلي.'], causesIntro: 'الغزارة عرض قد يرتبط بالرحم أو الإباضة أو الأدوية أو التخثر، فلا يكفي تعويض الحديد إذا استمر السبب.', causes: ['اختلال الإباضة أو المرحلة قبل انقطاع الطمث.', 'أورام ليفية أو سلائل أو عضال غدي.', 'اضطراب نزف وراثي أو أدوية تؤثر في التخثر.', 'الحمل ومضاعفاته أو الغدة الدرقية وأسباب أخرى.'] },
      en: { lead: 'Heavy menstrual bleeding is not measured by impression alone. Product changes, leakage, lost sleep, activity limits, and energy provide useful clues, and ongoing loss can deplete iron.', meaning: 'It is flow greater or longer than usual that interferes with life or raises anemia risk, sometimes involving frequent changes, leakage, or large clots.', biology: 'Iron is lost with blood and is needed to make oxygen-carrying hemoglobin. Stores may fall before a blood count shows clear anemia.', patterns: ['Changing protection hourly or repeatedly using double protection.', 'Bleeding that wakes you or lasts much longer than usual.', 'Fatigue, dizziness, palpitations, breathlessness, or pallor.', 'Easy bruising, nose or gum bleeding, or a family history.'], causesIntro: 'Heavy flow may relate to the uterus, ovulation, medicines, or clotting, so replacing iron alone is not enough if loss continues.', causes: ['Ovulation changes or transition toward menopause.', 'Fibroids, polyps, or adenomyosis.', 'Inherited bleeding disorders or medicines affecting clotting.', 'Pregnancy-related problems, thyroid conditions, and other causes.'] }
    },
    {
      id: 'pms-and-pmdd-complete-guide', category: 'mind', iconName: 'psychology_alt', cover: 'sleep.png',
      titleAr: 'متلازمة ما قبل الحيض وPMDD: فهم النمط ودعم الصحة النفسية', titleEn: 'PMS and PMDD: Understanding the Pattern and Supporting Mental Health',
      sourceUrls: ['https://www.acog.org/womens-health/faqs/Premenstrual-Syndrome', 'https://womenshealth.gov/menstrual-cycle/premenstrual-syndrome'],
      ar: {
        lead: 'الأعراض السابقة للحيض حقيقية وقد تكون جسدية أو نفسية، لكن توقيتها المتكرر وتحسنها بعد بدء الدورة مفتاح لفهم النمط.',
        meaning: 'تشير PMS إلى أعراض دورية قبل الحيض، بينما PMDD نمط أشد يرتبط بضيق أو تعطيل واضح ويحتاج تقييمًا مهنيًا.',
        biology: 'قد لا تكون الهرمونات غير طبيعية؛ بعض الأجسام والدماغ تكون أكثر حساسية للتغير الطبيعي فيها وتأثيره في النواقل العصبية.',
        patterns: ['أعراض تظهر قبل الحيض وتخف خلال أيام من بدايته.', 'تهيج أو حزن أو قلق أو حساسية للرفض أو صعوبة تركيز.', 'انتفاخ وألم ثدي وصداع وتغير الشهية أو النوم والطاقة.', 'تعطيل العمل أو الدراسة أو العلاقات أو شعور بفقد السيطرة.'],
        causesIntro: 'التوثيق اليومي مهم لأن الاكتئاب والقلق واضطراب النوم أو الغدة الدرقية قد تتفاقم قبل الحيض أيضًا.',
        causes: ['حساسية فردية للتغير الهرموني الدوري.', 'حالة نفسية موجودة تتفاقم قبل الحيض.', 'نقص النوم أو الضغط المزمن.', 'حالة جسدية أو دواء يحاكي جزءًا من الأعراض.'],
        urgent: ['أفكار بإيذاء النفس أو عدم القدرة على ضمان سلامتك.', 'هياج شديد أو فقد اتصال بالواقع أو سلوك خطر.', 'تدهور نفسي سريع بعد بدء دواء أو تغييره.']
      },
      en: {
        lead: 'Premenstrual symptoms are real and can be physical or emotional. Repeated timing and improvement after menstruation begins are central to understanding the pattern.',
        meaning: 'PMS describes cyclical premenstrual symptoms. PMDD is a more severe pattern with marked distress or functional impairment that needs professional assessment.',
        biology: 'Hormone levels may not be abnormal. Some brains and bodies appear more sensitive to normal cyclical changes and their interaction with neurotransmitters.',
        patterns: ['Symptoms that arise before menstruation and ease after it begins.', 'Irritability, sadness, anxiety, rejection sensitivity, or poor concentration.', 'Bloating, breast tenderness, headache, appetite, sleep, or energy changes.', 'Disruption of work, school, relationships, or a sense of losing control.'],
        causesIntro: 'Daily records matter because depression, anxiety, sleep disorders, or thyroid conditions may also worsen before a period.',
        causes: ['Individual sensitivity to cyclical hormone change.', 'An existing mental health condition with premenstrual worsening.', 'Sleep loss or chronic overload.', 'A physical condition or medicine that mimics part of the picture.'],
        urgent: ['Thoughts of self-harm or inability to remain safe.', 'Severe agitation, loss of contact with reality, or dangerous behavior.', 'Rapid deterioration after starting or changing a medicine.']
      }
    },
    {
      id: 'pcos-complete-guide', category: 'health', iconName: 'hub', cover: 'doctor-visit.png',
      titleAr: 'تكيس المبايض: دليل متوازن للأعراض والتشخيص والرعاية طويلة المدى', titleEn: 'PCOS: A Balanced Guide to Symptoms, Diagnosis, and Long-Term Care',
      sourceUrls: ['https://www.cdc.gov/diabetes/risk-factors/pcos-polycystic-ovary-syndrome.html', 'https://www.nichd.nih.gov/sites/default/files/2024-04/NICHDWHPCOSweb.pdf'],
      ar: { lead: 'تكيس المبايض حالة هرمونية واستقلابية متنوعة، ولا يثبتها شكل المبيض وحده ولا عرض واحد مثل الحبوب أو عدم انتظام الدورة.', meaning: 'قد يجمع التشخيص بين اضطراب الإباضة وعلامات زيادة الأندروجين ومظهر مبيضي معين بعد استبعاد أسباب أخرى تشبهه.', biology: 'قد تتداخل إشارات الأنسولين والأندروجينات مع نمو الحويصلات والإباضة، لكن التجربة تختلف ولا ترتبط بقيمة الشخص أو إرادته.', patterns: ['دورات متباعدة أو غائبة أو نزف غير متوقع.', 'شعر زائد أو حب شباب أو تساقط شعر بنمط معين.', 'صعوبة حمل بسبب إباضة غير منتظمة.', 'تغير السكر أو الدهون عند بعض الأشخاص.'], causesIntro: 'لا يوجد اختبار منفرد يحسم الحالة، ويجب النظر إلى التاريخ والفحص والتحاليل واستبعاد البدائل.', causes: ['تفاعل عوامل وراثية وهرمونية واستقلابية.', 'مقاومة الأنسولين عند بعض المصابات لا الجميع.', 'اضطراب الغدة الدرقية أو البرولاكتين أو حالات كظرية.', 'أدوية أو مراحل حياة تغير الدورة أو الشعر والجلد.'] },
      en: { lead: 'Polycystic ovary syndrome is a varied hormonal and metabolic condition. Ovarian appearance alone, or one symptom such as acne or irregular periods, does not establish it.', meaning: 'Diagnosis may combine ovulation disturbance, signs of higher androgen activity, and a particular ovarian pattern after look-alike causes are excluded.', biology: 'Insulin and androgen signaling may affect follicle development and ovulation, but experiences vary and are never a measure of character or willpower.', patterns: ['Widely spaced, absent, or unexpected periods.', 'Excess hair growth, acne, or a particular pattern of scalp hair loss.', 'Difficulty conceiving because ovulation is unpredictable.', 'Glucose or lipid changes in some people.'], causesIntro: 'No single test proves PCOS; history, examination, selected tests, and exclusion of alternatives matter.', causes: ['Genetic, hormonal, and metabolic factors.', 'Insulin resistance in some but not all people.', 'Thyroid, prolactin, or adrenal conditions that can mimic symptoms.', 'Medicines and life stages that change cycles, hair, or skin.'] }
    },
    {
      id: 'endometriosis-complete-guide', category: 'health', iconName: 'flare', cover: 'period-pain.png',
      titleAr: 'بطانة الرحم المهاجرة: الأعراض والتشخيص وخيارات الرعاية', titleEn: 'Endometriosis: Symptoms, Diagnosis, and Care Options',
      sourceUrls: ['https://www.nichd.nih.gov/health/topics/endometri/conditioninfo/treatment', 'https://www.acog.org/womens-health/faqs/endometriosis'],
      ar: {
        lead: 'بطانة الرحم المهاجرة حالة التهابية مزمنة قد تسبب ألمًا أو صعوبة حمل، وشدة الأعراض لا تعكس دائمًا مقدار المرض الظاهر.',
        meaning: 'في هذه الحالة يوجد نسيج شبيه ببطانة الرحم خارج الرحم، ويمكن أن يرتبط بالتهاب وندبات والتصاقات وألم يتغير عبر الدورة أو يستمر خارجها.',
        biology: 'يتفاعل النسيج مع البيئة الهرمونية والمناعية، لكن الآلية ليست مجرد دم محبوس، كما أن سبب ظهور الحالة يظل متعدد العوامل.',
        patterns: ['ألم دورة يعطل الحياة أو يزداد بمرور السنوات.', 'ألم أثناء العلاقة أو التبرز أو التبول خاصة حول الحيض.', 'ألم حوض مزمن أو تعب أو انتفاخ متكرر.', 'صعوبة حمل أو تاريخ عائلي للحالة.'],
        causesIntro: 'لا يثبت العرض وحده الحالة، وقد تتداخل معها أسباب عضلية وهضمية وبولية أخرى.',
        causes: ['عوامل وراثية ومناعية وهرمونية قيد الدراسة.', 'التصاقات أو عضال غدي أو أكياس مرتبطة بالحالة.', 'حالات قاع الحوض أو الأمعاء أو المثانة المتزامنة.', 'أسباب ألم أخرى يجب تقييمها بدل افتراض تشخيص واحد.']
      },
      en: {
        lead: 'Endometriosis is a chronic inflammatory condition that may cause pain or difficulty conceiving, and symptom severity does not always match the amount of visible disease.',
        meaning: 'Tissue similar to the uterine lining exists outside the uterus and may be associated with inflammation, scarring, adhesions, and pain that cycles or persists.',
        biology: 'The tissue interacts with hormonal and immune environments. The mechanism is not simply trapped menstrual blood, and the cause is considered multifactorial.',
        patterns: ['Period pain that disables daily life or worsens over years.', 'Pain with sex, bowel movements, or urination, especially near menstruation.', 'Chronic pelvic pain, fatigue, or recurring bloating.', 'Difficulty conceiving or a family history of endometriosis.'],
        causesIntro: 'Symptoms alone cannot prove endometriosis, and muscular, bowel, and urinary causes can overlap.',
        causes: ['Genetic, immune, and hormonal factors under study.', 'Adhesions, adenomyosis, or endometriosis-related cysts.', 'Coexisting pelvic floor, bowel, or bladder conditions.', 'Other pain causes that deserve assessment rather than one assumed diagnosis.']
      }
    },
    {
      id: 'ovulation-and-fertile-window-complete-guide', category: 'fertility', iconName: 'egg_alt', cover: 'fertility-awareness.png',
      titleAr: 'الإباضة والنافذة الخصبة: ما الذي نعرفه وما الذي يبقى تقديرًا؟', titleEn: 'Ovulation and the Fertile Window: What We Know and What Remains an Estimate',
      sourceUrls: ['https://www.cdc.gov/reproductive-health/infertility-faq/index.html', 'https://womenshealth.gov/menstrual-cycle/your-menstrual-cycle'],
      ar: {
        lead: 'الإباضة حدث بيولوجي لا يمكن لتطبيق تقويمي إثباته وحده، والنافذة الخصبة تقدير احتمالي يتغير حتى عند صاحبة الدورة المنتظمة.',
        meaning: 'النافذة الخصبة هي الأيام التي يمكن أن يحدث فيها حمل بسبب بقاء الحيوانات المنوية عدة أيام وبقاء البويضة وقتًا أقصر بعد الإباضة.',
        biology: 'تسبق الإباضة إشارة هرمونية وتغيرات في الحويصلة ومخاط عنق الرحم، ثم يرتفع البروجسترون بعد خروج البويضة عادة.',
        patterns: ['تغير الإفرازات إلى نمط أكثر شفافية وانزلاقًا عند بعض الأشخاص.', 'ارتفاع طفيف مستمر في الحرارة الأساسية بعد الإباضة لا قبلها.', 'اختبار بول لهرمون LH يشير إلى اقتراب الإباضة ولا يضمنها.', 'اختلاف موعد الإباضة بين دورة وأخرى.'],
        causesIntro: 'يمكن للمرض والضغط وتغير النوم وبعض الحالات الهرمونية أن يغير توقيت الإباضة.',
        causes: ['اختلاف طبيعي بين الدورات.', 'تكيس المبايض أو تغيرات الغدة الدرقية والبرولاكتين.', 'مرحلة ما بعد الولادة والرضاعة أو ما قبل انقطاع الطمث.', 'نقص الطاقة أو مرض حاد أو أدوية معينة.']
      },
      en: {
        lead: 'Ovulation is a biological event that a calendar app cannot prove by itself. The fertile window is a probability estimate that can shift even with regular cycles.',
        meaning: 'The fertile window includes days when pregnancy can occur because sperm may survive for several days while the egg remains available for a shorter time after ovulation.',
        biology: 'A hormonal signal and changes in the follicle and cervical mucus precede ovulation, while progesterone usually rises after the egg is released.',
        patterns: ['More clear and slippery cervical mucus for some people.', 'A small sustained basal temperature rise after, not before, ovulation.', 'A urine LH test suggesting an approaching surge without guaranteeing ovulation.', 'Ovulation timing that varies from one cycle to another.'],
        causesIntro: 'Illness, stress, sleep changes, and hormonal conditions can shift ovulation timing.',
        causes: ['Normal cycle-to-cycle variation.', 'PCOS or thyroid and prolactin changes.', 'Postpartum, breastfeeding, or perimenopausal stages.', 'Low energy availability, acute illness, and selected medicines.']
      }
    },
    {
      id: 'fertility-signs-bbt-mucus-complete-guide', category: 'fertility', iconName: 'thermostat', cover: 'fertility-awareness.png',
      titleAr: 'علامات الخصوبة والحرارة والإفرازات: دليل الاستخدام الواقعي', titleEn: 'Fertility Signs, Basal Temperature, and Cervical Mucus: A Practical Guide',
      sourceUrls: ['https://www.cdc.gov/contraception/about/index.html', 'https://www.acog.org/womens-health/infographics/fertility-awareness-based-methods-of-family-planning'],
      ar: {
        lead: 'مراقبة الحرارة الأساسية والإفرازات قد تساعد على فهم النمط، لكنها تحتاج تعليمًا جيدًا ولا ينبغي اختزالها في لون أو قراءة واحدة.',
        meaning: 'الوعي بالخصوبة يجمع ملاحظات يومية لتقدير أيام احتمال الحمل، وقد يستخدم للتخطيط للحمل أو تجنبه ضمن طريقة واضحة القواعد.',
        biology: 'يؤثر الإستروجين في مخاط عنق الرحم قبل الإباضة، ويرفع البروجسترون الحرارة الأساسية قليلًا بعدها؛ لذا تختلف وظيفة كل علامة.',
        patterns: ['قياس الحرارة فور الاستيقاظ قبل الحركة وفي وقت متقارب.', 'وصف الإحساس والإفرازات بدل الاعتماد على صورة فقط.', 'تأثير الحمى وقلة النوم والكحول والعمل الليلي في الحرارة.', 'تأثير العدوى والأدوية والسائل المنوي في تفسير الإفرازات.'],
        causesIntro: 'البيانات المشوشة لا تعني وجود مشكلة؛ قد تكون ببساطة غير قابلة للتفسير في تلك الدورة.',
        causes: ['توقيت قياس غير ثابت أو جهاز مختلف.', 'مرض أو سفر أو نوم متقطع.', 'رضاعة أو مرحلة ما قبل انقطاع الطمث أو دورة بلا إباضة.', 'التهاب مهبلي أو دواء يغير الإفرازات.']
      },
      en: {
        lead: 'Basal temperature and cervical mucus observations can improve pattern awareness, but they require sound instruction and cannot be reduced to one color or one reading.',
        meaning: 'Fertility awareness combines daily observations to estimate days when pregnancy is possible and may be used to pursue or avoid pregnancy under a defined method.',
        biology: 'Estrogen affects cervical mucus before ovulation, while progesterone raises basal temperature slightly afterward, so the two signs answer different questions.',
        patterns: ['Taking temperature immediately after waking and before activity.', 'Describing sensation and mucus instead of relying on one image.', 'Fever, poor sleep, alcohol, and shift work altering temperature.', 'Infection, medicines, and semen complicating mucus interpretation.'],
        causesIntro: 'Confusing data does not automatically indicate disease; a cycle may simply be uninterpretable.',
        causes: ['Inconsistent timing or a different thermometer.', 'Illness, travel, or interrupted sleep.', 'Breastfeeding, perimenopause, or a cycle without ovulation.', 'Vaginal infection or medicine that changes secretions.']
      }
    },
    {
      id: 'sleep-and-menstrual-cycle-complete-guide', category: 'mind', iconName: 'bedtime', cover: 'sleep.png',
      titleAr: 'النوم والدورة الشهرية: علاقة ثنائية وخطة عملية ليالٍ أهدأ', titleEn: 'Sleep and the Menstrual Cycle: A Two-Way Relationship and a Practical Plan',
      sourceUrls: ['https://www.nhlbi.nih.gov/health/sleep', 'https://www.acog.org/womens-health/faqs/sleep-health-and-disorders'],
      ar: { lead: 'قد تؤثر أعراض الدورة في النوم، وقد يجعل نقص النوم الألم والمزاج والطاقة أصعب؛ لذلك من المفيد معالجة الاتجاهين بدل لوم الهرمونات وحدها.', meaning: 'النوم عملية بيولوجية تنظّم الانتباه والمناعة والاستقلاب والمزاج، ويحتاج تقييمه إلى النظر في المدة والجودة والتوقيت والانتظام.', biology: 'تتفاعل الساعة البيولوجية مع الضوء والحرارة والهرمونات، وقد يرفع الألم أو النزف أو القلق عدد مرات الاستيقاظ حتى لو كانت مدة السرير طويلة.', patterns: ['صعوبة النوم أو الاستيقاظ المتكرر في مرحلة محددة من الدورة.', 'شخير مرتفع أو توقف تنفس ملحوظ أو صداع صباحي.', 'نعاس نهاري يهدد القيادة أو الدراسة والعمل.', 'اعتماد متزايد على الكافيين أو المهدئات.'], causesIntro: 'قد تكون الدورة جزءًا من الصورة، لكن اضطراب النوم قد يكون مستقلًا ويحتاج تقييمًا.', causes: ['الألم أو الغزارة أو التعرق وتغير الحرارة.', 'قلق أو اكتئاب أو PMS وPMDD.', 'انقطاع النفس أثناء النوم أو تململ الساقين.', 'مناوبات العمل والكافيين والضوء والشاشات وبعض الأدوية.'] },
      en: { lead: 'Cycle symptoms may disturb sleep, while sleep loss can make pain, mood, and energy harder. Addressing both directions is more useful than blaming hormones alone.', meaning: 'Sleep is a biological process supporting attention, immunity, metabolism, and mood. Assessment considers duration, quality, timing, and consistency.', biology: 'The body clock interacts with light, temperature, and hormones, while pain, bleeding, or anxiety may increase awakenings even when time in bed is long.', patterns: ['Difficulty falling asleep or repeated waking at a specific cycle phase.', 'Loud snoring, witnessed breathing pauses, or morning headache.', 'Daytime sleepiness that threatens driving, school, or work.', 'Increasing reliance on caffeine or sedating products.'], causesIntro: 'The cycle may be part of the picture, but a sleep disorder can also exist independently and deserves assessment.', causes: ['Pain, heavy flow, sweating, or temperature change.', 'Anxiety, depression, PMS, or PMDD.', 'Sleep apnea or restless legs.', 'Shift work, caffeine, light exposure, screens, and some medicines.'] }
    },
    {
      id: 'movement-and-menstrual-cycle-complete-guide', category: 'fitness', iconName: 'directions_walk', cover: 'movement.png',
      titleAr: 'الحركة والرياضة عبر الدورة: المرونة أهم من القواعد الصارمة', titleEn: 'Movement and Exercise Across the Cycle: Flexibility Over Rigid Rules',
      sourceUrls: ['https://womenshealth.gov/getting-active/physical-activity-menstrual-cycle', 'https://www.acog.org/womens-health/infographics/stay-active'],
      ar: { lead: 'لا توجد خطة تمرين واحدة يجب أن تتبعها كل النساء حسب أيام الدورة؛ الأفضل تعديل الجهد وفق الأعراض والهدف والصحة العامة.', meaning: 'الحركة تشمل المشي والقوة والمرونة والأنشطة اليومية، وتبقى فائدتها مرتبطة بالاستمرار والتدرج والتعافي لا بمطابقة جدول هرموني جامد.', biology: 'قد تتغير الطاقة أو الحرارة أو الألم أو الدافع عند بعض الأشخاص، لكن الفروق الفردية أكبر من قاعدة عامة ويمكن للأداء أن يبقى ثابتًا.', patterns: ['التمرين الذي يحسن التقلصات أو المزاج بدل زيادتهما.', 'دوخة أو ضيق نفس أو ضعف قد يشير إلى نقص حديد أو مشكلة أخرى.', 'ألم حاد أو تورم أو نزف يزداد مع الجهد.', 'غياب الدورة مع تدريب مكثف أو تغذية غير كافية.'], causesIntro: 'انخفاض الأداء ليس دائمًا بسبب الدورة، وقد يرتبط بالنوم أو الحديد أو المرض أو حجم التدريب.', causes: ['ألم الحيض أو PMS وتأثيرهما المؤقت.', 'نقص الحديد بسبب نزف غزير.', 'نقص الطاقة المتاحة أو الإفراط في التدريب.', 'إصابة أو مرض أو دواء أو ضغط وقلة نوم.'] },
      en: { lead: 'There is no single cycle-day training plan every woman must follow. Adjusting effort to symptoms, goals, recovery, and overall health is more useful.', meaning: 'Movement includes walking, strength, mobility, sport, and daily activity. Benefits depend on consistency, progression, and recovery rather than a rigid hormonal timetable.', biology: 'Energy, temperature, pain, or motivation may shift for some people, but individual variation is larger than a universal rule and performance can remain stable.', patterns: ['Movement that improves cramps or mood instead of worsening them.', 'Dizziness, breathlessness, or weakness suggesting iron loss or another issue.', 'Sharp pain, swelling, or bleeding that increases with exertion.', 'Missing periods with intense training or inadequate energy intake.'], causesIntro: 'Reduced performance is not always caused by the cycle and may relate to sleep, iron, illness, or training load.', causes: ['Menstrual pain or PMS with temporary impact.', 'Iron deficiency from heavy bleeding.', 'Low energy availability or overtraining.', 'Injury, illness, medicines, stress, or sleep loss.'] }
    },
    {
      id: 'nutrition-iron-and-cycle-complete-guide', category: 'nutrition', iconName: 'restaurant', cover: 'nutrition.png',
      titleAr: 'التغذية والحديد والدورة: بناء وجبات مفيدة بلا حميات هرمونية', titleEn: 'Nutrition, Iron, and the Cycle: Useful Meals Without Hormone Diets',
      sourceUrls: ['https://www.acog.org/womens-health/faqs/healthy-eating', 'https://womenshealth.gov/healthy-eating/how-eat-health/vitamins-and-minerals-women'],
      ar: { lead: 'التغذية الداعمة للدورة ليست قائمة سحرية لكل مرحلة، بل نمط كافٍ ومتوازن يحمي الطاقة والحديد والعظام والعلاقة الصحية مع الطعام.', meaning: 'الوجبة المتوازنة تجمع مصادر البروتين والكربوهيدرات والدهون والألياف والمغذيات الدقيقة، مع مرونة تحترم الثقافة والميزانية والشهية.', biology: 'يسهم الحديد في نقل الأكسجين، والكالسيوم وفيتامين د في العظام، وتحتاج الإشارات الهرمونية إلى طاقة كافية؛ الحرمان الشديد قد يربك الإباضة.', patterns: ['تعب أو دوخة مع غزارة قد يستدعي فحص الحديد.', 'تخطي وجبات متكرر أو خوف شديد من الطعام أو فقد وزن سريع.', 'أعراض هضمية مستمرة تمنع تناول مجموعات واسعة.', 'استخدام مكملات كثيرة من دون تحاليل أو مراجعة التداخلات.'], causesIntro: 'لا يفسر طعام واحد عرضًا معقدًا، لكن النقص أو الحرمان قد يزيدان العبء.', causes: ['فقد الحديد مع النزف أو انخفاض تناوله أو امتصاصه.', 'نقص الطاقة المتاحة بسبب حمية صارمة أو نشاط مرتفع.', 'قيود غذائية أو مرض هضمي أو دواء يؤثر في الامتصاص.', 'معلومات مضللة تعد بموازنة الهرمونات بسرعة.'] },
      en: { lead: 'Cycle-supportive nutrition is not a magical menu for each phase. It is an adequate, balanced pattern that protects energy, iron, bones, and a healthy relationship with food.', meaning: 'A balanced meal combines protein, carbohydrate, fats, fiber, and micronutrients with flexibility for culture, budget, appetite, and access.', biology: 'Iron helps carry oxygen, calcium and vitamin D support bone, and reproductive signaling needs enough energy. Severe restriction can disrupt ovulation.', patterns: ['Fatigue or dizziness with heavy bleeding that may justify iron testing.', 'Repeated skipped meals, intense food fear, or rapid weight loss.', 'Persistent digestive symptoms that exclude broad food groups.', 'Multiple supplements used without testing or interaction review.'], causesIntro: 'One food does not explain a complex symptom, but deficiency and restriction can add to the burden.', causes: ['Iron loss from bleeding or low intake or absorption.', 'Low energy availability from strict dieting or high activity.', 'Dietary restrictions, digestive disease, or medicines affecting absorption.', 'Misinformation promising instant hormone balance.'] }
    },
    {
      id: 'stress-and-late-periods-complete-guide', category: 'mind', iconName: 'self_improvement', cover: 'cycle-tracking.png',
      titleAr: 'الضغط النفسي وتأخر الدورة: كيف يرتبطان من دون إلقاء اللوم عليك؟', titleEn: 'Stress and Late Periods: Understanding the Link Without Blame',
      sourceUrls: ['https://womenshealth.gov/mental-health/good-mental-health/stress-and-your-health', 'https://www.acog.org/womens-health/faqs/amenorrhea-absence-of-periods'],
      ar: { lead: 'يمكن للضغط الشديد أو المستمر أن يؤثر في توقيت الإباضة، لكن عبارة «إنه مجرد توتر» لا تكفي لاستبعاد الحمل أو سبب صحي آخر.', meaning: 'الضغط استجابة جسدية ونفسية للمطالب أو الخطر، وقد يكون قصيرًا أو مزمنًا؛ تأثيره في الدورة يختلف ولا يعني أنك فشلت في الاسترخاء.', biology: 'تتواصل أنظمة الضغط في الدماغ مع الإشارات المنظمة للإباضة والنوم والشهية، وقد يتأخر التبويض أو يغيب عندما تتغير البيئة الجسدية بشدة.', patterns: ['تأخر بعد حدث كبير أو مرض أو سفر مع عودة النمط لاحقًا.', 'ضغط يرافقه أرق أو تغير شهية أو نوبات هلع.', 'غياب متكرر أو مطول بدل تأخر واحد.', 'احتمال حمل أو أعراض هرمونية أخرى لا يفسرها الضغط وحده.'], causesIntro: 'يجب التعامل مع الضغط كعامل محتمل ضمن صورة كاملة لا كتفسير تلقائي.', causes: ['عبء نفسي مزمن أو صدمة أو تغير كبير في الحياة.', 'نقص النوم أو الطعام أو مرض متزامن.', 'حمل أو رضاعة أو وسيلة منع حمل.', 'تكيس المبايض أو الغدة الدرقية أو أسباب غياب أخرى.'] },
      en: { lead: 'Severe or sustained stress can influence ovulation timing, but saying “it is only stress” is not enough to rule out pregnancy or another health cause.', meaning: 'Stress is a physical and emotional response to demands or threat. It may be brief or chronic, and cycle effects vary; a late period is not a failure to relax correctly.', biology: 'Brain stress systems communicate with signals governing ovulation, sleep, and appetite. Ovulation may shift or pause when the physical environment changes substantially.', patterns: ['A delay after a major event, illness, or travel followed by return to baseline.', 'Stress with insomnia, appetite change, or panic episodes.', 'Repeated or prolonged absence rather than one late period.', 'Pregnancy possibility or other hormonal signs not explained by stress alone.'], causesIntro: 'Stress should be considered as one possible factor in a full picture, not an automatic explanation.', causes: ['Chronic overload, trauma, or a major life change.', 'Sleep or food loss, or a simultaneous illness.', 'Pregnancy, breastfeeding, or contraception.', 'PCOS, thyroid disease, or other causes of absent periods.'] }
    },
    {
      id: 'contraception-and-bleeding-complete-guide', category: 'health', iconName: 'medication', cover: 'life-stages.png',
      titleAr: 'وسائل منع الحمل وتغير النزف: ما المتوقع وما الذي يحتاج مراجعة؟', titleEn: 'Contraception and Bleeding Changes: What to Expect and What Needs Review',
      sourceUrls: ['https://www.cdc.gov/contraception/hcp/usspr/bleeding-irregularities-contraception.html', 'https://www.acog.org/womens-health/faqs/combined-hormonal-birth-control-pill-patch-ring'],
      ar: { lead: 'قد تغير وسائل منع الحمل توقيت النزف أو كميته أو توقفه، لكن النزف الجديد لا يجب أن ينسب تلقائيًا إلى الوسيلة من دون مراجعة الاستخدام واحتمال الحمل وأسباب أخرى.', meaning: 'النزف أثناء استخدام وسيلة هرمونية قد يكون نزفًا انسحابيًا أو بقعًا غير منتظمة، وليس بالضرورة حيضًا ناتجًا عن إباضة.', biology: 'تغير الهرمونات سمك بطانة الرحم والإباضة ومخاط عنق الرحم بطرق تختلف حسب الحبوب واللصقة والحلقة والحقن والغرسة واللولب.', patterns: ['بقع في الأشهر الأولى قد تخف مع الوقت.', 'نزف بعد جرعات فائتة أو تداخل دوائي.', 'غياب نزف مع استخدام صحيح قد يكون متوقعًا في بعض الوسائل.', 'ألم أو إفراز أو نزف بعد العلاقة يحتاج تقييمًا مستقلًا.'], causesIntro: 'يجب مراعاة طريقة الاستخدام ومدة بدء الوسيلة ورغبة الشخص في الاستمرار.', causes: ['تكيّف بطانة الرحم مع الوسيلة.', 'جرعات فائتة أو قيء أو تداخل دوائي.', 'حمل أو عدوى أو سبب في عنق الرحم أو الرحم.', 'وسيلة غير هرمونية قد تغير الغزارة لدى بعض الأشخاص.'] },
      en: { lead: 'Contraception may change bleeding timing, amount, or whether it occurs. New bleeding should not automatically be blamed on the method without reviewing use, pregnancy possibility, and other causes.', meaning: 'Bleeding with hormonal contraception may be withdrawal bleeding or irregular spotting rather than menstruation following ovulation.', biology: 'Hormonal methods affect the uterine lining, ovulation, and cervical mucus differently across pills, patches, rings, injections, implants, and intrauterine systems.', patterns: ['Spotting during early months that may improve over time.', 'Bleeding after missed doses or a medicine interaction.', 'No bleeding that may be expected with correct use of some methods.', 'Pain, discharge, or bleeding after sex needing separate assessment.'], causesIntro: 'Method use, time since initiation, safety, and the person’s goals all matter.', causes: ['The uterine lining adapting to the method.', 'Missed doses, vomiting, or a medicine interaction.', 'Pregnancy, infection, or a cervical or uterine cause.', 'A nonhormonal method increasing flow for some users.'] }
    },
    {
      id: 'first-period-complete-guide', category: 'basics', iconName: 'school', cover: 'life-stages.png',
      titleAr: 'أول دورة شهرية: دليل مطمئن للفتاة والأسرة', titleEn: 'The First Period: A Reassuring Guide for Young People and Families',
      sourceUrls: ['https://www.acog.org/womens-health/faqs/your-first-period', 'https://womenshealth.gov/menstrual-cycle/your-menstrual-cycle'],
      ar: { lead: 'أول دورة مرحلة طبيعية في البلوغ وليست شيئًا مخيفًا أو مخجلًا، والاستعداد الهادئ يمنح الفتاة لغة وخيارات وخصوصية.', meaning: 'الحيض الأول هو بداية نزف دوري من الرحم بعد تطور علامات البلوغ، وقد تبقى الدورات غير منتظمة خلال السنوات الأولى.', biology: 'تنضج إشارات الدماغ والمبيضين تدريجيًا، وقد لا تحدث الإباضة في كل دورة مبكرة، ولهذا يختلف التوقيت والكمية في البداية.', patterns: ['بقع بنية أو حمراء ثم نزف خفيف أو متوسط.', 'تفاوت الفاصل بين الدورات الأولى.', 'تقلصات أو صداع أو تغير مزاج بدرجات مختلفة.', 'نزف شديد جدًا أو ألم معطل أو غياب طويل يستحق إخبار بالغ موثوق.'], causesIntro: 'الاختلاف شائع، لكن العمر والتطور والصحة العامة والتغذية تؤثر في التوقيت.', causes: ['تنوع طبيعي في وقت البلوغ وتاريخ العائلة.', 'تغذية أو وزن أو نشاط أو مرض مزمن يؤثر في التطور.', 'اضطراب هرموني عند وجود علامات غير معتادة.', 'دواء أو حالة نزف تفسر الغزارة الشديدة.'] },
      en: { lead: 'A first period is a normal stage of puberty, not something frightening or shameful. Calm preparation gives a young person language, choices, and privacy.', meaning: 'Menarche is the first menstrual bleed after other puberty changes, and cycles may remain irregular during the early years.', biology: 'Brain and ovarian signals mature gradually, and ovulation may not occur in every early cycle, so timing and amount can vary.', patterns: ['Brown or red spotting followed by light or moderate flow.', 'Changing intervals during the first cycles.', 'Cramps, headache, or mood change of varying intensity.', 'Very heavy flow, disabling pain, or prolonged absence that should be shared with a trusted adult.'], causesIntro: 'Variation is common, while age, development, general health, and nutrition influence timing.', causes: ['Normal variation in puberty timing and family patterns.', 'Nutrition, weight, activity, or chronic illness affecting development.', 'A hormonal condition when unusual signs are present.', 'A medicine or bleeding condition behind very heavy flow.'] }
    },
    {
      id: 'perimenopause-bleeding-complete-guide', category: 'health', iconName: 'change_circle', cover: 'life-stages.png',
      titleAr: 'ما قبل انقطاع الطمث: تغيرات النزف والأعراض التي تستحق الانتباه', titleEn: 'Perimenopause: Bleeding Changes and Symptoms Worth Attention',
      sourceUrls: ['https://www.acog.org/womens-health/faqs/perimenopausal-bleeding-and-bleeding-after-menopause', 'https://womenshealth.gov/menopause/menopause-symptoms-and-relief'],
      ar: { lead: 'قد تصبح الدورة أقصر أو أطول أو أقل توقعًا قبل انقطاع الطمث، لكن العمر لا يجعل كل نزف طبيعيًا تلقائيًا.', meaning: 'ما قبل انقطاع الطمث مرحلة انتقالية تتغير فيها الإباضة والهرمونات قبل مرور 12 شهرًا كاملًا من دون حيض، وهو التعريف السريري لانقطاع الطمث.', biology: 'قد تتقلب مستويات الإستروجين والبروجسترون بدل الانخفاض في خط مستقيم، فتظهر تغيرات في النزف والحرارة والنوم والمزاج والمهبل.', patterns: ['تغير طول الدورة أو غزارتها مقارنة بالنمط السابق.', 'هبات ساخنة أو تعرق ليلي واضطراب نوم.', 'جفاف أو ألم مهبلي أو أعراض بولية.', 'نزف بين الدورات أو بعد العلاقة أو بعد انقطاع الطمث.'], causesIntro: 'قد تكون التغيرات انتقالية، لكن الأسباب البنيوية والدوائية والحمل وأمراض الرحم تبقى ممكنة.', causes: ['تغير الإباضة في المرحلة الانتقالية.', 'أورام ليفية أو سلائل أو عضال غدي.', 'أدوية أو وسائل هرمونية أو اضطراب الغدة الدرقية.', 'تغيرات في بطانة الرحم تحتاج تقييمًا بحسب العمر والخطر.'] },
      en: { lead: 'Cycles may become shorter, longer, or less predictable before menopause, but age does not make every bleeding change automatically normal.', meaning: 'Perimenopause is the transition before twelve complete months without a period, the clinical marker of menopause.', biology: 'Estrogen and progesterone may fluctuate instead of declining in a straight line, affecting bleeding, temperature, sleep, mood, vaginal tissues, and urinary symptoms.', patterns: ['A change in cycle length or heaviness from the previous baseline.', 'Hot flashes, night sweats, and disrupted sleep.', 'Vaginal dryness, pain, or urinary symptoms.', 'Bleeding between periods, after sex, or after menopause.'], causesIntro: 'Changes may be transitional, while pregnancy, medicines, structural causes, and uterine disease remain possible.', causes: ['Changing ovulation during the transition.', 'Fibroids, polyps, or adenomyosis.', 'Medicines, hormonal methods, or thyroid conditions.', 'Uterine lining changes requiring age- and risk-appropriate assessment.'] }
    },
    {
      id: 'postpartum-periods-complete-guide', category: 'health', iconName: 'child_friendly', cover: 'life-stages.png',
      titleAr: 'عودة الدورة بعد الولادة: النزف والرضاعة والخصوبة والتعافي', titleEn: 'Periods After Birth: Bleeding, Breastfeeding, Fertility, and Recovery',
      sourceUrls: ['https://www.acog.org/womens-health/faqs/postpartum-birth-control', 'https://womenshealth.gov/pregnancy/childbirth-and-beyond/recovering-birth'],
      ar: {
        lead: 'النزف بعد الولادة ليس دورة شهرية بالضرورة، وموعد عودة الحيض يختلف مع الرضاعة والتعافي، بينما يمكن أن تعود الخصوبة قبل أول دورة.',
        meaning: 'الهلابة إفراز ونزف طبيعيان خلال التعافي بعد الولادة يتغير لونهما وكميتهما تدريجيًا، أما أول حيض فيأتي لاحقًا بتوقيت متفاوت.',
        biology: 'تنخفض هرمونات الحمل بعد الولادة، وقد يؤخر البرولاكتين المرتبط بالرضاعة الإباضة، لكنه لا يمنعها على نحو مضمون في كل الظروف.',
        patterns: ['نزف يتناقص تدريجيًا ويتغير من الأحمر إلى ألوان أفتح.', 'زيادة مؤقتة مع النشاط ثم تحسن مع الراحة.', 'عودة دورة قد تكون مختلفة في الأشهر الأولى.', 'خصوبة محتملة قبل أول نزف حيضي.'],
        causesIntro: 'توقيت الولادة وطريقتها والرضاعة والأدوية والمضاعفات تغير صورة التعافي.',
        causes: ['هلابة طبيعية والتئام موضع المشيمة.', 'عودة الإباضة والحيض بوتيرة فردية.', 'بقايا أنسجة أو عدوى أو مشكلة في انقباض الرحم عند النزف غير الطبيعي.', 'وسيلة منع حمل بدأت بعد الولادة.'],
        urgent: ['نزف يملأ فوطة كبيرة خلال ساعة أو كتل كبيرة مع ضعف.', 'حمى أو رائحة كريهة أو ألم متزايد في البطن.', 'ضيق نفس أو ألم صدر أو صداع شديد أو تورم مفاجئ.']
      },
      en: {
        lead: 'Bleeding after birth is not necessarily a menstrual period. The return of menstruation varies with breastfeeding and recovery, while fertility can return before the first period.',
        meaning: 'Lochia is normal discharge and bleeding during postpartum healing that changes in color and amount. A first menstrual period occurs later on an individual timeline.',
        biology: 'Pregnancy hormones fall after birth, and prolactin associated with breastfeeding may delay ovulation, but it does not reliably prevent ovulation in every situation.',
        patterns: ['Bleeding that gradually decreases and changes from red to lighter colors.', 'A temporary increase with activity followed by improvement with rest.', 'A returning period that may differ during early months.', 'Possible fertility before the first menstrual bleed.'],
        causesIntro: 'Birth timing and method, breastfeeding, medicines, and complications shape recovery.',
        causes: ['Normal lochia and healing at the placental site.', 'Return of ovulation and menstruation on an individual timeline.', 'Retained tissue, infection, or poor uterine contraction when bleeding is abnormal.', 'A contraceptive method started after birth.'],
        urgent: ['Soaking a large pad within an hour or passing large clots with weakness.', 'Fever, foul odor, or increasing abdominal pain.', 'Breathlessness, chest pain, severe headache, or sudden swelling.']
      }
    },
    {
      id: 'vaginal-discharge-complete-guide', category: 'health', iconName: 'opacity', cover: 'doctor-visit.png',
      titleAr: 'الإفرازات المهبلية: ما الطبيعي ومتى تشير إلى حاجة للفحص؟', titleEn: 'Vaginal Discharge: What Is Normal and When It Needs Assessment',
      sourceUrls: ['https://www.acog.org/womens-health/faqs/vulvovaginal-health', 'https://www.cdc.gov/sti/about/about-sti-risk-and-oral-sex.html'],
      ar: { lead: 'الإفرازات جزء طبيعي من صحة المهبل وقد تتغير عبر الدورة، لكن الرائحة القوية أو الحكة أو الألم أو التغير المفاجئ تستحق تقييمًا بدل التشخيص باللون وحده.', meaning: 'الإفراز الطبيعي يجمع سوائل وخلايا ومخاطًا يحافظ على رطوبة الأنسجة، وتختلف كميته وقوامه مع الهرمونات والحمل والنشاط الجنسي.', biology: 'يحافظ المهبل على بيئة ميكروبية وحموضة متوازنة، وقد يسبب الغسل الداخلي والمواد المعطرة اضطرابًا بدل تنظيف أفضل.', patterns: ['إفراز شفاف أو أبيض يتغير قوامه حول الإباضة.', 'رائحة جديدة قوية أو حكة أو حرقان أو تورم.', 'ألم حوض أو نزف أو حرارة مع الإفراز.', 'تكرار الأعراض بعد علاج ذاتي غير مؤكد.'], causesIntro: 'الأعراض المتشابهة قد تنتج من أسباب مختلفة وعلاج أحدها قد يزيد الآخر.', causes: ['تغير طبيعي مرتبط بالدورة أو الحمل.', 'التهاب فطري أو اختلال بكتيري.', 'عدوى منقولة جنسيًا أو التهاب عنق الرحم.', 'تهيّج من عطر أو صابون أو غسول داخلي أو منتج صحي.'] },
      en: { lead: 'Discharge is a normal part of vaginal health and may change through the cycle. Strong odor, itching, pain, or a sudden change deserves assessment rather than diagnosis by color alone.', meaning: 'Normal discharge combines fluid, cells, and mucus that maintain tissue moisture. Amount and texture vary with hormones, pregnancy, and sexual activity.', biology: 'The vagina maintains a microbial and acidic environment. Internal washing and scented products can disrupt rather than improve that balance.', patterns: ['Clear or white discharge with texture changing near ovulation.', 'A strong new odor, itching, burning, or swelling.', 'Pelvic pain, bleeding, or fever accompanying discharge.', 'Symptoms recurring after uncertain self-treatment.'], causesIntro: 'Similar symptoms can have different causes, and treatment for one may worsen another.', causes: ['Normal cycle- or pregnancy-related change.', 'Yeast infection or bacterial imbalance.', 'A sexually transmitted infection or cervicitis.', 'Irritation from fragrance, soap, douching, or a menstrual product.'] }
    },
    {
      id: 'thyroid-and-periods-complete-guide', category: 'health', iconName: 'monitor_heart', cover: 'doctor-visit.png',
      titleAr: 'الغدة الدرقية والدورة: متى يكون التغير جزءًا من صورة أوسع؟', titleEn: 'Thyroid Health and Periods: When Cycle Change Is Part of a Wider Picture',
      sourceUrls: ['https://www.niddk.nih.gov/health-information/endocrine-diseases/hypothyroidism', 'https://www.niddk.nih.gov/health-information/endocrine-diseases/graves-disease'],
      ar: { lead: 'يمكن لاضطراب الغدة الدرقية أن يغير النزف أو التوقيت، لكنه لا يشخّص من الدورة وحدها؛ الأعراض العامة والتحاليل هي التي تكمل الصورة.', meaning: 'تصنع الغدة هرمونات تؤثر في الاستقلاب والحرارة والقلب والدماغ، ويمكن أن تتداخل زيادتها أو نقصها مع الإباضة والحيض.', biology: 'ينظم الدماغ الغدة عبر TSH، ثم تصل هرموناتها إلى أنسجة كثيرة؛ لهذا قد تجتمع تغيرات الدورة مع الطاقة والوزن والجلد والأمعاء والنبض.', patterns: ['تعب وبرد وإمساك وجفاف أو زيادة وزن غير مفسرة.', 'خفقان وحرارة وتعرق ورجفة أو نقص وزن غير مقصود.', 'دورة أثقل أو أخف أو متباعدة مع أعراض عامة.', 'تورم رقبة أو تغير عينين أو تاريخ عائلي للغدة.'], causesIntro: 'كثير من هذه الأعراض غير نوعي، لذلك الاختبار الموجه أفضل من التخمين أو المكملات.', causes: ['قصور الغدة المناعي أو بعد علاج أو دواء.', 'فرط الغدة مثل داء غريفز أو التهاب مؤقت.', 'تغيرات الحمل وما بعد الولادة.', 'حالات أخرى تشبه أعراض الغدة مثل نقص الحديد أو القلق.'] },
      en: { lead: 'Thyroid disorders can alter bleeding or timing, but they cannot be diagnosed from a cycle alone. General symptoms and appropriate testing complete the picture.', meaning: 'The thyroid makes hormones affecting metabolism, temperature, heart, brain, and many tissues. Too much or too little activity can interact with ovulation and menstruation.', biology: 'The brain regulates the thyroid through TSH, and thyroid hormones reach many organs, so cycle changes may occur with shifts in energy, weight, skin, bowel habits, and heart rate.', patterns: ['Fatigue, cold sensitivity, constipation, dry skin, or unexplained weight gain.', 'Palpitations, heat, sweating, tremor, or unintended weight loss.', 'Heavier, lighter, or widely spaced periods with broader symptoms.', 'Neck swelling, eye changes, or a family thyroid history.'], causesIntro: 'Many symptoms are nonspecific, so targeted testing is better than guessing or taking supplements.', causes: ['Autoimmune hypothyroidism or reduced function after treatment or medicine.', 'Hyperthyroidism such as Graves disease or temporary inflammation.', 'Pregnancy and postpartum thyroid changes.', 'Look-alike conditions such as iron deficiency or anxiety.'] }
    },
    {
      id: 'preparing-for-period-doctor-visit-complete-guide', category: 'basics', iconName: 'medical_information', cover: 'doctor-visit.png',
      titleAr: 'كيف تستعدين لزيارة الطبيبة بسبب الدورة: من السجل إلى القرار المشترك', titleEn: 'Preparing for a Period-Related Health Visit: From Records to Shared Decisions',
      sourceUrls: ['https://www.acog.org/womens-health/faqs/abnormal-uterine-bleeding', 'https://womenshealth.gov/menstrual-cycle/your-menstrual-cycle-and-your-health'],
      ar: { lead: 'زيارة ناجحة لا تحتاج ملفًا مثاليًا؛ تحتاج هدفًا واضحًا وملخصًا قصيرًا للأعراض والأسئلة التي تهمك وحدودك في الفحص والمشاركة.', meaning: 'التحضير يعني تنظيم ما تعرفينه من دون تشخيص نفسك: التوقيت والكمية والأثر والأدوية واحتمال الحمل وما الذي تريدين فهمه أو تحسينه.', biology: 'تستخدم الطبيبة النمط لتقرر إن كانت الأولوية لاستبعاد الحمل أو فقر الدم أو سبب هرموني أو بنيوي أو التهابي، ثم تختار الفحوص التي تغير القرار.', patterns: ['تغير مستمر في التوقيت أو الغزارة أو الألم.', 'أعراض عامة مثل دوخة أو حمى أو تغير وزن أو شعر.', 'ارتباط بوسيلة منع حمل أو دواء أو ولادة.', 'أثر واضح في النوم والعمل والعلاقة والحركة.'], causesIntro: 'الزيارة لا تبدأ بقائمة فحوص للجميع، بل بسؤال سريري يوجه الفحص والتحليل.', causes: ['حمل أو تغير إباضة أو وسيلة هرمونية.', 'نقص حديد أو غدة درقية أو اضطراب نزف.', 'أورام ليفية أو سلائل أو بطانة مهاجرة.', 'عدوى أو أسباب بولية وهضمية وعضلية متداخلة.'], track: ['اكتبي ثلاث جمل تلخص المشكلة والهدف.', 'أحضري تواريخ آخر دورات ووصف الغزارة والألم.', 'صوري أسماء الأدوية والمكملات والجرعات بدل الاعتماد على الذاكرة.', 'اكتبي ما لا توافقين عليه في الفحص وما تحتاجينه للشعور بالأمان.'], visit: ['ما الاحتمالات الأكثر منطقية ولماذا؟', 'ما الفحص الذي سيغير الخطة وما البدائل؟', 'ما خيارات تخفيف الأعراض ومزايا كل منها ومخاطرها؟', 'متى أتوقع التحسن ومتى أعود أو أطلب طوارئ؟'] },
      en: { lead: 'A useful visit does not require a perfect file. It needs a clear goal, a short symptom summary, the questions that matter to you, and your boundaries around examination and sharing.', meaning: 'Preparation means organizing what you know without diagnosing yourself: timing, amount, impact, medicines, pregnancy possibility, and what you want to understand or improve.', biology: 'A clinician uses the pattern to decide whether to prioritize pregnancy, anemia, hormonal, structural, or inflammatory causes and selects tests that can change the decision.', patterns: ['Persistent change in timing, heaviness, or pain.', 'Broader symptoms such as dizziness, fever, weight, hair, or skin change.', 'A link with contraception, a medicine, birth, or a procedure.', 'Clear impact on sleep, work, relationships, and movement.'], causesIntro: 'A visit does not begin with every possible test; it begins with a clinical question that guides examination and investigation.', causes: ['Pregnancy, ovulation change, or a hormonal method.', 'Iron deficiency, thyroid disease, or a bleeding disorder.', 'Fibroids, polyps, or endometriosis.', 'Infection or overlapping urinary, bowel, and muscular causes.'], track: ['Write three sentences summarizing the problem and your goal.', 'Bring recent cycle dates and a practical description of flow and pain.', 'Photograph medicine and supplement labels and doses.', 'Write examination boundaries and what helps you feel safe.'], visit: ['Which explanations are most likely and why?', 'Which test would change the plan, and what alternatives exist?', 'What relief options exist and what are their benefits and risks?', 'When should improvement occur, and when should I return or seek urgent care?'] }
    },
  ];

  const extraRaw =
    (typeof window !== 'undefined' && window.LUNE_LONG_ARTICLES_EXTRA_RAW) ||
    (typeof global !== 'undefined' && global.LUNE_LONG_ARTICLES_EXTRA_RAW) ||
    [];
  const allRaw = rawArticles.concat(extraRaw);

  window.LUNE_LONG_ARTICLES = allRaw.map((item, index) => ({
    id: item.id,
    category: item.category,
    iconName: item.iconName,
    minutes: item.minutes || 14,
    adultsOnly: item.adultsOnly === true,
    published: true,
    order: 100 + index,
    titleEn: item.titleEn,
    titleAr: item.titleAr,
    bodyEn: buildEnglish(completeTopic(item.en, EN_DEFAULTS), item.id),
    bodyAr: buildArabic(completeTopic(item.ar, AR_DEFAULTS), item.id),
    coverImageUrl: `https://lune-7d956.web.app/images/magazine/guides/${item.id.replace(/-complete-guide$/, '')}.webp`,
    excerptAr: item.ar.lead,
    excerptEn: item.en.lead,
    featured: index < 6,
    slug: item.id,
    sourceUrls: item.sourceUrls,
    contentVersion: 1,
  }));

  window.LUNE_LONG_ARTICLES_META = window.LUNE_LONG_ARTICLES.map((article) => ({
    id: article.id,
    slug: article.slug,
    category: article.category,
    minutes: article.minutes,
    adultsOnly: article.adultsOnly,
    published: article.published,
    order: article.order,
    titleEn: article.titleEn,
    titleAr: article.titleAr,
    excerptAr: article.excerptAr,
    excerptEn: article.excerptEn,
    coverImageUrl: article.coverImageUrl,
    featured: article.featured,
    sourceUrls: article.sourceUrls,
  }));
})();
