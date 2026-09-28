import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Central Firebase Remote Config service for dynamic app configuration.
/// Controls AdMob, RevenueCat, Free vs Pro feature limits, cross-promotion,
/// and live announcements in real-time from the Firebase Console without releasing updates!
class RemoteAdConfig extends ChangeNotifier {
  static final RemoteAdConfig instance = RemoteAdConfig._internal();
  RemoteAdConfig._internal();
  factory RemoteAdConfig() => instance;

  FirebaseRemoteConfig? _remoteConfig;
  bool _isFirebaseConnected = false;
  bool get isFirebaseConnected => _isFirebaseConnected;

  // Bundled In-App Defaults
  static const Map<String, dynamic> _defaultConfig = {
    // AdMob Control
    'ads_enabled': true,
    'banner_enabled': true,
    'interstitial_enabled': true,
    'interstitial_cooldown_seconds': 45,
    'android_banner_id': 'ca-app-pub-3940256099942544/6300978111',
    'android_interstitial_id': 'ca-app-pub-3940256099942544/1033173712',
    'ios_banner_id': 'ca-app-pub-3940256099942544/2934735716',
    'ios_interstitial_id': 'ca-app-pub-3940256099942544/4411468910',

    // RevenueCat & Monetization
    'vip_price_monthly': '\$1.49',
    'revenuecat_android_key': 'goog_YOUR_REVENUECAT_ANDROID_KEY',
    'revenuecat_ios_key': 'appl_YOUR_REVENUECAT_IOS_KEY',
    'revenuecat_entitlement_id': 'pro',
    'revenuecat_monthly_package_id': 'monthly',

    // Dynamic Feature Limits (Can unlock features remotely for promotions!)
    'free_max_resolution': '720p', // '720p' or '1080p'
    'free_max_fps': 30, // 30 or 60
    'watermark_enabled_for_free': true,
    'internal_audio_pro_only': true,

    // Dynamic Cross-Promotion
    'cross_promo_enabled': true,
    'cross_promo_title': 'All Video Downloader Master',
    'cross_promo_desc': 'Download HD videos from 1000+ social platforms & web with 1-tap!',
    'cross_promo_url': 'https://play.google.com/store/apps/details?id=com.yourbrand.video_downloader_master',

    // Cloud Notice / Announcement
    'announcement_enabled': false,
    'announcement_title': '⚡ New Update Available',
    'announcement_message': 'Experience smoother 60FPS recordings and faster gallery exports!',
  };

  // State Variables
  bool _adsEnabled = true;
  bool _bannerEnabled = true;
  bool _interstitialEnabled = true;
  int _interstitialCooldownSeconds = 45;

  String _androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  String _androidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  String _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  String _iosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  String _vipPriceMonthly = '\$1.49';
  String _revenueCatAndroidKey = 'goog_YOUR_REVENUECAT_ANDROID_KEY';
  String _revenueCatIosKey = 'appl_YOUR_REVENUECAT_IOS_KEY';
  String _entitlementId = 'pro';
  String _monthlyPackageId = 'monthly';

  String _freeMaxResolution = '720p';
  int _freeMaxFps = 30;
  bool _watermarkEnabledForFree = true;
  bool _internalAudioProOnly = true;

  bool _crossPromoEnabled = true;
  String _crossPromoTitle = 'All Video Downloader Master';
  String _crossPromoDesc = 'Download HD videos from 1000+ social platforms & web with 1-tap!';
  String _crossPromoUrl = 'https://play.google.com/store/apps/details?id=com.yourbrand.video_downloader_master';

  bool _announcementEnabled = false;
  String _announcementTitle = '';
  String _announcementMessage = '';

  // Getters
  bool get adsEnabled => _adsEnabled;
  bool get bannerEnabled => _adsEnabled && _bannerEnabled;
  bool get interstitialEnabled => _adsEnabled && _interstitialEnabled;
  int get interstitialCooldownSeconds => _interstitialCooldownSeconds;

  String get bannerId {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _androidBannerId : _iosBannerId;
  }

  String get interstitialId {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId;
  }

  String get vipPriceMonthly => _vipPriceMonthly;
  String get revenueCatApiKey {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _revenueCatAndroidKey : _revenueCatIosKey;
  }
  String get entitlementId => _entitlementId;
  String get monthlyPackageId => _monthlyPackageId;

  String get freeMaxResolution => _freeMaxResolution;
  int get freeMaxFps => _freeMaxFps;
  bool get watermarkEnabledForFree => _watermarkEnabledForFree;
  bool get internalAudioProOnly => _internalAudioProOnly;

  bool get crossPromoEnabled => _crossPromoEnabled;
  String get crossPromoTitle => _crossPromoTitle;
  String get crossPromoDesc => _crossPromoDesc;
  String get crossPromoUrl => _crossPromoUrl;

