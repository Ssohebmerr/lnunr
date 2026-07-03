/// Thrown when the Cloud Function rejects an AI request.
class AiGatewayException implements Exception {
  const AiGatewayException(this.code, {this.message});

  final String code;
  final String? message;

  bool get isDailyLimit => code == 'daily_limit_reached';
  bool get isPremiumRequired => code == 'premium_required';

  @override
  String toString() => 'AiGatewayException($code${message != null ? ': $message' : ''})';
}
