/// Rotating "question of the week" prompts per community topic.
///
/// Fully client-side: the shown question is derived from the ISO week number
/// and the community topic, so every member sees the same question during the
/// same week without any server state. An admin-managed override can be added
/// later via the community catalog.
library;

class WeeklyQuestion {
  const WeeklyQuestion({required this.en, required this.ar});

  final String en;
  final String ar;

  String forLocale(String languageCode) =>
      languageCode.startsWith('ar') ? ar : en;
}

const Map<String, List<WeeklyQuestion>> _questionsByTopic = {
  'general': [
    WeeklyQuestion(
      en: 'What is one self-care habit that actually helps you during your period?',
      ar: 'شو عادة العناية الذاتية اللي فعلاً بتساعدك أيام الدورة؟',
    ),
    WeeklyQuestion(
      en: 'How do you track your cycle — apps, notes, or intuition?',
      ar: 'كيف بتتابعي دورتك — تطبيقات، ملاحظات، ولا إحساس؟',
    ),
    WeeklyQuestion(
      en: 'What do you wish you had learned earlier about your cycle?',
      ar: 'شو الشي اللي يا ريتك تعلمتيه عن دورتك من زمان؟',
    ),
    WeeklyQuestion(
      en: 'Share one small win from this week — cycle-related or not!',
      ar: 'شاركينا إنجاز صغير من هالأسبوع — عن الدورة أو غيرها!',
    ),
  ],
  'conception': [
    WeeklyQuestion(
      en: 'What keeps you hopeful during the two-week wait?',
      ar: 'شو اللي بيخليكي متفائلة خلال فترة الانتظار؟',
    ),
    WeeklyQuestion(
      en: 'Which ovulation signs do you personally rely on the most?',
      ar: 'شو علامات التبويض اللي بتعتمدي عليها أكثر شي؟',
    ),
    WeeklyQuestion(
      en: 'How do you and your partner support each other on this journey?',
      ar: 'كيف بتدعموا بعض إنتي وشريكك بهالرحلة؟',
    ),
    WeeklyQuestion(
      en: 'What advice would you give someone just starting to try?',
      ar: 'شو نصيحتك لحدا لسا ببداية محاولات الحمل؟',
    ),
  ],
  'contraception': [
    WeeklyQuestion(
      en: 'What do you wish someone had told you before choosing your method?',
      ar: 'شو يا ريت حدا حكالك ياه قبل ما تختاري وسيلتك؟',
    ),
    WeeklyQuestion(
      en: 'How did you decide which contraception method fits your life?',
      ar: 'كيف قررتي أي وسيلة منع حمل بتناسب حياتك؟',
    ),
    WeeklyQuestion(
      en: 'Side effects: what helped you manage them?',
      ar: 'الآثار الجانبية: شو اللي ساعدك تتعاملي معها؟',
    ),
    WeeklyQuestion(
      en: 'Have you ever switched methods? What made you change?',
      ar: 'جربتي تغيري وسيلتك؟ شو السبب اللي خلاكي تغيري؟',
    ),
  ],
  'condition': [
    WeeklyQuestion(
      en: 'What daily habit makes the biggest difference for your symptoms?',
      ar: 'شو العادة اليومية اللي بتفرق أكثر شي مع أعراضك؟',
    ),
    WeeklyQuestion(
      en: 'How did you finally get your diagnosis? Share your story.',
      ar: 'كيف وصلتي أخيرًا للتشخيص؟ شاركينا قصتك.',
    ),
    WeeklyQuestion(
      en: 'What question do you wish you had asked your doctor sooner?',
      ar: 'شو السؤال اللي يا ريتك سألتيه لطبيبتك من زمان؟',
    ),
    WeeklyQuestion(
      en: 'What is one myth about your condition you want to bust?',
      ar: 'شو خرافة منتشرة عن حالتك بدك تصححيها؟',
    ),
  ],
  'support': [
    WeeklyQuestion(
      en: 'What is one kind thing you can do for yourself today?',
      ar: 'شو شي لطيف ممكن تعمليه لحالك اليوم؟',
    ),
    WeeklyQuestion(
      en: 'Who in your life truly understands what you are going through?',
      ar: 'مين بحياتك فعلاً بيفهم شو عم تمري فيه؟',
    ),
    WeeklyQuestion(
      en: 'What helps you on the hardest days? Share it — it might help someone.',
      ar: 'شو بيساعدك بأصعب الأيام؟ شاركينا — يمكن يساعد حدا غيرك.',
    ),
    WeeklyQuestion(
      en: 'Write a short message of encouragement to another member.',
      ar: 'اكتبي رسالة تشجيع قصيرة لعضوة ثانية.',
    ),
  ],
  'culture': [
    WeeklyQuestion(
      en: 'How is the period talked about (or not) in your family?',
      ar: 'كيف بيتم الحديث عن الدورة (أو ما بيتم) بعيلتك؟',
    ),
    WeeklyQuestion(
      en: 'What tradition or remedy did your mother or grandmother pass down?',
      ar: 'شو وصفة أو عادة ورثتيها عن إمك أو ستك؟',
    ),
    WeeklyQuestion(
      en: 'What would you change about how society treats women\'s health?',
      ar: 'شو بتغيري بطريقة تعامل المجتمع مع صحة المرأة؟',
    ),
    WeeklyQuestion(
      en: 'How do you handle fasting, prayer, or rituals during your period?',
      ar: 'كيف بتتعاملي مع الصيام والعبادات أيام الدورة؟',
    ),
  ],
  'age': [
    WeeklyQuestion(
      en: 'What do you wish adults had explained better when you were younger?',
      ar: 'شو يا ريت الكبار شرحوه أحسن لما كنتي أصغر؟',
    ),
    WeeklyQuestion(
      en: 'First period stories — funny, awkward, or sweet. Share yours!',
      ar: 'قصص أول دورة — مضحكة أو محرجة أو حلوة. شاركينا قصتك!',
    ),
    WeeklyQuestion(
      en: 'What is the best health advice you have received so far?',
      ar: 'شو أحلى نصيحة صحية وصلتك لهلأ؟',
    ),
    WeeklyQuestion(
      en: 'How do you balance studies/work with self-care during your cycle?',
      ar: 'كيف بتوازني بين الدراسة/الشغل والاهتمام بحالك أيام الدورة؟',
    ),
  ],
};

/// Deterministic string hash — stable across app runs and platforms
/// (unlike [String.hashCode]).
int _stableHash(String s) => s.codeUnits.fold(0, (acc, c) => acc + c);

/// The question every member of [topic] communities sees this week.
WeeklyQuestion weeklyQuestionFor(String topic, {DateTime? now}) {
  final list = _questionsByTopic[topic] ?? _questionsByTopic['general']!;
  final date = now ?? DateTime.now();
  final dayOfYear = date.difference(DateTime(date.year)).inDays;
  final week = dayOfYear ~/ 7;
  return list[(week + _stableHash(topic)) % list.length];
}
