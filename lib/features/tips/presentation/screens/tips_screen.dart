import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';
import '../../../goals/data/providers/smart_tips_provider.dart';

class TipsScreen extends ConsumerStatefulWidget {
  const TipsScreen({super.key});

  @override
  ConsumerState<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends ConsumerState<TipsScreen> {
  // AI Tip of the Day
  String? _aiTip;
  bool _aiTipLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAiTip();
  }

  Future<void> _loadAiTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTip = prefs.getString('ai_tip_of_day');
      final cachedDate = prefs.getString('ai_tip_date');
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (cachedTip != null && cachedDate == today) {
        if (mounted) setState(() { _aiTip = cachedTip; _aiTipLoading = false; });
        return;
      }

      final tip = await GeminiService().generate(
        'Give one unique, practical money-saving tip for today. Be specific and actionable. Keep it under 80 words. Do not use bullet points.',
        systemInstruction: 'You are a friendly financial advisor. Give fresh, creative savings tips.',
      );

      await prefs.setString('ai_tip_of_day', tip);
      await prefs.setString('ai_tip_date', today);
      if (mounted) setState(() { _aiTip = tip; _aiTipLoading = false; });
    } catch (e) {
      debugPrint('AI Tip error: $e');
      if (mounted) setState(() { _aiTipLoading = false; });
    }
  }

  // Compound interest calculator state
  double _principal = 1000;
  double _monthlyContribution = 100;
  double _annualRate = 7;
  int _years = 10;

  final _principalController = TextEditingController(text: '1000');
  final _monthlyController = TextEditingController(text: '100');
  final _rateController = TextEditingController(text: '7');

  @override
  void dispose() {
    _principalController.dispose();
    _monthlyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  double _calculateCompoundInterest() {
    final r = _annualRate / 100 / 12;
    final n = _years * 12;
    // Future value of principal
    final fvPrincipal = _principal * pow(1 + r, n);
    // Future value of monthly contributions
    final fvContributions =
        r > 0 ? _monthlyContribution * ((pow(1 + r, n) - 1) / r) : _monthlyContribution * n;
    return fvPrincipal + fvContributions;
  }

  double _calculateTotalContributed() {
    return _principal + (_monthlyContribution * _years * 12);
  }

  @override
  Widget build(BuildContext context) {
    final smartTips = ref.watch(smartTipsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Tips & Education',
          style:
              AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundDark,
              AppColors.backgroundDark.withBlue(30)
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Tip of the Day
                _buildAiTipOfDay(),
                const SizedBox(height: 24),

                // Savings Tips Carousel
                _buildTipsCarousel(smartTips),
                const SizedBox(height: 24),

                // Financial Literacy Snippets
                _buildFinancialLiteracySection(),
                const SizedBox(height: 24),

                // Compound Interest Calculator
                _buildCompoundInterestCalculator(),
                const SizedBox(height: 24),

                // Quick Financial Facts
                _buildQuickFacts(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiTipOfDay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.15),
            AppColors.primaryBlue.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'AI Tip of the Day',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_aiTipLoading)
            _buildShimmer()
          else if (_aiTip != null)
            Text(
              _aiTip!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimaryDark,
                height: 1.6,
              ),
            )
          else
            Text(
              'Check back later for your personalized AI tip!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 14,
          width: i == 2 ? 180 : double.infinity,
          decoration: BoxDecoration(
            color: AppColors.backgroundDarkElevated,
            borderRadius: BorderRadius.circular(7),
          ),
        );
      }),
    );
  }

  Widget _buildTipsCarousel(List<SmartTip> tips) {
    final allTips = [
      ...tips,
      // Add static savings tips if smart tips are few
      if (tips.length < 3) ..._getStaticTips(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_rounded,
                color: AppColors.accentGold, size: 24),
            const SizedBox(width: 8),
            Text(
              'Savings Tips',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: allTips.length.clamp(0, 8),
            itemBuilder: (context, index) {
              final tip = allTips[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tip.color.withValues(alpha: 0.2),
                      tip.color.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tip.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tip.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(tip.icon, color: tip.color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tip.title,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: tip.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tip.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tip.potentialSaving,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: tip.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Text(
                        tip.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryDark,
                          height: 1.5,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<SmartTip> _getStaticTips() {
    return [
      SmartTip(
        id: 'static_50_30_20',
        title: '50/30/20 Rule',
        description:
            'Allocate 50% of income to needs, 30% to wants, and 20% to savings. This simple rule helps maintain financial balance.',
        potentialSaving: '20% income',
        icon: Icons.pie_chart_rounded,
        color: const Color(0xFF10B981),
        category: 'education',
      ),
      SmartTip(
        id: 'static_emergency',
        title: 'Emergency Fund',
        description:
            'Aim for 3-6 months of expenses in an emergency fund. Start with \$1,000, then build up gradually. This protects against unexpected costs.',
        potentialSaving: '3-6 months',
        icon: Icons.shield_rounded,
        color: const Color(0xFF3B82F6),
        category: 'education',
      ),
      SmartTip(
        id: 'static_automate',
        title: 'Automate Savings',
        description:
            'Set up automatic transfers to savings on payday. You cannot spend what you never see. Pay yourself first!',
        potentialSaving: 'Auto-save',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF8B5CF6),
        category: 'education',
      ),
    ];
  }

  Widget _buildFinancialLiteracySection() {
    final snippets = [
      {
        'title': 'The Power of Compound Interest',
        'content':
            'Albert Einstein called compound interest the "eighth wonder of the world." Your money earns interest on interest, creating exponential growth over time.',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Pay Yourself First',
        'content':
            'Before paying bills or spending, set aside savings. Even \$5/day adds up to \$1,825/year. Treat savings as a non-negotiable expense.',
        'icon': Icons.savings_rounded,
        'color': const Color(0xFFFFB020),
      },
      {
        'title': 'The Latte Factor',
        'content':
            'Small daily expenses add up. A \$5 daily coffee costs \$1,825/year. Invested at 7% for 30 years, that becomes over \$185,000.',
        'icon': Icons.coffee_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Rule of 72',
        'content':
            'Divide 72 by your annual return rate to estimate how many years it takes to double your money. At 7%, your money doubles in ~10.3 years.',
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Inflation Matters',
        'content':
            'With 3% average inflation, \$100 today will only have the purchasing power of ~\$74 in 10 years. Investing helps your money outpace inflation.',
        'icon': Icons.show_chart_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'title': 'Diversification',
        'content':
            'Do not put all eggs in one basket. Spread your savings across different accounts, investments, and goals to reduce risk.',
        'icon': Icons.grid_view_rounded,
        'color': const Color(0xFF06B6D4),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school_rounded, color: AppColors.primaryBlue, size: 24),
            const SizedBox(width: 8),
            Text(
              'Financial Literacy',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...snippets.map((snippet) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.backgroundDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: (snippet['color'] as Color).withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          (snippet['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(snippet['icon'] as IconData,
                        color: snippet['color'] as Color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snippet['title'] as String,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: snippet['color'] as Color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          snippet['content'] as String,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryDark,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCompoundInterestCalculator() {
    final futureValue = _calculateCompoundInterest();
    final totalContributed = _calculateTotalContributed();
    final interestEarned = futureValue - totalContributed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calculate_rounded,
                color: AppColors.primaryGreen, size: 24),
            const SizedBox(width: 8),
            Text(
              'Compound Interest Calculator',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              // Principal
              _buildCalcInput(
                'Initial Investment',
                _principalController,
                '\$',
                (v) {
                  setState(() {
                    _principal = double.tryParse(v) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 14),

              // Monthly contribution
              _buildCalcInput(
                'Monthly Contribution',
                _monthlyController,
                '\$',
                (v) {
                  setState(() {
                    _monthlyContribution = double.tryParse(v) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 14),

              // Annual rate
              _buildCalcInput(
                'Annual Return Rate',
                _rateController,
                '%',
                (v) {
                  setState(() {
                    _annualRate = double.tryParse(v) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 14),

              // Years slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Time Period',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textTertiaryDark)),
                  Text('$_years years',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primaryGreen,
                  inactiveTrackColor: AppColors.backgroundDarkElevated,
                  thumbColor: AppColors.primaryGreen,
                  overlayColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _years.toDouble(),
                  min: 1,
                  max: 40,
                  divisions: 39,
                  onChanged: (v) => setState(() => _years = v.round()),
                ),
              ),
              const SizedBox(height: 20),

              // Results
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen.withValues(alpha: 0.15),
                      AppColors.primaryBlue.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text('Future Value',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiaryDark)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${NumberFormat('#,##0').format(futureValue)}',
                      style: AppTextStyles.moneyLarge.copyWith(
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('Total Contributed',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textTertiaryDark)),
                              const SizedBox(height: 4),
                              Text(
                                '\$${NumberFormat('#,##0').format(totalContributed)}',
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.glassBorder,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text('Interest Earned',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textTertiaryDark)),
                              const SizedBox(height: 4),
                              Text(
                                '\$${NumberFormat('#,##0').format(interestEarned)}',
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.accentGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalcInput(String label, TextEditingController controller,
      String prefix, ValueChanged<String> onChanged) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiaryDark)),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.textPrimaryDark),
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixText: prefix == '\$' ? '\$ ' : null,
              suffixText: prefix == '%' ? '%' : null,
              prefixStyle: const TextStyle(color: AppColors.primaryGreen),
              suffixStyle: const TextStyle(color: AppColors.primaryGreen),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primaryGreen),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFacts() {
    final facts = [
      'The average American saves only 5.8% of their income.',
      'Starting to save at 25 vs 35 can double your retirement fund.',
      'A penny saved is worth more than a penny earned due to taxes.',
      'It takes 21 days to form a new savings habit.',
      '78% of workers live paycheck to paycheck without savings.',
      'The S&P 500 has returned ~10% annually over the last century.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_stories_rounded,
                color: Color(0xFFEC4899), size: 24),
            const SizedBox(width: 8),
            Text(
              'Did You Know?',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...facts.asMap().entries.map((entry) {
          final colors = [
            const Color(0xFF10B981),
            const Color(0xFF3B82F6),
            const Color(0xFFFFB020),
            const Color(0xFF8B5CF6),
            const Color(0xFFEF4444),
            const Color(0xFF06B6D4),
          ];
          final color = colors[entry.key % colors.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDarkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondaryDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
