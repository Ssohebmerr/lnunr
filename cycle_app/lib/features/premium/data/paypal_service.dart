import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_secrets.dart';
import '../../../core/storage/user_prefs.dart';

class PayPalCheckoutResult {
  const PayPalCheckoutResult({
    required this.approvalUrl,
    required this.orderId,
  });

  final String approvalUrl;
  final String orderId;
}

/// PayPal checkout for Cycle Aura Premium (monthly).
class PayPalService {
  PayPalService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  static final _baseUrl = AppSecrets.cloudFunctionsUrl;
  static const pendingOrderKey = 'paypal_pending_order_id';

  final FirebaseAuth _auth;

  Future<bool> hasPendingOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(pendingOrderKey);
    return id != null && id.isNotEmpty;
  }

  /// Creates a PayPal order and stores [orderId] until capture succeeds.
  Future<PayPalCheckoutResult?> startCheckout() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/createPayPalOrder'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final approvalUrl = data['approvalUrl'] as String?;
    final orderId = data['orderId'] as String?;
    if (approvalUrl == null ||
        approvalUrl.isEmpty ||
        orderId == null ||
        orderId.isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pendingOrderKey, orderId);

    return PayPalCheckoutResult(approvalUrl: approvalUrl, orderId: orderId);
  }

  Future<bool> launchApprovalPage(String approvalUrl) {
    final uri = Uri.parse(approvalUrl);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Captures the pending PayPal order after the user returns from checkout.
  Future<bool> capturePendingOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderId = prefs.getString(pendingOrderKey);
    if (orderId == null || orderId.isEmpty) return false;

    final user = _auth.currentUser;
    if (user == null) return false;

    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/capturePayPalOrder'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'orderId': orderId}),
    );

    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] == 'COMPLETED') {
      await prefs.remove(pendingOrderKey);
      await UserPrefs.setPremium(true);
      return true;
    }
    return false;
  }
}
