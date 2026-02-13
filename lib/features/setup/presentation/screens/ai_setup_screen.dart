import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/gemini_service.dart';

/// AI-powered setup: user describes what they want → AI offers 2 options or full custom.
/// Works for jars, goals, notifications, budgets — anything.
class AiSetupScreen extends StatefulWidget {
  const AiSetupScreen({super.key});

  @override
  State<AiSetupScreen> createState() => _AiSetupScreenState();
}

class _AiSetupScreenState extends State<AiSetupScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>>? _options;
  String? _selectedOptionLabel;
  String _step = 'ask'; // ask → options → customize → done

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
        title: Text('✨ AI Setup', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimaryDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 'ask':
        return _buildAskStep();
      case 'options':
        return _buildOptionsStep();
      case 'customize':
        return _buildCustomizeStep();
      case 'done':
        return _buildDoneStep();
      default:
        return _buildAskStep();
    }
  }

  // ─── STEP 1: Ask what they want ───
  Widget _buildAskStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🤖', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(
          'Tell me what you need',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Describe it however you want. I\'ll figure out the rest.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
        ),
        const SizedBox(height: 24),

        // Example chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _exampleChip('I want to save for a car'),
            _exampleChip('Help me budget for groceries'),
            _exampleChip('Remind me to save every Friday'),
            _exampleChip('I spend too much on takeout'),
          ],
        ),
        const SizedBox(height: 24),

        // Input
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDarkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TextField(
            controller: _controller,
            maxLines: 3,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
            decoration: InputDecoration(
              hintText: 'e.g. "I want to save \$5000 for a holiday by summer"',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _generateOptions,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Generate Options ✨', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _exampleChip(String text) {
    return GestureDetector(
      onTap: () => _controller.text = text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
        ),
        child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGreen)),
      ),
    );
  }

  // ─── STEP 2: Show 2 AI options + custom ───
  Widget _buildOptionsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick a plan', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('AI created these for you. Pick one or go fully custom.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark)),
          const SizedBox(height: 20),

          if (_options != null)
            for (int i = 0; i < _options!.length; i++) ...[
              _buildOptionCard(_options![i], i),
              const SizedBox(height: 12),
            ],

          // Full custom option
          _buildCustomOptionCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option, int index) {
    final label = option['label'] as String? ?? 'Option ${index + 1}';
    final desc = option['description'] as String? ?? '';
    final details = option['details'] as Map<String, dynamic>? ?? {};
    final isSelected = _selectedOptionLabel == label;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedOptionLabel = label);
        _applyOption(option);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [AppColors.primaryGreen.withValues(alpha: 0.2), AppColors.primaryGreen.withValues(alpha: 0.05)])
              : null,
          color: isSelected ? null : AppColors.backgroundDarkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(index == 0 ? '⚡' : '🎯', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(desc, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...details.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('• ', style: TextStyle(color: AppColors.primaryGreen)),
                    Expanded(child: Text('${e.key}: ${e.value}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimaryDark))),
                  ],
                ),
              )),
            ],

            // Notification preferences
            if (option['notifications'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.blueAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      option['notifications'] as String,
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.blueAccent),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomOptionCard() {
    return GestureDetector(
      onTap: () => setState(() => _step = 'customize'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundDarkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            const Text('🛠️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fully Custom', style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
                  Text('Set everything exactly how you want it',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.textTertiaryDark, size: 16),
          ],
        ),
      ),
    );
  }

  // ─── STEP 3: Full custom ───
  Widget _buildCustomizeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your way', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Tell me exactly what you want — amount, timing, notifications, everything.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark)),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDarkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TextField(
            controller: _controller,
            maxLines: 5,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
            decoration: InputDecoration(
              hintText: 'e.g. "Save \$200/week into a Holiday jar, remind me every Friday at 9am, and send me a tip every Monday"',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _applyCustom,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Apply My Setup ✨', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ─── STEP 4: Done ───
  Widget _buildDoneStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text('All set!', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Your personalized setup is ready.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Let\'s Go! 🚀', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── AI Logic ───
  Future<void> _generateOptions() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final raw = await GeminiService().generate(
        _controller.text.trim(),
        systemInstruction: '''
You are the setup AI for SmartSave, a personal finance app.
The user describes what they want. Create exactly 2 options.
Respond ONLY with valid JSON array (no markdown):
[
  {
    "label": "Quick Start",
    "description": "Short description",
    "details": {"Target": "\$2000", "Timeline": "6 months", "Weekly saving": "\$77"},
    "notifications": "Reminder every Friday at 9am + weekly progress report",
    "jar_name": "Holiday Fund",
    "jar_target": 2000,
    "notification_schedule": "weekly_friday_9am"
  },
  {
    "label": "Aggressive Saver",
    "description": "Short description",
    "details": {"Target": "\$2000", "Timeline": "3 months", "Weekly saving": "\$154"},
    "notifications": "Daily reminder at 8pm + motivational tip every morning",
    "jar_name": "Holiday Fund",
    "jar_target": 2000,
    "notification_schedule": "daily_8pm"
  }
]
Make options meaningfully different. Include notification preferences in each.
''',
      );

      var cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll('```', '').trim();
      }

      final parsed = jsonDecode(cleaned) as List;
      setState(() {
        _options = parsed.cast<Map<String, dynamic>>();
        _step = 'options';
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI couldn\'t generate options. Try rephrasing!')),
        );
      }
    }
  }

  Future<void> _applyOption(Map<String, dynamic> option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_setup_config', jsonEncode(option));
    await prefs.setString('notification_schedule', option['notification_schedule'] as String? ?? 'weekly');
    setState(() => _step = 'done');
  }

  Future<void> _applyCustom() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final raw = await GeminiService().generate(
        _controller.text.trim(),
        systemInstruction: '''
Parse the user's custom setup request into JSON:
{"jar_name":"...","jar_target":0,"weekly_amount":0,"notification_schedule":"daily_8pm|weekly_friday_9am|custom","notification_text":"...","tips_frequency":"daily|weekly"}
Respond ONLY with valid JSON.
''',
      );

      var cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll('```', '').trim();
      }

      final config = jsonDecode(cleaned) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_setup_config', jsonEncode(config));
      await prefs.setString('notification_schedule', config['notification_schedule'] as String? ?? 'weekly');

      setState(() {
        _step = 'done';
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }
}
