import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:proplinq/core/constants/api_constants.dart';
import 'package:proplinq/core/services/api_service.dart';
import 'package:proplinq/features/auth/services/auth_service.dart';


class ChatService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

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
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error sending chat message: $e');
      return false;
    }
  }

  // Get user chats
  Future<List<Map<String, dynamic>>> getUserChats() async {
    try {
      print('📥 Fetching user chats...');
      
      final response = await _apiService.get(
        ApiConstants.getUserChats,
        requiresAuth: true,
      );

      print('📥 Get user chats response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Parse the response based on your API structure
        final data = response.data;
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
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
      
      // Filter chats for this specific agent and property
      return allChats.where((chat) {
        return chat['agent_id'] == agentId && 
               chat['property_id'] == propertyId;
      }).toList();
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
