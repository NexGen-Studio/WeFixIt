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
  bool _isLoadingAd = false;

  Completer<bool>? _adCompleter;
  bool _rewardEarned = false;

  /// Initialize AdMob
  Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  /// Get Rewarded Ad Unit ID
  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID
    }
    return '';
  }

  /// Load Rewarded Ad
  Future<void> loadRewardedAd() async {
    if (!_isInitialized) await initialize();
    
    // Prevent multiple concurrent load requests
    if (_isLoadingAd) {
      print('⚠️ [AdMob] Already loading ad, skipping duplicate request');
      return;
    }
    
    // If ad is already ready, don't load again
    if (_isRewardedAdReady && _rewardedAd != null) {
      print('✅ [AdMob] Ad already loaded and ready');
      return;
    }

    _isLoadingAd = true;
    print('🔵 [AdMob] Starting ad load...');

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('🔵 [AdMob] Ad loaded');
          
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          _isLoadingAd = false;
          
          print('✅ [AdMob] Rewarded Ad loaded (callbacks will be set when shown)');
        },
        onAdFailedToLoad: (error) {
          print('❌ Rewarded Ad failed to load: $error');
          _isRewardedAdReady = false;
          _isLoadingAd = false;
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
    
    if (!_isRewardedAdReady || _rewardedAd == null) {
      print('⚠️ [AdMob] Ad not ready, preparing...');
      final ready = await prepareRewardedAd();
      if (!ready) {
        print('❌ [AdMob] Rewarded Ad still not ready');
        return false;
      }
      print('✅ [AdMob] Ad prepared successfully');
    }

    _adCompleter = Completer<bool>();
    _rewardEarned = false;
    print('🔵 [AdMob] Completer created, setting up callbacks NOW...');

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
        
        if (_adCompleter != null && !_adCompleter!.isCompleted) {
          print('🔵 [AdMob] Completing completer with result: $_rewardEarned');
          _adCompleter!.complete(_rewardEarned);
          print('✅ [AdMob] Completer completed!');
          _adCompleter = null;
          _rewardEarned = false;
        } else {
          print('⚠️ [AdMob] No completer to complete!');
        }
        
        print('🔵 [AdMob] Preloading next ad...');
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ [AdMob] *** AD FAILED TO SHOW: $error ***');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
        
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
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('💰 [AdMob] *** USER EARNED REWARD: ${reward.amount} ${reward.type} ***');
        _rewardEarned = true;
      },
    );
    print('🔵 [AdMob] _rewardedAd!.show() returned, waiting for completer...');
    
    final result = await _adCompleter!.future;
    print('✅ [AdMob] showRewardedAd() RETURNING: $result');
    return result;
  }

  /// Check if rewarded ad is ready
  bool get isRewardedAdReady => _isRewardedAdReady;

  /// Dispose
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
  }
}
