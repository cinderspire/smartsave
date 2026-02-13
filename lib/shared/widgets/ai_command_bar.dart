import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/ai_command_service.dart';
import '../../features/goals/data/providers/money_jar_provider.dart';
import '../../features/goals/data/providers/savings_provider.dart';
import '../../features/goals/data/models/money_jar.dart';
import '../../features/goals/data/models/savings_goal.dart';

/// A magic input bar: type what you want, AI does it.
class AiCommandBar extends ConsumerStatefulWidget {
  const AiCommandBar({super.key});

  @override
  ConsumerState<AiCommandBar> createState() => _AiCommandBarState();
}

class _AiCommandBarState extends ConsumerState<AiCommandBar> {
  final _controller = TextEditingController();
  bool _processing = false;
  String? _feedback;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input row
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreen.withValues(alpha: 0.15),
                AppColors.primaryGreen.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.auto_awesome, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
                  decoration: InputDecoration(
                    hintText: 'Try: "Create a vacation jar for \$2000"',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiaryDark,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (_) => _execute(),
                ),
              ),
              _processing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.send_rounded, color: AppColors.primaryGreen),
                      onPressed: _execute,
                    ),
            ],
          ),
        ),

        // Feedback
        if (_feedback != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              _feedback!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGreen),
            ),
          ),
      ],
    );
  }

  Future<void> _execute() async {
    final input = _controller.text.trim();
    if (input.isEmpty || _processing) return;

    setState(() {
      _processing = true;
      _feedback = null;
    });

    final cmd = await AiCommandService().interpret(input);
    final action = cmd['action'] as String? ?? 'unknown';

    switch (action) {
      case 'create_jar':
        final name = cmd['name'] as String? ?? 'New Jar';
        final target = (cmd['target'] as num?)?.toDouble() ?? 500;
        final jar = MoneyJar(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          purpose: JarPurpose.custom,
          targetAmount: target,
          iconName: 'savings',
          colorValue: 0xFF10B981,
        );
        ref.read(moneyJarsProvider.notifier).addJar(jar);
        setState(() => _feedback = '✅ Created "$name" jar — target \$${target.toInt()}');
        break;

      case 'create_goal':
        final name = cmd['name'] as String? ?? 'New Goal';
        final target = (cmd['target'] as num?)?.toDouble() ?? 1000;
        final goal = SavingsGoal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          targetAmount: target,
          deadline: DateTime.now().add(const Duration(days: 180)),
          category: 'general',
        );
        ref.read(savingsGoalsProvider.notifier).addGoal(goal);
        setState(() => _feedback = '✅ Created "$name" goal — target \$${target.toInt()}');
        break;

      case 'add_deposit':
        final amount = (cmd['amount'] as num?)?.toDouble() ?? 0;
        final targetName = cmd['target_name'] as String? ?? '';
        // Try to find matching jar
        final jars = ref.read(moneyJarsProvider);
        final match = jars.where((j) => j.name.toLowerCase().contains(targetName.toLowerCase())).toList();
        if (match.isNotEmpty) {
          ref.read(moneyJarsProvider.notifier).depositToJar(match.first.id, amount, 'AI deposit');
          setState(() => _feedback = '✅ Added \$${amount.toInt()} to "${match.first.name}"');
        } else {
          setState(() => _feedback = '⚠️ Couldn\'t find "$targetName". Create it first!');
        }
        break;

      case 'smart_tip':
      case 'budget_advice':
        final msg = cmd['message'] as String? ?? cmd['question'] as String? ?? cmd['topic'] as String? ?? '';
        setState(() => _feedback = '💡 $msg');
        break;

      default:
        setState(() => _feedback = cmd['message'] as String? ?? '🤔 Try something like "Create a holiday jar for \$1500"');
    }

    _controller.clear();
    setState(() => _processing = false);
  }
}
