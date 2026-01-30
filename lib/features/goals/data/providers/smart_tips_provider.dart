import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'savings_provider.dart';
import 'challenge_provider.dart';
import 'money_jar_provider.dart';

class SmartTip {
  final String id;
  final String title;
  final String description;
  final String potentialSaving;
  final IconData icon;
  final Color color;
  final String category;
  final bool isDismissed;

  SmartTip({
    required this.id,
    required this.title,
    required this.description,
    required this.potentialSaving,
    required this.icon,
    required this.color,
    required this.category,
    this.isDismissed = false,
  });
}

final smartTipsProvider = Provider<List<SmartTip>>((ref) {
  final goals = ref.watch(savingsGoalsProvider);
  final streak = ref.watch(savingsStreakProvider);
  final roundUps = ref.watch(roundUpProvider);
  final challenges = ref.watch(challengesProvider);
  final monthlySavings = ref.watch(monthlySavingsProvider);
  final jars = ref.watch(moneyJarsProvider);

  final tips = <SmartTip>[];

  // Tip based on round-up spending patterns
  final recentRoundUps = roundUps
      .where(
          (t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
      .toList();

  // Dining out analysis
  final diningRoundUps = recentRoundUps
      .where((t) =>
          t.merchant.toLowerCase().contains('restaurant') ||
          t.merchant.toLowerCase().contains('coffee') ||
          t.merchant.toLowerCase().contains('fast food') ||
          t.merchant.toLowerCase().contains('cafe'))
      .toList();

  if (diningRoundUps.length >= 2) {
    final diningTotal = diningRoundUps.fold(
        0.0, (sum, t) => sum + t.originalAmount);
    final potentialSaving = (diningTotal * 0.3).toStringAsFixed(0);
    tips.add(SmartTip(
      id: 'dining_reduce',
      title: 'Reduce Dining Out',
      description:
          'You spent \$${diningTotal.toStringAsFixed(0)} on dining this month. Cooking at home 3 more times/week could save you \$$potentialSaving/month.',
      potentialSaving: '\$$potentialSaving/mo',
      icon: Icons.restaurant_rounded,
      color: const Color(0xFFFF6B6B),
      category: 'spending',
    ));
  }

  // Streak motivation
  if (streak.currentStreak > 0 && streak.currentStreak < 7) {
    tips.add(SmartTip(
      id: 'streak_boost',
      title: 'Build Your Streak',
      description:
          'You are on a ${streak.currentStreak}-day saving streak! Reach 7 days to unlock streak bonuses. Keep saving daily!',
      potentialSaving: '7-day goal',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFFF6B35),
      category: 'motivation',
    ));
  } else if (streak.currentStreak >= 7 && streak.currentStreak < 30) {
    tips.add(SmartTip(
      id: 'streak_milestone',
      title: 'Streak on Fire!',
      description:
          '${streak.currentStreak} days strong! Your next milestone is 30 days. At this rate, you are building great savings habits.',
      potentialSaving: '30-day goal',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFFFB020),
      category: 'motivation',
    ));
  } else if (streak.currentStreak >= 30) {
    tips.add(SmartTip(
      id: 'streak_legend',
      title: 'Savings Legend!',
      description:
          'Incredible ${streak.currentStreak}-day streak! You are in the top 5% of savers. Your discipline is paying off.',
      potentialSaving: 'Top saver',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFF10B981),
      category: 'motivation',
    ));
  }

  // Round-up potential
  if (recentRoundUps.isNotEmpty) {
    final avgRoundUp = recentRoundUps.fold(0.0, (sum, t) => sum + t.roundUpAmount) /
        recentRoundUps.length;
    final projected = (avgRoundUp * 30).toStringAsFixed(0);
    tips.add(SmartTip(
      id: 'roundup_projection',
      title: 'Round-Up Potential',
      description:
          'Your average round-up is \$${avgRoundUp.toStringAsFixed(2)}. At this rate, you could save \$$projected/month in spare change alone!',
      potentialSaving: '\$$projected/mo',
      icon: Icons.currency_exchange_rounded,
      color: const Color(0xFF3B82F6),
      category: 'savings',
    ));
  }

  // Challenge suggestion
  final activeChallenges = challenges.where((c) => c.isActive).toList();
  if (activeChallenges.isEmpty) {
    tips.add(SmartTip(
      id: 'challenge_start',
      title: 'Start a Challenge',
      description:
          'The 52-week challenge can help you save \$1,378 this year! Start small and build up weekly.',
      potentialSaving: '\$1,378/yr',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFF8B5CF6),
      category: 'challenge',
    ));
  } else if (activeChallenges.length == 1) {
    tips.add(SmartTip(
      id: 'challenge_add',
      title: 'Add Another Challenge',
      description:
          'You are doing great with ${activeChallenges.first.name}! Adding a No-Spend Day challenge could boost your savings even more.',
      potentialSaving: '+\$300/mo',
      icon: Icons.add_circle_rounded,
      color: const Color(0xFF8B5CF6),
      category: 'challenge',
    ));
  }

  // Monthly savings trend
  if (monthlySavings.length >= 2) {
    final sortedKeys = monthlySavings.keys.toList()..sort();
    final lastTwo = sortedKeys.length >= 2
        ? sortedKeys.sublist(sortedKeys.length - 2)
        : sortedKeys;
    if (lastTwo.length == 2) {
      final prev = monthlySavings[lastTwo[0]] ?? 0.0;
      final curr = monthlySavings[lastTwo[1]] ?? 0.0;
      if (curr > prev && prev > 0) {
        final increase = ((curr - prev) / prev * 100).toStringAsFixed(0);
        tips.add(SmartTip(
          id: 'trend_up',
          title: 'Savings Trending Up!',
          description:
              'Your savings increased by $increase% compared to last month. Keep this momentum going!',
          potentialSaving: '+$increase%',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF10B981),
          category: 'insight',
        ));
      } else if (curr < prev && prev > 0) {
        final decrease = ((prev - curr) / prev * 100).toStringAsFixed(0);
        tips.add(SmartTip(
          id: 'trend_down',
          title: 'Savings Dipped',
          description:
              'Your savings decreased by $decrease% this month. Consider setting up auto-deposits to stay consistent.',
          potentialSaving: 'Auto-save',
          icon: Icons.trending_down_rounded,
          color: const Color(0xFFEF4444),
          category: 'insight',
        ));
      }
    }
  }

  // Goal completion projection
  final incompleteGoals =
      goals.where((g) => !g.isComplete && g.daysLeft > 0).toList();
  for (final goal in incompleteGoals.take(1)) {
    final dailyNeeded = goal.remaining / goal.daysLeft;
    if (dailyNeeded > 0) {
      tips.add(SmartTip(
        id: 'goal_pace_${goal.id}',
        title: 'Goal: ${goal.name}',
        description:
            'Save \$${dailyNeeded.toStringAsFixed(2)}/day to reach your ${goal.name} goal on time. That is \$${(dailyNeeded * 7).toStringAsFixed(0)}/week.',
        potentialSaving: '\$${dailyNeeded.toStringAsFixed(0)}/day',
        icon: Icons.flag_rounded,
        color: const Color(0xFFEC4899),
        category: 'goal',
      ));
    }
  }

  // Money jar tip
  final unallocatedJars = jars.where((j) => j.allocationPercent == 0).toList();
  if (unallocatedJars.isNotEmpty && jars.length > 1) {
    tips.add(SmartTip(
      id: 'jar_allocation',
      title: 'Set Up Auto-Allocation',
      description:
          '${unallocatedJars.length} of your money jars have no allocation rule. Set percentages to auto-distribute deposits.',
      potentialSaving: 'Auto-split',
      icon: Icons.account_balance_rounded,
      color: const Color(0xFF06B6D4),
      category: 'jars',
    ));
  }

  // Subscription savings tip (always show as a general tip)
  tips.add(SmartTip(
    id: 'subscription_review',
    title: 'Review Subscriptions',
    description:
        'The average person spends \$219/month on subscriptions. Review yours to find savings. Cancel unused services.',
    potentialSaving: '\$50-100/mo',
    icon: Icons.subscriptions_rounded,
    color: const Color(0xFFF59E0B),
    category: 'spending',
  ));

  return tips;
});
