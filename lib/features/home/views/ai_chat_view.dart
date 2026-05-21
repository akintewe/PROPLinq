import 'package:flutter/material.dart';
import '../../../core/services/ai_chat_service.dart';

class AiChatView extends StatefulWidget {
  final String? propertyTitle;

  const AiChatView({
    super.key,
    @Deprecated('conversationId is managed internally') String? conversationId,
    this.propertyTitle,
  });

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  final AiChatService _service = AiChatService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_AiMessage> _messages = [];
  final Set<int> _respondedIndexes = {};
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _service.resetConversation();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    text = text.trim();
    if (text.isEmpty || _isSending) return;
    _inputController.clear();

    setState(() {
      _messages.add(_AiMessage(text: text, isFromUser: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_AiMessage(
          text: reply.text,
          isFromUser: false,
          title: reply.title,
          instruction: reply.instruction,
          options: reply.options,
        ));
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_AiMessage(
          text: 'Sorry, something went wrong. Please try again.',
          isFromUser: false,
          isError: true,
        ));
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  void _onOptionTap(int messageIndex, AiChatOption option) {
    setState(() => _respondedIndexes.add(messageIndex));
    _sendOption(option);
  }

  Future<void> _sendOption(AiChatOption option) async {
    if (_isSending) return;

    setState(() {
      _messages.add(_AiMessage(text: option.label, isFromUser: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final reply = await _service.sendOptionSelection(option.id, option.label);
      if (!mounted) return;
      setState(() {
        _messages.add(_AiMessage(
          text: reply.text,
          isFromUser: false,
          title: reply.title,
          instruction: reply.instruction,
          options: reply.options,
        ));
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_AiMessage(
          text: 'Sorry, something went wrong. Please try again.',
          isFromUser: false,
          isError: true,
        ));
        _isSending = false;
      });
    }
    _scrollToBottom();
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
            const Text(
              'PropLinq AI',
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (widget.propertyTitle != null)
              Text(
                widget.propertyTitle!,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) return _buildTypingIndicator();
                      return _buildBubble(i, _messages[i]);
                    },
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 56, color: Color(0xFF426DC2)),
          const SizedBox(height: 12),
          const Text(
            'Ask me anything',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
          ),
          const SizedBox(height: 6),
          Text(
            widget.propertyTitle != null
                ? 'Questions about ${widget.propertyTitle}'
                : 'Properties, pricing, locations — I\'m here to help.',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(int index, _AiMessage msg) {
    final optionsUsed = _respondedIndexes.contains(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: msg.isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Title badge
          if (!msg.isFromUser && msg.title != null && msg.title!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF426DC2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                msg.title!,
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),

          // Bubble
          Align(
            alignment: msg.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isFromUser
                    ? const Color(0xFF426DC2)
                    : msg.isError
                        ? const Color(0xFFFFF3F3)
                        : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isFromUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isFromUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: msg.isFromUser
                      ? Colors.white
                      : msg.isError
                          ? Colors.red[700]
                          : Colors.black87,
                ),
              ),
            ),
          ),

          // Options
          if (!msg.isFromUser && msg.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: msg.options.map((opt) {
                return GestureDetector(
                  onTap: optionsUsed ? null : () => _onOptionTap(index, opt),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: optionsUsed ? 0.4 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: optionsUsed ? const Color(0xFFF5F5F5) : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: optionsUsed
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFF426DC2).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: optionsUsed ? const Color(0xFF9E9E9E) : const Color(0xFF426DC2),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Instruction hint
          if (!msg.isFromUser && msg.instruction != null && !optionsUsed) ...[
            const SizedBox(height: 4),
            Text(
              msg.instruction!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              onSubmitted: _sendMessage,
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
            onTap: () => _sendMessage(_inputController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF426DC2), Color(0xFF75CFEA)]),
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
  final String? title;
  final String? instruction;
  final List<AiChatOption> options;
  final bool isError;

  _AiMessage({
    required this.text,
    required this.isFromUser,
    this.title,
    this.instruction,
    this.options = const [],
    this.isError = false,
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
