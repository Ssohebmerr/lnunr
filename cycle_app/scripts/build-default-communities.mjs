import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const out = join(__dirname, '../public/admin/default-communities.json');

const communities = [
  { id: 'general-cycle', nameEn: 'General Cycle Chat', nameAr: 'دردشة الدورة العامة', descriptionEn: 'Share experiences, tips, and support for everyday cycle tracking.', descriptionAr: 'شاركي تجاربك ونصائحك وادعمي غيرك في تتبع الدورة اليومي.', topic: 'general', iconName: 'chat_bubble_outline', maxMembers: 200, order: 1 },
  { id: 'trying-to-conceive', nameEn: 'Trying to Conceive', nameAr: 'محاولة الحمل', descriptionEn: 'A safe space for fertility journeys, ovulation tips, and hope.', descriptionAr: 'مساحة آمنة لرحلات الخصوبة ونصائح الإباضة والأمل.', topic: 'conception', iconName: 'favorite_outline', maxMembers: 150, order: 2 },
  { id: 'contraception', nameEn: 'Birth Control & Contraception', nameAr: 'منع الحمل', descriptionEn: 'Discuss pills, LARC, and contraception experiences (not medical advice).', descriptionAr: 'ناقشي الحبوب ووسائل منع الحمل (ليست نصيحة طبية).', topic: 'contraception', iconName: 'medication_outlined', maxMembers: 150, order: 3 },
  { id: 'pcos', nameEn: 'PCOS Support', nameAr: 'دعم PCOS', descriptionEn: 'Connect with others managing PCOS symptoms and lifestyle changes.', descriptionAr: 'تواصلي مع من يعيشون PCOS وتغييرات نمط الحياة.', topic: 'condition', iconName: 'healing_outlined', maxMembers: 200, order: 4 },
  { id: 'endometriosis', nameEn: 'Endometriosis Circle', nameAr: 'دائرة بطانة الرحم المهاجرة', descriptionEn: 'Peer support for endometriosis pain, diagnosis journeys, and self-care.', descriptionAr: 'دعم جماعي لآلام بطانة الرحم المهاجرة ورحلات التشخيص والعناية الذاتية.', topic: 'condition', iconName: 'spa_outlined', maxMembers: 200, order: 5 },
  { id: 'period-support', nameEn: 'Period Day Support', nameAr: 'دعم أيام الدورة', descriptionEn: 'Short posts and encouragement during period days — you are not alone.', descriptionAr: 'منشورات قصيرة وتشجيع في أيام الدورة — لستِ وحدك.', topic: 'support', iconName: 'water_drop_outlined', maxMembers: 100, order: 6 },
  { id: 'wellness-ar', nameEn: 'Arabic Wellness Circle', nameAr: 'مجتمع العافية العربي', descriptionEn: 'Arabic-first community for cycle wellness, culture, and sisterhood.', descriptionAr: 'مجتمع عربي للعافية والدورة والأخوة النسائية.', topic: 'culture', iconName: 'language_outlined', maxMembers: 200, order: 7 },
  { id: 'young-adults', nameEn: 'Young Adults (18–25)', nameAr: 'شابات (18–25)', descriptionEn: 'Questions and support for young adults learning about their cycles.', descriptionAr: 'أسئلة ودعم للشابات اللواتي يتعلمن عن دورتهن.', topic: 'age', iconName: 'school_outlined', maxMembers: 100, order: 8 },
  { id: 'mental-wellness', nameEn: 'Mental Wellness & Mood', nameAr: 'الصحة النفسية والمزاج', descriptionEn: 'Talk about PMS mood, anxiety, and emotional self-care during your cycle.', descriptionAr: 'ناقشي مزاج ما قبل الدورة والقلق والعناية النفسية خلال دورتك.', topic: 'support', iconName: 'psychology_outlined', maxMembers: 200, order: 9 },
  { id: 'postpartum', nameEn: 'Postpartum & Recovery', nameAr: 'ما بعد الولادة والتعافي', descriptionEn: 'Support for cycles returning after birth, breastfeeding, and recovery.', descriptionAr: 'دعم لعودة الدورة بعد الولادة والرضاعة والتعافي.', topic: 'support', iconName: 'child_care_outlined', maxMembers: 150, order: 10 },
  { id: 'fitness-cycle', nameEn: 'Fitness & Your Cycle', nameAr: 'الرياضة ودورتك', descriptionEn: 'Exercise tips aligned with cycle phases — train with your body.', descriptionAr: 'نصائح رياضية متوافقة مع مراحل الدورة — تمرّني مع جسمك.', topic: 'general', iconName: 'fitness_center_outlined', maxMembers: 150, order: 11 },
];

writeFileSync(out, JSON.stringify(communities, null, 2), 'utf8');
console.log(`Wrote ${communities.length} communities`);
