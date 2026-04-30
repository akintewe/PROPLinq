import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';
import '../../auth/services/auth_service.dart';
import 'in_app_chat_view.dart';

class MessagesView extends StatefulWidget {
  final bool isAgent;
  final VoidCallback? onConversationRead;

  const MessagesView({
    super.key,
    required this.isAgent,
    this.onConversationRead,
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
  Timer? _refreshTimer;
  bool _isFetching = false;
  bool _isFirstLoad = true;
  Map<String, bool> _unreadStatusCache = {}; // Cache for unread status
  Map<String, bool> _onlineStatusCache = {}; // Cache for online status
  Timer? _onlineStatusRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(_filterConversations);
    _updateOnlineStatus(); // Update current user's online status
    _checkOnlineStatuses(); // Check online statuses for all conversations
    
    // Periodically refresh conversations list (faster)
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _loadConversations();
    });
    
    // Periodically check online statuses
    _onlineStatusRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      _checkOnlineStatuses();
    });
    
    // Update current user's online status every 30 seconds
    _onlineStatusRefreshTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _updateOnlineStatus();
    });
  }

  Future<void> _updateOnlineStatus() async {
    print('💚 [MessagesView] Updating current user online status...');
    final success = await _chatService.updateOnlineStatus();
    print('💚 [MessagesView] Update online status result: $success');
  }

  Future<void> _checkOnlineStatuses() async {
    if (_conversations.isEmpty) {
      print('💚 [MessagesView] No conversations to check online status');
      return;
    }
    
    try {
      // Extract user IDs from conversations
      final userIds = _conversations
          .map((conv) => conv['other_person_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .map((id) => int.tryParse(id!))
          .where((id) => id != null)
          .cast<int>()
          .toList();
      
      print('💚 [MessagesView] Checking online status for user IDs: $userIds');
      if (userIds.isEmpty) {
        print('⚠️ [MessagesView] No valid user IDs found');
        return;
      }
      
      final statusMap = await _chatService.checkOnlineStatus(userIds);
      print('💚 [MessagesView] Received status map: $statusMap');
      
      if (mounted) {
        setState(() {
          // Update cache with string keys (matching other_person_id format)
          statusMap.forEach((key, value) {
            _onlineStatusCache[key] = value;
            print('💚 [MessagesView] Cached online status for user $key: $value');
          });
        });
        print('💚 [MessagesView] Updated online status cache. Total cached: ${_onlineStatusCache.length}');
      }
    } catch (e, stackTrace) {
      print('❌ [MessagesView] Error checking online statuses: $e');
      print('❌ [MessagesView] Stack trace: $stackTrace');
    }
  }

  bool _isUserOnline(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return _onlineStatusCache[userId] ?? false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    _onlineStatusRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    if (_isFetching) return;
    if (!mounted) return;
    
    _isFetching = true;
    try {
      if (_isFirstLoad && mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      
      final chatData = await _chatService.getUserChats();
      
      if (!mounted) return;
      
      // Get current user to determine who is sender vs receiver
      final currentUser = await _authService.getCurrentUser();
      if (!mounted) return;
      
      final currentUserId = currentUser?.id.toString();
      
      // Group conversations by receiver_id (for home seekers) or sender_id (for agents)
      Map<String, Map<String, dynamic>> conversationMap = {};
      
      for (final chat in chatData) {
        final propertyId = chat['property_id']?.toString();
        final message = chat['message'] ?? '';
        final sentAt = chat['sent_at'] ?? chat['updated_at'] ?? chat['created_at'] ?? '';
        final receivedAt = chat['received_at'] as String?;
        
        // Extract sender_id to determine if current user sent this message
        final senderId = chat['sender_id']?.toString();
        final isSentByCurrentUser = senderId == currentUserId;
        
        // Extract user information from the new API structure
        final user = chat['user'] as Map<String, dynamic>?;
        final otherPersonId = user?['id']?.toString() ?? '';
        final userName = user?['name'] as String?;
        final userProfileImage = user?['profile_image_url'] as String?;
        
        // Use the other person's ID as the conversation key
        String conversationKey = otherPersonId;
        
        if (conversationKey.isEmpty) continue;
        
        // Determine if this message is unread
        // Unread = received_at is null AND current user is NOT the sender
        // (meaning the message was sent TO the current user and they haven't read it yet)
        final isUnread = receivedAt == null && !isSentByCurrentUser;
        
        // Create or update conversation entry
        if (!conversationMap.containsKey(conversationKey)) {
          conversationMap[conversationKey] = {
            'id': conversationKey,
            'other_person_id': otherPersonId,
            'property_id': propertyId,
            'message': message,
            'sent_at': sentAt,
            'received_at': receivedAt,
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
      
      // Precompute unread status for all conversations
      await _updateUnreadStatusCache(conversations);
      
      if (!mounted) return;
      
      setState(() {
        _conversations = conversations;
        _filteredConversations = conversations;
        _isLoading = false;
        _isFirstLoad = false;
      });
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _conversations = [];
        _filteredConversations = [];
        _isLoading = false;
        _isFirstLoad = false;
      });
    }
    finally {
      _isFetching = false;
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

  Future<void> _updateUnreadStatusCache(List<Map<String, dynamic>> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, bool> newCache = {};
    
    for (final conversation in conversations) {
      final conversationId = conversation['id']?.toString();
      if (conversationId == null) continue;
      
      // Get the last seen timestamp for this conversation
      final lastSeenKey = 'last_seen_$conversationId';
      final lastSeenTimestampStr = prefs.getString(lastSeenKey);
      
      // Get the message timestamp
      final messageTimestampStr = conversation['sent_at'] as String?;
      if (messageTimestampStr == null) {
        newCache[conversationId] = false;
        continue;
      }
      
      final messageTimestamp = DateTime.tryParse(messageTimestampStr);
      if (messageTimestamp == null) {
        newCache[conversationId] = false;
        continue;
      }
      
      // If no last seen timestamp, use the API's has_unread flag
      if (lastSeenTimestampStr == null) {
        newCache[conversationId] = conversation['has_unread'] == true;
        continue;
      }
      
      // Parse last seen timestamp
      final lastSeenTimestamp = DateTime.tryParse(lastSeenTimestampStr);
      if (lastSeenTimestamp == null) {
        newCache[conversationId] = conversation['has_unread'] == true;
        continue;
      }
      
      // Message is unread if it's newer than when we last saw this conversation
      newCache[conversationId] = messageTimestamp.isAfter(lastSeenTimestamp);
    }
    
    _unreadStatusCache = newCache;
  }

  bool _hasUnreadMessages(Map<String, dynamic> conversation) {
    final conversationId = conversation['id']?.toString();
    if (conversationId == null) return false;
    
    // Check cache first
    return _unreadStatusCache[conversationId] ?? false;
  }

  Widget _buildConversationAvatar(Map<String, dynamic> conversation) {
    final profileImageUrl = conversation['user_profile_image'] as String?;
    final userName = conversation['user_name'] as String?;
    
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      // Show actual profile image
      return ClipOval(
        child: CachedNetworkImage(imageUrl: 
          profileImageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) {
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
    
    
    // Mark conversation as read when opened
    _markConversationAsRead(conversation);
    
    // Create agent data structure for the chat screen with user information
    final userName = conversation['user_name'] as String?;
    final userProfileImage = conversation['user_profile_image'] as String?;
    
    // Try to extract phone number from conversation data
    String? phoneNumber;
    String? email;
    
    // Check if conversation has user data with phone number
    if (conversation.containsKey('user_data')) {
      final userData = conversation['user_data'] as Map<String, dynamic>?;
      phoneNumber = userData?['phone_number'] as String?;
      email = userData?['email'] as String?;
    }
    
    // If no user_data, check if we have sender/receiver data
    if (phoneNumber == null && conversation.containsKey('sender')) {
      final sender = conversation['sender'] as Map<String, dynamic>?;
      if (sender?['id']?.toString() == otherPersonId) {
        phoneNumber = sender?['phone_number'] as String?;
        email = sender?['email'] as String?;
      }
    }
    
    if (phoneNumber == null && conversation.containsKey('receiver')) {
      final receiver = conversation['receiver'] as Map<String, dynamic>?;
      if (receiver?['id']?.toString() == otherPersonId) {
        phoneNumber = receiver?['phone_number'] as String?;
        email = receiver?['email'] as String?;
      }
    }
    
    
    final agentData = {
      'id': otherPersonId,
      'user': {
        'id': otherPersonId,
        'full_name': userName ?? _getConversationName(conversation),
        'profile_image_url': userProfileImage,
        'phone_number': phoneNumber,
        'email': email,
      },
    };
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InAppChatView(
          agentData: agentData,
          propertyTitle: 'Property $propertyId',
          propertyId: propertyId,
        ),
      ),
    ).then((_) {
      widget.onConversationRead?.call();
      _loadConversations(); // Refresh conversation list to update read status
    });
  }

  Future<void> _markConversationAsRead(Map<String, dynamic> conversation) async {
    final conversationKey = conversation['id']?.toString();
    if (conversationKey == null) return;
    
    // Save the current timestamp as the last seen time for this conversation
    final prefs = await SharedPreferences.getInstance();
    final lastSeenKey = 'last_seen_$conversationKey';
    await prefs.setString(lastSeenKey, DateTime.now().toIso8601String());
    
    
    // Update local state and cache to immediately remove the unread indicator
    setState(() {
      // Update cache
      _unreadStatusCache[conversationKey] = false;
      
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
    });
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
                                // Add subtle background color for unread messages
                                color: hasUnread ? const Color(0xFFF0F7FF) : Colors.white,
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
                                                // Unread badge - more prominent than before
                                                if (hasUnread) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF426DC2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Text(
                                                      'NEW',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
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

