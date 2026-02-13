import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'gemini_service.dart';

/// AI interprets natural language and returns structured commands.
/// Users say what they want → AI figures out what to do.
class AiCommandService {
  static final AiCommandService _instance = AiCommandService._();
  factory AiCommandService() => _instance;
  AiCommandService._();

  static const _systemPrompt = '''
You are the AI engine inside the SmartSave finance app.
The user will describe what they want in plain language.
You MUST respond with ONLY a valid JSON object (no markdown, no explanation).

Available commands:
1. create_jar — Create a money jar (savings container)
   {"action":"create_jar","name":"...","target":1000,"icon":"emoji","color":"#hex"}

2. create_goal — Create a savings goal
   {"action":"create_goal","name":"...","target":500,"deadline":"2026-06-01"}

3. add_deposit — Add money to a jar or goal
   {"action":"add_deposit","target_name":"...","amount":50}

4. smart_tip — Generate a savings tip
   {"action":"smart_tip","topic":"..."}

5. budget_advice — Give budget advice
   {"action":"budget_advice","question":"..."}

6. unknown — If you can't understand
   {"action":"unknown","message":"I didn't understand. Try: 'Create a vacation jar for \$2000'"}

Rules:
- Pick realistic defaults for missing values (icon, color, deadline)
- Currency amounts should be numbers, not strings
- Keep it simple and helpful
''';

  /// Parse natural language into a structured command
  Future<Map<String, dynamic>> interpret(String userInput) async {
    try {
      final raw = await GeminiService().generate(
        userInput,
        systemInstruction: _systemPrompt,
      );

      // Strip markdown fences if AI added them
      var cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll('```', '').trim();
      }

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('AiCommandService error: $e');
      return {
        'action': 'unknown',
        'message': 'Something went wrong. Try again!',
      };
    }
  }
}
