import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/room_model.dart';

class HotelService {
  static final HotelService _instance = HotelService._internal();
  factory HotelService() => _instance;
  HotelService._internal();

  final ApiService _apiService = ApiService();

  /// Create a hotel with rooms (manual entry)
  /// POST /api/v1/hotels
  Future<ApiResponse<Map<String, dynamic>>> createHotel({
    required Map<String, String> fields,
    required Map<String, File> files,
    required List<RoomModel> rooms,
  }) async {
    try {
      debugPrint('🏨 [HotelService] Creating hotel with rooms');
      debugPrint('🏨 [HotelService] Rooms count: ${rooms.length}');

      // Add rooms as indexed form fields (Laravel array format)
      final fieldsWithRooms = Map<String, String>.from(fields);

      for (int i = 0; i < rooms.length; i++) {
        final room = rooms[i];
        fieldsWithRooms['rooms[$i][name]'] = room.name;
        fieldsWithRooms['rooms[$i][type]'] = room.type;
        fieldsWithRooms['rooms[$i][price]'] = room.price.toString();
        fieldsWithRooms['rooms[$i][capacity]'] = room.capacity.toString();
        fieldsWithRooms['rooms[$i][count]'] = room.count.toString();

        // Add features as indexed array
        for (int j = 0; j < room.features.length; j++) {
          fieldsWithRooms['rooms[$i][features][$j]'] = room.features[j];
        }
      }

      debugPrint('🏨 [HotelService] Sending hotel data with ${rooms.length} rooms');

      final response = await _apiService.postFormData<Map<String, dynamic>>(
        '/hotels',
        fields: fieldsWithRooms,
        files: files,
        requiresAuth: true,
        fromJson: (json) => json,
      );

      debugPrint('🏨 [HotelService] Hotel creation response: ${response.success}');
      return response;
    } catch (e) {
      debugPrint('🏨 [HotelService] Error creating hotel: $e');
      rethrow;
    }
  }

  /// Create a hotel with rooms from CSV file
  /// POST /api/v1/hotels (with room_csv file)
  Future<ApiResponse<Map<String, dynamic>>> createHotelWithCsv({
    required Map<String, String> fields,
    required Map<String, File> propertyImages,
    required String csvFilePath,
  }) async {
    try {
      debugPrint('🏨 [HotelService] Creating hotel with CSV rooms');

      // Combine property images and CSV file
      final allFiles = Map<String, File>.from(propertyImages);
      allFiles['room_csv'] = File(csvFilePath);

      debugPrint('🏨 [HotelService] Uploading hotel with CSV file');

      final response = await _apiService.postFormData<Map<String, dynamic>>(
        '/hotels',
        fields: fields,
        files: allFiles,
        requiresAuth: true,
        fromJson: (json) => json,
      );

      debugPrint('🏨 [HotelService] Hotel creation with CSV response: ${response.success}');
      return response;
    } catch (e) {
      debugPrint('🏨 [HotelService] Error creating hotel with CSV: $e');
      rethrow;
    }
  }

  /// Get rooms for a specific hotel
  /// GET /api/v1/hotels/{hotel}/rooms
  Future<ApiResponse<List<RoomModel>>> getHotelRooms(int hotelId) async {
    try {
      debugPrint('🏨 [HotelService] Fetching rooms for hotel: $hotelId');

      final response = await _apiService.get<List<RoomModel>>(
        '/hotels/$hotelId/rooms',
        requiresAuth: true,
        fromJson: (json) {
          debugPrint('🏨 [HotelService] Raw rooms response: $json');
          final roomsData = (json['data'] ?? json['rooms'] ?? json) as List<dynamic>?;
          debugPrint('🏨 [HotelService] Rooms array: $roomsData');
          if (roomsData == null) return <RoomModel>[];
          return roomsData
              .map((room) => RoomModel.fromJson(room as Map<String, dynamic>))
              .toList();
        },
      );

      debugPrint('🏨 [HotelService] Fetched ${response.data?.length ?? 0} rooms');
      return response;
    } catch (e) {
      debugPrint('🏨 [HotelService] Error fetching rooms: $e');
      rethrow;
    }
  }

