import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Product ID for "Buy me a coffee" (300 JPY)
  // MUST be configured in Google Play Console with this exact ID.
  static const String _coffeeProductId = 'donation_300';
  
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool get isAvailable => _isAvailable;

  // Callback to handle purchase status in UI
  Function(String)? onPurchaseSuccess;
  Function(String)? onPurchaseError;

  Future<void> init() async {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        debugPrint('Purchase Stream Error: $error');
      },
    );

    await _initStore();
  }

  Future<void> _initStore() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      debugPrint('Store not available');
      return;
    }

    const Set<String> _kIds = <String>{_coffeeProductId};
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_kIds);
    
    if (response.error != null) {
      debugPrint('Query Product Error: ${response.error}');
      return;
    }

    if (response.productDetails.isEmpty) {
      debugPrint('No products found. Ensure "$_coffeeProductId" is active in Play Console.');
      return;
    }

    _products = response.productDetails;
  }

  Future<void> buyCoffee() async {
    if (!_isAvailable) {
       onPurchaseError?.call('ストアに接続できません。');
       return;
    }
    
    if (!_products.any((p) => p.id == _coffeeProductId)) {
       onPurchaseError?.call('商品情報が見つかりません。\nGoogle Play Consoleで "$_coffeeProductId" を作成してください。');
       return;
    }

    final purchaseParam = PurchaseParam(productDetails: _products.firstWhere((p) => p.id == _coffeeProductId));
    
    try {
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      onPurchaseError?.call('購入処理開始に失敗しました: $e');
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase Pending...');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          onPurchaseError?.call('購入エラー: ${purchaseDetails.error?.message ?? "不明なエラー"}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          onPurchaseSuccess?.call('ありがとうございます！\nコーヒーをご馳走になりました！');
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
