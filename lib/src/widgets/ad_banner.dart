import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../services/purchase_service.dart';

/// AdMob Banner Widget - Shows banner ad for free users, nothing for Pro users
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  // TEMPORARY: Set to false to completely disable banner for debugging
  static const bool _enableBanner = true;
  
  final _adMobService = AdMobService();
  final _purchaseService = PurchaseService();
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    _isPro = await _purchaseService.isPro();
    if (!_isPro && mounted) {
      // Only load ad for free users
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    await _adMobService.initialize();
    _bannerAd = _adMobService.createBannerAd();
    
    // Wait a bit for ad to load
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isAdLoaded = _adMobService.isBannerAdReady;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Banner disabled for debugging
    if (!_enableBanner) {
      return const SizedBox.shrink();
    }
    
    // Pro users see nothing
    if (_isPro) {
      return const SizedBox.shrink();
    }

    // Free users see banner ad
    if (_bannerAd != null && _isAdLoaded) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: Container(
          alignment: Alignment.center,
          color: const Color(0xFF0D1218),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }

    // Loading state or ad failed
    return const SizedBox(
      width: 320,
      height: 50,
      child: ColoredBox(
        color: Color(0xFF0D1218),
      ),
    );
  }
}
