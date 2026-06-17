import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  static const String _premiumKey = 'is_premium_user';
  static const String _weeklySubId = 'water_tracker_weekly';
  static final String _monthlySubId = 'water_tracker_monthly';
  static final String _yearlySubId = 'water_tracker_yearly';
  static final String _lifetimeId = 'water_tracker_lifetime';

  static const Set<String> _allProductIds = {
    _weeklySubId,
    _monthlySubId,
    _yearlySubId,
    _lifetimeId,
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  /// 初始化内购
  Future<void> init() async {
    // 先检查本地缓存
    await _checkLocalPremium();
    
    // 设置购买监听
    final purchaseStream = _iap.purchaseStream;
    _subscription = purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );
    
    // 加载商品信息
    await loadProducts();
  }

  /// 加载商品
  Future<void> loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    final response = await _iap.queryProductDetails(_allProductIds);
    if (response.error != null) {
      print('Product query error: ${response.error}');
    }
    _products = response.productDetails;
  }

  /// 恢复购买
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// 购买商品
  Future<bool> buy(ProductDetails product) async {
    final available = await _iap.isAvailable();
    if (!available) return false;

    final purchaseParam = PurchaseParam(productDetails: product);
    
    if (product.id == _lifetimeId) {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  /// 处理购买更新
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(purchase);
          break;
        case PurchaseStatus.error:
          print('Purchase error: ${purchase.error}');
          break;
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
          break;
      }

      // 确认购买
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  /// 验证并发放购买
  void _verifyAndDeliver(PurchaseDetails purchase) async {
    // TODO: 这里应该向服务器验证购买凭证
    // 现在简化处理：只要是购买状态就解锁
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      await _setLocalPremium(true);
      print('Premium unlocked: ${purchase.productID}');
    }
  }

  /// 检查是否为高级用户
  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  /// 本地设置高级状态
  Future<void> _setLocalPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
  }

  /// 检查本地缓存
  Future<void> _checkLocalPremium() async {
    // 本地缓存 + 服务器验证
  }

  /// 释放资源
  void dispose() {
    _subscription?.cancel();
  }
}

/// 订阅计划信息
class SubscriptionPlan {
  final String id;
  final String title;
  final String price;
  final String? originalPrice;
  final String? discount;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.price,
    this.originalPrice,
    this.discount,
    this.isPopular = false,
  });
}
