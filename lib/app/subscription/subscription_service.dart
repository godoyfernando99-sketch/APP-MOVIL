import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  final Set<String> _productIds = {
    'scanner_animal_basic',
    'scanner_animal_intermediate',
    'scanner_animal_pro',
  };

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();
      debugPrint('[SubscriptionService] In-app purchases available: $_isAvailable');

      if (_isAvailable) {
        await _loadProducts();
        _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate);
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Initialize failed: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        debugPrint('[SubscriptionService] Query products error: ${response.error}');
        return;
      }
      
      _products = response.productDetails;
      debugPrint('[SubscriptionService] Loaded ${_products.length} products');
      
      for (final product in _products) {
        debugPrint('[SubscriptionService] Product: ${product.id} - ${product.title} - ${product.price}');
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Load products failed: $e');
    }
  }

  Future<void> buyProduct(ProductDetails product, Function(String planId) onSuccess) async {
    try {
      if (!_isAvailable) {
        debugPrint('[SubscriptionService] In-app purchases not available');
        return;
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      
      if (product.id.contains('subscription')) {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Buy product failed: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      debugPrint('[SubscriptionService] Purchase update: ${purchase.productID} - ${purchase.status}');
      
      if (purchase.status == PurchaseStatus.purchased) {
        _handlePurchaseSuccess(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('[SubscriptionService] Purchase error: ${purchase.error}');
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void _handlePurchaseSuccess(PurchaseDetails purchase) {
    debugPrint('[SubscriptionService] Purchase successful: ${purchase.productID}');
  }

  String getPlanIdFromProductId(String productId) {
    if (productId.contains('basic')) return 'basic';
    if (productId.contains('intermediate')) return 'intermediate';
    if (productId.contains('pro')) return 'pro';
    return 'free';
  }

  Future<void> restorePurchases() async {
    try {
      if (!_isAvailable) return;
      await _iap.restorePurchases();
      debugPrint('[SubscriptionService] Restore purchases completed');
    } catch (e) {
      debugPrint('[SubscriptionService] Restore purchases failed: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
