import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../../core/config/app_secrets.dart';

/// Google Play Billing for Premium subscriptions on Android (Play policy).
class PlayBillingService {
  PlayBillingService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  static const productId = 'premium_monthly';
  static const packageName = 'com.lune.app';
  static final _baseUrl = AppSecrets.cloudFunctionsUrl;

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<bool> isAvailable() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    return _iap.isAvailable();
  }

  Future<void> startListening({VoidCallback? onPremiumGranted}) async {
    if (!await isAvailable()) return;
    await _purchaseSub?.cancel();
    _purchaseSub = _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.productID != productId) continue;

        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            final verified = await _verifyOnServer(purchase);
            if (verified) onPremiumGranted?.call();
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
          case PurchaseStatus.error:
            debugPrint('Play purchase error: ${purchase.error}');
          case PurchaseStatus.pending:
            debugPrint('Play purchase pending: ${purchase.productID}');
          case PurchaseStatus.canceled:
            break;
        }
      }
    });
  }

  void dispose() => _purchaseSub?.cancel();

  Future<ProductDetails?> loadProduct() async {
    if (!await isAvailable()) return null;
    final response = await _iap.queryProductDetails({productId});
    if (response.error != null) {
      debugPrint('Play product query error: ${response.error}');
      return null;
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Play product not found: ${response.notFoundIDs}');
    }
    if (response.productDetails.isEmpty) return null;
    return response.productDetails.first;
  }

  Future<bool> subscribe(ProductDetails product) async {
    if (!await isAvailable()) return false;
    final PurchaseParam param = product is GooglePlayProductDetails
        ? GooglePlayPurchaseParam(productDetails: product)
        : PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    if (!await isAvailable()) return;
    await _iap.restorePurchases();
  }

  Future<bool> _verifyOnServer(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final token = await user.getIdToken();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/verifyPlayPurchase'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'purchaseToken': purchase.verificationData.serverVerificationData,
              'productId': purchase.productID,
              'packageName': packageName,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint(
          'verifyPlayPurchase HTTP ${response.statusCode}: ${response.body}',
        );
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['verified'] as bool? ?? data['entitled'] as bool? ?? false;
    } catch (e, st) {
      debugPrint('verifyPlayPurchase failed: $e\n$st');
      return false;
    }
  }
}
