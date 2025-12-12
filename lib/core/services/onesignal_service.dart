import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Service class for managing OneSignal push notifications
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  
  factory OneSignalService() {
    return _instance;
  }
  
  OneSignalService._internal();

  /// Initialize OneSignal with your App ID
  /// Replace 'YOUR_ONESIGNAL_APP_ID' with your actual OneSignal App ID
  Future<void> initialize() async {
    try {
      
      // Initialize OneSignal with your App ID
      OneSignal.initialize('d8189f7d-4a8f-4543-bfb1-3d167b86d859');
      
      // Request permission for push notifications (iOS)
      await OneSignal.Notifications.requestPermission(true);
      
      // Set up notification handlers
      _setupNotificationHandlers();
      
    } catch (e) {
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
    });
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
      await OneSignal.login(userId);
    } catch (e) {
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

