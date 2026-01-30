import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../goals/data/models/savings_challenge.dart';
import '../../../goals/data/providers/challenge_provider.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(challengesProvider);
    final activeChallenges = ref.watch(activeChallengesProvider);
    final totalChallengeSaved = ref.watch(totalChallengeSavingsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Challenges',
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateChallengeSheet(context, ref),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.backgroundDark, AppColors.backgroundDark.withBlue(30)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(activeChallenges.length, totalChallengeSaved),
                const SizedBox(height: 24),
                Text(
                  'Active Challenges',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (activeChallenges.isEmpty)
                  _buildEmptyState(context, ref)
                else
                  ...activeChallenges.map((c) => _buildChallengeCard(context, ref, c)),
                const SizedBox(height: 24),
                if (challenges.where((c) => !c.isActive).isNotEmpty) ...[
                  Text(
                    'Paused Challenges',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...challenges.where((c) => !c.isActive).map((c) => _buildChallengeCard(context, ref, c)),
                ],
                const SizedBox(height: 24),
                _buildChallengeIdeasCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(int activeCount, double totalSaved) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenge Savings',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${totalSaved.toStringAsFixed(2)}',
                  style: AppTextStyles.moneyLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '$activeCount active challenges',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, WidgetRef ref, SavingsChallenge challenge) {
    final color = _challengeColor(challenge.type);
    final icon = _challengeIcon(challenge.type);
    final progress = challenge.durationDays > 0
        ? (challenge.daysCompleted / challenge.durationDays).clamp(0.0, 1.0)
        : 0.0;

    // Expected vs actual savings tracking
    final expectedSavings = challenge.expectedSavings;
    final isAhead = challenge.totalSaved >= expectedSavings;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showChallengeDetailSheet(context, ref, challenge);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(challenge.isActive ? 0.4 : 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Circular progress indicator around icon
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor: AppColors.backgroundDarkElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              challenge.name,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: challenge.isActive
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textTertiaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!challenge.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.textTertiaryDark.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PAUSED',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textTertiaryDark,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isAhead
                                    ? AppColors.profit.withOpacity(0.15)
                                    : AppColors.loss.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isAhead ? 'ON TRACK' : 'BEHIND',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isAhead ? AppColors.profit : AppColors.loss,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${challenge.daysCompleted} of ${challenge.durationDays} days',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Visual week/day grid for challenge progress
            _buildChallengeVisualGrid(challenge, color),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.backgroundDarkElevated,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
                    Text(
                      '\$${challenge.totalSaved.toStringAsFixed(2)}',
                      style: AppTextStyles.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Expected', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
                    Text(
                      '\$${expectedSavings.toStringAsFixed(2)}',
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Progress', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimaryDark),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeVisualGrid(SavingsChallenge challenge, Color color) {
    switch (challenge.type) {
      case ChallengeType.fiftyTwoWeek:
        return _buildWeekGrid(challenge, color);
      case ChallengeType.noSpend:
        return _buildNoSpendGrid(challenge, color);
      case ChallengeType.penny:
        return _buildDayGrid(challenge, color);
      case ChallengeType.roundUp:
        return _buildRoundUpVisual(challenge, color);
    }
  }

  Widget _buildWeekGrid(SavingsChallenge challenge, Color color) {
    // Show weeks 1-12 in a compact grid (first 12 weeks)
    final completedWeeks = challenge.entries.length;
    final currentWeek = challenge.currentWeek;
    final weeksToShow = currentWeek.clamp(0, 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Progress', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(weeksToShow, (i) {
            final weekNum = i + 1;
            final isCompleted = i < completedWeeks;
            final isCurrent = weekNum == currentWeek && !isCompleted;
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? color
                    : isCurrent
                        ? color.withOpacity(0.3)
                        : AppColors.backgroundDarkElevated,
                borderRadius: BorderRadius.circular(8),
                border: isCurrent ? Border.all(color: color, width: 2) : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : Text(
                        '\$$weekNum',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isCurrent ? color : AppColors.textTertiaryDark,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNoSpendGrid(SavingsChallenge challenge, Color color) {
    // Show the last 14 days
    final completedDates = challenge.entries.map((e) {
      final d = e.date;
      return DateTime(d.year, d.month, d.day);
    }).toSet();
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('No-Spend Days', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark)),
            Text('${challenge.entries.length} days', style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final day = DateTime.now().subtract(Duration(days: 6 - i));
            final dayDate = DateTime(day.year, day.month, day.day);
            final isNoSpend = completedDates.contains(dayDate);
            return Column(
              children: [
                Text(dayNames[day.weekday - 1], style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark)),
                const SizedBox(height: 4),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNoSpend ? color : AppColors.backgroundDarkElevated,
                    border: !isNoSpend ? Border.all(color: AppColors.glassBorder) : null,
                  ),
                  child: isNoSpend
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : Center(child: Text('${day.day}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark))),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDayGrid(SavingsChallenge challenge, Color color) {
    final completedDays = challenge.entries.length;
    final currentDay = challenge.currentDay;
    final daysToShow = currentDay.clamp(0, 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Penny Progress', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark)),
            Text('Day $currentDay of ${challenge.durationDays}', style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(daysToShow, (i) {
            final dayNum = i + 1;
            final isCompleted = i < completedDays;
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? color : AppColors.backgroundDarkElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : Text('$dayNum', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 9)),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRoundUpVisual(SavingsChallenge challenge, Color color) {
    // Show recent round-up amounts as visual bars
    final recent = challenge.entries.reversed.take(7).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    final maxAmount = recent.fold(0.0, (max, e) => e.amount > max ? e.amount : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Round-ups', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: recent.map((entry) {
            final height = maxAmount > 0 ? (entry.amount / maxAmount * 40).clamp(6.0, 40.0) : 6.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    Text(
                      '\$${entry.amount.toStringAsFixed(2)}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark, fontSize: 8),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.emoji_events_rounded, color: AppColors.textTertiaryDark, size: 56),
            const SizedBox(height: 16),
            Text(
              'No active challenges',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a savings challenge to boost your savings!',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Start Challenge',
              onPressed: () => _showCreateChallengeSheet(context, ref),
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeIdeasCard() {
    final ideas = [
      {'title': '52-Week Challenge', 'desc': 'Save \$1 week 1, \$2 week 2... total \$1,378', 'icon': Icons.calendar_month_rounded, 'color': const Color(0xFF10B981)},
      {'title': 'Penny Challenge', 'desc': 'Save 1c day 1, 2c day 2... total \$667.95', 'icon': Icons.monetization_on_rounded, 'color': const Color(0xFFFFB020)},
      {'title': 'No-Spend Days', 'desc': 'Track days without spending. Save \$10 each!', 'icon': Icons.block_rounded, 'color': const Color(0xFFEF4444)},
      {'title': 'Round-Up Saver', 'desc': 'Round up purchases, save the difference', 'icon': Icons.currency_exchange_rounded, 'color': const Color(0xFF3B82F6)},
    ];

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge Ideas',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...ideas.map((idea) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (idea['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(idea['icon'] as IconData, color: idea['color'] as Color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idea['title'] as String,
                        style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark),
                      ),
                      Text(
                        idea['desc'] as String,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showChallengeDetailSheet(BuildContext context, WidgetRef ref, SavingsChallenge challenge) {
    final color = _challengeColor(challenge.type);
    final icon = _challengeIcon(challenge.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.backgroundDarkElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiaryDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              challenge.name,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.textPrimaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              challenge.description,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    children: [
                      _buildDetailStat('Total Saved', '\$${challenge.totalSaved.toStringAsFixed(2)}', color),
                      const SizedBox(width: 16),
                      _buildDetailStat('Entries', '${challenge.entries.length}', AppColors.primaryBlue),
                      const SizedBox(width: 16),
                      _buildDetailStat('Day', '${challenge.currentDay}', AppColors.accentGold),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showLogEntrySheet(context, ref, challenge);
                          },
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Log Entry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(challengesProvider.notifier).toggleActive(challenge.id);
                            Navigator.pop(ctx);
                          },
                          icon: Icon(challenge.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
                          label: Text(challenge.isActive ? 'Pause' : 'Resume'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondaryDark,
                            side: BorderSide(color: AppColors.glassBorder),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Entries',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: challenge.entries.isEmpty
                  ? Center(
                      child: Text(
                        'No entries yet. Start logging!',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryDark),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: challenge.entries.length,
                      itemBuilder: (context, index) {
                        final entry = challenge.entries[challenge.entries.length - 1 - index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDarkCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                entry.completed ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: entry.completed ? color : AppColors.textTertiaryDark,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.note ?? 'Entry',
                                      style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark),
                                    ),
                                    Text(
                                      _formatDate(entry.date),
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+\$${entry.amount.toStringAsFixed(2)}',
                                style: AppTextStyles.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(challengesProvider.notifier).deleteChallenge(challenge.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${challenge.name} deleted')),
                    );
                  },
                  child: Text(
                    'Delete Challenge',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.loss),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.titleLarge.copyWith(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
          ],
        ),
      ),
    );
  }

  void _showLogEntrySheet(BuildContext context, WidgetRef ref, SavingsChallenge challenge) {
    Navigator.pop(context); // close detail sheet first
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    // Pre-fill based on challenge type
    switch (challenge.type) {
      case ChallengeType.fiftyTwoWeek:
        amountController.text = challenge.currentWeek.toString();
        noteController.text = 'Week ${challenge.currentWeek} saving';
        break;
      case ChallengeType.penny:
        amountController.text = (challenge.currentDay * 0.01).toStringAsFixed(2);
        noteController.text = 'Day ${challenge.currentDay} penny saving';
        break;
      case ChallengeType.noSpend:
        amountController.text = '10.00';
        noteController.text = 'No-spend day completed';
        break;
      case ChallengeType.roundUp:
        noteController.text = 'Round-up saving';
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundDarkElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiaryDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Log Entry',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              challenge.name,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'Amount (\$)',
                labelStyle: TextStyle(color: AppColors.textTertiaryDark),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: _challengeColor(challenge.type)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _challengeColor(challenge.type)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              style: TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                labelStyle: TextStyle(color: AppColors.textTertiaryDark),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _challengeColor(challenge.type)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    final entry = ChallengeEntry(
                      date: DateTime.now(),
                      amount: amount,
                      completed: true,
                      note: noteController.text.isNotEmpty ? noteController.text : null,
                    );
                    ref.read(challengesProvider.notifier).addEntry(challenge.id, entry);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logged \$${amount.toStringAsFixed(2)} for ${challenge.name}!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _challengeColor(challenge.type),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Log Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChallengeSheet(BuildContext context, WidgetRef ref) {
    ChallengeType selectedType = ChallengeType.fiftyTwoWeek;

    final challengeTemplates = {
      ChallengeType.fiftyTwoWeek: {
        'name': '52-Week Challenge',
        'description': 'Save \$1 in week 1, \$2 in week 2, and so on. By week 52, you will have saved \$1,378!',
        'days': 364,
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFF10B981),
      },
      ChallengeType.penny: {
        'name': 'Penny Challenge',
        'description': 'Save 1 cent on day 1, 2 cents on day 2, etc. By day 365, you save \$667.95!',
        'days': 365,
        'icon': Icons.monetization_on_rounded,
        'color': const Color(0xFFFFB020),
      },
      ChallengeType.noSpend: {
        'name': 'No-Spend Challenge',
        'description': 'Track days where you spend nothing. Save \$10 for each no-spend day!',
        'days': 30,
        'icon': Icons.block_rounded,
        'color': const Color(0xFFEF4444),
      },
      ChallengeType.roundUp: {
        'name': 'Round-Up Challenge',
        'description': 'Log your purchases and save the spare change by rounding up to the nearest dollar.',
        'days': 90,
        'icon': Icons.currency_exchange_rounded,
        'color': const Color(0xFF3B82F6),
      },
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: AppColors.backgroundDarkElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiaryDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Start a Challenge',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a savings challenge to boost your progress',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 24),
                ...ChallengeType.values.map((type) {
                  final template = challengeTemplates[type]!;
                  final isSelected = selectedType == type;
                  final color = template['color'] as Color;

                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedType = type),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.15) : AppColors.backgroundDarkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : AppColors.glassBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(template['icon'] as IconData, color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template['name'] as String,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: isSelected ? color : AppColors.textPrimaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  template['description'] as String,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: color, size: 24),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                GradientButton(
                  text: 'Start Challenge',
                  onPressed: () {
                    final template = challengeTemplates[selectedType]!;
                    final challenge = SavingsChallenge(
                      id: const Uuid().v4(),
                      type: selectedType,
                      name: template['name'] as String,
                      description: template['description'] as String,
                      startDate: DateTime.now(),
                      durationDays: template['days'] as int,
                    );
                    ref.read(challengesProvider.notifier).addChallenge(challenge);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${challenge.name} started!')),
                    );
                  },
                  width: double.infinity,
                  icon: Icons.emoji_events_rounded,
                  gradient: LinearGradient(
                    colors: [
                      challengeTemplates[selectedType]!['color'] as Color,
                      (challengeTemplates[selectedType]!['color'] as Color).withOpacity(0.7),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  Color _challengeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.fiftyTwoWeek: return const Color(0xFF10B981);
      case ChallengeType.penny: return const Color(0xFFFFB020);
      case ChallengeType.noSpend: return const Color(0xFFEF4444);
      case ChallengeType.roundUp: return const Color(0xFF3B82F6);
    }
  }

  IconData _challengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.fiftyTwoWeek: return Icons.calendar_month_rounded;
      case ChallengeType.penny: return Icons.monetization_on_rounded;
      case ChallengeType.noSpend: return Icons.block_rounded;
      case ChallengeType.roundUp: return Icons.currency_exchange_rounded;
    }
  }
}
