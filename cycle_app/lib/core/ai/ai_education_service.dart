import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../privacy/consent_manager.dart';
import '../premium/premium_gate.dart';
import 'ai_context_engine.dart';
import 'ai_gateway.dart';
import 'models/health_snapshot.dart';
import 'prepared_education_content.dart';

/// AI-powered education service that provides personalized content
/// based on the user's cycle phase and questions.
/// Uses a hybrid approach: prepared content + AI generation + caching.
class AiEducationService {
  AiEducationService({
    required AiContextEngine contextEngine,
    required AiGateway gateway,
  })  : _engine = contextEngine,
        _gateway = gateway;

  final AiContextEngine _engine;
  final AiGateway _gateway;

  static const _cachePrefix = 'ai_edu_cache_';
  static const _cacheExpiry = Duration(hours: 24);

  /// Gets educational content based on user's question.
  /// First checks prepared content, then falls back to AI generation.
  Future<String?> getPersonalizedContent({
    required String question,
    String languageCode = 'ar',
  }) async {
    // 1. Check cache first
    final cached = await _getCachedResponse(question, languageCode);
    if (cached != null) return cached;

    // 2. Check prepared content
    final prepared = _searchPreparedContent(question, languageCode);
    if (prepared != null) {
      await _cacheResponse(question, prepared, languageCode);
      return prepared;
    }

    // 3. Fall back to AI generation
    if (!await ConsentManager.hasAiConsent()) return null;
    if (!await PremiumGate.hasPremium()) return null;

    final snapshot = await _engine.buildSnapshot();
    if (snapshot.isEmpty) return null;

    final language = languageCode == 'ar' ? 'Arabic' : 'English';
    final prompt = _buildEducationPrompt(question, snapshot, language);

    final reply = await _gateway.request(
      message: prompt,
      context: snapshot.toPromptMap(),
      analyzeMode: true,
    );

    if (reply != null && reply.trim().isNotEmpty) {
      final response = reply.trim();
      await _cacheResponse(question, response, languageCode);
      return response;
    }

    return null;
  }

  /// Gets educational content based on user's current phase.
  Future<String?> getPhaseEducation({
    String languageCode = 'ar',
  }) async {
    final snapshot = await _engine.buildSnapshot();
    if (snapshot.isEmpty) return null;

    // Check prepared content for phase education
    final phaseKey = _getPhaseKey(snapshot.currentPhase);
    final prepared = _searchPreparedContent(phaseKey, languageCode);
    if (prepared != null) return prepared;

    // Fall back to AI
    if (!await ConsentManager.hasAiConsent()) return null;
    if (!await PremiumGate.hasPremium()) return null;

    final language = languageCode == 'ar' ? 'Arabic' : 'English';
    final prompt = _buildPhaseEducationPrompt(snapshot, language);

    final reply = await _gateway.request(
      message: prompt,
      context: snapshot.toPromptMap(),
      analyzeMode: true,
    );
    return (reply == null || reply.trim().isEmpty) ? null : reply.trim();
  }

  /// Gets educational content about pregnancy tracking.
  Future<String?> getPregnancyEducation({
    String languageCode = 'ar',
  }) async {
    // Check prepared content for pregnancy
    final prepared = _searchPreparedContent('حمل', languageCode);
    if (prepared != null) return prepared;

    // Fall back to AI
    if (!await ConsentManager.hasAiConsent()) return null;
    if (!await PremiumGate.hasPremium()) return null;

    final snapshot = await _engine.buildSnapshot();
    if (snapshot.isEmpty) return null;

    final language = languageCode == 'ar' ? 'Arabic' : 'English';
    final prompt = _buildPregnancyEducationPrompt(snapshot, language);

    final reply = await _gateway.request(
      message: prompt,
      context: snapshot.toPromptMap(),
      analyzeMode: true,
    );
    return (reply == null || reply.trim().isEmpty) ? null : reply.trim();
  }

  /// Searches prepared content by query
  String? _searchPreparedContent(String query, String language) {
    final results = PreparedEducationContent.search(query, language: language);
    if (results.isEmpty) return null;

    // Return the first matching result's body
    return results.first['body'];
  }

  /// Gets phase key for searching prepared content
  String _getPhaseKey(String? phase) {
    if (phase == null) return 'دورة';

    final phaseLower = phase.toLowerCase();
    if (phaseLower.contains('menstrual') || phaseLower.contains('حيض')) {
      return 'دورة';
    } else if (phaseLower.contains('follicular') || phaseLower.contains('جريبي')) {
      return 'مراحل';
    } else if (phaseLower.contains('ovulation') || phaseLower.contains('إباض')) {
      return 'إباضة';
    } else if (phaseLower.contains('luteal') || phaseLower.contains('أصفار')) {
      return 'مراحل';
    }
    return 'دورة';
  }

