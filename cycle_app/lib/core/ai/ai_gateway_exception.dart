/// Thrown when the Cloud Function rejects an AI request.
class AiGatewayException implements Exception {
  const AiGatewayException(this.code, {this.message});

  final String code;
  final String? message;

  bool get isDailyLimit => code == 'daily_limit_reached';
  bool get isPremiumRequired => code == 'premium_required';
  bool get isProfileRequired => code == 'profile_required';
  bool get isAuthRequired => code == 'auth_required';
  bool get isNetworkError => code == 'network_error';
  bool get isServerError => code == 'server_error';

  /// User-facing Arabic message (no internal Firebase jargon).
  String get userMessage {
    if (isDailyLimit) {
      return 'وصلتي للحد اليومي من رسائل المساعد. جرّبي بكرة 💛';
    }
    if (isPremiumRequired || isProfileRequired) {
      return 'Premium مش مفعّل على الحساب اللي داخل منه الآن. افتحي تبويب الحساب وفعّلي Premium، أو سجّلي دخول بالإيميل اللي عليه الاشتراك.';
    }
    if (isAuthRequired) {
      return 'لازم تكوني مسجّلة دخول عشان تستخدمي المساعد. ارجعي لشاشة الترحيب وسجّلي دخول.';
    }
    if (isNetworkError) {
      return 'ما قدرنا نوصل للسيرفر. تأكدي من الإنترنت وحاولي مرة ثانية.';
    }
    return 'المساعد مش متاح حالياً. حاولي بعد شوي.';
  }

  @override
  String toString() =>
      'AiGatewayException($code${message != null ? ': $message' : ''})';
}
