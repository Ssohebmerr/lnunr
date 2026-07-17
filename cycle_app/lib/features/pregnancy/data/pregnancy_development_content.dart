/// Formats CRL / head-to-heel length for display (cm or mm).
String formatPregnancyLength(double lengthCm, String lang) {
  if (lengthCm < 0.1) {
    return lang.startsWith('ar') ? 'أقل من 1 مم' : '< 1 mm';
  }
  if (lengthCm < 1) {
    final mm = (lengthCm * 10).round().clamp(1, 999);
    return lang.startsWith('ar') ? '$mm مم' : '$mm mm';
  }
  final rounded = lengthCm >= 10
      ? lengthCm.toStringAsFixed(0)
      : lengthCm.toStringAsFixed(1);
  return lang.startsWith('ar') ? '$rounded سم' : '$rounded cm';
}

/// Formats estimated fetal weight.
String formatPregnancyWeight(int grams, String lang) {
  if (grams <= 0) {
    return lang.startsWith('ar') ? 'أقل من 1 جم' : '< 1 g';
  }
  if (grams < 1000) {
    return lang.startsWith('ar') ? '$grams جم' : '$grams g';
  }
  final kg = (grams / 1000).toStringAsFixed(1);
  return lang.startsWith('ar') ? '$kg كغ' : '$kg kg';
}

/// Week-by-week fetal growth (length/weight) and development copy.
class PregnancyWeekInfo {
  const PregnancyWeekInfo({
    required this.lengthCm,
    required this.weightGrams,
    required this.bodyEn,
    required this.bodyAr,
    required this.maternalEn,
    required this.maternalAr,
    required this.fruitEn,
    required this.fruitAr,
  });

  /// Crown–rump (early) or head-to-heel (20+) length in centimetres.
  final double lengthCm;

  /// Estimated weight in grams (0 = show as under 1 g).
  final int weightGrams;
  final String bodyEn;
  final String bodyAr;
  final String maternalEn;
  final String maternalAr;
  final String fruitEn;
  final String fruitAr;

  String lengthDisplay(String lang) => formatPregnancyLength(lengthCm, lang);

  String weightDisplay(String lang) => formatPregnancyWeight(weightGrams, lang);

  String bodyFor(String lang) => lang.startsWith('ar') ? bodyAr : bodyEn;
  String maternalFor(String lang) =>
      lang.startsWith('ar') ? maternalAr : maternalEn;
  String fruitFor(String lang) => lang.startsWith('ar') ? fruitAr : fruitEn;
}

/// Fruit/vegetable size comparison for each week.
String fruitForWeek(int week, String lang) {
  const fruit = <int, (String, String)>{
    4: (' Poppy seed', 'بذرة خشخاش'),
    5: (' Sesame seed', 'بذرة سمسم'),
    6: (' Lentil', 'عدسة'),
    7: (' Blueberry', 'توت بري'),
    8: (' Raspberry', 'توت أحمر'),
    9: (' Cherry', 'كرزة'),
    10: (' Strawberry', 'فراولة'),
    11: (' Lime', 'حبة ليمون'),
    12: (' Plum', 'حبة برقوق'),
    13: (' Pea pod', 'قرنة بازلاء'),
    14: (' Lemon', 'ليمونة'),
    15: (' Apple', 'تفاحة'),
    16: (' Avocado', 'أفوكادو'),
    17: (' Pear', 'كمثرى'),
    18: (' Bell pepper', 'فليفلة'),
    19: (' Mango', 'مانغو'),
    20: (' Banana', 'موزة'),
    21: (' Carrot', 'جزر'),
    22: (' Papaya', 'بابايا'),
    23: (' Grapefruit', 'جريب فروت'),
    24: (' Corn on the cob', 'ذرة'),
    25: (' Turnip', 'لفت'),
    26: (' Zucchini', 'كوسة'),
    27: (' Cauliflower', 'قرنبيط'),
    28: (' Eggplant', 'باذنجان'),
    29: (' Butternut squash', 'قرع'),
    30: (' Cucumber', 'خيار'),
    31: (' Coconut', 'جوز هند'),
    32: (' Pineapple', 'أناناس'),
    33: (' Honeydew melon', 'شمام'),
    34: (' Cantaloupe', 'بطيخ أصفر'),
    35: (' Watermelon', 'بطيخ'),
    36: (' Romaine lettuce', 'خس روماني'),
    37: (' Swiss chard', 'سلق'),
    38: (' Pumpkin', 'يقطين'),
    39: (' Small watermelon', 'بطيخ صغير'),
    40: (' Mini watermelon', 'بطيخ مصغر'),
  };
  final f = fruit[week.clamp(3, 40)];
  if (f == null) return '';
  return lang.startsWith('ar') ? f.$2 : f.$1;
}

class PregnancyDevelopmentContent {
  PregnancyDevelopmentContent._();

