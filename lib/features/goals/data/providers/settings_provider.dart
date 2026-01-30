import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _currencyKey = 'smartsave_currency';
const _themeKey = 'smartsave_theme_mode';
const _roundUpRuleKey = 'smartsave_roundup_rule';
const _notificationsKey = 'smartsave_notifications';

// ── Currency ──

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('USD') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_currencyKey) ?? 'USD';
  }

  Future<void> setCurrency(String currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
  }

  String get symbol {
    switch (state) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '\u20AC';
      case 'GBP':
        return '\u00A3';
      case 'JPY':
        return '\u00A5';
      case 'CAD':
        return 'CA\$';
      case 'AUD':
        return 'AU\$';
      case 'CHF':
        return 'CHF';
      case 'INR':
        return '\u20B9';
      case 'TRY':
        return '\u20BA';
      case 'BRL':
        return 'R\$';
      default:
        return '\$';
    }
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>(
  (ref) => CurrencyNotifier(),
);

final currencySymbolProvider = Provider<String>((ref) {
  final currency = ref.watch(currencyProvider);
  switch (currency) {
    case 'USD':
      return '\$';
    case 'EUR':
      return '\u20AC';
    case 'GBP':
      return '\u00A3';
    case 'JPY':
      return '\u00A5';
    case 'CAD':
      return 'CA\$';
    case 'AUD':
      return 'AU\$';
    case 'CHF':
      return 'CHF';
    case 'INR':
      return '\u20B9';
    case 'TRY':
      return '\u20BA';
    case 'BRL':
      return 'R\$';
    default:
      return '\$';
  }
});

// ── Theme Mode ──

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_themeKey) ?? 2; // dark by default
    state = ThemeMode.values[idx.clamp(0, 2)];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

// ── Round-up Rule ──
// 0 = nearest dollar, 1 = nearest $2, 2 = nearest $5

class RoundUpRuleNotifier extends StateNotifier<int> {
  RoundUpRuleNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_roundUpRuleKey) ?? 0;
  }

  Future<void> setRule(int rule) async {
    state = rule;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_roundUpRuleKey, rule);
  }

  String get ruleLabel {
    switch (state) {
      case 0:
        return 'Nearest \$1';
      case 1:
        return 'Nearest \$2';
      case 2:
        return 'Nearest \$5';
      default:
        return 'Nearest \$1';
    }
  }

  double computeRoundUp(double amount) {
    final target = state == 0 ? 1.0 : (state == 1 ? 2.0 : 5.0);
    final remainder = amount % target;
    if (remainder == 0) return target;
    return double.parse((target - remainder).toStringAsFixed(2));
  }
}

final roundUpRuleProvider = StateNotifierProvider<RoundUpRuleNotifier, int>(
  (ref) => RoundUpRuleNotifier(),
);

// ── Notifications ──

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, state);
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, bool>(
  (ref) => NotificationsNotifier(),
);