  bool get announcementEnabled => _announcementEnabled;
  String get announcementTitle => _announcementTitle;
  String get announcementMessage => _announcementMessage;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        if (Platform.isAndroid) {
          try {
            await Firebase.initializeApp();
          } catch (_) {
            // Options fallback using your verified google-services.json
            await Firebase.initializeApp(
              options: const FirebaseOptions(
                apiKey: 'AIzaSyAAfiWtoXQggz03dGIsqKdAVnTX-rteWf4',
                appId: '1:883069180184:android:a9aeed0d443815560d666d',
                messagingSenderId: '883069180184',
                projectId: 'screen-recording-2b210',
                storageBucket: 'screen-recording-2b210.firebasestorage.app',
              ),
            );
          }
        } else {
          await Firebase.initializeApp();
        }
      }

      final rc = FirebaseRemoteConfig.instance;
      _remoteConfig = rc;

      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );

      await rc.setDefaults(_defaultConfig);
      final activated = await rc.fetchAndActivate();
      _isFirebaseConnected = true;
      _syncValues();

      final allKeys = rc.getAll().keys.toList();
      debugPrint('[RemoteAdConfig] ✅ Firebase Remote Config connected successfully!');
      debugPrint('[RemoteAdConfig] Active parameters count: ${allKeys.length}, Activated: $activated');
      debugPrint('[RemoteAdConfig] Loaded keys: $allKeys');

      _lastFetchStatus = 'Connected (${allKeys.length} keys active)';
      notifyListeners();

      rc.onConfigUpdated.listen((event) async {
        await rc.activate();
        _syncValues();
        debugPrint('[RemoteAdConfig] Real-Time Remote Config updated: ${event.updatedKeys}');
      });
    } catch (e) {
      _lastFetchStatus = 'Offline mode ($e)';
      debugPrint('[RemoteAdConfig] Note: Running in safe offline mode ($e)');
      _syncValues();
    }
  }

  int get activeKeysCount => _remoteConfig?.getAll().length ?? 0;
  String? _lastFetchStatus;
  String? get lastFetchStatus => _lastFetchStatus;

  Future<bool> forceFetch() async {
    try {
      if (_remoteConfig == null) {
        await initialize();
      }
      if (_remoteConfig != null) {
        final activated = await _remoteConfig!.fetchAndActivate();
        _isFirebaseConnected = true;
        _syncValues();
        _lastFetchStatus = 'Connected (${_remoteConfig!.getAll().length} keys active)';
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _lastFetchStatus = 'Fetch error ($e)';
      notifyListeners();
      return false;
    }
  }

  void _syncValues() {
    if (_remoteConfig != null) {
      _adsEnabled = _remoteConfig!.getBool('ads_enabled');
      _bannerEnabled = _remoteConfig!.getBool('banner_enabled');
      _interstitialEnabled = _remoteConfig!.getBool('interstitial_enabled');
      _interstitialCooldownSeconds = _remoteConfig!.getInt('interstitial_cooldown_seconds');

      _androidBannerId = _remoteConfig!.getString('android_banner_id');
      _androidInterstitialId = _remoteConfig!.getString('android_interstitial_id');
      _iosBannerId = _remoteConfig!.getString('ios_banner_id');
      _iosInterstitialId = _remoteConfig!.getString('ios_interstitial_id');

      _vipPriceMonthly = _remoteConfig!.getString('vip_price_monthly');

      final rcAndroid = _remoteConfig!.getString('revenuecat_android_key');
      if (rcAndroid.isNotEmpty) _revenueCatAndroidKey = rcAndroid;
      final rcIos = _remoteConfig!.getString('revenuecat_ios_key');
      if (rcIos.isNotEmpty) _revenueCatIosKey = rcIos;
      final rcEntitlement = _remoteConfig!.getString('revenuecat_entitlement_id');
      if (rcEntitlement.isNotEmpty) _entitlementId = rcEntitlement;
      final rcMonthly = _remoteConfig!.getString('revenuecat_monthly_package_id');
      if (rcMonthly.isNotEmpty) _monthlyPackageId = rcMonthly;

      // Dynamic Feature Limits
      _freeMaxResolution = _remoteConfig!.getString('free_max_resolution');
      _freeMaxFps = _remoteConfig!.getInt('free_max_fps');
      _watermarkEnabledForFree = _remoteConfig!.getBool('watermark_enabled_for_free');
      _internalAudioProOnly = _remoteConfig!.getBool('internal_audio_pro_only');

      // Cross Promotion
      _crossPromoEnabled = _remoteConfig!.getBool('cross_promo_enabled');
      _crossPromoTitle = _remoteConfig!.getString('cross_promo_title');
      _crossPromoDesc = _remoteConfig!.getString('cross_promo_desc');
      _crossPromoUrl = _remoteConfig!.getString('cross_promo_url');

      // Announcement
      _announcementEnabled = _remoteConfig!.getBool('announcement_enabled');
      _announcementTitle = _remoteConfig!.getString('announcement_title');
      _announcementMessage = _remoteConfig!.getString('announcement_message');
    }
    notifyListeners();
  }
}
