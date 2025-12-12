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
      
      final token = await _storageService.getToken();
      
      // If file is provided, use form-data
      if (file != null && file.isNotEmpty) {
        
        final dio = Dio();
        final Map<String, dynamic> formFields = {
          'sender_id': senderId, // Send as string, not int
          'receiver_id': receiverId, // Send as string, not int
          'message': message,
          'sent_at': DateTime.now().toIso8601String(),
          'file': file, // Send file path as string
        };
        if (propertyId.isNotEmpty) {
          formFields['property_id'] = propertyId; // only include when available
        }
        final formData = FormData.fromMap(formFields);


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

        return response.statusCode == 200 || response.statusCode == 201;
      } else {
        // No file, send as regular JSON
        
        final Map<String, dynamic> body = {
          'sender_id': int.parse(senderId),
          'receiver_id': int.parse(receiverId),
          'message': message,
          'sent_at': DateTime.now().toIso8601String(),
        };
        final parsedPropertyId = int.tryParse(propertyId);
        if (parsedPropertyId != null) {
          body['property_id'] = parsedPropertyId;
        }


        final response = await _apiService.post(
          ApiConstants.chatWebhook,
          body: body,
          requiresAuth: true, // This will add the Bearer token
        );

        return response.statusCode == 200 || response.statusCode == 201;
      }
    } catch (e) {
      
      // Print more detailed error information
      if (e is DioException) {
      }
      
      return false;
    }
  }

  // Get conversation with a specific user (receiver_id)
  Future<List<Map<String, dynamic>>> getConversation(String receiverId) async {
    try {
      final token = await _storageService.getToken();
      
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
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final innerData = data['data'];
          
          // Check if innerData contains 'messages' key (new API structure: data.data.messages)
          if (innerData is Map<String, dynamic>) {
            if (innerData.containsKey('messages')) {
              final messagesValue = innerData['messages'];
              
              if (messagesValue is List) {
                final chatData = messagesValue;
                return List<Map<String, dynamic>>.from(chatData);
              }
            }
          }
          
          // Fallback: check if data['data'] is directly a List (old API structure)
          if (innerData is List) {
            return List<Map<String, dynamic>>.from(innerData);
          }
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      }
      
      return [];
    } catch (e) {
      // If it's a 404, it means no conversation exists yet - this is normal
      if (e.toString().contains('404')) {
        return [];
      }
      
      return [];
    }
  }

  // Get user chats (legacy method - keeping for compatibility)
  Future<List<Map<String, dynamic>>> getUserChats() async {
    try {
      // Use Dio directly to get raw response since ApiService has issues with array data
      final dio = Dio();
      final token = await _storageService.getToken();
      
      final response = await dio.get(
        '${ApiConstants.apiBaseUrl}${ApiConstants.getUserChats}',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final chatData = data['data'] as List<dynamic>?;
          return List<Map<String, dynamic>>.from(chatData ?? []);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      }
      
      return [];
    } catch (e) {
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
        return false;
      }

      
      return await sendMessage(
        message: message,
        senderId: currentUser.id.toString(),
        receiverId: recipientId,
        propertyId: propertyId,
        file: file,
      );
    } catch (e) {
      return false;
    }
  }

  // Get chat history for a specific agent (receiver_id)
  Future<List<Map<String, dynamic>>> getChatHistory({
    required String agentId,
    required String propertyId,
  }) async {
    try {
      // Use the new conversation endpoint with receiver_id
      final conversation = await getConversation(agentId);
      
      // Filter by property_id if needed (since conversation is already filtered by receiver_id)
      final filteredChats = conversation.where((chat) {
        final chatPropertyId = chat['property_id']?.toString();
        
        // If no property_id in chat, show all messages for this agent
        if (chatPropertyId == null || chatPropertyId.isEmpty) {
          return true;
        }
        
        return chatPropertyId == propertyId;
      }).toList();
      
      return filteredChats;
    } catch (e) {
      return [];
    }
  }

  // Mark message as received
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      print('💚 [ChatService] Marking message as received: messageId=$messageId');
      final messageIdInt = int.tryParse(messageId);
      if (messageIdInt == null) {
        print('⚠️ [ChatService] Invalid message ID: $messageId');
        return false;
      }
      
      // Use Dio directly to make the request
      final dio = Dio();
      final token = await _storageService.getToken();
      
      print('💚 [ChatService] Making request to: ${ApiConstants.apiBaseUrl}${ApiConstants.markMessageReceived(messageIdInt)}');
      
      final response = await dio.post(
        '${ApiConstants.apiBaseUrl}${ApiConstants.markMessageReceived(messageIdInt)}',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      print('💚 [ChatService] Mark message received response: statusCode=${response.statusCode}');
      print('💚 [ChatService] Mark message received response data: ${response.data}');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      print('❌ [ChatService] Error marking message as received: $e');
      print('❌ [ChatService] Stack trace: $stackTrace');
      if (e is DioException) {
        print('❌ [ChatService] DioException response: ${e.response?.data}');
        print('❌ [ChatService] DioException status: ${e.response?.statusCode}');
      }
      return false;
    }
  }

  // Get current user's online status
  Future<Map<String, dynamic>?> getMyOnlineStatus() async {
    try {
      print('💚 [ChatService] Getting current user online status...');
      
      // Use Dio directly to make the request
      final dio = Dio();
      final token = await _storageService.getToken();
      
      print('💚 [ChatService] Making request to: ${ApiConstants.apiBaseUrl}${ApiConstants.myOnlineStatus}');
      
      final response = await dio.get(
        '${ApiConstants.apiBaseUrl}${ApiConstants.myOnlineStatus}',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      print('💚 [ChatService] Get my online status response: statusCode=${response.statusCode}');
      print('💚 [ChatService] Get my online status response data: ${response.data}');
      print('💚 [ChatService] Response data type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        // Handle different response structures
        if (data is Map<String, dynamic>) {
          // Check for nested data
          if (data.containsKey('data')) {
            return data['data'] as Map<String, dynamic>?;
          }
          return data;
        }
      }
      
      return null;
    } catch (e, stackTrace) {
      print('❌ [ChatService] Error getting my online status: $e');
      print('❌ [ChatService] Stack trace: $stackTrace');
      if (e is DioException) {
        print('❌ [ChatService] DioException response: ${e.response?.data}');
        print('❌ [ChatService] DioException status: ${e.response?.statusCode}');
      }
      return null;
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
      return 0;
    }
  }

  // Update current user's online status
  Future<bool> updateOnlineStatus() async {
    try {
      print('💚 [ChatService] Updating online status...');
      final response = await _apiService.post(
        ApiConstants.updateOnlineStatus,
        body: {},
        requiresAuth: true,
      );
      print('💚 [ChatService] Update online status response: statusCode=${response.statusCode}');
      print('💚 [ChatService] Update online status response data: ${response.data}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      print('❌ [ChatService] Error updating online status: $e');
      print('❌ [ChatService] Stack trace: $stackTrace');
      return false;
    }
  }

  // Check online status for multiple users
  Future<Map<String, bool>> checkOnlineStatus(List<int> userIds) async {
    try {
      print('💚 [ChatService] Checking online status for user IDs: $userIds');
      print('💚 [ChatService] Request body: {user_ids: $userIds}');
      
      // Use Dio directly to see raw response, similar to chat endpoints
      final dio = Dio();
      final token = await _storageService.getToken();
      
      print('💚 [ChatService] Making request to: ${ApiConstants.apiBaseUrl}${ApiConstants.checkOnlineStatus}');
      
      final response = await dio.post(
        '${ApiConstants.apiBaseUrl}${ApiConstants.checkOnlineStatus}',
        data: {
          'user_ids': userIds,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      print('💚 [ChatService] Raw response statusCode: ${response.statusCode}');
      print('💚 [ChatService] Raw response data: ${response.data}');
      print('💚 [ChatService] Raw response data type: ${response.data.runtimeType}');
      print('💚 [ChatService] Raw response headers: ${response.headers}');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        // Check if response has nested data structure
        if (data is Map<String, dynamic>) {
          // Check for nested 'data' key first
          if (data.containsKey('data')) {
            final innerData = data['data'];
            print('💚 [ChatService] Found nested data key: $innerData (type: ${innerData.runtimeType})');
            
            // Handle List format: data: [{id: 19, is_online: false}, ...]
            if (innerData is List) {
              print('💚 [ChatService] Data is a List, processing items...');
              final Map<String, bool> statusMap = {};
              for (var item in innerData) {
                if (item is Map<String, dynamic>) {
                  final userId = item['id']?.toString();
                  final isOnline = item['is_online'];
                  if (userId != null) {
                    statusMap[userId] = isOnline == true || isOnline == 1;
                    print('💚 [ChatService] User $userId: is_online=$isOnline -> ${statusMap[userId]}');
                  }
                }
              }
              print('💚 [ChatService] Final status map (from List): $statusMap');
              return statusMap;
            }
            
            // Handle Map format: data: {19: {is_online: true}, ...}
            if (innerData is Map<String, dynamic>) {
              final Map<String, bool> statusMap = {};
              innerData.forEach((key, value) {
                print('💚 [ChatService] Processing user $key: value=$value (type: ${value.runtimeType})');
                // Handle both {user_id: {is_online: true}} and {user_id: true} formats
                if (value is Map<String, dynamic> && value.containsKey('is_online')) {
                  statusMap[key] = value['is_online'] == true;
                } else if (value is bool) {
                  statusMap[key] = value;
                } else if (value is int) {
                  statusMap[key] = value == 1;
                }
              });
              print('💚 [ChatService] Final status map (from nested Map): $statusMap');
              return statusMap;
            }
          }
          
          // Direct map structure (fallback)
          final Map<String, bool> statusMap = {};
          data.forEach((key, value) {
            // Skip non-user keys
            if (key == 'status' || key == 'message' || key == 'data') return;
            
            print('💚 [ChatService] Processing user $key: value=$value (type: ${value.runtimeType})');
            // Handle both {user_id: {is_online: true}} and {user_id: true} formats
            if (value is Map<String, dynamic> && value.containsKey('is_online')) {
              statusMap[key] = value['is_online'] == true;
            } else if (value is bool) {
              statusMap[key] = value;
            } else if (value is int) {
              // Handle case where API returns 1/0 instead of true/false
              statusMap[key] = value == 1;
            }
          });
          print('💚 [ChatService] Final status map (direct map): $statusMap');
          return statusMap;
        } else if (data is List) {
          print('💚 [ChatService] Response data is a List: $data');
          // If response is a list, convert to map
          final Map<String, bool> statusMap = {};
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              final userId = item['user_id']?.toString() ?? item['id']?.toString();
              if (userId != null) {
                final isOnline = item['is_online'] == true || item['is_online'] == 1;
                statusMap[userId] = isOnline;
                print('💚 [ChatService] Found user $userId: is_online=$isOnline');
              }
            }
          }
          print('💚 [ChatService] Final status map (from List): $statusMap');
          return statusMap;
        } else {
          print('⚠️ [ChatService] Response data is not a Map or List: ${data.runtimeType}');
        }
      } else {
        print('⚠️ [ChatService] Non-200 status or null data: statusCode=${response.statusCode}, data=${response.data}');
      }
      return {};
    } catch (e, stackTrace) {
      print('❌ [ChatService] Error checking online status: $e');
      print('❌ [ChatService] Stack trace: $stackTrace');
      if (e is DioException) {
        print('❌ [ChatService] DioException response: ${e.response?.data}');
        print('❌ [ChatService] DioException status: ${e.response?.statusCode}');
      }
      return {};
    }
  }

  // Get property details by ID
  Future<Map<String, dynamic>?> getPropertyDetails(String propertyId) async {
    try {
      
      final dio = Dio();
      final token = await _storageService.getToken();
      
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

      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Handle different response formats
        if (data is Map<String, dynamic>) {
          // Direct object response
          if (data.containsKey('data')) {
            final propertyData = data['data'] as Map<String, dynamic>?;
            return propertyData;
          } else {
            return data;
          }
        } else if (data is List && data.isNotEmpty) {
          // Array response - take first item
          return data.first as Map<String, dynamic>?;
        } else {
          return null;
        }
      }
      
      return null;
    } catch (e) {
      if (e.toString().contains('404')) {
      }
      return null;
    }
  }
}
