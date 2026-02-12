# 💰 SmartSave

### Spare Change. Superpowered.

> Round-ups, money jars, and savings challenges — one beautifully designed app that turns every spare cent into your financial future.

<p align="center">
  <img src="screenshots/screenshot1.png" width="200" />
  <img src="screenshots/screenshot2.png" width="200" />
  <img src="screenshots/screenshot3.png" width="200" />
</p>

---

## ✨ Features

| | Feature | Description |
|---|---|---|
| 🏦 | **Smart Dashboard** | Total savings, round-up totals, streak counter & quick-action buttons in glassmorphic cards |
| 🎯 | **Savings Goals** | Named targets with visual progress tracking and percentage completion |
| 🪙 | **Round-Up Savings** | Every purchase rounds up ($1/$2/$5) — spare change compounds into real money |
| 🏺 | **Money Jars** | Envelope-style budgeting with **Auto-Split** allocation across jars |
| 📊 | **Budget Tracker** | Category-based budgets with pie charts and overspending alerts |
| 🏆 | **Savings Challenges** | 30-Day, 52-Week, No-Spend Week — gamified programs with progress tracking |
| 🔥 | **Streaks** | Current & best streak tracking to reward consistency |
| 📈 | **Stats & Insights** | Savings rate, monthly trends, breakdown charts — advanced analytics for Pro |
| 🤖 | **AI Financial Coach** | Conversational coach for budgets, investing, debt & tax tips |
| 💡 | **Compound Interest Calculator** | Interactive tool to visualize long-term savings growth |

## 💎 Premium (RevenueCat)

| Free | Premium |
|------|---------|
| Dashboard, basic goals, round-ups, streaks, tips | Unlimited goals, Money Jars + Auto-Split, advanced stats, AI Coach, all challenges |

RevenueCat is **architecturally embedded** — not bolted on:

- **`RevenueCatService` singleton** with graceful degradation to free-tier
- **Riverpod providers** (`isPremiumProvider`, `offeringsProvider`) for reactive premium state
- **`PremiumGate` widget** — reusable lock overlay with upgrade CTA
- **Strategic paywall touchpoints** that surface through value demonstration
- Entitlement: `rebecca_premium` · Full restore support · Platform-aware API keys

## 🎨 Design

**Neon Fintech** — Deep navy `#0A1628` background, neon green `#39FF14` primary, electric blue `#00E5FF` secondary. Glassmorphic containers with blur effects. Gold `#FFD700` for achievements.

## 🛠 Tech Stack

- **Flutter + Dart** — Cross-platform
- **Riverpod** — 15+ reactive providers
- **Hive + SharedPreferences** — Local-first, zero servers
- **RevenueCat** `purchases_flutter ^8.1.0`
- **fl_chart** — Animated visualizations
- **Google Fonts** · **intl** · **uuid**

## 🏗 Build & Run

```bash
flutter pub get
flutter run
```

Bundle ID: `com.cinderspire.smartsave`

## 🔒 Privacy

All financial data stored **locally on-device** via Hive. No cloud. No tracking.

**Privacy Policy:** https://playtools.top/privacy-policy.html

## 👤 Developer

**MUSTAFA BILGIC** · [cinderspire](https://github.com/cinderspire)

---

*Because building wealth shouldn't feel like a sacrifice — it should feel like a game you're winning.* 🚀