  /// Gets cached response if available and not expired
  Future<String?> _getCachedResponse(String question, String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + _hashKey(question, language);
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final data = jsonDecode(cachedData) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);

        if (DateTime.now().difference(timestamp) < _cacheExpiry) {
          return data['response'] as String;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Caches a response
  Future<void> _cacheResponse(String question, String response, String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + _hashKey(question, language);
      final data = {
        'question': question,
        'response': response,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(cacheKey, jsonEncode(data));
    } catch (_) {}
  }

  /// Creates a hash key for caching
  String _hashKey(String question, String language) {
    final combined = '$question:$language';
    return combined.hashCode.toRadixString(16);
  }

  String _buildEducationPrompt(String question, HealthSnapshot s, String lang) {
    return 'Respond in $lang. You are a warm, supportive menstrual cycle wellness educator. '
        'The user is asking: "$question"\n\n'
        'Current cycle state:\n'
        '- Phase: ${s.currentPhase ?? 'unknown'}\n'
        '- Cycle day: ${s.currentCycleDay ?? '?'}\n'
        '- Cycle length: ${s.cycleLength ?? '?'} days\n'
        '- Period duration: ${s.periodDuration ?? '?'} days\n'
        '- Recent symptoms: ${s.recentSymptoms}\n'
        '- Average pain: ${s.averagePainLevel ?? 'no data'}\n'
        '- Wellness hub: ${s.wellnessHub}\n\n'
        'RULES:\n'
        '- Provide comprehensive, educational content about the topic\n'
        '- Use simple, easy-to-understand language\n'
        '- Include practical tips when relevant\n'
        '- Always recommend consulting a healthcare provider for medical concerns\n'
        '- NEVER diagnose conditions or prescribe medication\n'
        '- Be warm, supportive, and encouraging\n'
        '- Use the user\'s cycle data to personalize the content\n'
        '- Keep the response detailed but not overwhelming (5-8 sentences)';
  }

  String _buildPhaseEducationPrompt(HealthSnapshot s, String lang) {
    return 'Respond in $lang. You are a warm, supportive menstrual cycle wellness educator. '
        'Provide comprehensive educational content about the user\'s current cycle phase.\n\n'
        'Current cycle state:\n'
        '- Phase: ${s.currentPhase ?? 'unknown'}\n'
        '- Cycle day: ${s.currentCycleDay ?? '?'}\n'
        '- Cycle length: ${s.cycleLength ?? '?'} days\n'
        '- Period duration: ${s.periodDuration ?? '?'} days\n'
        '- Recent symptoms: ${s.recentSymptoms}\n'
        '- Average pain: ${s.averagePainLevel ?? 'no data'}\n'
        '- Wellness hub: ${s.wellnessHub}\n\n'
        'Include in your response:\n'
        '1. What phase they are in and what it means\n'
        '2. What hormones are doing right now\n'
        '3. What to expect in the coming days\n'
        '4. Nutrition tips for this phase\n'
        '5. Exercise recommendations\n'
        '6. Self-care suggestions\n'
        '7. When to see a doctor if needed\n\n'
        'RULES:\n'
        '- Use simple, easy-to-understand language\n'
        '- Be warm, supportive, and encouraging\n'
        '- Never diagnose or prescribe\n'
        '- Keep the response comprehensive but not overwhelming (6-10 sentences)';
  }

  String _buildPregnancyEducationPrompt(HealthSnapshot s, String lang) {
    return 'Respond in $lang. You are a warm, supportive menstrual cycle wellness educator. '
        'Provide comprehensive educational content about pregnancy tracking and fertility.\n\n'
        'Current cycle state:\n'
        '- Phase: ${s.currentPhase ?? 'unknown'}\n'
        '- Cycle day: ${s.currentCycleDay ?? '?'}\n'
        '- Cycle length: ${s.cycleLength ?? '?'} days\n'
        '- Period duration: ${s.periodDuration ?? '?'} days\n'
        '- Ovulation date: ${s.ovulationDate ?? 'unknown'}\n'
        '- Pregnancy chances: ${s.pregnancyChances ?? 'unknown'}\n'
        '- Recent symptoms: ${s.recentSymptoms}\n'
        '- Wellness hub: ${s.wellnessHub}\n\n'
        'Include in your response:\n'
        '1. Understanding fertility window and ovulation\n'
        '2. Signs to look for during fertile window\n'
        '3. How to track ovulation effectively\n'
        '4. Nutrition for fertility and early pregnancy\n'
        '5. Lifestyle tips for conception\n'
        '6. When to take a pregnancy test\n'
        '7. When to see a doctor\n\n'
        'RULES:\n'
        '- Use simple, easy-to-understand language\n'
        '- Be warm, supportive, and encouraging\n'
        '- Never diagnose or prescribe\n'
        '- Always recommend consulting a healthcare provider\n'
        '- Keep the response comprehensive but not overwhelming (6-10 sentences)';
  }
}
