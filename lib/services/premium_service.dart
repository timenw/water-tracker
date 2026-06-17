import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: 接入 in_app_purchase v4
// import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  static const String _premiumKey = 'is_premium_user';

  /// 初始化内购
  Future<void> init() async {
    await _checkLocalPremium();
  }

  /// 检查是否为高级用户
  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  /// 设置高级状态（用于测试或服务器验证后）
  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
  }

  /// 检查本地缓存
  Future<void> _checkLocalPremium() async {
    // TODO: 服务器验证
  }

  /// 释放资源
  void dispose() {}
}
