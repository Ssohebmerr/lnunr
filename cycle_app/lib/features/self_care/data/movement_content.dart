// Gentle, phase-aware movement routines — a real guided screen that replaces
// the old "stretch" tip snackbar. Nothing strenuous: slow stretches and
// mobility that respect where the body is in the cycle.

class MovementStep {
  const MovementStep({
    required this.en,
    required this.ar,
    required this.seconds,
    required this.cueEn,
    required this.cueAr,
  });

  final String en;
  final String ar;
  final int seconds;

  /// A short breathing/form cue shown under the step name.
  final String cueEn;
  final String cueAr;

  String name(String lang) => lang.startsWith('ar') ? ar : en;
  String cue(String lang) => lang.startsWith('ar') ? cueAr : cueEn;
}

class MovementRoutine {
  const MovementRoutine({
    required this.key,
    required this.en,
    required this.ar,
    required this.subtitleEn,
    required this.subtitleAr,
    required this.steps,
  });

  final String key;
  final String en;
  final String ar;
  final String subtitleEn;
  final String subtitleAr;
  final List<MovementStep> steps;

  String title(String lang) => lang.startsWith('ar') ? ar : en;
  String subtitle(String lang) => lang.startsWith('ar') ? subtitleAr : subtitleEn;

  int get totalSeconds => steps.fold(0, (sum, s) => sum + s.seconds);
}

class MovementContent {
  MovementContent._();

  static const _restful = MovementRoutine(
    key: 'menstrual',
    en: 'Restful release',
    ar: 'استرخاء وراحة',
    subtitleEn: 'Soft stretches to ease cramps during your period.',
    subtitleAr: 'تمددات لطيفة لتخفيف التشنّجات أثناء الدورة.',
    steps: [
      MovementStep(
        en: 'Child\'s pose',
        ar: 'وضعية الطفل',
        seconds: 45,
        cueEn: 'Knees wide, forehead down, breathe into your lower back.',
        cueAr: 'الركبتان متباعدتان، الجبين للأسفل، تنفّسي نحو أسفل الظهر.',
      ),
      MovementStep(
        en: 'Reclined twist (right)',
        ar: 'التواء مستلقٍ (يمين)',
        seconds: 30,
        cueEn: 'Drop knees to the right, gaze left, soften the belly.',
        cueAr: 'أنزلي الركبتين لليمين، انظري لليسار، أرخي البطن.',
      ),
      MovementStep(
        en: 'Reclined twist (left)',
        ar: 'التواء مستلقٍ (يسار)',
        seconds: 30,
        cueEn: 'Drop knees to the left, gaze right, breathe slowly.',
        cueAr: 'أنزلي الركبتين لليسار، انظري لليمين، تنفّسي ببطء.',
      ),
      MovementStep(
        en: 'Knees to chest',
        ar: 'الركبتان للصدر',
        seconds: 30,
        cueEn: 'Hug knees in, rock gently side to side.',
        cueAr: 'احتضني ركبتيك، تمايلي بلطف يميناً ويساراً.',
      ),
      MovementStep(
        en: 'Legs up rest',
        ar: 'راحة الساقين للأعلى',
        seconds: 60,
        cueEn: 'Rest legs up a wall, hands on belly, let go.',
        cueAr: 'ارفعي ساقيك على الحائط، يداك على البطن، استرخي.',
      ),
    ],
  );

  static const _energize = MovementRoutine(
    key: 'follicular',
    en: 'Rising energy flow',
    ar: 'تدفّق الطاقة الصاعدة',
    subtitleEn: 'Wake the body up as your energy climbs.',
    subtitleAr: 'أيقظي جسدك مع تصاعد طاقتك.',
    steps: [
      MovementStep(
        en: 'Cat–cow',
        ar: 'القطة والبقرة',
        seconds: 40,
        cueEn: 'Flow between arch and round with each breath.',
        cueAr: 'تنقّلي بين التقوّس والاستدارة مع كل نفس.',
      ),
      MovementStep(
        en: 'Standing side reach',
        ar: 'مدّ جانبي واقف',
        seconds: 30,
        cueEn: 'Reach up and over to each side, feel the ribs open.',
        cueAr: 'مدّي ذراعك للأعلى وللجانب، اشعري بانفتاح الأضلاع.',
      ),
      MovementStep(
        en: 'Low lunge (right)',
        ar: 'اندفاع منخفض (يمين)',
        seconds: 35,
        cueEn: 'Sink hips forward, lift the chest, breathe wide.',
        cueAr: 'ادفعي الورك للأمام، ارفعي الصدر، تنفّسي بعمق.',
      ),
      MovementStep(
        en: 'Low lunge (left)',
        ar: 'اندفاع منخفض (يسار)',
        seconds: 35,
        cueEn: 'Switch sides, keep the front knee over the ankle.',
        cueAr: 'بدّلي الجهة، أبقي الركبة الأمامية فوق الكاحل.',
      ),
      MovementStep(
        en: 'Forward fold sway',
        ar: 'انحناء أمامي متمايل',
        seconds: 30,
        cueEn: 'Hang loose, sway gently, release the neck.',
        cueAr: 'تدلّي بارتخاء، تمايلي بلطف، أرخي الرقبة.',
      ),
    ],
  );

