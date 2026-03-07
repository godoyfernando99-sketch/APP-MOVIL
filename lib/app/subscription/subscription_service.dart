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
        // Escuchamos el stream de compras
        _subscription = _iap.purchaseStream.listen(
          (List<PurchaseDetails> purchases) {
            _onPurchaseUpdate(purchases);
          },
          onError: (error) {
            debugPrint('[SubscriptionService] Stream error: $error');
          },
        );
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Initialize failed: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        debugPrint('[SubscriptionService] Query products error: ${response.error}');
        return;
      }

      _products = response.productDetails;
      debugPrint('[SubscriptionService] Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('[SubscriptionService] Load products failed: $e');
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    try {
      if (!_isAvailable) return;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      // En Android/iOS las suscripciones se manejan como NonConsumable
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('[SubscriptionService] Buy product failed: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final PurchaseDetails purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        _handlePurchaseSuccess(purchase);
      } 

      if (purchase.status == PurchaseStatus.error) {
        debugPrint('[SubscriptionService] Error: ${purchase.error}');
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void _handlePurchaseSuccess(PurchaseDetails purchase) {
    debugPrint('[SubscriptionService] SUCCESS: ${purchase.productID}');
    // Aquí es donde conectarías con tu AuthController para subir el nivel a PRO
  }

  String getPlanIdFromProductId(String productId) {
    if (productId.contains('basic')) return 'basic';
    if (productId.contains('intermediate')) return 'intermediate';
    if (productId.contains('pro')) return 'pro';
    return 'free';
  }

  void dispose() {
    _subscription?.cancel();
  }
}