  /// Get availability for a specific room over a date range (public, no auth)
  /// GET /api/v1/rooms/{room_id}/availability?start_date=...&end_date=...
  Future<ApiResponse<List<Map<String, dynamic>>>> getRoomAvailability({
    required int roomId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      debugPrint('🏨 [HotelService] Fetching availability for room $roomId: $startDate → $endDate');
      final response = await _apiService.get<List<Map<String, dynamic>>>(
        ApiConstants.roomAvailability(roomId),
        queryParams: {'start_date': startDate, 'end_date': endDate},
        requiresAuth: false,
        fromJson: (json) {
          final list = (json['data'] ?? json) as List<dynamic>;
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        },
      );
      debugPrint('🏨 [HotelService] Availability response: ${response.data?.length ?? 0} entries');
      return response;
    } catch (e) {
      debugPrint('🏨 [HotelService] Error fetching availability: $e');
      rethrow;
    }
  }

  /// Get agent calendar for a room
  /// GET /api/v1/agent/calendar/room/{room_id}?start_date=...&end_date=...
  Future<ApiResponse<List<Map<String, dynamic>>>> getAgentCalendar({
    required int roomId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      debugPrint('🏨 [HotelService] Fetching agent calendar for room $roomId');
      final response = await _apiService.get<List<Map<String, dynamic>>>(
        ApiConstants.agentCalendarRoom(roomId),
        queryParams: {'start_date': startDate, 'end_date': endDate},
        requiresAuth: true,
        fromJson: (json) {
          final list = (json['data'] ?? json) as List<dynamic>;
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        },
      );
      return response;
    } catch (e) {
      debugPrint('🏨 [HotelService] Error fetching agent calendar: $e');
      rethrow;
    }
  }

  /// Block dates for a room (agent only)
  /// POST /api/v1/agent/calendar/room/{room_id}/block
  Future<ApiResponse<Map<String, dynamic>>> blockRoomDates({
    required int roomId,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    try {
      debugPrint('🏨 [HotelService] Blocking dates for room $roomId: $startDate → $endDate ($reason)');
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.agentBlockRoom(roomId),
        body: {'start_date': startDate, 'end_date': endDate, 'reason': reason},
        requiresAuth: true,
        fromJson: (json) => json,
      );
      return response;
    } catch (e) {
      debugPrint('🏨 [HotelService] Error blocking dates: $e');
      rethrow;
    }
  }

  /// Unblock dates for a room (agent only)
  /// DELETE /api/v1/agent/calendar/unblock/{uuid}
  Future<ApiResponse<Map<String, dynamic>>> unblockDates(String uuid) async {
    try {
      debugPrint('🏨 [HotelService] Unblocking dates with uuid: $uuid');
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiConstants.agentUnblockDates(uuid),
        requiresAuth: true,
        fromJson: (json) => json,
      );
      return response;
    } catch (e) {
      debugPrint('🏨 [HotelService] Error unblocking dates: $e');
      rethrow;
    }
  }

  /// Upload rooms CSV for a hotel
  Future<ApiResponse<Map<String, dynamic>>> uploadRoomsCsv({
    required int hotelId,
    required String filePath,
  }) async {
    try {
      debugPrint('🏨 [HotelService] Uploading rooms CSV for hotel: $hotelId');

      final Map<String, File> files = {
        'csv_file': File(filePath),
      };

      final response = await _apiService.postFormData<Map<String, dynamic>>(
        '/hotels/$hotelId/rooms/upload',
        fields: {},
        files: files,
        requiresAuth: true,
        fromJson: (json) => json,
      );

      debugPrint('🏨 [HotelService] CSV upload response: ${response.success}');
      return response;
    } catch (e) {
      debugPrint('🏨 [HotelService] Error uploading CSV: $e');
      rethrow;
    }
  }
}
