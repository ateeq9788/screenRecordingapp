import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../theme/app_config.dart';
import 'remote_ad_config.dart';

class PurchaseService extends ChangeNotifier {
  static final PurchaseService instance = PurchaseService._internal();
  PurchaseService._internal();
  factory PurchaseService() => instance;

  bool _isConfigured = false;
  bool get isConfigured => _isConfigured;

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  Package? _monthlyPackage;
  Package? get monthlyPackage => _monthlyPackage;

  String? _cachedPriceString;
  AppConfig? _appConfig;

  String get monthlyPriceDisplay {
    if (_monthlyPackage != null) {
      return '${_monthlyPackage!.storeProduct.priceString} / month';
    }
    if (_cachedPriceString != null) {
      return '$_cachedPriceString / month';
    }
    return '${RemoteAdConfig.instance.vipPriceMonthly} / month';
  }

  Future<void> initialize({AppConfig? appConfig}) async {
    _appConfig = appConfig;

    if (kIsWeb) return;

    final apiKey = RemoteAdConfig.instance.revenueCatApiKey;
    if (apiKey.isEmpty || apiKey.contains('YOUR_REVENUECAT')) {
      debugPrint('[PurchaseService] RevenueCat in sandbox mode.');
      return;
    }

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      _isConfigured = true;

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _handleCustomerInfoUpdate(customerInfo);
      });

      final customerInfo = await Purchases.getCustomerInfo();
      _handleCustomerInfoUpdate(customerInfo);
      await fetchOfferings();
    } catch (e) {
      debugPrint('[PurchaseService] Error initializing RevenueCat: $e');
    }
  }

  Future<void> fetchOfferings() async {
    if (!_isConfigured) return;
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current != null) {
        _monthlyPackage = current.monthly;
        _monthlyPackage ??= current.availablePackages.firstWhere(
          (pkg) =>
              pkg.packageType == PackageType.monthly ||
              pkg.identifier.toLowerCase().contains('month'),
          orElse: () => current.availablePackages.isNotEmpty
              ? current.availablePackages.first
              : throw Exception('No packages in current offering'),
        );
        if (_monthlyPackage != null) {
          _cachedPriceString = _monthlyPackage!.storeProduct.priceString;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[PurchaseService] Error fetching offerings: $e');
    }
  }

  Future<bool> buyMonthlySubscription(AppConfig appConfig) async {
    _appConfig = appConfig;
    if (!_isConfigured) {
      await appConfig.setVipUser(true);
      notifyListeners();
      return true;
    }

    if (_monthlyPackage == null) {
      await fetchOfferings();
      if (_monthlyPackage == null) {
        throw Exception('Monthly subscription package not found in store offerings.');
      }
    }

    _isPurchasing = true;
    notifyListeners();

    try {
      final purchaseResult = await Purchases.purchasePackage(_monthlyPackage!);
      final hasPro = _isEntitlementActive(purchaseResult);
      await appConfig.setVipUser(hasPro);
      _isPurchasing = false;
      notifyListeners();
      return hasPro;
    } on PurchasesErrorCode catch (e) {
      _isPurchasing = false;
      notifyListeners();
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    } catch (e) {
      _isPurchasing = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> restorePurchases(AppConfig appConfig) async {
    _appConfig = appConfig;
    if (!_isConfigured) {
      return appConfig.isVipUser;
    }

    _isPurchasing = true;
    notifyListeners();

    try {
      final customerInfo = await Purchases.restorePurchases();
      final hasPro = _isEntitlementActive(customerInfo);
      await appConfig.setVipUser(hasPro);
      _isPurchasing = false;
      notifyListeners();
      return hasPro;
    } catch (e) {
      _isPurchasing = false;
      notifyListeners();
      rethrow;
    }
  }

  void _handleCustomerInfoUpdate(CustomerInfo customerInfo) {
    final hasPro = _isEntitlementActive(customerInfo);
    if (_appConfig != null && _appConfig!.isVipUser != hasPro) {
      _appConfig!.setVipUser(hasPro);
    }
    notifyListeners();
  }

  bool _isEntitlementActive(CustomerInfo customerInfo) {
    final entitlementId = RemoteAdConfig.instance.entitlementId;
    final entitlement = customerInfo.entitlements.all[entitlementId];
    return entitlement?.isActive == true;
  }
}
