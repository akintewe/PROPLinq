import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

/// Service to cache and manage user's bookings data
/// This prevents flickering in UI and reduces API calls
class BookingsCacheService {
  static final BookingsCacheService _instance = BookingsCacheService._internal();
  factory BookingsCacheService() => _instance;
  BookingsCacheService._internal();

  final ApiService _apiService = ApiService();
  
  // Cached bookings data
  List<Map<String, dynamic>> _cachedBookings = [];
  DateTime? _lastFetchTime;
  bool _isFetching = false;
  
  // Cache duration: 2 minutes
  final Duration _cacheDuration = const Duration(minutes: 2);

  /// Get all cached bookings
  List<Map<String, dynamic>> get cachedBookings => List.unmodifiable(_cachedBookings);

  /// Check if a specific property has been booked with successful payment
  bool hasBookedProperty(String propertyId) {
    return _cachedBookings.any((booking) {
      final bookingPropertyId = booking['property_id']?.toString();
      final paymentStatus = (booking['payment_status'] as String?)?.toLowerCase();
      
      // Check if property ID matches and payment is successful
      return bookingPropertyId == propertyId && 
             (paymentStatus == 'paid' || 
              paymentStatus == 'successful' || 
              paymentStatus == 'completed');
    });
  }

  /// Check if cache is still valid
  bool get isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  /// Fetch bookings from API and cache them
  Future<void> fetchAndCacheBookings({bool forceRefresh = false}) async {
    // Don't fetch if already fetching
    if (_isFetching) {
      debugPrint('🔄 [BookingsCacheService] Already fetching bookings, skipping...');
      return;
    }

    // Use cache if valid and not forcing refresh
    if (!forceRefresh && isCacheValid) {
      debugPrint('✅ [BookingsCacheService] Using cached bookings (${_cachedBookings.length} items)');
      return;
    }

    _isFetching = true;

    try {
      debugPrint('📋 [BookingsCacheService] Fetching bookings from API...');
      
      final response = await _apiService.get<dynamic>(
        ApiConstants.bookings,
        requiresAuth: true,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final data = response.data;
        List<dynamic> bookingsList = [];

        // Handle different response structures
        if (data is List) {
          bookingsList = data;
        } else if (data is Map<String, dynamic>) {
          final inner = data['data'];
          if (inner is List) {
            bookingsList = inner;
          } else if (inner is Map && inner['bookings'] is List) {
            bookingsList = inner['bookings'] as List<dynamic>;
          } else if (data['bookings'] is List) {
            bookingsList = data['bookings'] as List<dynamic>;
          }
        }

        // Convert to list of maps
        _cachedBookings = bookingsList
            .map((item) {
              if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              return <String, dynamic>{};
            })
            .where((item) => item.isNotEmpty)
            .toList();

        _lastFetchTime = DateTime.now();

        debugPrint('✅ [BookingsCacheService] Successfully cached ${_cachedBookings.length} bookings');
      } else {
        debugPrint('⚠️ [BookingsCacheService] Failed to fetch bookings: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ [BookingsCacheService] Error fetching bookings: $e');
    } finally {
      _isFetching = false;
    }
  }

  /// Clear the cache (call this on logout)
  void clearCache() {
    _cachedBookings = [];
    _lastFetchTime = null;
    debugPrint('🗑️ [BookingsCacheService] Cache cleared');
  }

  /// Refresh cache in background (doesn't block)
  void refreshInBackground() {
    fetchAndCacheBookings(forceRefresh: true).catchError((e) {
      debugPrint('❌ [BookingsCacheService] Background refresh failed: $e');
    });
  }

  /// Add a new booking to cache (call after successful booking)
  void addBookingToCache(Map<String, dynamic> booking) {
    _cachedBookings.add(booking);
    debugPrint('➕ [BookingsCacheService] Added booking to cache: ${booking['id']}');
  }

  /// Update booking in cache (call after payment success)
  void updateBookingInCache(String bookingId, Map<String, dynamic> updatedData) {
    final index = _cachedBookings.indexWhere((b) => b['id']?.toString() == bookingId);
    if (index != -1) {
      _cachedBookings[index] = {..._cachedBookings[index], ...updatedData};
      debugPrint('🔄 [BookingsCacheService] Updated booking in cache: $bookingId');
    }
  }
}
