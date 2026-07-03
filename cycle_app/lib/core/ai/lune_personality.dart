import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The three Lune AI personas the user can switch between.
///
/// Each persona changes the AI's tone, depth, and what it emphasizes — while
/// keeping the same safety rules and language matching.
enum LunePersonality {
  /// Warm, witty, casual best-friend tone — the default.
  friend('friend'),

  /// Calm, factual, evidence-informed clinical educator tone (NOT a doctor).
  doctor('doctor'),

  /// Energetic, motivational wellness coach — habits, streaks, momentum.
  coach('coach');

  const LunePersonality(this.id);

  final String id;

  static LunePersonality fromId(String? id) {
    return LunePersonality.values.firstWhere(
      (p) => p.id == id,
      orElse: () => LunePersonality.friend,
    );
  }
}

/// Visual + textual metadata for a persona.
class LunePersonalityMeta {
  const LunePersonalityMeta({
    required this.icon,
    required this.gradient,
    required this.titleEn,
    required this.titleAr,
    required this.tagEn,
    required this.tagAr,
  });

  final IconData icon;
  final List<Color> gradient;
  final String titleEn;
  final String titleAr;
  final String tagEn;
  final String tagAr;

  String title(String lang) => lang == 'ar' ? titleAr : titleEn;
  String tag(String lang) => lang == 'ar' ? tagAr : tagEn;
}

const Map<LunePersonality, LunePersonalityMeta> kLunePersonalityMeta = {
  LunePersonality.friend: LunePersonalityMeta(
    icon: Icons.favorite_rounded,
    gradient: [Color(0xFFEC6B9C), Color(0xFFF4A0B0)],
    titleEn: 'Friend',
    titleAr: 'صديقة',
    tagEn: 'Warm & casual',
    tagAr: 'دافئة وعفوية',
  ),
  LunePersonality.doctor: LunePersonalityMeta(
    icon: Icons.medical_services_rounded,
    gradient: [Color(0xFF6B7FE8), Color(0xFF8FA8F5)],
    titleEn: 'Wellness expert',
    titleAr: 'مرشدة صحية',
    tagEn: 'Factual & calm',
    tagAr: 'دقيقة وهادئة',
  ),
  LunePersonality.coach: LunePersonalityMeta(
    icon: Icons.bolt_rounded,
    gradient: [Color(0xFFE89B4F), Color(0xFFF4C26E)],
    titleEn: 'Coach',
    titleAr: 'محفّزة',
    tagEn: 'Energetic & focused',
    tagAr: 'حماسية ومحفّزة',
  ),
};

/// Persists and exposes the user's currently selected [LunePersonality].
class LunePersonalityPrefs {
  LunePersonalityPrefs._();

  static const _key = 'lune_personality_v1';

  /// In-memory cache so synchronous reads (system prompts) work without await.
  static LunePersonality _cached = LunePersonality.friend;

  /// Tracks the in-flight `load()` so `set()` can wait for it before writing
  /// to SharedPreferences — prevents a slow `load()` from clobbering a fresh
  /// `set()` (or vice versa) with stale disk data.
  static Future<void>? _pendingLoad;

  static LunePersonality get current => _cached;

  static Future<void> load() async {
    final future = _doLoad();
    _pendingLoad = future;
    try {
      await future;
    } finally {
      // Only clear if no newer load was queued.
      if (identical(_pendingLoad, future)) _pendingLoad = null;
    }
  }

  static Future<void> _doLoad() async {
    final sp = await SharedPreferences.getInstance();
    _cached = LunePersonality.fromId(sp.getString(_key));
  }

  static Future<void> set(LunePersonality p) async {
    // If a load() is still in flight, wait for it — otherwise the load could
    // finish *after* set() and overwrite _cached with stale disk data.
    final pending = _pendingLoad;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {
        // load() shouldn't throw, but don't let it block set() if it does.
      }
    }
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, p.id);
    _cached = p;
  }
}

/// Extra system-prompt instructions that get appended to the base prompt.
///
/// Keep these short — they refine TONE only. Safety, language-matching, and
/// response format remain owned by the base [AiPromptStyle].
class LunePersonalityPrompts {
  LunePersonalityPrompts._();

  static String forPersonality(LunePersonality p) {
    return switch (p) {
      LunePersonality.friend => _friend,
      LunePersonality.doctor => _doctor,
      LunePersonality.coach => _coach,
    };
  }

  static const _friend = '''
PERSONA OVERRIDE — Friend mode:
- Warm best-friend tone. Use light humor and emojis sparingly (1–2 max).
- Be casual, validating, and easy to read. Cheerlead without being fake.
- Prefer flowing sentences over bullet lists for chat.''';

  static const _doctor = '''
PERSONA OVERRIDE — Wellness Expert mode (NOT a licensed clinician):
- Calm, precise, evidence-informed tone — like a kind nurse-educator.
- Use clear medical/anatomical terms when relevant, but always explain them.
- Lean on structured short paragraphs; you MAY use small bullet lists for symptoms or steps.
- Avoid emojis. Be measured, never alarmist.
- Still: NEVER diagnose, NEVER prescribe doses. Recommend professional care for anything serious.''';

  static const _coach = '''
PERSONA OVERRIDE — Coach mode:
- Energetic, motivational, action-focused. Speak in second person ("you've got this").
- Always end with ONE concrete micro-action the user can do in the next 30 minutes.
- Celebrate small wins. Use 1 emoji for energy (🌟 ⚡️ 💪) — no more.
- Keep paragraphs short and punchy.''';
}
