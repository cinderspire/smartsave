import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/revenue_cat_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../features/premium/presentation/screens/paywall_screen.dart';

/// Wraps a child behind a premium check. Shows a lock overlay for free users.
class PremiumGate extends ConsumerWidget {
  final Widget child;
  final String featureName;

  const PremiumGate({
    super.key,
    required this.child,
    this.featureName = 'This feature',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);
    if (isPremium) return child;

    return Stack(
      children: [
        // Blurred / dimmed content preview
        IgnorePointer(
          child: Opacity(opacity: 0.3, child: child),
        ),
        // Lock overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () => PaywallScreen.show(context),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundDark.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: AppColors.wealthGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$featureName requires Premium',
                      style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to unlock',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGreen),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small premium badge icon to show on nav items / buttons.
class PremiumBadge extends ConsumerWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);
    if (isPremium) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        gradient: AppColors.wealthGradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 10),
    );
  }
}
