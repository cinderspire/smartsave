/// Central feature toggle — flip a bool to add/remove any feature.
/// Remote Config can override these at runtime.
class FeatureFlags {
  FeatureFlags._();

  // ─── AI Features ───
  static bool aiCoach = true;        // AI Chat coach (Gemini)
  static bool aiInsight = true;       // Daily AI insight on dashboard
  static bool aiSmartTips = true;     // AI-powered savings tips

  // ─── Core Features ───
  static bool expenses = true;        // Expense tracking with AI categorization
  static bool moneyJars = true;       // Visual savings jars
  static bool goals = true;           // Savings goals tracker
  static bool deposit = true;         // Manual deposit action
  static bool roundUp = false;        // Round-up micro-savings (disabled — no bank integration yet)

  // ─── Screens / Tabs ───
  static bool statsTab = true;        // Stats & charts
  static bool settingsTab = true;     // Settings / profile

  // ─── Removed / Disabled ───
  static bool streak = false;         // Day streak gamification
  static bool challenges = false;     // Weekly challenges
  static bool investingBasics = false; // Education section (coming soon)
  static bool budgetScreen = false;   // Full budget planner (coming soon)

  /// Apply overrides from Firebase Remote Config JSON.
  static void applyRemoteOverrides(Map<String, dynamic> overrides) {
    if (overrides.containsKey('ai_coach')) aiCoach = overrides['ai_coach'] as bool;
    if (overrides.containsKey('ai_insight')) aiInsight = overrides['ai_insight'] as bool;
    if (overrides.containsKey('ai_smart_tips')) aiSmartTips = overrides['ai_smart_tips'] as bool;
    if (overrides.containsKey('money_jars')) moneyJars = overrides['money_jars'] as bool;
    if (overrides.containsKey('goals')) goals = overrides['goals'] as bool;
    if (overrides.containsKey('round_up')) roundUp = overrides['round_up'] as bool;
    if (overrides.containsKey('streak')) streak = overrides['streak'] as bool;
    if (overrides.containsKey('challenges')) challenges = overrides['challenges'] as bool;
  }
}