  /// Approximate length (cm) and weight (g) + development line per week.
  static const _weeks = <(int, double, int, String, String)>[
    (
      3,
      0.02,
      0,
      'Fertilization creates a zygote that divides as it travels toward the uterus.',
      'يحدث الإخصاب وتتكوّن اللاقحة، ثم تنقسم خلاياها في طريقها نحو الرحم.',
    ),
    (
      4,
      0.2,
      0,
      'The neural tube and early brain structure begin to form.',
      'يبدأ تشكّل الأنبوب العصبي وبنية الدماغ المبكرة.',
    ),
    (
      5,
      0.4,
      0,
      'The heart starts beating. The circulatory system develops.',
      'يبدأ القلب بالنبض. الجهاز الدوري يتطور.',
    ),
    (
      6,
      0.6,
      0,
      'Brain hemispheres appear. Facial features start to take shape.',
      'نصفي الدماغ يظهران. الملامح تبدأ بالتشكّل.',
    ),
    (
      7,
      1.0,
      1,
      'Arm and leg buds form. Brain growth accelerates.',
      'بدايات الذراعين والساقين تظهر. نمو الدماغ يتسارع.',
    ),
    (
      8,
      1.6,
      1,
      'Fingers and toes begin forming. A heartbeat is often seen on ultrasound.',
      'الأصابع تبدأ بالتشكّل. غالباً يظهر نبض القلب في السونار.',
    ),
    (
      9,
      2.3,
      2,
      'Eyelids develop. Major joints are forming.',
      'الجفون تتطور. المفاصل الرئيسية تتشكّل.',
    ),
    (
      10,
      3.1,
      4,
      'Vital organs continue maturing. Bones start to harden.',
      'الأعضاء الحيوية تستمر بالنضج. العظام تبدأ بالتصلّب.',
    ),
    (
      11,
      4.1,
      7,
      'Baby can open and close fists. Tooth buds appear.',
      'الجنين يحرّك قبضتيه. بدايات الأسنان تظهر.',
    ),
    (
      12,
      5.4,
      14,
      'Reflexes develop. The first trimester ends — organs are in place.',
      'المنعكسات تتطور. ينتهي الثلث الأول — الأعضاء في مكانها.',
    ),
    (
      13,
      7.4,
      23,
      'Vocal cords form. Intestines move into the abdomen.',
      'الحبال الصوتية تتشكّل. الأمعاء تنتقل إلى البطن.',
    ),
    (
      14,
      8.7,
      43,
      'Fine hair (lanugo) may appear. Kidneys produce urine.',
      'شعر ناعم (زغب) قد يظهر. الكلى تفرز البول.',
    ),
    (
      15,
      10.1,
      70,
      'Bones harden further. Baby can sense light.',
      'العظام تتصلّب أكثر. الجنين يستشعر الضوء.',
    ),
    (
      16,
      11.6,
      100,
      'Facial muscles work — baby may suck. You might feel first flutters.',
      'عضلات الوجه تعمل — قد يمص. قد تشعرين بأول رفرفات.',
    ),
    (
      17,
      13.0,
      140,
      'Fat stores begin. The skeleton continues to strengthen.',
      'يبدأ تخزين الدهون. الهيكل العظمي يقوى.',
    ),
    (
      18,
      14.2,
      190,
      'Ears stand out on the head. Baby hears your heartbeat.',
      'الأذنان بارزتان. الجنين يسمع نبض قلبكِ.',
    ),
    (
      19,
      15.3,
      240,
      'A waxy coating (vernix) protects the skin. Movements grow stronger.',
      'طبقة شمعية (Vernix) تحمي الجلد. الحركات تصبح أقوى.',
    ),
    (
      20,
      25.6,
      300,
      'Halfway point — anatomy scan week. Fingers, toes, and sex may be seen.',
      'منتصف الحمل — أسبوع السونار. الأصابع وربما الجنس يظهران.',
    ),
    (
      21,
      26.7,
      360,
      'Swallowing and taste develop. Bone marrow makes blood cells.',
      'البلع والتذوق يتطوران. نخاع العظم يصنع خلايا الدم.',
    ),
    (
      22,
      27.8,
      430,
      'Lips and eyelids are distinct. Sleep–wake cycles emerge.',
      'الشفاه والجفون واضحة. دورات النوم واليقظة تبدأ.',
    ),
    (
      23,
      28.8,
      501,
      'Lungs practice “breathing” fluid. Skin is still translucent.',
      'الرئتان تتمرّنان على «التنفس». الجلد لا يزال شفافاً.',
    ),
    (
      24,
      30.0,
      600,
      'Viability milestone — lungs mature with medical support if needed.',
      'محطة النضج — الرئتان تنضجان مع الدعم الطبي عند الحاجة.',
    ),
    (
      25,
      34.6,
      660,
      'Hands are fully formed. Hair colour and texture develop.',
      'اليدان مكتملتان. لون وملمس الشعر يتطوران.',
    ),
    (
      26,
      35.6,
      760,
      'Eyes open. Brain wave activity for hearing increases.',
      'العينان تفتحان. نشاط الدماغ للسمع يزداد.',
    ),
    (
      27,
      36.6,
      875,
      'Lungs, liver, and immune system still maturing. Movements feel stronger.',
      'الرئتان والكبد والمناعة لا تزال تنضج. الحركات أقوى.',
    ),
    (
      28,
      37.6,
      1005,
      'Third trimester begins. Baby can blink and dream (REM sleep).',
      'بداية الثلث الأخير. الجنين يرمش وقد يحلم (نوم REM).',
    ),
    (
      29,
      38.6,
      1153,
      'Muscles and lungs keep maturing. Kicks may feel sharper.',
      'العضلات والرئتان تنضجان. الركلات قد تكون أوضح.',
    ),
    (
      30,
      39.9,
      1319,
      'Bone marrow takes over red blood cell production.',
      'نخاع العظم يتولى إنتاج كريات الدم الحمراء.',
    ),
    (
      31,
      41.1,
      1502,
      'All five senses are active. Brain connections multiply rapidly.',
      'الحواس الخمس نشطة. وصلات الدماغ تتكاثر بسرعة.',
    ),
    (
      32,
      42.4,
      1702,
      'Toenails visible. Baby practices breathing movements.',
      'أظافر القدم ظاهرة. الجنين يتمرّن على التنفس.',
    ),
    (
      33,
      43.7,
      1918,
      'Skull bones firm but flexible for birth. Immune support from you continues.',
      'عظام الجمجمة صلبة لكن مرنة للولادة. دعم المناعة منكِ مستمر.',
    ),
    (
      34,
      45.0,
      2146,
      'Lungs near maturity. Central nervous system fine-tunes.',
      'الرئتان قرب النضج. الجهاز العصبي ينضج.',
    ),
    (
      35,
      46.2,
      2383,
      'Kidneys fully developed. Liver processes some waste.',
      'الكلى مكتملة. الكبد يعالج بعض الفضلات.',
    ),
    (
      36,
      47.4,
      2622,
      'Baby may drop head-down. Most systems are ready for life outside.',
      'قد يثبت الجنين رأسه للأسفل. معظم الأجهزة جاهزة.',
    ),
    (
      37,
      48.6,
      2859,
      'Early term — lungs and brain continue final tuning.',
      'مبكر النضج — الرئتان والدماغ ينضجان.',
    ),
    (
      38,
      49.8,
      3083,
      'Organs mature. Vernix and fine hair may shed.',
      'الأعضاء تنضج. الطبقة الشمعية والزغب قد يتساقطان.',
    ),
    (
      39,
      50.7,
      3288,
      'Full term approaches. Baby builds fat for warmth after birth.',
      'قرب النضج الكامل. الجنين يخزّن دهوناً للدفء بعد الولادة.',
    ),
    (
      40,
      51.2,
      3462,
      'Due week — baby is ready. Trust your body and your care team.',
      'أسبوع الولادة المتوقع — الجنين جاهز. ثقي بجسمكِ وفريق رعايتكِ.',
    ),
  ];

