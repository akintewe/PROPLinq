import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user preferences like selected discovery location
class UserPreferencesService {
  static final UserPreferencesService _instance = UserPreferencesService._();
  factory UserPreferencesService() => _instance;
  UserPreferencesService._();

  static const String _selectedLocationKey = 'selected_discovery_location';
  static const String _selectedLocationCoordinatesKey = 'selected_location_coordinates';
  static const String _userCountryKey = 'user_country';
  static const String _cautionFeeNoticeDismissedKey = 'caution_fee_notice_dismissed';

  /// Save the user's selected discovery location (for non-Nigeria users)
  Future<void> saveSelectedLocation(String location, {Map<String, double>? coordinates}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLocationKey, location);

    if (coordinates != null) {
      await prefs.setString(
        _selectedLocationCoordinatesKey,
        '${coordinates['lat']},${coordinates['lng']}',
      );
    }
  }

  /// Get the user's saved discovery location
  Future<String?> getSelectedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLocationKey);
  }

  /// Get the user's saved location coordinates
  Future<Map<String, double>?> getSelectedLocationCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    final coordsString = prefs.getString(_selectedLocationCoordinatesKey);

    if (coordsString != null) {
      final parts = coordsString.split(',');
      if (parts.length == 2) {
        return {
          'lat': double.parse(parts[0]),
          'lng': double.parse(parts[1]),
        };
      }
    }

    return null;
  }

  /// Clear the selected location (when user logs out or wants to reset)
  Future<void> clearSelectedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedLocationKey);
    await prefs.remove(_selectedLocationCoordinatesKey);
  }

  /// Save user's country (detected from IP or GPS)
  Future<void> saveUserCountry(String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userCountryKey, country);
  }

  /// Get user's saved country
  Future<String?> getUserCountry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userCountryKey);
  }

  /// Check if the caution fee notice has been dismissed
  Future<bool> hasDismissedCautionFeeNotice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cautionFeeNoticeDismissedKey) ?? false;
  }

  /// Mark the caution fee notice as dismissed
  Future<void> dismissCautionFeeNotice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cautionFeeNoticeDismissedKey, true);
  }

  /// Clear all user preferences
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedLocationKey);
    await prefs.remove(_selectedLocationCoordinatesKey);
    await prefs.remove(_userCountryKey);
  }
}
