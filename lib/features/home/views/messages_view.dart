import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../../auth/services/auth_service.dart';
import 'in_app_chat_view.dart';

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
  final AuthService _authService = AuthService();
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
    try {
      print('📥 Loading conversations from API...');
      setState(() {
        _isLoading = true;
      });
      
      final chatData = await _chatService.getUserChats();
      print('📥 Received ${chatData.length} conversations from API');
      print('📥 Chat data: $chatData');
      
      // Get current user to determine who is sender vs receiver
      final currentUser = await _authService.getCurrentUser();
      final currentUserId = currentUser?.id.toString();
      print('📥 Current user ID: $currentUserId');
      
      // Group conversations by receiver_id (for home seekers) or sender_id (for agents)
      Map<String, Map<String, dynamic>> conversationMap = {};
      
      for (final chat in chatData) {
        final senderId = chat['sender_id']?.toString();
        final receiverId = chat['receiver_id']?.toString();
        final propertyId = chat['property_id']?.toString();
        final message = chat['message'] ?? '';
        final sentAt = chat['sent_at'] ?? chat['updated_at'] ?? chat['created_at'] ?? '';
        final receivedAt = chat['received_at'] as String?;
        
        // Extract user information from the new API structure
        final user = chat['user'] as Map<String, dynamic>?;
        final userName = user?['name'] as String?;
        final userProfileImage = user?['profile_image_url'] as String?;
        
        print('📥 Processing chat - Sender: $senderId, Receiver: $receiverId, Property: $propertyId');
        print('📥 Chat - Message: $message, Received at: $receivedAt');
        print('📥 Chat - User: $userName, Profile Image: $userProfileImage');
        
        // Determine the other person in the conversation
        String otherPersonId;
        String conversationKey;
        
        if (widget.isAgent) {
          // For agents, group by sender_id (the home seeker who contacted them)
          otherPersonId = senderId ?? '';
          conversationKey = senderId ?? '';
        } else {
          // For home seekers, group by receiver_id (the agent they contacted)
          otherPersonId = receiverId ?? '';
          conversationKey = receiverId ?? '';
        }
        
        if (conversationKey.isEmpty) continue;
        
        // Determine if this message is unread
        // Unread = received_at is null AND message is NOT from current user
        final isUnread = receivedAt == null && senderId != currentUserId;
        print('📥 Chat - Is unread: $isUnread (receivedAt: $receivedAt, senderId: $senderId, currentUser: $currentUserId)');
        
        // Create or update conversation entry
        if (!conversationMap.containsKey(conversationKey)) {
          conversationMap[conversationKey] = {
            'id': conversationKey,
            'other_person_id': otherPersonId,
            'property_id': propertyId,
            'message': message,
            'sent_at': sentAt,
            'received_at': receivedAt,
            'sender_id': senderId,
            'unread_count': isUnread ? 1 : 0, // WhatsApp style: 1 if any unread, 0 if all read
            'last_message_time': DateTime.tryParse(sentAt) ?? DateTime.now(),
            'has_unread': isUnread,
            'user_name': userName,
            'user_profile_image': userProfileImage,
          };
        } else {
          // Update with latest message if this one is newer
          final existingTime = conversationMap[conversationKey]!['last_message_time'] as DateTime;
          final currentTime = DateTime.tryParse(sentAt) ?? DateTime.now();
          
          if (currentTime.isAfter(existingTime)) {
            // This is the latest message - update conversation with this message's data
            conversationMap[conversationKey]!.updateAll((key, value) {
              switch (key) {
                case 'message':
                  return message;
                case 'sent_at':
                  return sentAt;
                case 'received_at':
                  return receivedAt;
                case 'sender_id':
                  return senderId;
                case 'last_message_time':
                  return currentTime;
                case 'unread_count':
                  // WhatsApp style: Show 1 if latest message is unread, 0 if read
                  return isUnread ? 1 : 0;
                case 'has_unread':
                  return isUnread;
                case 'user_name':
                  return userName;
                case 'user_profile_image':
                  return userProfileImage;
                default:
                  return value;
              }
            });
          } else {
            // This is an older message - check if it's unread and update has_unread flag
            if (isUnread) {
              conversationMap[conversationKey]!['has_unread'] = true;
              // Keep unread_count as 1 if there are any unread messages (WhatsApp style)
              conversationMap[conversationKey]!['unread_count'] = 1;
            }
          }
        }
      }
      
      // Convert map to list and sort by last message time (newest conversations first)
      final conversations = conversationMap.values.toList();
      conversations.sort((a, b) {
        final aTime = a['last_message_time'] as DateTime;
        final bTime = b['last_message_time'] as DateTime;
        return bTime.compareTo(aTime); // Most recent conversations at the top
      });
      
      print('📥 Processed ${conversations.length} unique conversations');
      print('📥 Conversations sorted by sent_at (newest first)');
      
      // Debug: Print conversation timestamps and unread status to verify sorting
      for (int i = 0; i < conversations.length; i++) {
        final conv = conversations[i];
        final time = conv['last_message_time'] as DateTime;
        final message = conv['message']?.toString() ?? '';
        final unreadCount = conv['unread_count'] as int;
        final hasUnread = conv['has_unread'] as bool;
        print('📥 Conversation $i: $time - ${message.length > 20 ? "${message.substring(0, 20)}..." : message} - Unread: $unreadCount (has_unread: $hasUnread)');
      }
      
      setState(() {
        _conversations = conversations;
        _filteredConversations = conversations;
        _isLoading = false;
      });
      
    } catch (e) {
      print('❌ Error loading conversations: $e');
      setState(() {
        _conversations = [];
        _filteredConversations = [];
        _isLoading = false;
      });
    }
  }

  void _filterConversations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations.where((conversation) {
          final conversationName = _getConversationName(conversation).toLowerCase();
          final message = conversation['message']?.toString().toLowerCase() ?? '';
          final propertyId = conversation['property_id']?.toString().toLowerCase() ?? '';
          
          return conversationName.contains(query) || 
                 message.contains(query) ||
                 propertyId.contains(query);
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
    // Use the actual user name from the conversation data
    final userName = conversation['user_name'] as String?;
    if (userName != null && userName.isNotEmpty) {
      return userName;
    }
    
    // Fallback to placeholder if no name available
    final otherPersonId = conversation['other_person_id']?.toString() ?? '';
    return 'User $otherPersonId';
  }

  String _getLastMessage(Map<String, dynamic> conversation) {
    return conversation['message'] ?? '';
  }

  bool _hasUnreadMessages(Map<String, dynamic> conversation) {
    return conversation['has_unread'] == true;
  }

  Widget _buildConversationAvatar(Map<String, dynamic> conversation) {
    final profileImageUrl = conversation['user_profile_image'] as String?;
    final userName = conversation['user_name'] as String?;
    
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      // Show actual profile image
      return ClipOval(
        child: Image.network(
          profileImageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to initials if image fails to load
            return _buildInitialsAvatar(userName);
          },
        ),
      );
    } else {
      // Fallback to initials if no profile image
      return _buildInitialsAvatar(userName);
    }
  }

  Widget _buildInitialsAvatar(String? userName) {
    String initial = 'U';
    if (userName != null && userName.isNotEmpty) {
      initial = userName[0].toUpperCase();
    }
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF426DC2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _openChat(Map<String, dynamic> conversation) {
    final otherPersonId = conversation['other_person_id']?.toString() ?? '';
    final propertyId = conversation['property_id']?.toString() ?? '';
    
    print('🚀 Opening chat with user: $otherPersonId, property: $propertyId');
    
    // Mark conversation as read when opened
    _markConversationAsRead(conversation);
    
    // Create agent data structure for the chat screen with user information
    final userName = conversation['user_name'] as String?;
    final userProfileImage = conversation['user_profile_image'] as String?;
    
    final agentData = {
      'id': otherPersonId,
      'user': {
        'id': otherPersonId,
        'full_name': userName ?? _getConversationName(conversation),
        'profile_image_url': userProfileImage,
      },
    };
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InAppChatView(
          agentData: agentData,
          propertyTitle: 'Property $propertyId', // Placeholder title
          propertyId: propertyId,
        ),
      ),
    );
  }

  void _markConversationAsRead(Map<String, dynamic> conversation) {
    // Mark this conversation as read by updating the local state
    setState(() {
      final conversationKey = conversation['id']?.toString();
      if (conversationKey != null) {
        // Find and update the conversation in both lists
        for (int i = 0; i < _conversations.length; i++) {
          if (_conversations[i]['id'] == conversationKey) {
            _conversations[i]['unread_count'] = 0;
            _conversations[i]['has_unread'] = false;
            break;
          }
        }
        
        for (int i = 0; i < _filteredConversations.length; i++) {
          if (_filteredConversations[i]['id'] == conversationKey) {
            _filteredConversations[i]['unread_count'] = 0;
            _filteredConversations[i]['has_unread'] = false;
            break;
          }
        }
      }
    });
    
    print('✅ Marked conversation ${conversation['id']} as read');
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
                            final hasUnread = _hasUnreadMessages(conversation);
                            
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
                                onTap: () => _openChat(conversation),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      // Profile Picture
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF426DC2),
                                        ),
                                        child: _buildConversationAvatar(conversation),
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
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                                      color: Colors.black,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                // Date with blue dot for unread messages
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      _formatDate(conversation['sent_at']),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: hasUnread ? const Color(0xFF426DC2) : const Color(0xFF868686),
                                                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                                      ),
                                                    ),
                                                    if (hasUnread) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: const BoxDecoration(
                                                          color: Color(0xFF426DC2),
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
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
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: hasUnread ? const Color(0xFF426DC2) : const Color(0xFF868686),
                                                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                // WhatsApp style: Only show blue dot for unread, no count number
                                                if (hasUnread) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF426DC2),
                                                      shape: BoxShape.circle,
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

