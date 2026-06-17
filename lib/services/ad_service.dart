import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // AdMob App ID
  static const String _appId = 'ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy'; // 替换为你的 AdMob App ID

  // 测试广告单元 ID
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialVideoId = 'ca-app-pub-3940256099942544/8691691433';

  // 正式广告单元 ID（需要替换）
  static const String _prodBannerId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy'; // 替换为你的 Banner Ad Unit ID
  static const String _prodInterstitialId = 'ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz'; // 替换为你的 Interstitial Ad Unit ID

  // 当前使用的广告单元 ID
  static String get _bannerId => _isTest ? _testBannerId : _prodBannerId;
  static String get _interstitialId => _isTest ? _testInterstitialId : _prodInterstitialId;

  // 是否为测试模式
  static bool get _isTest {
    // 发布时改为 false
    return true;
  }

  // 广告实例
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;

  // 插屏广告展示间隔（秒）
  static const int _interstitialInterval = 180; // 3分钟
  DateTime? _lastInterstitialTime;

  /// 初始化 AdMob
  Future<void> init() async {
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['YOUR_TEST_DEVICE_ID'], // 添加你的测试设备 ID
      ),
    );
  }

  /// 创建 Banner 广告
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerLoaded = false;
          ad.dispose();
        },
        onAdOpened: (ad) {},
        onAdClosed: (ad) {},
      ),
    );
  }

  /// 加载 Banner 广告
  void loadBanner() {
    _bannerAd?.dispose();
    _bannerAd = createBannerAd();
    _bannerAd!.load();
  }

  /// 获取 Banner 广告 Widget
  Widget getBannerWidget() {
    if (_bannerAd != null && _isBannerLoaded) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }

  /// 加载插屏广告
  Future<void> loadInterstitial() async {
    await InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoaded = false;
        },
      ),
    );
  }

  /// 展示插屏广告
  Future<void> showInterstitial() async {
    // 检查展示间隔
    if (_lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!).inSeconds;
      if (elapsed < _interstitialInterval) {
        return; // 间隔太短，不展示
      }
    }

    if (_isInterstitialLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          loadInterstitial(); // 预加载下一个
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          loadInterstitial();
        },
      );
      
      await _interstitialAd!.show();
      _lastInterstitialTime = DateTime.now();
    }
  }

  /// 释放广告资源
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}
