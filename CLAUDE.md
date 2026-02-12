# Rebecca (formerly SmartSave)

> Personal Finance, Budget Tracking & Micro-Savings — Powered by RevenueCat

## Project Info
- **Type:** Flutter App
- **Version:** 1.0.0+1
- **Organization:** com.cinderspire
- **Platforms:** iOS, Android
- **Monetization:** RevenueCat (purchases_flutter)

## Commands
```bash
flutter pub get          # Install deps
flutter run              # Debug run
flutter test             # Run tests
flutter build ios --no-codesign  # iOS build
flutter build appbundle  # Android AAB
```

## Key Dependencies
flutter, flutter_riverpod, google_fonts, fl_chart, intl, shared_preferences, uuid, hive, hive_flutter, purchases_flutter

## Architecture
- State management: Riverpod (StateNotifier + Provider)
- Storage: SharedPreferences + Hive
- Entry point: lib/main.dart
- RevenueCat: lib/core/services/revenue_cat_service.dart
- Paywall: lib/features/premium/presentation/screens/paywall_screen.dart

## RevenueCat Setup
Replace API keys in `lib/core/services/revenue_cat_service.dart` with real keys.
Entitlement: `rebecca_premium`. Offering: `default`.

## Guidelines
- Follow existing code patterns
- Run tests before committing
- Keep pubspec.yaml clean
- Target iOS 15+ and Android API 24+
- All finance calculations must be on-device (no external APIs)
