import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

/// Service class for managing OneSignal push notifications
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  
  factory OneSignalService() {
    return _instance;
  }
  
  OneSignalService._internal();
  
  final ApiService _apiService = ApiService();

  /// Initialize OneSignal with your App ID
  /// Replace 'YOUR_ONESIGNAL_APP_ID' with your actual OneSignal App ID
  Future<void> initialize() async {
    try {
      print('🔔 [OneSignalService] Initializing OneSignal...');
      
      // Initialize OneSignal with your App ID
      OneSignal.initialize('d8189f7d-4a8f-4543-bfb1-3d167b86d859');
      
      // Request permission for push notifications (iOS)
      await OneSignal.Notifications.requestPermission(true);
      
      // Set up notification handlers
      _setupNotificationHandlers();
      
      // Set up subscription observer to update player_id when it changes
      _setupSubscriptionObserver();
      
      // Try to get and update player_id immediately
      _updatePlayerIdIfAvailable();
      
      print('✅ [OneSignalService] OneSignal initialized successfully');
    } catch (e) {
      print('❌ [OneSignalService] Error initializing OneSignal: $e');
    }
  }

  /// Set up notification event handlers
  void _setupNotificationHandlers() {
    // Handle notification opened event
    OneSignal.Notifications.addClickListener((event) {
      _handleNotificationOpened(event.notification);
    });

    // Handle notification received event (when app is in foreground)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // You can modify the notification or prevent it from displaying
      event.preventDefault();
      event.notification.display();
    });

    // Handle notification permission changes
    OneSignal.Notifications.addPermissionObserver((state) {
      print('🔔 [OneSignalService] Notification permission changed: $state');
      // Update player_id when permission is granted
      if (state) {
        _updatePlayerIdIfAvailable();
      }
    });
  }
  
  /// Set up subscription observer to automatically update player_id
  void _setupSubscriptionObserver() {
    try {
      // Listen for subscription state changes
      OneSignal.User.pushSubscription.addObserver((state) {
        print('🔔 [OneSignalService] Push subscription state changed');
        
        // Get current subscription ID
        final subscriptionId = OneSignal.User.pushSubscription.id;
        print('   - Subscription ID: $subscriptionId');
        print('   - OptedIn: ${OneSignal.User.pushSubscription.optedIn}');
        
        // Update player_id when subscription is available
        if (subscriptionId != null && subscriptionId.isNotEmpty) {
          _updatePlayerIdOnBackend(subscriptionId);
        }
      });
    } catch (e) {
      print('❌ [OneSignalService] Error setting up subscription observer: $e');
    }
  }
  
  /// Try to get and update player_id if available
  Future<void> _updatePlayerIdIfAvailable() async {
    try {
      // Wait a bit for OneSignal to initialize
      await Future.delayed(const Duration(seconds: 2));
      
      final playerId = await getSubscriptionId();
      if (playerId != null && playerId.isNotEmpty) {
        print('🔔 [OneSignalService] Player ID available: $playerId');
        await _updatePlayerIdOnBackend(playerId);
      } else {
        print('⚠️ [OneSignalService] Player ID not available yet, will retry...');
        // Retry after a delay
        Future.delayed(const Duration(seconds: 3), () {
          _updatePlayerIdIfAvailable();
        });
      }
    } catch (e) {
      print('❌ [OneSignalService] Error checking player ID: $e');
    }
  }
  
  /// Update player_id on backend
  Future<void> _updatePlayerIdOnBackend(String playerId) async {
    try {
      print('📤 [OneSignalService] Updating player_id on backend: $playerId');
      
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.updatePlayerId,
        body: {
          'player_id': playerId,
        },
        requiresAuth: true,
        fromJson: (json) => json,
      );
      
      if (response.success) {
        print('✅ [OneSignalService] Player ID updated successfully on backend');
      } else {
        print('⚠️ [OneSignalService] Failed to update player ID: ${response.message}');
        if (response.errors != null) {
          print('   Errors: ${response.errors}');
        }
      }
    } catch (e) {
      print('❌ [OneSignalService] Error updating player_id on backend: $e');
    }
  }
  
  /// Manually update player_id (can be called from outside)
  Future<void> updatePlayerId() async {
    final playerId = await getSubscriptionId();
    if (playerId != null && playerId.isNotEmpty) {
      await _updatePlayerIdOnBackend(playerId);
    } else {
      print('⚠️ [OneSignalService] Cannot update player_id: ID not available');
    }
  }

  /// Handle notification opened/clicked
  void _handleNotificationOpened(OSNotification notification) {
    try {
      // Get notification data
      final data = notification.additionalData;

      // Handle different notification types based on custom data
      if (data != null) {
        final type = data['type'] as String?;
        
        switch (type) {
          case 'message':
            // Navigate to messages screen
            break;
          case 'property':
            // Navigate to property details
            final propertyId = data['property_id'];
            break;
          case 'booking':
            // Navigate to booking details
            final bookingId = data['booking_id'];
            break;
          default:
            break;
        }
      }
    } catch (e) {
    }
  }

  /// Set external user ID (e.g., your user's ID from backend)
  Future<void> setExternalUserId(String userId) async {
    try {
      print('🔔 [OneSignalService] Setting external user ID: $userId');
      await OneSignal.login(userId);
      
      // Also update player_id when user logs in
      await _updatePlayerIdIfAvailable();
    } catch (e) {
      print('❌ [OneSignalService] Error setting external user ID: $e');
    }
  }

  /// Remove external user ID (e.g., when user logs out)
  Future<void> removeExternalUserId() async {
    try {
      await OneSignal.logout();
    } catch (e) {
    }
  }

  /// Set user tags for targeted notifications
  Future<void> setUserTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
    } catch (e) {
    }
  }

  /// Remove user tags
  Future<void> removeUserTags(List<String> keys) async {
    try {
      OneSignal.User.removeTags(keys);
    } catch (e) {
    }
  }

  /// Get the current push subscription ID (OneSignal Player ID)
  Future<String?> getSubscriptionId() async {
    try {
      final subscriptionId = OneSignal.User.pushSubscription.id;
      return subscriptionId;
    } catch (e) {
      return null;
    }
  }

  /// Check if user has granted notification permission
  bool hasNotificationPermission() {
    final permission = OneSignal.Notifications.permission;
    return permission;
  }

  /// Prompt user to enable notifications if not already enabled
  Future<bool> promptForPushNotifications() async {
    try {
      final permission = await OneSignal.Notifications.requestPermission(true);
      return permission;
    } catch (e) {
      return false;
    }
  }

  /// Send a tag to identify user type (agent or tenant)
  Future<void> setUserType(String userType) async {
    await setUserTags({'user_type': userType});
  }

  /// Send location tag for location-based notifications
  Future<void> setUserLocation(String location) async {
    await setUserTags({'location': location});
  }
}

