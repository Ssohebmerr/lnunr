import 'package:flutter/material.dart';

import 'article_icon_registry.dart';

enum ArticleCategory { basics, health, nutrition, mind, adult }

class Article {
  const Article({
    required this.id,
    required this.category,
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.minutes,
    this.adultsOnly = false,
  });

  factory Article.fromMap(String id, Map<String, dynamic> data) {
    final categoryName = data['category'] as String? ?? 'basics';
    final category = ArticleCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => ArticleCategory.basics,
    );
    return Article(
      id: id,
      category: category,
      icon: articleIconFromName(data['iconName'] as String? ?? 'article_outlined'),
      titleEn: data['titleEn'] as String? ?? '',
      titleAr: data['titleAr'] as String? ?? '',
      bodyEn: data['bodyEn'] as String? ?? '',
      bodyAr: data['bodyAr'] as String? ?? '',
      minutes: (data['minutes'] as num?)?.toInt() ?? 3,
      adultsOnly: data['adultsOnly'] as bool? ?? false,
    );
  }

  final String id;
  final ArticleCategory category;
  final IconData icon;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final int minutes;

  /// Hidden for users known to be under 18.
  final bool adultsOnly;

  String title(String lang) => lang == 'ar' ? titleAr : titleEn;
  String body(String lang) => lang == 'ar' ? bodyAr : bodyEn;
}

