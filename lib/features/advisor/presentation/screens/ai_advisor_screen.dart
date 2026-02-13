import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/gemini_service.dart';

/// AI Advisor: user describes a situation → AI gives smart options.
/// Shopping, dining, subscriptions, bills — anything spending-related.
class AiAdvisorScreen extends StatefulWidget {
  final String? initialQuery;
  const AiAdvisorScreen({super.key, this.initialQuery});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _advice;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      _getAdvice();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('💡 AI Advisor', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimaryDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick scenario chips
              Text('What are you thinking about?',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _scenarioChip('🛒', 'Grocery shopping this week'),
                  _scenarioChip('👟', 'I want new sneakers (\$150)'),
                  _scenarioChip('📱', 'Should I upgrade my phone?'),
                  _scenarioChip('🍕', 'Eating out vs cooking tonight'),
                  _scenarioChip('🎄', 'Christmas gift budget'),
                  _scenarioChip('✈️', 'Planning a weekend trip'),
                  _scenarioChip('💊', 'Monthly subscriptions review'),
                  _scenarioChip('🏠', 'Energy bill too high'),
                ],
              ),
              const SizedBox(height: 20),

              // Input
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
                        decoration: InputDecoration(
                          hintText: 'Describe what you\'re spending on...',
                          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onSubmitted: (_) => _getAdvice(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: Icon(Icons.auto_awesome, color: AppColors.primaryGreen),
                              onPressed: _getAdvice,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Results
              if (_advice != null) ...[
                // Summary
                if (_advice!['summary'] != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryGreen.withValues(alpha: 0.15), AppColors.primaryGreen.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(_advice!['summary'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryDark, height: 1.5)),
                  ),
                const SizedBox(height: 16),

                // Options
                if (_advice!['options'] != null)
                  for (final option in (_advice!['options'] as List)) ...[
                    _buildOptionCard(option as Map<String, dynamic>),
                    const SizedBox(height: 12),
                  ],

                // Savings tip
                if (_advice!['savings_tip'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Savings Tip', style: AppTextStyles.labelMedium.copyWith(color: Colors.amber, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_advice!['savings_tip'] as String,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimaryDark, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _scenarioChip(String emoji, String text) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _getAdvice();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text('$emoji $text', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
      ),
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option) {
    final title = option['title'] as String? ?? '';
    final desc = option['description'] as String? ?? '';
    final cost = option['cost'] as String? ?? '';
    final saving = option['saving'] as String? ?? '';
    final verdict = option['verdict'] as String? ?? '';

    Color verdictColor = AppColors.textSecondaryDark;
    if (verdict.toLowerCase().contains('best') || verdict.toLowerCase().contains('recommended')) {
      verdictColor = AppColors.primaryGreen;
    } else if (verdict.toLowerCase().contains('splurge') || verdict.toLowerCase().contains('expensive')) {
      verdictColor = Colors.redAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold))),
              if (cost.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(cost, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark, height: 1.4)),
          if (saving.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('💚 Save: $saving', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGreen)),
          ],
          if (verdict.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(verdict, style: AppTextStyles.labelSmall.copyWith(color: verdictColor, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Future<void> _getAdvice() async {
    if (_controller.text.trim().isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _advice = null;
    });

    try {
      final raw = await GeminiService().generate(
        _controller.text.trim(),
        systemInstruction: '''
You are a smart shopping & spending advisor in the SmartSave finance app.
The user describes something they want to buy or spend on.
Give practical, actionable advice with clear options.

Respond ONLY with valid JSON (no markdown):
{
  "summary": "Brief assessment of the situation (1-2 sentences)",
  "options": [
    {
      "title": "Option name",
      "description": "What this means",
      "cost": "\$XX",
      "saving": "\$XX vs most expensive option",
      "verdict": "Best value / Splurge / Budget pick / Recommended"
    }
  ],
  "savings_tip": "One actionable tip to save money in this situation"
}

Rules:
- Give 2-4 options, from cheapest to most expensive
- Be specific with numbers
- Include a creative savings hack
- For groceries: suggest meal planning, store brands, seasonal items
- For electronics: suggest refurbished, waiting for sales, older models  
- For dining: suggest cooking alternatives with cost comparison
- For subscriptions: suggest free alternatives or bundle deals
- Keep it practical for busy mums on a budget
''',
      );

      var cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll('```', '').trim();
      }

      setState(() {
        _advice = jsonDecode(cleaned) as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get advice. Try again!')),
        );
      }
    }
  }
}
