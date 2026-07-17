import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../../core/firebase/cloud_functions_client.dart';

/// Google Play Billing for Premium subscriptions on Android (Play policy).
///
/// Two subscription SKUs are supported (must exist in Play Console and match
/// `play_billing.js` — enforced by a contract test):
///   - premium_monthly
///   - premium_yearly  (usually the better value; shows a savings badge)
class PlayBillingService {
  PlayBillingService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  static const monthlyProductId = 'premium_monthly';
  static const yearlyProductId = 'premium_yearly';

  /// Back-compat alias — the monthly SKU is the default plan.
  static const productId = monthlyProductId;

  static const Set<String> productIds = {monthlyProductId, yearlyProductId};

  static const packageName = 'com.luneapp.cycle';
  static final _functions = CloudFunctionsClient.instance;

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
        if (!productIds.contains(purchase.productID)) continue;

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

  /// Loads all configured plans (monthly + yearly) from Play, keyed by SKU.
  /// Returns an empty map when billing is unavailable or none are found.
  Future<Map<String, ProductDetails>> loadProducts() async {
    if (!await isAvailable()) return const {};
    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      debugPrint('Play product query error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Play products not found: ${response.notFoundIDs}');
    }
    return {for (final p in response.productDetails) p.id: p};
  }

  /// Back-compat: loads just the monthly plan (falls back to any available).
  Future<ProductDetails?> loadProduct() async {
    final products = await loadProducts();
    if (products.containsKey(monthlyProductId)) {
      return products[monthlyProductId];
    }
    return products.isEmpty ? null : products.values.first;
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
      final response = await _functions.post(
        '/verifyPlayPurchase',
        body: {
          'purchaseToken': purchase.verificationData.serverVerificationData,
          'productId': purchase.productID,
          'packageName': packageName,
        },
        timeout: const Duration(seconds: 30),
      );

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
