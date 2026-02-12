import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RevenueCat API keys — replace with your real keys before production.
const _rcAppleApiKey = 'appl_REPLACE_WITH_YOUR_APPLE_API_KEY';
const _rcGoogleApiKey = 'goog_REPLACE_WITH_YOUR_GOOGLE_API_KEY';

/// Entitlement identifier configured in RevenueCat dashboard.
const rcPremiumEntitlement = 'rebecca_premium';

/// Offering identifier.
const rcDefaultOffering = 'default';

/// RevenueCat singleton wrapper.
class RevenueCatService {
  RevenueCatService._();
  static final instance = RevenueCatService._();

  bool _initialized = false;
  bool _demoMode = false;

  /// Whether running with placeholder keys (all features unlocked).
  bool get isDemoMode => _demoMode;

  /// Call once at app start.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final key = Platform.isIOS ? _rcAppleApiKey : _rcGoogleApiKey;
      if (key.contains('REPLACE') || key.contains('your_') || key.isEmpty) {
        debugPrint('[RevenueCat] Placeholder API key detected → demo mode (premium unlocked)');
        _demoMode = true;
        return;
      }
      await Purchases.setLogLevel(LogLevel.debug);

      final PurchasesConfiguration configuration;
      if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_rcAppleApiKey);
      } else {
        configuration = PurchasesConfiguration(_rcGoogleApiKey);
      }
      await Purchases.configure(configuration);
      _initialized = true;
    } catch (e) {
      debugPrint('[RevenueCat] Init failed: $e');
      // App continues in free-tier mode if RC is unreachable.
    }
  }

  /// Returns `true` when the user has an active premium entitlement.
  Future<bool> isPremium() async {
    if (_demoMode) return true;
    if (!_initialized) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(rcPremiumEntitlement);
    } catch (_) {
      return false;
    }
  }

  /// Fetch current offerings (packages the user can buy).
  Future<Offerings?> getOfferings() async {
    if (!_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  /// Purchase a package, returns `true` on success.
  Future<bool> purchase(Package package) async {
    if (!_initialized) return false;
    try {
      final result = await Purchases.purchasePackage(package);
      return result.entitlements.active.containsKey(rcPremiumEntitlement);
    } on PurchasesErrorCode catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Restore previous purchases.
  Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(rcPremiumEntitlement);
    } catch (_) {
      return false;
    }
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────────────────

/// Holds current premium status. Starts `false`, updated after init.
class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(kDebugMode || RevenueCatService.instance.isDemoMode) {
    _init();
  }

  Future<void> _init() async {
    // Check local cache first for instant UI.
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('rebecca_is_premium') ?? false;

    // Then verify with RevenueCat.
    final live = await RevenueCatService.instance.isPremium();
    state = live;
    await prefs.setBool('rebecca_is_premium', live);
  }

  Future<void> refresh() async {
    final live = await RevenueCatService.instance.isPremium();
    state = live;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rebecca_is_premium', live);
  }

  /// Convenience for after purchase/restore.
  void setPremium(bool value) {
    state = value;
    SharedPreferences.getInstance().then((p) => p.setBool('rebecca_is_premium', value));
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>(
  (ref) => PremiumNotifier(),
);

/// Fetched offerings (nullable while loading).
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  return RevenueCatService.instance.getOfferings();
});
