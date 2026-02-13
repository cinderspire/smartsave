import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  static const _defaults = <String, Object>{
    'maintenance_mode': false,
    'premium_monthly_price': '3.99',
    'app_announcement': '',
    'force_update_version': '0.0.0',
    'savings_tips_enabled': true,
    'roundup_multiplier': '1.0',
    'gemini_api_key': '',
  };

  Future<void> init() async {
    if (_initialized) return;
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _remoteConfig.setDefaults(
        _defaults.map((k, v) => MapEntry(k, v.toString())),
      );
      await _remoteConfig.fetchAndActivate();
      _initialized = true;
    } catch (e) {
      debugPrint('RemoteConfig init failed: $e');
    }
  }

  bool get maintenanceMode =>
      _initialized ? _remoteConfig.getBool('maintenance_mode') : false;

  String get premiumMonthlyPrice =>
      _initialized ? _remoteConfig.getString('premium_monthly_price') : '3.99';

  String get appAnnouncement =>
      _initialized ? _remoteConfig.getString('app_announcement') : '';

  String get forceUpdateVersion =>
      _initialized ? _remoteConfig.getString('force_update_version') : '0.0.0';

  bool get savingsTipsEnabled =>
      _initialized ? _remoteConfig.getBool('savings_tips_enabled') : true;

  double get roundupMultiplier =>
      _initialized ? _remoteConfig.getDouble('roundup_multiplier') : 1.0;

  String get geminiApiKey =>
      _initialized ? _remoteConfig.getString('gemini_api_key') : '';
}