  static const _glow = MovementRoutine(
    key: 'ovulation',
    en: 'Open & glow',
    ar: 'انفتاح وإشراق',
    subtitleEn: 'Confident, open movement for your peak-energy days.',
    subtitleAr: 'حركة واثقة ومنفتحة لأيام ذروة طاقتك.',
    steps: [
      MovementStep(
        en: 'Heart opener',
        ar: 'فتح الصدر',
        seconds: 35,
        cueEn: 'Interlace hands behind you, lift the chest.',
        cueAr: 'اشبكي يديك خلفك، ارفعي الصدر.',
      ),
      MovementStep(
        en: 'Standing figure-4 (right)',
        ar: 'وضعية الرقم 4 واقفة (يمين)',
        seconds: 30,
        cueEn: 'Cross ankle over knee, sit back gently for balance.',
        cueAr: 'ضعي الكاحل فوق الركبة، اجلسي للخلف بلطف للتوازن.',
      ),
      MovementStep(
        en: 'Standing figure-4 (left)',
        ar: 'وضعية الرقم 4 واقفة (يسار)',
        seconds: 30,
        cueEn: 'Switch sides, keep breathing steady.',
        cueAr: 'بدّلي الجهة، حافظي على تنفّس ثابت.',
      ),
      MovementStep(
        en: 'Hip circles',
        ar: 'دوائر الورك',
        seconds: 30,
        cueEn: 'Slow circles each way, loosen the hips.',
        cueAr: 'دوائر بطيئة بالاتجاهين، أرخي الوركين.',
      ),
      MovementStep(
        en: 'Tall mountain breath',
        ar: 'نفَس الجبل الشامخ',
        seconds: 30,
        cueEn: 'Stand tall, sweep arms up on the inhale.',
        cueAr: 'قفي بشموخ، ارفعي ذراعيك مع الشهيق.',
      ),
    ],
  );

  static const _soothe = MovementRoutine(
    key: 'luteal',
    en: 'Wind-down & soothe',
    ar: 'تهدئة واسترخاء',
    subtitleEn: 'Calming stretches for the tender pre-period days.',
    subtitleAr: 'تمددات مهدّئة لأيام ما قبل الدورة الحسّاسة.',
    steps: [
      MovementStep(
        en: 'Seated forward fold',
        ar: 'انحناء أمامي جالس',
        seconds: 40,
        cueEn: 'Fold softly over the legs, let the head hang.',
        cueAr: 'انحني بلطف فوق ساقيك، دعي رأسك يتدلّى.',
      ),
      MovementStep(
        en: 'Butterfly',
        ar: 'الفراشة',
        seconds: 40,
        cueEn: 'Soles together, gently bounce or hold and breathe.',
        cueAr: 'باطن القدمين معاً، تمايلي بلطف أو اثبتي وتنفّسي.',
      ),
      MovementStep(
        en: 'Neck & shoulder rolls',
        ar: 'تدوير الرقبة والكتف',
        seconds: 30,
        cueEn: 'Slow rolls to release built-up tension.',
        cueAr: 'تدوير بطيء لتحرير التوتّر المتراكم.',
      ),
      MovementStep(
        en: 'Supported bridge',
        ar: 'الجسر المدعوم',
        seconds: 40,
        cueEn: 'Lift hips onto a cushion, rest and breathe.',
        cueAr: 'ارفعي الورك على وسادة، استريحي وتنفّسي.',
      ),
      MovementStep(
        en: 'Savasana rest',
        ar: 'استرخاء تام',
        seconds: 60,
        cueEn: 'Lie still, soften everything, let the body sink.',
        cueAr: 'استلقي بسكون، أرخي كل شيء، دعي جسدك يغرق في الراحة.',
      ),
    ],
  );

  static const all = <MovementRoutine>[_restful, _energize, _glow, _soothe];

  /// Picks the routine that best fits the current cycle phase.
  static MovementRoutine forPhase(String? phase) {
    final p = (phase ?? '').toLowerCase();
    if (p.contains('menstr') || p.contains('period') || p.contains('حيض') || p.contains('دور')) {
      return _restful;
    }
    if (p.contains('follicular') || p.contains('جريبي') || p.contains('بصيلي') || p.contains('نمو')) {
      return _energize;
    }
    if (p.contains('ovul') || p.contains('fertil') || p.contains('إباض') || p.contains('تبويض') || p.contains('خصوب')) {
      return _glow;
    }
    if (p.contains('luteal') || p.contains('أصفر') || p.contains('لوتي') || p.contains('بعد الإباض')) {
      return _soothe;
    }
    return _soothe;
  }
}