/// Curated educational library. All content is general wellness education,
/// reviewed for a young audience except items marked [Article.adultsOnly].
class EducationContent {
  static const articles = [
    // ----------------------------------------------------------- basics
    Article(
      id: 'what_is_cycle',
      category: ArticleCategory.basics,
      icon: Icons.loop_outlined,
      minutes: 3,
      titleEn: 'What is a menstrual cycle?',
      titleAr: 'ما هي الدورة الشهرية؟',
      bodyEn:
          'Your menstrual cycle is the monthly rhythm your body follows, counted '
          'from the first day of one period to the first day of the next. A typical '
          'cycle lasts 21 to 35 days — 28 is an average, not a rule.\n\n'
          'During each cycle, hormones rise and fall in a beautiful, coordinated '
          'pattern. They prepare the lining of the uterus, release an egg around '
          'the middle of the cycle, and — if there is no pregnancy — the lining '
          'is shed as your period.\n\n'
          'Every body is different. Your "normal" is what is regular for YOU, '
          'and tracking your cycle in this app helps you discover that personal '
          'pattern over a few months.',
      bodyAr:
          'الدورة الشهرية هي الإيقاع الشهري الذي يتبعه جسمك، وتُحسب من أول يوم '
          'في الدورة إلى أول يوم في الدورة التالية. تستمر الدورة الطبيعية من 21 '
          'إلى 35 يومًا — والـ 28 يومًا متوسط وليس قاعدة.\n\n'
          'خلال كل دورة، ترتفع الهرمونات وتنخفض بنمط منسق وجميل: تجهز بطانة '
          'الرحم، وتطلق بويضة في منتصف الدورة تقريبًا، وإذا لم يحدث حمل تنزل '
          'البطانة على شكل دورة شهرية.\n\n'
          'كل جسم مختلف عن الآخر. "الطبيعي" هو ما هو منتظم بالنسبة لكِ أنتِ، '
          'وتتبّع دورتك في هذا التطبيق يساعدك على اكتشاف نمطك الشخصي خلال '
          'بضعة أشهر.',
    ),
    Article(
      id: 'cycle_phases',
      category: ArticleCategory.basics,
      icon: Icons.brightness_4_outlined,
      minutes: 4,
      titleEn: 'The four phases of your cycle',
      titleAr: 'مراحل الدورة الأربع',
      bodyEn:
          'Your cycle has four phases, each with its own energy.\n\n'
          '1. Menstrual phase (your period): hormone levels are low. Many feel '
          'tired and inward — rest is productive here.\n\n'
          '2. Follicular phase: estrogen rises and so does energy, focus, and '
          'mood. A great time to start new things.\n\n'
          '3. Ovulation: around mid-cycle, an egg is released. Energy and '
          'confidence often peak.\n\n'
          '4. Luteal phase: progesterone takes over. Energy gradually softens, '
          'and some experience PMS in the last days. Slowing down and being '
          'gentle with yourself helps.\n\n'
          'Knowing your phase helps you plan workouts, work, and rest around '
          'your natural rhythm instead of fighting it.',
      bodyAr:
          'لدورتك أربع مراحل، ولكل مرحلة طاقتها الخاصة.\n\n'
          '1. مرحلة الحيض (الدورة): مستويات الهرمونات منخفضة. كثيرات يشعرن '
          'بالتعب والانطواء — الراحة هنا إنجاز بحد ذاتها.\n\n'
          '2. المرحلة الجريبية: يرتفع الإستروجين ومعه الطاقة والتركيز والمزاج. '
          'وقت رائع لبدء أشياء جديدة.\n\n'
          '3. الإباضة: في منتصف الدورة تقريبًا تنطلق البويضة. غالبًا تكون الطاقة '
          'والثقة في القمة.\n\n'
          '4. المرحلة الأصفرية: يتولى البروجستيرون القيادة. تهدأ الطاقة تدريجيًا، '
          'وقد تشعر بعضهن بأعراض ما قبل الدورة في الأيام الأخيرة. التمهل '
          'واللطف مع نفسك يساعدان كثيرًا.\n\n'
          'معرفة مرحلتك تساعدك على تخطيط الرياضة والعمل والراحة حول إيقاعك '
          'الطبيعي بدل مقاومته.',
    ),
    Article(
      id: 'first_period',
      category: ArticleCategory.basics,
      icon: Icons.emoji_nature_outlined,
      minutes: 3,
      titleEn: 'Your first periods: a gentle guide',
      titleAr: 'دوراتك الأولى: دليل لطيف',
      bodyEn:
          'If your periods started recently, welcome — your body is doing '
          'exactly what it should.\n\n'
          'In the first year or two, cycles are often irregular: they may come '
          'early, late, or skip a month. This is completely normal while your '
          'hormones find their rhythm.\n\n'
          'Keep a small kit (pad, spare underwear) in your bag, track your days '
          'in this app, and remember: a period is not something to be ashamed '
          'of. Every woman you admire has one.\n\n'
          'Talk to a trusted adult or doctor if pain keeps you home from school, '
          'bleeding is very heavy, or you simply feel worried. Asking questions '
          'is a sign of strength.',
      bodyAr:
          'إذا بدأت دورتك مؤخرًا، أهلًا بك — جسمك يقوم بما يجب عليه تمامًا.\n\n'
          'في السنة الأولى أو الثانية، غالبًا ما تكون الدورات غير منتظمة: قد '
          'تأتي مبكرًا أو متأخرًا أو تتخطى شهرًا. هذا طبيعي تمامًا بينما تجد '
          'هرموناتك إيقاعها.\n\n'
          'احتفظي بمستلزمات صغيرة (فوطة، ملابس داخلية احتياطية) في حقيبتك، '
          'وتتبعي أيامك في هذا التطبيق، وتذكري: الدورة ليست شيئًا يُخجل منه. '
          'كل امرأة تعجبين بها تمر بها.\n\n'
          'تحدثي مع شخص بالغ تثقين به أو طبيبة إذا كان الألم يمنعك من المدرسة، '
          'أو كان النزيف غزيرًا جدًا، أو شعرتِ بالقلق. طرح الأسئلة دليل قوة.',
    ),
    // ----------------------------------------------------------- health
    Article(
      id: 'pms_explained',
      category: ArticleCategory.health,
      icon: Icons.cloud_outlined,
      minutes: 3,
      titleEn: 'PMS: why it happens and what helps',
      titleAr: 'أعراض ما قبل الدورة: لماذا تحدث وما الذي يساعد',
      bodyEn:
          'In the days before your period, falling estrogen and progesterone '
          'can affect mood, sleep, appetite, and energy. This is premenstrual '
          'syndrome — PMS — and it is very common.\n\n'
          'What helps: regular sleep, gentle movement, magnesium-rich foods '
          '(nuts, leafy greens, dark chocolate), less caffeine and salt, and '
          'planning lighter days when you can.\n\n'
          'Track your symptoms in the app — seeing the pattern repeat makes it '
          'predictable, and predictable is manageable.\n\n'
          'If PMS regularly disrupts your life, relationships, or work, mention '
          'it to a doctor. Severe forms are treatable, and you deserve support.',
      bodyAr:
          'في الأيام التي تسبق الدورة، يمكن لانخفاض الإستروجين والبروجستيرون '
          'أن يؤثر على المزاج والنوم والشهية والطاقة. هذه متلازمة ما قبل '
          'الدورة، وهي شائعة جدًا.\n\n'
          'ما الذي يساعد: نوم منتظم، حركة لطيفة، أطعمة غنية بالمغنيسيوم '
          '(مكسرات، خضار ورقية، شوكولاتة داكنة)، تقليل الكافيين والملح، '
          'وتخطيط أيام أخف عندما تستطيعين.\n\n'
          'تتبعي أعراضك في التطبيق — رؤية النمط يتكرر تجعله متوقعًا، والمتوقع '
          'يمكن التعامل معه.\n\n'
          'إذا كانت الأعراض تعطل حياتك أو علاقاتك أو عملك بانتظام، اذكريها '
          'للطبيبة. الحالات الشديدة قابلة للعلاج، وأنتِ تستحقين الدعم.',
    ),
    Article(
      id: 'period_pain',
      category: ArticleCategory.health,
      icon: Icons.healing_outlined,
      minutes: 3,
      titleEn: 'Period pain: what is normal?',
      titleAr: 'ألم الدورة: ما هو الطبيعي؟',
      bodyEn:
          'Mild to moderate cramps in the first days of a period are common — '
          'the uterus contracts to shed its lining.\n\n'
          'Comfort that works: a warm compress on the lower belly, gentle '
          'stretching or walking, staying hydrated, and rest.\n\n'
          'Pain is NOT normal when it makes you miss school or work every '
          'month, does not improve with simple pain relief, or gets worse over '
          'time. These can be signs of treatable conditions like endometriosis.\n\n'
          'Use the pain tracking in this app — a clear record of "how much, '
          'how long, how often" is exactly what a doctor needs to help you.',
      bodyAr:
          'التقلصات الخفيفة إلى المتوسطة في أيام الدورة الأولى شائعة — فالرحم '
          'ينقبض ليتخلص من بطانته.\n\n'
          'وسائل راحة مجربة: كمادة دافئة على أسفل البطن، تمدد لطيف أو مشي، '
          'شرب الماء بانتظام، والراحة.\n\n'
          'الألم ليس طبيعيًا عندما يجعلك تتغيبين عن المدرسة أو العمل كل شهر، '
          'أو لا يتحسن مع مسكنات بسيطة، أو يزداد سوءًا مع الوقت. قد تكون هذه '
          'علامات على حالات قابلة للعلاج مثل بطانة الرحم المهاجرة.\n\n'
          'استخدمي تتبع الألم في هذا التطبيق — سجل واضح عن "كم، وكم مدة، وكم '
          'مرة" هو بالضبط ما تحتاجه الطبيبة لمساعدتك.',
    ),
    Article(
      id: 'see_doctor',
      category: ArticleCategory.health,
      icon: Icons.medical_services_outlined,
      minutes: 2,
      titleEn: 'Signs it is time to see a doctor',
      titleAr: 'علامات تستدعي زيارة الطبيبة',
      bodyEn:
          'Most cycle variations are normal, but some signs deserve a '
          'professional look:\n\n'
          '• No period for 3 months (and no pregnancy)\n'
          '• Cycles consistently shorter than 21 or longer than 35 days\n'
          '• Bleeding so heavy you change protection every hour\n'
          '• Bleeding between periods\n'
          '• Pain that painkillers do not touch\n'
          '• Periods that suddenly change character\n\n'
          'None of these mean something is definitely wrong — they simply mean '
          '"worth checking". Bring your app data to the appointment; the '
          'doctor report feature can summarize it for you.',
      bodyAr:
          'معظم تغيرات الدورة طبيعية، لكن بعض العلامات تستحق نظرة مختصة:\n\n'
          '• انقطاع الدورة 3 أشهر (دون حمل)\n'
          '• دورات أقصر من 21 يومًا أو أطول من 35 يومًا باستمرار\n'
          '• نزيف غزير لدرجة تغيير الفوطة كل ساعة\n'
          '• نزيف بين الدورات\n'
          '• ألم لا تؤثر فيه المسكنات\n'
          '• تغير مفاجئ في طبيعة الدورة\n\n'
          'لا تعني أي من هذه العلامات أن هناك خطبًا مؤكدًا — بل تعني فقط "تستحق '
          'الفحص". خذي بيانات التطبيق معك للموعد؛ ميزة تقرير الطبيبة تلخصها لك.',
    ),
    // ----------------------------------------------------------- nutrition
    Article(
      id: 'cycle_nutrition',
      category: ArticleCategory.nutrition,
      icon: Icons.restaurant_outlined,
      minutes: 3,
      titleEn: 'Eating with your cycle',
      titleAr: 'التغذية مع دورتك',
      bodyEn:
          'Your nutritional needs shift across the month.\n\n'
          'During your period: iron is lost with bleeding — lentils, spinach, '
          'red meat, and dates help. Pair iron with vitamin C for absorption.\n\n'
          'Follicular phase: your body handles carbs well; whole grains and '
          'fresh produce fuel rising energy.\n\n'
          'Luteal phase: cravings are real — hormones increase appetite. '
          'Magnesium (nuts, dark chocolate) and complex carbs steady mood and '
          'energy. Reducing salt eases bloating.\n\n'
          'No food is forbidden. The goal is supporting your body, not '
          'restricting it.',
      bodyAr:
          'احتياجاتك الغذائية تتغير على مدار الشهر.\n\n'
          'أثناء الدورة: يُفقد الحديد مع النزيف — العدس والسبانخ واللحوم '
          'الحمراء والتمر تساعد. اجمعي الحديد مع فيتامين C لامتصاص أفضل.\n\n'
          'المرحلة الجريبية: جسمك يتعامل مع الكربوهيدرات جيدًا؛ الحبوب الكاملة '
          'والخضار الطازجة تغذي طاقتك الصاعدة.\n\n'
          'المرحلة الأصفرية: الرغبة الشديدة بالأكل حقيقية — الهرمونات تزيد '
          'الشهية. المغنيسيوم (المكسرات، الشوكولاتة الداكنة) والكربوهيدرات '
          'المعقدة يثبتان المزاج والطاقة. وتقليل الملح يخفف الانتفاخ.\n\n'
          'لا يوجد طعام ممنوع. الهدف دعم جسمك، لا تقييده.',
    ),
    Article(
      id: 'cycle_exercise',
      category: ArticleCategory.nutrition,
      icon: Icons.fitness_center_outlined,
      minutes: 3,
      titleEn: 'Moving through your phases',
      titleAr: 'الحركة عبر مراحل دورتك',
      bodyEn:
          'You do not need the same workout every day — your cycle suggests a '
          'natural training plan.\n\n'
          'Period days: gentle wins. Walking, stretching, and light yoga can '
          'actually ease cramps.\n\n'
          'Follicular phase: energy climbs — great for cardio, strength '
          'training, and trying new classes.\n\n'
          'Around ovulation: many hit personal bests now. Enjoy it, but warm '
          'up well.\n\n'
          'Luteal phase: shift toward moderate intensity — pilates, swimming, '
          'steady walks. In the final days, honor lower energy without guilt.\n\n'
          'The best exercise is the one you actually do — your cycle just '
          'helps you choose when.',
      bodyAr:
          'لستِ بحاجة لنفس التمرين كل يوم — دورتك تقترح خطة تدريب طبيعية.\n\n'
          'أيام الدورة: اللطيف يكسب. المشي والتمدد واليوغا الخفيفة قد تخفف '
          'التقلصات فعلًا.\n\n'
          'المرحلة الجريبية: الطاقة تتصاعد — ممتازة للكارديو وتمارين القوة '
          'وتجربة صفوف جديدة.\n\n'
          'حول الإباضة: كثيرات يحققن أفضل أرقامهن الآن. استمتعي، لكن أحسني '
          'الإحماء.\n\n'
          'المرحلة الأصفرية: انتقلي لشدة معتدلة — بيلاتس، سباحة، مشي منتظم. '
          'وفي الأيام الأخيرة، احترمي طاقتك المنخفضة دون ذنب.\n\n'
          'أفضل تمرين هو الذي تمارسينه فعلًا — دورتك فقط تساعدك على اختيار '
          'التوقيت.',
    ),
    // ----------------------------------------------------------- mind
    Article(
      id: 'hormones_mood',
      category: ArticleCategory.mind,
      icon: Icons.psychology_outlined,
      minutes: 3,
      titleEn: 'Hormones and your mood',
      titleAr: 'الهرمونات ومزاجك',
      bodyEn:
          'If your mood changes across the month, you are not "moody" — you '
          'are cyclical, and that is human biology.\n\n'
          'Estrogen supports serotonin, the "good mood" messenger. When it '
          'rises (follicular phase), many feel brighter and more social. When '
          'it falls (late luteal), sensitivity, irritability, or tearfulness '
          'can visit.\n\n'
          'What helps: naming it ("this is day 26, not a life crisis"), '
          'logging your mood in the app to see your pattern, sunlight and '
          'movement, and protecting sleep in the luteal phase.\n\n'
          'And if low mood is heavy, lasting, or scary at any point in the '
          'cycle — reach out to someone you trust or a professional. You never '
          'have to carry it alone.',
      bodyAr:
          'إذا كان مزاجك يتغير عبر الشهر، فأنتِ لست "مزاجية" — أنتِ دورية، '
          'وهذه بيولوجيا إنسانية.\n\n'
          'الإستروجين يدعم السيروتونين، رسول "المزاج الجيد". عندما يرتفع '
          '(المرحلة الجريبية) تشعر كثيرات بإشراق واجتماعية أكبر. وعندما ينخفض '
          '(أواخر المرحلة الأصفرية) قد تزور الحساسية أو الانفعال أو الدموع.\n\n'
          'ما يساعد: تسمية الأمر ("هذا اليوم 26، وليست أزمة حياة")، تسجيل '
          'مزاجك في التطبيق لرؤية نمطك، الشمس والحركة، وحماية النوم في '
          'المرحلة الأصفرية.\n\n'
          'وإذا كان المزاج المنخفض ثقيلًا أو مستمرًا أو مخيفًا في أي وقت من '
          'الدورة — تواصلي مع شخص تثقين به أو مختصة. لا يجب أن تحملي ذلك '
          'وحدك أبدًا.',
    ),
    Article(
      id: 'self_kindness',
      category: ArticleCategory.mind,
      icon: Icons.volunteer_activism_outlined,
      minutes: 2,
      titleEn: 'The art of being kind to yourself',
      titleAr: 'فن اللطف مع النفس',
      bodyEn:
          'Productivity culture says every day should look the same. Your '
          'body says otherwise — and your body is right.\n\n'
          'Being kind to yourself during your cycle is not laziness; it is '
          'strategy. Rest during your period is how you fund the energy of '
          'your follicular phase.\n\n'
          'Try this: on low days, lower the bar on purpose. Choose the '
          'gentlest version of your tasks. Say "this is enough for today" '
          'and mean it.\n\n'
          'The challenges in this app are designed for exactly this — small, '
          'kind actions that count. A glass of water is a victory. Claim it.',
      bodyAr:
          'ثقافة الإنتاجية تقول إن كل الأيام يجب أن تتشابه. جسمك يقول غير '
          'ذلك — وجسمك على حق.\n\n'
          'اللطف مع نفسك خلال دورتك ليس كسلًا؛ إنه استراتيجية. الراحة أثناء '
          'الدورة هي ما يموّل طاقة مرحلتك الجريبية.\n\n'
          'جربي هذا: في الأيام المنخفضة، اخفضي السقف عمدًا. اختاري النسخة '
          'الألطف من مهامك. قولي "هذا يكفي لليوم" واقصديها.\n\n'
          'تحديات هذا التطبيق مصممة لهذا بالضبط — أفعال صغيرة لطيفة لها '
          'قيمة. كوب الماء انتصار. طالبي به.',
    ),
    // ----------------------------------------------------------- adult (18+)
    Article(
      id: 'fertility_window',
      category: ArticleCategory.adult,
      icon: Icons.favorite_outline,
      minutes: 3,
      adultsOnly: true,
      titleEn: 'Understanding your fertile window',
      titleAr: 'فهم نافذة الخصوبة',
      bodyEn:
          'The fertile window is the days in each cycle when pregnancy is '
          'possible — roughly the five days before ovulation plus ovulation '
          'day itself.\n\n'
          'Ovulation usually happens about 14 days BEFORE the next period '
          'starts (not after the previous one). With irregular cycles, the '
          'timing shifts, which is why predictions improve the longer you '
          'track.\n\n'
          'Signs some notice near ovulation: clearer stretchy discharge, a '
          'slight rise in basal body temperature after ovulation, and mild '
          'one-sided twinges.\n\n'
          'Whether you are trying to conceive or to avoid pregnancy, remember '
          'app predictions are estimates, not guarantees — discuss reliable '
          'options with a healthcare provider.',
      bodyAr:
          'نافذة الخصوبة هي الأيام التي يكون فيها الحمل ممكنًا في كل دورة — '
          'تقريبًا الأيام الخمسة قبل الإباضة بالإضافة إلى يوم الإباضة نفسه.\n\n'
          'تحدث الإباضة عادة قبل 14 يومًا من بدء الدورة التالية (وليس بعد '
          'السابقة). مع الدورات غير المنتظمة يتغير التوقيت، ولهذا تتحسن '
          'التوقعات كلما تتبعتِ أكثر.\n\n'
          'علامات تلاحظها بعضهن قرب الإباضة: إفرازات شفافة مطاطية، ارتفاع '
          'طفيف في حرارة الجسم الأساسية بعد الإباضة، ووخزات خفيفة في جانب '
          'واحد.\n\n'
          'سواء كنتِ تحاولين الحمل أو تجنبه، تذكري أن توقعات التطبيق تقديرات '
          'وليست ضمانات — ناقشي الخيارات الموثوقة مع مقدمة رعاية صحية.',
    ),
    Article(
      id: 'contraception_overview',
      category: ArticleCategory.adult,
      icon: Icons.medication_outlined,
      minutes: 4,
      adultsOnly: true,
      titleEn: 'Contraception: an honest overview',
      titleAr: 'وسائل منع الحمل: نظرة صادقة',
      bodyEn:
          'There is no single "best" contraception — only the best fit for '
          'your body, health history, and life.\n\n'
          'Hormonal options (pill, patch, ring, injection, hormonal IUD, '
          'implant) prevent ovulation or thicken cervical mucus. They can also '
          'change bleeding patterns — lighter for some, irregular for others.\n\n'
          'Non-hormonal options include the copper IUD and barrier methods like '
          'condoms — the only method that also protects against infections.\n\n'
          'Fertility-awareness methods rely on precise daily tracking and have '
          'higher real-world failure rates; they demand consistency.\n\n'
          'This app can track whichever method you use, but the choice itself '
          'belongs in a conversation with a doctor who knows your history.',
      bodyAr:
          'لا توجد وسيلة منع حمل "أفضل" واحدة — فقط الأنسب لجسمك وتاريخك '
          'الصحي وحياتك.\n\n'
          'الخيارات الهرمونية (حبوب، لصقة، حلقة، حقن، لولب هرموني، غرسة) تمنع '
          'الإباضة أو تزيد كثافة مخاط عنق الرحم. وقد تغير أنماط النزيف — أخف '
          'لبعضهن، وغير منتظم لأخريات.\n\n'
          'الخيارات غير الهرمونية تشمل اللولب النحاسي والوسائل الحاجزة مثل '
          'الواقي — وهو الوسيلة الوحيدة التي تحمي أيضًا من العدوى.\n\n'
          'طرق الوعي بالخصوبة تعتمد على تتبع يومي دقيق ونسب فشلها الواقعية '
          'أعلى؛ فهي تتطلب التزامًا صارمًا.\n\n'
          'يستطيع هذا التطبيق تتبع أي وسيلة تستخدمينها، لكن الاختيار نفسه '
          'مكانه حوار مع طبيبة تعرف تاريخك.',
    ),
  ];

  static List<Article> byCategory(ArticleCategory category,
      {required bool includeAdult}) {
    return filterByCategory(articles, category, includeAdult: includeAdult);
  }

  static List<Article> filterByCategory(
    List<Article> source,
    ArticleCategory category, {
    required bool includeAdult,
  }) {
    return source
        .where((a) =>
            a.category == category && (includeAdult || !a.adultsOnly))
        .toList();
  }

  static List<Article> visible({required bool includeAdult}) =>
      articles.where((a) => includeAdult || !a.adultsOnly).toList();
}
