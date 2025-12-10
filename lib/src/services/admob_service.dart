import 'dart:io';
import 'dart:async';
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

  // Completer for tracking ad dismissal
  Completer<bool>? _adCompleter;
  bool _rewardEarned = false;

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
          print('🔵 [AdMob] Ad loaded');
          
          // CRITICAL: Store the ad but don't set callbacks yet!
          // Callbacks will be set in showRewardedAd() to avoid overwriting active callbacks
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          
          print('✅ [AdMob] Rewarded Ad loaded (callbacks will be set when shown)');
        },
        onAdFailedToLoad: (error) {
          print('❌ Rewarded Ad failed to load: $error');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  /// Wait for Rewarded Ad to be ready
  Future<bool> prepareRewardedAd() async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      print('⚠️ Rewarded Ad not ready, loading...');
      await loadRewardedAd();
      
      // Wait logic: Check every 500ms for up to 5 seconds
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_isRewardedAdReady && _rewardedAd != null) return true;
      }
      
      return _isRewardedAdReady && _rewardedAd != null;
    }
    return true;
  }

  /// Show Rewarded Ad and wait until it's fully dismissed
  Future<bool> showRewardedAd() async {
    print('🔵 [AdMob] showRewardedAd() CALLED');
    
    // Ensure ready (fast check)
    if (!_isRewardedAdReady || _rewardedAd == null) {
      print('⚠️ [AdMob] Ad not ready, preparing...');
      // Try to prepare one last time if not called before
      final ready = await prepareRewardedAd();
      if (!ready) {
        print('❌ [AdMob] Rewarded Ad still not ready');
        return false;
      }
      print('✅ [AdMob] Ad prepared successfully');
    }

    // Create completer and reset reward flag
    _adCompleter = Completer<bool>();
    _rewardEarned = false;
    print('🔵 [AdMob] Completer created, setting up callbacks NOW...');

    // Set up callbacks RIGHT BEFORE showing the ad
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('🎬 [AdMob] *** AD SHOWED - FULLSCREEN NOW ***');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('👋 [AdMob] *** AD DISMISSED - USER CLOSED AD ***');
        print('🔵 [AdMob] Disposing ad object...');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
        print('✅ [AdMob] Ad disposed, state reset');
        
        // Complete the completer if it exists
        if (_adCompleter != null && !_adCompleter!.isCompleted) {
          print('🔵 [AdMob] Completing completer with result: $_rewardEarned');
          _adCompleter!.complete(_rewardEarned);
          print('✅ [AdMob] Completer completed!');
          _adCompleter = null;
          _rewardEarned = false;
        } else {
          print('⚠️ [AdMob] No completer to complete!');
        }
        
        // Preload next ad
        print('🔵 [AdMob] Preloading next ad...');
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ [AdMob] *** AD FAILED TO SHOW: $error ***');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
        
        // Complete with failure
        if (_adCompleter != null && !_adCompleter!.isCompleted) {
          print('🔵 [AdMob] Completing completer with FAILURE');
          _adCompleter!.complete(false);
          _adCompleter = null;
          _rewardEarned = false;
        }
      },
    );
    print('✅ [AdMob] Callbacks set!');

    print('🔵 [AdMob] Calling _rewardedAd!.show()...');
    // Show ad with reward callback
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('💰 [AdMob] *** USER EARNED REWARD: ${reward.amount} ${reward.type} ***');
        _rewardEarned = true;
      },
    );
    print('🔵 [AdMob] _rewardedAd!.show() returned, waiting for completer...');
    
    // Wait until the ad is dismissed or failed
    final result = await _adCompleter!.future;
    print('✅ [AdMob] showRewardedAd() RETURNING: $result');
    return result;
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
