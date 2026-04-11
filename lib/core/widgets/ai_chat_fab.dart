import 'package:flutter/material.dart';
import '../services/ai_chat_service.dart';

class AiChatFab extends StatefulWidget {
  const AiChatFab({super.key});

  @override
  State<AiChatFab> createState() => _AiChatFabState();
}

class _AiChatFabState extends State<AiChatFab> {
  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiChatSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _openChat,
      backgroundColor: const Color(0xFF426DC2),
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
    );
  }
}

// ─────────────────────────────────────────────
// Internal message model
// ─────────────────────────────────────────────
class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final String? title;
  final String? instruction;
  final List<AiChatOption> options;
  final bool isError;

  _ChatMessage({
    required this.role,
    required this.text,
    this.title,
    this.instruction,
    this.options = const [],
    this.isError = false,
  });
}

// ─────────────────────────────────────────────
// Bottom sheet
// ─────────────────────────────────────────────
class _AiChatSheet extends StatefulWidget {
  const _AiChatSheet();

  @override
  State<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<_AiChatSheet> {
  final AiChatService _service = AiChatService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  // Once an options message has been responded to, disable those chips
  final Set<int> _respondedOptionMessageIndexes = {};

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

  Future<void> _sendText(String text) async {
    if (text.isEmpty || _isTyping) return;
    _inputController.clear();

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: reply.text,
          title: reply.title,
          instruction: reply.instruction,
          options: reply.options,
        ));
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: 'Sorry, something went wrong. Please try again.',
          isError: true,
        ));
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  void _onOptionTap(int messageIndex, String optionLabel) {
    // Mark this message's options as used so they grey out
    setState(() {
      _respondedOptionMessageIndexes.add(messageIndex);
    });
    _sendText(optionLabel);
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78 + bottomInset,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF426DC2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PropLinq AI',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                    Text(
                      'Ask me anything about properties',
                      style: TextStyle(fontSize: 12, color: Color(0xFF868686)),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Color(0xFF868686), size: 22),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) return _buildTypingIndicator();
                      final msg = _messages[index];
                      final optionsAlreadyUsed = _respondedOptionMessageIndexes.contains(index);
                      return _buildMessageBubble(msg, index, optionsAlreadyUsed);
                    },
                  ),
          ),

          // Input row
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
              color: Colors.white,
            ),
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendText,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFB0B5BB)),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _sendText(_inputController.text.trim()),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF426DC2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF426DC2).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF426DC2), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'How can I help you?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask me about properties, rental prices, neighbourhoods, or anything real estate.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF868686), height: 1.4),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip('Best areas in Lagos?'),
                _suggestionChip('Average rent in Abuja?'),
                _suggestionChip('How do I book a shortlet?'),
                _suggestionChip('What documents do I need?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return GestureDetector(
      onTap: () => _sendText(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF426DC2).withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF426DC2), fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, int index, bool optionsUsed) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: Color(0xFF426DC2), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Title badge (if present)
                    if (!isUser && msg.title != null && msg.title!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF426DC2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg.title!,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    // Main bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xFF426DC2)
                            : msg.isError
                                ? const Color(0xFFFFF3F3)
                                : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: isUser
                              ? Colors.white
                              : msg.isError
                                  ? Colors.red[700]
                                  : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isUser) const SizedBox(width: 4),
            ],
          ),

          // Options chips (below assistant bubble)
          if (!isUser && msg.options.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: msg.options.map((opt) {
                  return GestureDetector(
                    onTap: optionsUsed ? null : () => _onOptionTap(index, opt.label),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: optionsUsed ? 0.4 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: optionsUsed ? const Color(0xFFF5F5F5) : const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: optionsUsed
                                ? const Color(0xFFE0E0E0)
                                : const Color(0xFF426DC2).withOpacity(0.4),
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
            ),
          ],

          // Instruction hint
          if (!isUser && msg.instruction != null && msg.instruction!.isNotEmpty && !optionsUsed) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                msg.instruction!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(color: Color(0xFF426DC2), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────��───────────
// Animated typing dots
// ─────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((_controller.value * 3) - i).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF426DC2).withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
