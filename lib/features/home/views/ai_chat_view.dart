import 'package:flutter/material.dart';
import '../../../core/services/ai_chat_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class AiChatView extends StatefulWidget {
  /// A unique identifier for this AI conversation session.
  final String conversationId;
  final String? propertyTitle;

  const AiChatView({
    super.key,
    required this.conversationId,
    this.propertyTitle,
  });

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  final AiChatService _aiChatService = AiChatService();
  final ApiService _apiService = ApiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_AiMessage> _messages = [];
  bool _isConnecting = true;
  bool _isSending = false;
  bool _connectionFailed = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _connectionFailed = false;
    });
    try {
      await _aiChatService.connect(
        conversationId: widget.conversationId,
        onMessage: _onAiResponse,
      );
      if (mounted) setState(() => _isConnecting = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectionFailed = true;
        });
      }
    }
  }

  void _onAiResponse(Map<String, dynamic> data) {
    final text = data['response'] as String? ?? data['message'] as String? ?? '';
    if (text.isEmpty) return;
    if (!mounted) return;
    setState(() {
      // Remove typing indicator if present
      _messages.removeWhere((m) => m.isTyping);
      _messages.add(_AiMessage(text: text, isFromUser: false, timestamp: DateTime.now()));
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    _inputController.clear();
    setState(() {
      _messages.add(_AiMessage(text: text, isFromUser: true, timestamp: DateTime.now()));
      _messages.add(_AiMessage(text: '', isFromUser: false, timestamp: DateTime.now(), isTyping: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      // Send the user message via HTTP — the AI response will arrive via WebSocket
      await _apiService.post<Map<String, dynamic>>(
        ApiConstants.chatWebhook,
        body: {
          'conversation_id': widget.conversationId,
          'message': text,
        },
        requiresAuth: true,
        fromJson: (json) => json,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.isTyping));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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

  @override
  void dispose() {
    _aiChatService.disconnect();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Assistant', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
            if (widget.propertyTitle != null)
              Text(widget.propertyTitle!, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _connectionFailed
                  ? Colors.red
                  : _isConnecting
                      ? Colors.orange
                      : const Color(0xFF10B981),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_connectionFailed)
            Container(
              color: const Color(0xFFFFF3CD),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Connection failed. Responses may be delayed.', style: TextStyle(fontSize: 12, color: Color(0xFF856404)))),
                  TextButton(
                    onPressed: _connect,
                    child: const Text('Retry', style: TextStyle(fontSize: 12, color: Color(0xFF426DC2))),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isConnecting && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF426DC2)))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smart_toy_outlined, size: 64, color: Color(0xFFCCCCCC)),
                            const SizedBox(height: 12),
                            const Text('Ask me anything about this property', style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _buildBubble(_messages[i]),
                      ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(_AiMessage msg) {
    if (msg.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, right: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => _TypingDot(delay: i * 200)),
          ),
        ),
      );
    }

    return Align(
      alignment: msg.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: msg.isFromUser ? 60 : 0,
          right: msg.isFromUser ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isFromUser ? const Color(0xFF426DC2) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 14,
            color: msg.isFromUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: Color(0xFF999999)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF426DC2), Color(0xFF75CFEA)],
                ),
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final bool isTyping;

  _AiMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.isTyping = false,
  });
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(widget.delay / 600, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF888888)),
        ),
      ),
    );
  }
}
