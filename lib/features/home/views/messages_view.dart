import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class MessagesView extends StatefulWidget {
  final bool isAgent;
  
  const MessagesView({
    super.key,
    required this.isAgent,
  });

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(_filterConversations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    // No delay - load immediately
    setState(() {
      _conversations = [
        {
          'id': 1,
          'sender': {'full_name': 'Erlan Sadewa'},
          'receiver': {'full_name': 'You'},
          'message': 'Aight, noted',
          'sent_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'unread_count': 1,
        },
        {
          'id': 2,
          'sender': {'full_name': 'Sarah Johnson'},
          'receiver': {'full_name': 'You'},
          'message': 'Thanks for your interest in the property',
          'sent_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'unread_count': 0,
        },
        {
          'id': 3,
          'sender': {'full_name': 'Michael Chen'},
          'receiver': {'full_name': 'You'},
          'message': 'The apartment is still available',
          'sent_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'unread_count': 2,
        },
        {
          'id': 4,
          'sender': {'full_name': 'Emma Wilson'},
          'receiver': {'full_name': 'You'},
          'message': 'Would you like to schedule a viewing?',
          'sent_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'unread_count': 0,
        },
        {
          'id': 5,
          'sender': {'full_name': 'David Brown'},
          'receiver': {'full_name': 'You'},
          'message': 'The price is negotiable',
          'sent_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'unread_count': 1,
        },
      ];
      _filteredConversations = _conversations;
      _isLoading = false;
    });
  }

  void _filterConversations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations.where((conversation) {
          final senderName = conversation['sender']?['full_name']?.toString().toLowerCase() ?? '';
          final receiverName = conversation['receiver']?['full_name']?.toString().toLowerCase() ?? '';
          final message = conversation['message']?.toString().toLowerCase() ?? '';
          
          return senderName.contains(query) || 
                 receiverName.contains(query) || 
                 message.contains(query);
        }).toList();
      }
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else {
        // Format as day/month like "17/6"
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }

  String _getConversationName(Map<String, dynamic> conversation) {
    return conversation['sender']?['full_name'] ?? 'Unknown';
  }

  String _getLastMessage(Map<String, dynamic> conversation) {
    return conversation['message'] ?? '';
  }

  int _getUnreadCount(Map<String, dynamic> conversation) {
    return conversation['unread_count'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Messages',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF868686),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Color(0xFF868686),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            
            // Messages List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF426DC2),
                      ),
                    )
                  : _filteredConversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECF0F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 60,
                                  color: Color(0xFF426DC2),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Your conversations will appear here',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF868686),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _filteredConversations[index];
                            final unreadCount = _getUnreadCount(conversation);
                            
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: const Color(0xFFEFF0F2),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // Navigate to chat conversation
                                  // This would need to be implemented
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      // Profile Picture
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: const Color(0xFF426DC2),
                                        child: Text(
                                          _getConversationName(conversation)
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 12),
                                      
                                      // Message Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Name and Date Row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _getConversationName(conversation),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  _formatDate(conversation['sent_at']),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF868686),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 4),
                                            
                                            // Message Preview and Unread Badge Row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _getLastMessage(conversation),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF868686),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (unreadCount > 0) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF426DC2),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        unreadCount.toString(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

