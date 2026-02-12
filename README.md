# Rebecca 💰

**Personal Finance, Budget Tracking & Micro-Savings — Powered by RevenueCat**

> RevenueCat Hackathon Submission — "Rebecca" Brief (Money/Finance)

---

## 🎯 What is Rebecca?

Rebecca is an all-in-one personal finance app that combines **budget tracking**, **savings goals**, **micro-investing awareness**, and **gamified savings challenges** into a beautiful, dark-mode-first experience.

All calculations are performed **on-device** — no external finance APIs required.

## ✨ Features

### Free Tier
- 📊 **Dashboard** — Total savings overview, streaks, quick actions
- 🎯 **Savings Goals** — Create and track multiple goals with milestone celebrations
- 💰 **Round-Up Savings** — Simulate purchases and save spare change automatically
- 🏆 **Savings Challenges** — 52-Week, No-Spend, Penny, and Round-Up challenges
- 🏦 **Money Jars** — Categorized savings buckets with auto-allocation rules
- 📈 **Basic Statistics** — Monthly savings charts, savings breakdown
- 💡 **Smart Tips** — Personalized on-device financial tips
- 🎨 **Dark/Light Theme** — Full theme support
- 🛡️ **Onboarding** — Guided first-run experience

### Premium (RevenueCat) 👑
- 🧠 **AI-Powered Insights** — Deep spending analysis and personalized recommendations
- 📊 **Advanced Statistics** — Forecasts, trends, and deep-dive analytics
- 💱 **Multi-Currency** — 10+ currencies with on-device conversion
- 📤 **Export & Reports** — Download data as CSV
- 🎨 **Custom Themes** — Premium visual customizations
- 📈 **Investment Tracker** — Simulated micro-investing with growth projections

## 🏗️ Architecture

- **Framework:** Flutter 3.x (Dart)
- **State Management:** Riverpod
- **Local Storage:** SharedPreferences + Hive
- **Charts:** fl_chart
- **Monetization:** RevenueCat (`purchases_flutter ^8.1.0`)
- **Fonts:** Google Fonts (Inter)
- **Platforms:** iOS 15+ / Android API 24+

## 🔑 RevenueCat Integration

Rebecca uses RevenueCat for subscription management:

| Component | Location |
|---|---|
| Service singleton | `lib/core/services/revenue_cat_service.dart` |
| Premium state provider | `premiumProvider` (Riverpod StateNotifier) |
| Offerings provider | `offeringsProvider` (Riverpod FutureProvider) |
| Paywall screen | `lib/features/premium/presentation/screens/paywall_screen.dart` |
| Premium gate widget | `lib/core/widgets/premium_gate.dart` |

### Setup
1. Create a project in [RevenueCat Dashboard](https://app.revenuecat.com)
2. Replace API keys in `lib/core/services/revenue_cat_service.dart`:
   ```dart
   const _rcAppleApiKey = 'appl_YOUR_KEY';
   const _rcGoogleApiKey = 'goog_YOUR_KEY';
   ```
3. Create an entitlement named `rebecca_premium`
4. Configure products/offerings in the dashboard

### Paywall Flow
- Free users see a lock overlay on premium features (via `PremiumGate` widget)
- Tapping the lock opens the full-screen paywall with RevenueCat offerings
- Fallback UI shown when offerings are unavailable (e.g., simulator/demo)
- Demo mode: "Start Free Trial" button simulates purchase for hackathon judging

## 🚀 Getting Started

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build for iOS
flutter build ios --no-codesign

# Build for Android
flutter build appbundle
```

## 📁 Project Structure

```
lib/
├── core/
│   ├── services/          # RevenueCat service
│   ├── theme/             # Colors, text styles
│   └── widgets/           # PremiumGate, animated widgets
├── features/
│   ├── budget/            # Budget tracking screen
│   ├── challenges/        # Savings challenges
│   ├── coach/             # Financial coach
│   ├── goals/             # Savings goals + providers + models
│   ├── home/              # Dashboard + navigation
│   ├── jars/              # Money jars
│   ├── onboarding/        # First-run experience
│   ├── premium/           # Paywall screen
│   ├── profile/           # Settings + premium subscription
│   ├── roundup/           # Round-up savings
│   ├── stats/             # Statistics (partially premium-gated)
│   └── tips/              # Smart financial tips
├── shared/widgets/        # Glassmorphic containers, buttons
└── main.dart              # App entry point
```

## 📄 License

Built for the RevenueCat Hackathon. All rights reserved.

---

*Built with ❤️ using Flutter & RevenueCat*
