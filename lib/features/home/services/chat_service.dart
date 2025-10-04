import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:proplinq/core/constants/api_constants.dart';
import 'package:proplinq/core/services/api_service.dart';
import 'package:proplinq/core/services/storage_service.dart';
import 'package:proplinq/features/auth/services/auth_service.dart';


class ChatService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  // Send message via webhook
  Future<bool> sendMessage({
    required String message,
    required String userId,
    required String platform,
    String? timestamp,
  }) async {
    try {
      print('📤 Sending chat message: $message');
      
      final body = {
        'message': message,
        'user_id': userId,
        'timestamp': timestamp ?? DateTime.now().toIso8601String(),
        'platform': platform,
        'X-Chat-Signature': 'your-secret-token-here', // Add signature to body
      };

      final response = await _apiService.post(
        ApiConstants.chatWebhook,
        body: body,
        requiresAuth: true, // This will add the Bearer token
      );

      print('📤 Chat webhook response: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error sending chat message: $e');
      return false;
    }
  }

  // Get user chats
  Future<List<Map<String, dynamic>>> getUserChats() async {
    try {
      print('📥 Fetching user chats...');
      
      // Use Dio directly to get raw response since ApiService has issues with array data
      final dio = Dio();
      final token = await _authService.getCurrentUser();
      
      final response = await dio.get(
        '${ApiConstants.apiBaseUrl}${ApiConstants.getUserChats}',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer ${await _storageService.getToken()}',
          },
        ),
      );

      print('📥 Get user chats response: ${response.statusCode}');
      print('📥 Raw response data: ${response.data}');
      print('📥 Response data type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('📥 Parsing response data: $data');
        
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final chatData = data['data'] as List<dynamic>?;
          print('📥 Found data key with ${chatData?.length ?? 0} chats');
          if (chatData != null && chatData.isNotEmpty) {
            print('📥 First chat item: ${chatData.first}');
          }
          return List<Map<String, dynamic>>.from(chatData ?? []);
        }
        print('📥 No data key found in response');
        return [];
      }
      
      return [];
    } catch (e) {
      print('❌ Error fetching user chats: $e');
      return [];
    }
  }

  // Send in-app message (simulates sending via webhook)
  Future<bool> sendInAppMessage({
    required String message,
    required String recipientId,
    required String propertyId,
  }) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        print('❌ User not authenticated');
        return false;
      }

      print('📤 Sending in-app message to $recipientId about property $propertyId');
      
      // For in-app messages, we can either:
      // 1. Send via webhook with platform: "in_app"
      // 2. Store locally and sync later
      // 3. Use a different endpoint for in-app messages
      
      return await sendMessage(
        message: message,
        userId: currentUser.id.toString(),
        platform: 'in_app',
      );
    } catch (e) {
      print('❌ Error sending in-app message: $e');
      return false;
    }
  }

  // Get chat history for a specific property/agent
  Future<List<Map<String, dynamic>>> getChatHistory({
    required String agentId,
    required String propertyId,
  }) async {
    try {
      print('📥 Fetching chat history for agent $agentId, property $propertyId');
      
      final allChats = await getUserChats();
      print('📥 All chats received: ${allChats.length} total chats');
      print('📥 All chats data: $allChats');
      
      // If no chats at all, return empty list
      if (allChats.isEmpty) {
        print('📥 No chats found in API response');
        return [];
      }
      
      // Filter chats for this specific agent and property
      final filteredChats = allChats.where((chat) {
        // Extract agent_id and property_id from the payload
        final payload = chat['payload'] as Map<String, dynamic>?;
        final chatAgentId = payload?['agent_id']?.toString();
        final chatPropertyId = payload?['property_id']?.toString();
        
        print('📥 Checking chat - Agent: $chatAgentId, Property: $chatPropertyId');
        print('📥 Looking for - Agent: $agentId, Property: $propertyId');
        
        // For now, show all chats since backend is not saving agent_id and property_id properly
        // TODO: Backend needs to save agent_id and property_id in the payload
        if (chatAgentId == null && chatPropertyId == null) {
          print('📥 Chat has no agent_id/property_id, showing all chats for now');
          return true; // Show all chats until backend is fixed
        }
        
        return chatAgentId == agentId && chatPropertyId == propertyId;
      }).toList();
      
      print('📥 Filtered chats: ${filteredChats.length} messages');
      return filteredChats;
    } catch (e) {
      print('❌ Error fetching chat history: $e');
      return [];
    }
  }

  // Mark message as read
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      // This would depend on your API structure
      // For now, we'll just return true as a placeholder
      print('✅ Marking message $messageId as read');
      return true;
    } catch (e) {
      print('❌ Error marking message as read: $e');
      return false;
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount() async {
    try {
      final chats = await getUserChats();
      int unreadCount = 0;
      
      for (final chat in chats) {
        if (chat['is_read'] == false) {
          unreadCount++;
        }
      }
      
      return unreadCount;
    } catch (e) {
      print('❌ Error getting unread message count: $e');
      return 0;
    }
  }
}
