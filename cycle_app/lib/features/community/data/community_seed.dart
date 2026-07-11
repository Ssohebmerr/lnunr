import 'package:flutter/material.dart';

import 'models/community.dart';

/// Curated small communities — metadata lives in-app; posts in Firestore.
class CommunitySeed {
  CommunitySeed._();

  static const defaultRulesEn =
      'Be kind and supportive. No medical advice, spam, or harassment. '
      'Use nicknames only — never share personal contact info.';
  static const defaultRulesAr =
      'كوني لطيفة وداعمة. لا نصائح طبية ولا إزعاج ولا مضايقة. '
      'استخدمي الأسماء المستعارة فقط — لا تشاركي بيانات التواصل.';

  static const List<Community> defaults = [
    Community(
      id: 'general-cycle',
      nameEn: 'General Cycle Chat',
      nameAr: 'دردشة الدورة العامة',
      descriptionEn:
          'Share experiences, tips, and support for everyday cycle tracking.',
      descriptionAr: 'شاركي تجاربك ونصائحك وادعمي غيرك في تتبع الدورة اليومي.',
      topic: 'general',
      icon: Icons.chat_bubble_outline,
      maxMembers: 200,
    ),
    Community(
      id: 'trying-to-conceive',
      nameEn: 'Trying to Conceive',
      nameAr: 'محاولة الحمل',
      descriptionEn:
          'A safe space for fertility journeys, ovulation tips, and hope.',
      descriptionAr: 'مساحة آمنة لرحلات الخصوبة ونصائح الإباضة والأمل.',
      topic: 'conception',
      icon: Icons.favorite_outline,
      maxMembers: 150,
    ),
    Community(
      id: 'contraception',
      nameEn: 'Birth Control & Contraception',
      nameAr: 'منع الحمل',
      descriptionEn:
          'Discuss pills, LARC, and contraception experiences (not medical advice).',
      descriptionAr: 'ناقشي الحبوب ووسائل منع الحمل (ليست نصيحة طبية).',
      topic: 'contraception',
      icon: Icons.medication_outlined,
      maxMembers: 150,
    ),
    Community(
      id: 'pcos',
      nameEn: 'PCOS Support',
      nameAr: 'دعم PCOS',
      descriptionEn:
          'Connect with others managing PCOS symptoms and lifestyle changes.',
      descriptionAr: 'تواصلي مع من يعيشون PCOS وتغييرات نمط الحياة.',
      topic: 'condition',
      icon: Icons.healing_outlined,
      maxMembers: 200,
    ),
    Community(
      id: 'endometriosis',
      nameEn: 'Endometriosis Circle',
      nameAr: 'دائرة بطانة الرحم المهاجرة',
      descriptionEn:
          'Peer support for endometriosis pain, diagnosis journeys, and self-care.',
      descriptionAr:
          'دعم جماعي لآلام بطانة الرحم المهاجرة ورحلات التشخيص والعناية الذاتية.',
      topic: 'condition',
      icon: Icons.spa_outlined,
      maxMembers: 200,
    ),
    Community(
      id: 'period-support',
      nameEn: 'Period Day Support',
      nameAr: 'دعم أيام الدورة',
      descriptionEn:
          'Short posts and encouragement during period days — you are not alone.',
      descriptionAr: 'منشورات قصيرة وتشجيع في أيام الدورة — لستِ وحدك.',
      topic: 'support',
      icon: Icons.water_drop_outlined,
      maxMembers: 100,
    ),
    Community(
      id: 'wellness-ar',
      nameEn: 'Arabic Wellness Circle',
      nameAr: 'مجتمع العافية العربي',
      descriptionEn:
          'Arabic-first community for cycle wellness, culture, and sisterhood.',
      descriptionAr: 'مجتمع عربي للعافية والدورة والأخوة النسائية.',
      topic: 'culture',
      icon: Icons.language_outlined,
      maxMembers: 200,
    ),
    Community(
      id: 'young-adults',
      nameEn: 'Young Adults (18–25)',
      nameAr: 'شابات (18–25)',
      descriptionEn:
          'Questions and support for young adults learning about their cycles.',
      descriptionAr: 'أسئلة ودعم للشابات اللواتي يتعلمن عن دورتهن.',
      topic: 'age',
      icon: Icons.school_outlined,
      maxMembers: 100,
    ),
    Community(
      id: 'mental-wellness',
      nameEn: 'Mental Wellness & Mood',
      nameAr: 'الصحة النفسية والمزاج',
      descriptionEn:
          'Talk about PMS mood, anxiety, and emotional self-care during your cycle.',
      descriptionAr: 'ناقشي مزاج ما قبل الدورة والقلق والعناية النفسية خلال دورتك.',
      topic: 'support',
      icon: Icons.psychology_outlined,
      maxMembers: 200,
    ),
    Community(
      id: 'postpartum',
      nameEn: 'Postpartum & Recovery',
      nameAr: 'ما بعد الولادة والتعافي',
      descriptionEn:
          'Support for cycles returning after birth, breastfeeding, and recovery.',
      descriptionAr: 'دعم لعودة الدورة بعد الولادة والرضاعة والتعافي.',
      topic: 'support',
      icon: Icons.child_care_outlined,
      maxMembers: 150,
    ),
    Community(
      id: 'fitness-cycle',
      nameEn: 'Fitness & Your Cycle',
      nameAr: 'الرياضة ودورتك',
      descriptionEn:
          'Exercise tips aligned with cycle phases — train with your body.',
      descriptionAr: 'نصائح رياضية متوافقة مع مراحل الدورة — تمرّني مع جسمك.',
      topic: 'general',
      icon: Icons.fitness_center_outlined,
      maxMembers: 150,
    ),
    Community(
      id: 'menopause-support',
      nameEn: 'Menopause & Perimenopause',
      nameAr: 'سن الأمل وانقطاع الطمث',
      descriptionEn:
          'Support and stories for navigating menopause and perimenopause.',
      descriptionAr: 'الدعم والقصص للتعامل مع مرحلة ما قبل وانقطاع الطمث.',
      topic: 'condition',
      icon: Icons.wb_sunny_outlined,
      maxMembers: 150,
    ),
    Community(
      id: 'pms-pmdd-support',
      nameEn: 'PMS & PMDD Support',
      nameAr: 'دعم PMS و PMDD',
      descriptionEn:
          'A dedicated hub for sharing experiences and managing severe cycle mood swings.',
      descriptionAr: 'ملتقى مخصص لمشاركة التجارب والتعامل مع تقلبات المزاج الحادة.',
      topic: 'condition',
      icon: Icons.mood_bad_outlined,
      maxMembers: 200,
    ),
    Community(
      id: 'lifestyle-wellness',
      nameEn: 'Lifestyle & Nutrition',
      nameAr: 'نمط الحياة والتغذية',
      descriptionEn:
          'Diet, workouts, and lifestyle tweaks to balance your hormones.',
      descriptionAr: 'التغذية والرياضة وتعديلات نمط الحياة لتوازن الهرمونات.',
      topic: 'general',
      icon: Icons.restaurant_menu_outlined,
      maxMembers: 250,
    ),
    Community(
      id: 'pregnancy-support',
      nameEn: 'Pregnancy & Expecting',
      nameAr: 'الحمل والانتظار',
      descriptionEn:
          'Share the journey week by week — symptoms, questions, and joy.',
      descriptionAr: 'شاركي رحلة الحمل أسبوعاً بأسبوع — الأعراض والأسئلة والفرح.',
      topic: 'support',
      icon: Icons.child_friendly_outlined,
      maxMembers: 200,
    ),
    Community(
      id: 'irregular-periods',
      nameEn: 'Irregular & Missed Periods',
      nameAr: 'الدورة غير المنتظمة والمتأخرة',
      descriptionEn:
          'Support for late, missing, or unpredictable cycles — you are not alone.',
      descriptionAr: 'دعم للدورة المتأخرة أو الغائبة أو غير المتوقعة — لستِ وحدك.',
      topic: 'condition',
      icon: Icons.event_busy_outlined,
      maxMembers: 200,
    ),
    Community(
      id: 'sleep-cycle',
      nameEn: 'Sleep & Your Cycle',
      nameAr: 'النوم ودورتك',
      descriptionEn:
          'Tips and support for cycle-related insomnia, fatigue, and rest.',
      descriptionAr: 'نصائح ودعم للأرق والتعب المرتبط بالدورة والراحة.',
      topic: 'general',
      icon: Icons.bedtime_outlined,
      maxMembers: 150,
    ),
    Community(
      id: 'cycle-syncing',
      nameEn: 'Cycle Syncing & Productivity',
      nameAr: 'مزامنة الدورة والإنتاجية',
      descriptionEn:
          'Plan work, energy, and self-care around your cycle phases.',
      descriptionAr: 'خطّطي لعملك وطاقتك وعنايتك بنفسك حسب مراحل دورتك.',
      topic: 'general',
      icon: Icons.calendar_month_outlined,
      maxMembers: 200,
    ),
    Community(
      id: 'thyroid-hormones',
      nameEn: 'Thyroid & Hormonal Health',
      nameAr: 'الغدة الدرقية وصحة الهرمونات',
      descriptionEn:
          'Peer support for thyroid and hormone imbalances that affect cycles.',
      descriptionAr: 'دعم جماعي لاضطرابات الغدة والهرمونات التي تؤثر على الدورة.',
      topic: 'condition',
      icon: Icons.healing_outlined,
      maxMembers: 150,
    ),
    Community(
      id: 'fibroids-support',
      nameEn: 'Fibroids Support',
      nameAr: 'دعم الأورام الليفية',
      descriptionEn:
          'Share experiences with fibroids — symptoms, care, and questions.',
      descriptionAr: 'شاركي تجاربك مع الأورام الليفية — الأعراض والعناية والأسئلة.',
      topic: 'condition',
      icon: Icons.spa_outlined,
      maxMembers: 150,
    ),
  ];

  static List<Community> filterByTopic(String? topic) {
    if (topic == null || topic == 'all') return defaults;
    return defaults.where((c) => c.topic == topic).toList();
  }

  static List<Community> search(String query, String lang) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return defaults;
    return defaults.where((c) {
      final name = c.nameForLocale(lang).toLowerCase();
      final desc = c.descriptionForLocale(lang).toLowerCase();
      return name.contains(q) || desc.contains(q) || c.topic.contains(q);
    }).toList();
  }

  static Community? byId(String id) {
    for (final c in defaults) {
      if (c.id == id) return c;
    }
    return null;
  }
}
