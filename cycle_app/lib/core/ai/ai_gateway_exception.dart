/// Thrown when the Cloud Function rejects an AI request.
class AiGatewayException implements Exception {
  const AiGatewayException(this.code, {this.message});

  final String code;
  final String? message;

  bool get isDailyLimit => code == 'daily_limit_reached';
  bool get isPremiumRequired => code == 'premium_required';
  bool get isProfileRequired => code == 'profile_required';
  bool get isConsentRequired => code == 'consent_required';
  bool get isAdultRequired => code == 'adult_required';
  bool get isAuthRequired => code == 'auth_required';
  bool get isNetworkError => code == 'network_error';
  bool get isServerError => code == 'server_error';

  /// User-facing Arabic message (no internal Firebase jargon).
  String get userMessage {
    if (isDailyLimit) {
      return 'وصلتِ إلى الحد اليومي لرسائل المساعدة الذكية. عودي غداً 💛';
    }
    if (isPremiumRequired || isProfileRequired) {
      return 'محادثة لُون الذكية متاحة لمشتركات Premium. اشتركي من شاشة الخطط، أو تحققي من حالة اشتراكك في تبويب الحساب.';
    }
    if (isConsentRequired) {
      return 'يلزم قبول موافقة ميزات الذكاء الاصطناعي قبل إرسال رسائلك وسياق دورتك.';
    }
    if (isAdultRequired) {
      return 'Lune AI متاح للبالغات بعمر 18 سنة أو أكثر فقط.';
    }
    if (isAuthRequired) {
      return 'يلزم تسجيل الدخول لاستخدام المساعدة الذكية. عودي إلى شاشة الترحيب وسجّلي الدخول.';
    }
    if (isNetworkError) {
      return 'تعذّر الوصول إلى الخادم. تأكدي من اتصال الإنترنت وحاولي مجدداً.';
    }
    return 'المساعدة الذكية غير متاحة حالياً. حاولي بعد قليل.';
  }

  @override
  String toString() =>
      'AiGatewayException($code${message != null ? ': $message' : ''})';
}
