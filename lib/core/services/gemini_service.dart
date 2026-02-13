import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'remote_config_service.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const _primaryKey = 'AIzaSyA1jZXrjeL_aMXopAzku2Qcvv0fjcRwo_8';
  static const _secondaryKey = 'AIzaSyCDy_xWXe3F5D7cBYjIW3hcloV7vBHhdQA';
  static const _modelName = 'gemini-2.0-flash';

  bool _usingSecondary = false;

  String _getApiKey() {
    try {
      final rc = RemoteConfigService();
      final rcKey = rc.geminiApiKey;
      if (rcKey.isNotEmpty) return rcKey;
    } catch (_) {}
    return _usingSecondary ? _secondaryKey : _primaryKey;
  }

  /// Single prompt generation with automatic key fallback on 429.
  Future<String> generate(String prompt, {String? systemInstruction}) async {
    try {
      return await _doGenerate(prompt, systemInstruction: systemInstruction);
    } catch (e) {
      if (_is429(e) && !_usingSecondary) {
        debugPrint('GeminiService: 429 on primary key, switching to secondary');
        _usingSecondary = true;
        return await _doGenerate(prompt, systemInstruction: systemInstruction);
      }
      rethrow;
    }
  }

  /// Multi-turn chat with automatic key fallback on 429.
  Future<String> chat(
    List<Map<String, String>> history, {
    String? systemInstruction,
  }) async {
    try {
      return await _doChat(history, systemInstruction: systemInstruction);
    } catch (e) {
      if (_is429(e) && !_usingSecondary) {
        debugPrint('GeminiService: 429 on primary key, switching to secondary');
        _usingSecondary = true;
        return await _doChat(history, systemInstruction: systemInstruction);
      }
      rethrow;
    }
  }

  Future<String> _doGenerate(String prompt, {String? systemInstruction}) async {
    final model = GenerativeModel(
      model: _modelName,
      apiKey: _getApiKey(),
      systemInstruction:
          systemInstruction != null ? Content.text(systemInstruction) : null,
    );
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? 'No response generated.';
  }

  Future<String> _doChat(
    List<Map<String, String>> history, {
    String? systemInstruction,
  }) async {
    final model = GenerativeModel(
      model: _modelName,
      apiKey: _getApiKey(),
      systemInstruction:
          systemInstruction != null ? Content.text(systemInstruction) : null,
    );

    final chatHistory = <Content>[];
    for (var i = 0; i < history.length - 1; i++) {
      final msg = history[i];
      final role = msg['role'] == 'user' ? 'user' : 'model';
      chatHistory.add(Content(role, [TextPart(msg['content'] ?? '')]));
    }

    final chat = model.startChat(history: chatHistory);
    final lastMessage = history.last['content'] ?? '';
    final response = await chat.sendMessage(Content.text(lastMessage));
    return response.text ?? 'No response generated.';
  }

  bool _is429(Object e) {
    final msg = e.toString();
    return msg.contains('429') ||
        msg.contains('Resource has been exhausted') ||
        msg.contains('RESOURCE_EXHAUSTED');
  }
}
