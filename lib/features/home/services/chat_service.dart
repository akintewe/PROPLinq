import 'package:dio/dio.dart';
import 'package:proplinq/core/constants/api_constants.dart';
import 'package:proplinq/core/services/api_service.dart';
import 'package:proplinq/core/services/storage_service.dart';
import 'package:proplinq/features/auth/services/auth_service.dart';


class ChatService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  // Send message via new chat endpoint
  Future<bool> sendMessage({
    required String message,
    required String senderId,
    required String receiverId,
    required String propertyId,
    String? file,
  }) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      print('📤 Sending chat message: $message');
      print('📤 From: $senderId To: $receiverId Property: $propertyId');
      print('📤 Current authenticated user ID: ${currentUser?.id}');
      print('📤 Sender ID being sent: $senderId');
      print('📤 Are they the same? ${currentUser?.id.toString() == senderId}');
      
      final token = await _storageService.getToken();
      
      // If file is provided, use form-data
      if (file != null && file.isNotEmpty) {
        print('📤 File path being sent: $file');
        print('📤 Sending as form-data with file path as string');
        
        final dio = Dio();
        final formData = FormData.fromMap({
          'sender_id': senderId, // Send as string, not int
          'receiver_id': receiverId, // Send as string, not int
          'message': message,
          'property_id': propertyId, // Send as string, not int
          'sent_at': DateTime.now().toIso8601String(),
          'file': file, // Send file path as string
        });

        print('📤 Form data: ${formData.fields}');
        print('📤 File field: ${formData.files}');

        final response = await dio.post(
          '${ApiConstants.apiBaseUrl}${ApiConstants.chatWebhook}',
          data: formData,
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ),
        );

        print('📤 Chat webhook response: ${response.statusCode}');
        print('📤 Chat webhook data: ${response.data}');
        return response.statusCode == 200 || response.statusCode == 201;
      } else {
        // No file, send as regular JSON
        print('📤 Sending as JSON without file');
        
        final body = {
          'sender_id': int.parse(senderId),
          'receiver_id': int.parse(receiverId),
          'message': message,
          'property_id': int.parse(propertyId),
          'sent_at': DateTime.now().toIso8601String(),
        };

        print('📤 Chat request body: $body');

        final response = await _apiService.post(
          ApiConstants.chatWebhook,
          body: body,
          requiresAuth: true, // This will add the Bearer token
        );

        print('📤 Chat webhook response: ${response.statusCode}');
        print('📤 Chat webhook data: ${response.data}');
        return response.statusCode == 200 || response.statusCode == 201;
      }
    } catch (e) {
      print('❌ Error sending chat message: $e');
      
      // Print more detailed error information
      if (e is DioException) {
        print('❌ DioException details:');
        print('  - Type: ${e.type}');
        print('  - Message: ${e.message}');
        print('  - Response: ${e.response?.data}');
        print('  - Status Code: ${e.response?.statusCode}');
        print('  - Request Path: ${e.requestOptions.path}');
        print('  - Request Data: ${e.requestOptions.data}');
      }
      
      return false;
    }
  }

  // Get conversation with a specific user (receiver_id)
  Future<List<Map<String, dynamic>>> getConversation(String receiverId) async {
    try {
      final token = await _storageService.getToken();
      final currentUser = await _authService.getCurrentUser();
      
      print('📥 Fetching conversation with receiver: $receiverId');
      print('📥 Current user ID (from auth): ${currentUser?.id}');
      print('📥 Current user email: ${currentUser?.email}');
      print('📥 Full token: $token');
      print('📥 Full URL: ${ApiConstants.apiBaseUrl}/chats/conversation/$receiverId');
      
      // Use Dio directly to get raw response
      final dio = Dio();
      
      final response = await dio.get(
        '${ApiConstants.apiBaseUrl}/chats/conversation/$receiverId',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('📥 Get conversation response: ${response.statusCode}');
      print('📥 Raw response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('📥 Parsing conversation data: $data');
        
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final chatData = data['data'] as List<dynamic>?;
          print('📥 Found conversation with ${chatData?.length ?? 0} messages');
          if (chatData != null && chatData.isNotEmpty) {
            print('📥 First message: ${chatData.first}');
          }
          return List<Map<String, dynamic>>.from(chatData ?? []);
        }
        print('📥 No data key found in conversation response');
        return [];
      }
      
      return [];
    } catch (e) {
      print('❌ Error fetching conversation: $e');
      print('❌ Full error details: $e');
      
      // If it's a 404, it means no conversation exists yet - this is normal
      if (e.toString().contains('404')) {
        print('📥 No conversation found (404) - this is normal for new conversations');
        return [];
      }
      
      return [];
    }
  }

  // Get user chats (legacy method - keeping for compatibility)
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

  // Send in-app message
  Future<bool> sendInAppMessage({
    required String message,
    required String recipientId,
    required String propertyId,
    String? file,
  }) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        print('❌ User not authenticated');
        return false;
      }

      print('📤 Sending in-app message to $recipientId about property $propertyId');
      
      return await sendMessage(
        message: message,
        senderId: currentUser.id.toString(),
        receiverId: recipientId,
        propertyId: propertyId,
        file: file,
      );
    } catch (e) {
      print('❌ Error sending in-app message: $e');
      return false;
    }
  }

  // Get chat history for a specific agent (receiver_id)
  Future<List<Map<String, dynamic>>> getChatHistory({
    required String agentId,
    required String propertyId,
  }) async {
    try {
      print('📥 Fetching chat history for agent $agentId, property $propertyId');
      
      // Use the new conversation endpoint with receiver_id
      final conversation = await getConversation(agentId);
      print('📥 Conversation received: ${conversation.length} messages');
      print('📥 Conversation data: $conversation');
      
      // Filter by property_id if needed (since conversation is already filtered by receiver_id)
      final filteredChats = conversation.where((chat) {
        final chatPropertyId = chat['property_id']?.toString();
        print('📥 Checking chat - Property: $chatPropertyId');
        print('📥 Looking for - Property: $propertyId');
        
        // If no property_id in chat, show all messages for this agent
        if (chatPropertyId == null || chatPropertyId.isEmpty) {
          print('📥 Chat has no property_id, showing all messages for this agent');
          return true;
        }
        
        return chatPropertyId == propertyId;
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

  // Get property details by ID
  Future<Map<String, dynamic>?> getPropertyDetails(String propertyId) async {
    try {
      print('🏠 Fetching property details for ID: $propertyId');
      print('🏠 API URL: ${ApiConstants.apiBaseUrl}/properties/$propertyId');
      
      final dio = Dio();
      final token = await _storageService.getToken();
      print('🏠 Using token: ${token != null ? "Yes" : "No"}');
      
      final response = await dio.get(
        '${ApiConstants.apiBaseUrl}/properties/$propertyId',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      print('🏠 Property details response status: ${response.statusCode}');
      print('🏠 Property details response headers: ${response.headers}');
      print('🏠 Property details data: ${response.data}');
      print('🏠 Property details data type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('🏠 Property details received successfully');
        
        // Handle different response formats
        if (data is Map<String, dynamic>) {
          // Direct object response
          if (data.containsKey('data')) {
            final propertyData = data['data'] as Map<String, dynamic>?;
            print('🏠 Found property data in response.data: $propertyData');
            return propertyData;
          } else {
            print('🏠 Using direct response data: $data');
            return data;
          }
        } else if (data is List && data.isNotEmpty) {
          // Array response - take first item
          print('🏠 Array response, taking first item: ${data.first}');
          return data.first as Map<String, dynamic>?;
        } else {
          print('🏠 Unexpected response format: $data');
          return null;
        }
      }
      
      print('🏠 Non-200 response: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Error fetching property details: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e.toString().contains('404')) {
        print('🏠 Property not found (404) - this is normal for non-existent properties');
      }
      return null;
    }
  }
}
