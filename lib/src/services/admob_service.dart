import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool _isInitialized = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  /// Initialize AdMob
  Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  /// Get Banner Ad Unit ID
  String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      // TODO: Load from environment
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
    }
    return '';
  }

  /// Get Rewarded Ad Unit ID
  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      // TODO: Load from environment
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID
    }
    return '';
  }

  /// Load Rewarded Ad
  Future<void> loadRewardedAd() async {
    if (!_isInitialized) await initialize();

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          print('✅ Rewarded Ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('❌ Rewarded Ad failed to load: $error');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  /// Show Rewarded Ad
  Future<bool> showRewardedAd() async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      print('⚠️ Rewarded Ad not ready, loading...');
      await loadRewardedAd();
      // Wait a bit for load
      await Future.delayed(const Duration(seconds: 2));
      if (!_isRewardedAdReady || _rewardedAd == null) {
        return false; // Still not ready
      }
    }

    bool rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('🎬 Rewarded Ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('👋 Rewarded Ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
        // Preload next ad
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Rewarded Ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('🎁 User earned reward: ${reward.amount} ${reward.type}');
        rewardEarned = true;
      },
    );

    return rewardEarned;
  }

  /// Check if rewarded ad is ready
  bool get isRewardedAdReady => _isRewardedAdReady;

  /// Load Banner Ad
  BannerAd? createBannerAd() {
    if (!_isInitialized) {
      print('⚠️ AdMob not initialized');
      return null;
    }

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner, // 320x50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Banner Ad loaded');
          _isBannerAdReady = true;
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner Ad failed to load: $error');
          ad.dispose();
          _isBannerAdReady = false;
        },
      ),
    );

    _bannerAd!.load();
    return _bannerAd;
  }

  /// Check if banner ad is ready
  bool get isBannerAdReady => _isBannerAdReady;

  /// Dispose
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdReady = false;
  }
}
