import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'remote_ad_config.dart';

class AdService extends ChangeNotifier {
  static final AdService instance = AdService._internal();
  AdService._internal();
  factory AdService() => instance;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime? _lastInterstitialShownAt;

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      loadInterstitialAd();
      notifyListeners();
    } catch (e) {
      debugPrint('[AdService] MobileAds initialize error: $e');
    }
  }

  void loadInterstitialAd() {
    if (kIsWeb || !RemoteAdConfig.instance.interstitialEnabled || _isInterstitialLoading) return;

    final adUnitId = RemoteAdConfig.instance.interstitialId;
    if (adUnitId.isEmpty) return;

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Show interstitial after a recording session completes
  void showInterstitialAd({VoidCallback? onComplete}) {
    if (kIsWeb || !RemoteAdConfig.instance.interstitialEnabled) {
      onComplete?.call();
      return;
    }

    final cooldownSeconds = RemoteAdConfig.instance.interstitialCooldownSeconds;
    if (_lastInterstitialShownAt != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShownAt!).inSeconds;
      if (elapsed < cooldownSeconds) {
        onComplete?.call();
        return;
      }
    }

    if (_interstitialAd != null) {
      _lastInterstitialShownAt = DateTime.now();
      _interstitialAd!.show();
      onComplete?.call();
    } else {
      loadInterstitialAd();
      onComplete?.call();
    }
  }
}
