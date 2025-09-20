import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/chat_service.dart';

class InAppChatView extends StatefulWidget {
  final Map<String, dynamic> agentData;
  final String propertyTitle;
  final String? propertyId;
  
  const InAppChatView({
    super.key,
    required this.agentData,
    required this.propertyTitle,
    this.propertyId,
  });

  @override
  State<InAppChatView> createState() => _InAppChatViewState();
}

class _InAppChatViewState extends State<InAppChatView> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  bool _isLoadingChats = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final agentId = widget.agentData['id']?.toString() ?? widget.agentData['user_id']?.toString();
      final chatHistory = await _chatService.getChatHistory(
        agentId: agentId ?? '',
        propertyId: widget.propertyId ?? '',
      );
      
      setState(() {
        _messages.clear();
        // Convert API chat history to ChatMessage objects
        for (final chat in chatHistory) {
          _messages.add(ChatMessage(
            text: chat['message'] ?? '',
            isFromUser: chat['sender_id'] == chat['user_id'], // Assuming sender_id indicates if it's from user
            timestamp: DateTime.tryParse(chat['timestamp'] ?? '') ?? DateTime.now(),
          ));
        }
        
        // If no chat history, add welcome message
        if (_messages.isEmpty) {
          _addWelcomeMessage();
        }
        
        _isLoadingChats = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      print('❌ Error loading chat history: $e');
      setState(() {
        _messages.clear();
        _addWelcomeMessage();
        _isLoadingChats = false;
      });
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

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "Hi! I'm interested in the ${widget.propertyTitle} property. Could you please provide more details?",
        isFromUser: true,
        timestamp: DateTime.now(),
      ));
    });
    
    _scrollToBottom();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final messageText = _messageController.text.trim();
    
    // Add message to UI immediately
    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isFromUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // Send message via ChatService
    final agentId = widget.agentData['id']?.toString() ?? widget.agentData['user_id']?.toString();
    final success = await _chatService.sendInAppMessage(
      message: messageText,
      recipientId: agentId ?? '',
      propertyId: widget.propertyId ?? '',
    );
    
    if (success) {
      print('✅ Message sent successfully via webhook');
    } else {
      print('❌ Failed to send message via webhook');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openWhatsApp() {
    final phoneNumber = _getAgentWhatsApp();
    if (phoneNumber.isNotEmpty) {
      final whatsappUrl = "https://wa.me/$phoneNumber?text=Hi! I'm interested in the ${widget.propertyTitle} property.";
      
      // In a real app, you would use url_launcher here
      print('🔗 Opening WhatsApp with: $whatsappUrl');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening WhatsApp...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _getAgentWhatsApp() {
    // Extract WhatsApp number from agent data
    final user = widget.agentData['user'] as Map<String, dynamic>?;
    if (user != null && user['whatsapp_number'] != null) {
      return user['whatsapp_number'].toString().replaceAll(RegExp(r'[^\d]'), '');
    }
    if (user != null && user['phone_number'] != null) {
      return user['phone_number'].toString().replaceAll(RegExp(r'[^\d]'), '');
    }
    
    // Fallback to agent data
    final agent = widget.agentData['agent'] as Map<String, dynamic>?;
    if (agent != null && agent['whatsapp'] != null) {
      return agent['whatsapp'].toString().replaceAll(RegExp(r'[^\d]'), '');
    }
    if (agent != null && agent['phone'] != null) {
      return agent['phone'].toString().replaceAll(RegExp(r'[^\d]'), '');
    }
    
    return '';
  }

  String _getAgentName() {
    final user = widget.agentData['user'] as Map<String, dynamic>?;
    if (user != null && user['full_name'] != null) {
      return user['full_name'] as String;
    }
    
    final agent = widget.agentData['agent'] as Map<String, dynamic>?;
    return agent?['name'] as String? ?? 'Agent';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24.0, top: 8.0, bottom: 8.0, right: 8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEFF0F2),
                  width: 1.14,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF426DC2),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getAgentName(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const Text(
              'Online',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF00C851),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: GestureDetector(
              onTap: _openWhatsApp,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366), // WhatsApp green
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Continue on WhatsApp Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF25D366), // WhatsApp green
                  Color(0xFF128C7E), // Darker WhatsApp green
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat,
                    color: Color(0xFF25D366),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Continue on WhatsApp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Switch to WhatsApp for easier conversation',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _openWhatsApp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF25D366),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Chat Messages
          Expanded(
            child: _isLoadingChats
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF426DC2),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF426DC2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isFromUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isFromUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF426DC2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isFromUser 
                    ? const Color(0xFF426DC2)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: message.isFromUser ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          if (message.isFromUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF426DC2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
  });
}
