import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // 测试广告单元 ID
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  DateTime? _lastInterstitialTime;

  Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _testBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) { _isBannerLoaded = true; },
        onAdFailedToLoad: (ad, error) { ad.dispose(); },
      ),
    );
  }

  void loadBanner() {
    _bannerAd?.dispose();
    _bannerAd = createBannerAd();
    _bannerAd!.load();
  }

  Widget getBannerWidget() {
    if (_bannerAd != null && _isBannerLoaded) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> loadInterstitial() async {
    await InterstitialAd.load(
      adUnitId: _testInterstitialId,
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

  Future<void> showInterstitial() async {
    if (_lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!).inSeconds;
      if (elapsed < 180) return;
    }
    if (_isInterstitialLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialLoaded = false;
        },
      );
      await _interstitialAd!.show();
      _lastInterstitialTime = DateTime.now();
    }
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}