  static PregnancyWeekInfo _fromRow((int, double, int, String, String) row) {
    final w = row.$1;
    final f = fruitForWeek(w, 'en');
    final fAr = fruitForWeek(w, 'ar');
    return PregnancyWeekInfo(
      lengthCm: row.$2,
      weightGrams: row.$3,
      bodyEn: row.$4,
      bodyAr: row.$5,
      maternalEn: _trimesterMaternalEn(w),
      maternalAr: _trimesterMaternalAr(w),
      fruitEn: f,
      fruitAr: fAr,
    );
  }

  static String _trimesterMaternalEn(int week) {
    if (week <= 12) {
      return 'Fatigue, nausea, and tender breasts are common. Rest and small meals help.';
    }
    if (week <= 27) {
      return 'Energy often returns. Watch posture, hydration, and gentle movement.';
    }
    return 'Frequent bathroom trips, back pressure, and Braxton Hicks may appear. Pace yourself.';
  }

  static String _trimesterMaternalAr(int week) {
    if (week <= 12) {
      return 'التعب والغثيان وألم الثدي شائعة. الراحة والوجبات الصغيرة تساعد.';
    }
    if (week <= 27) {
      return 'الطاقة غالباً ترجع. انتبهي للوضعية والماء والحركة اللطيفة.';
    }
    return 'كثرة التبول وضغط الظهر وتقلصات براكستون قد تظهر. خذي راحتك.';
  }

  static PregnancyWeekInfo forWeek(int week, String lang) {
    final w = week.clamp(3, 40);
    for (var i = _weeks.length - 1; i >= 0; i--) {
      if (_weeks[i].$1 <= w) return _fromRow(_weeks[i]);
    }
    return _fromRow(_weeks.first);
  }

  static PregnancyWeekInfo? nextWeekPreview(int week) {
    if (week >= 40) return null;
    return forWeek(week + 1, 'en');
  }

  static int trimesterForWeek(int week) {
    if (week <= 12) return 1;
    if (week <= 27) return 2;
    return 3;
  }
}
