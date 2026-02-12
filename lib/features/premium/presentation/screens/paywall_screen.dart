import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/revenue_cat_service.dart';

/// Full-screen paywall presented when a free user taps a premium feature.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  /// Convenience: push as a modal route. Returns `true` if user unlocked premium.
  static Future<bool> show(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
    return result ?? false;
  }

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textTertiaryDark),
                ),
              ),

              // Hero icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.wealthGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 24),
              Text(
                'Unlock Rebecca Premium',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Take full control of your finances',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondaryDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Feature list
              ..._features.map((f) => _buildFeatureRow(f['icon'] as IconData, f['title'] as String, f['desc'] as String)),

              const SizedBox(height: 32),

              // Packages from RevenueCat (or fallback)
              offeringsAsync.when(
                data: (offerings) {
                  final pkgs = offerings?.current?.availablePackages ?? [];
                  if (pkgs.isEmpty) {
                    return _buildFallbackPurchaseButton();
                  }
                  return Column(
                    children: pkgs.map((pkg) => _buildPackageButton(pkg)).toList(),
                  );
                },
                loading: () => const CircularProgressIndicator(color: AppColors.primaryGreen),
                error: (_, __) => _buildFallbackPurchaseButton(),
              ),

              const SizedBox(height: 16),

              // Restore
              TextButton(
                onPressed: _loading ? null : _restore,
                child: Text(
                  'Restore Purchases',
                  style: AppTextStyles.button.copyWith(color: AppColors.textTertiaryDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cancel anytime. Payment charged to your App Store / Play Store account.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static final _features = [
    {
      'icon': Icons.insights_rounded,
      'title': 'AI-Powered Insights',
      'desc': 'Smart spending analysis & personalized savings tips',
    },
    {
      'icon': Icons.show_chart_rounded,
      'title': 'Investment Tracker',
      'desc': 'Simulated micro-investing with growth projections',
    },
    {
      'icon': Icons.currency_exchange_rounded,
      'title': 'Multi-Currency Support',
      'desc': '10+ currencies with on-device conversion',
    },
    {
      'icon': Icons.file_download_rounded,
      'title': 'Export & Reports',
      'desc': 'Download your data as CSV for tax or planning',
    },
    {
      'icon': Icons.bar_chart_rounded,
      'title': 'Advanced Statistics',
      'desc': 'Deep-dive charts, trends, and forecasts',
    },
    {
      'icon': Icons.palette_rounded,
      'title': 'Custom Themes',
      'desc': 'Personalize your experience with premium themes',
    },
  ];

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark)),
                Text(desc, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 20),
        ],
      ),
    );
  }

  Widget _buildPackageButton(Package pkg) {
    final product = pkg.storeProduct;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: _loading ? null : () => _purchase(pkg),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                '${product.title} — ${product.priceString}',
                style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildFallbackPurchaseButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _simulatePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'Start Free Trial — \$1.99/month',
                    style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _loading ? null : _simulatePurchase,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'Annual — \$9.99/year (save 58%)',
              style: AppTextStyles.button.copyWith(color: AppColors.primaryGreen, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _purchase(Package pkg) async {
    setState(() => _loading = true);
    final success = await RevenueCatService.instance.purchase(pkg);
    if (success && mounted) {
      ref.read(premiumProvider.notifier).setPremium(true);
      Navigator.pop(context, true);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    final success = await RevenueCatService.instance.restore();
    if (success && mounted) {
      ref.read(premiumProvider.notifier).setPremium(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium restored!')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous purchase found.')),
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Used when offerings are unavailable (demo / hackathon mode).
  Future<void> _simulatePurchase() async {
    setState(() => _loading = true);
    // In production this would call RevenueCat. For the hackathon demo we just
    // unlock premium locally so judges can test the full experience.
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ref.read(premiumProvider.notifier).setPremium(true);
      Navigator.pop(context, true);
    }
  }
}
