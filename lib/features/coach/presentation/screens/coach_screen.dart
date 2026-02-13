import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/gemini_service.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  static const _systemPrompt =
      'You are a friendly, encouraging AI financial coach in the AI SmartSave app. '
      'Your audience is busy mums who want to save money and build financial confidence. '
      'Give concise, actionable advice. Keep responses under 120 words. '
      'Use simple language, no jargon. Add relevant emoji occasionally. '
      'Be warm and supportive. If asked non-financial topics, gently redirect.';

  final List<Map<String, String>> _chatHistory = [];

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'message':
          'Hi! I\'m your AI financial coach powered by Gemini. Ask me anything about saving money, budgeting, or investing! 💰',
    },
  ];

  final List<String> _quickActions = [
    '💡 Budget tips',
    '📈 How to invest',
    '💳 Cut expenses',
    '🏦 Emergency fund',
    '👩‍👧 Save as a mum',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.wealthGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Coach',
                    style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.bold)),
                Text(
                  _isTyping ? 'Thinking...' : 'Powered by Gemini ✨',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: _isTyping
                          ? AppColors.primaryGreen
                          : AppColors.textSecondaryDark),
                ),
              ],
            ),
          ],
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
          child: Column(
            children: [
              Expanded(child: _buildMessagesList()),
              _buildQuickActions(),
              _buildInputArea(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.wealthGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.backgroundDarkCard,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: SizedBox(
              width: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (i) => _buildDot(i)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.wealthGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryGreen
                    : AppColors.backgroundDarkCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message['message'] as String,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isUser ? Colors.white : AppColors.textPrimaryDark,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _quickActions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendQuickAction(_quickActions[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundDarkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Text(
                _quickActions[index],
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textSecondaryDark),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundDarkCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: _messageController,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  hintText: 'Ask your AI coach...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textTertiaryDark),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isTyping ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: _isTyping ? null : AppColors.wealthGradient,
                color: _isTyping ? Colors.grey.shade800 : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _isTyping ? Icons.hourglass_top_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isTyping) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add({'isUser': true, 'message': userMessage});
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    _chatHistory.add({'role': 'user', 'content': userMessage});

    try {
      final response = await GeminiService().chat(
        _chatHistory,
        systemInstruction: _systemPrompt,
      );
      _chatHistory.add({'role': 'model', 'content': response});
      if (mounted) {
        setState(() {
          _messages.add({'isUser': false, 'message': response});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'message':
                'I\'m having trouble connecting right now. Please try again in a moment! 🔄',
          });
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _sendQuickAction(String action) {
    _messageController.text = action;
    _sendMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
