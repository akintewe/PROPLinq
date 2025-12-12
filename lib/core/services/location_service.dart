import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import '../../features/home/models/property_model.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  
  LocationService._();

  // Cache for location data to avoid repeated API calls
  Position? _cachedPosition;
  List<Map<String, dynamic>>? _cachedNearbyAreas;
  DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 10); // Cache for 10 minutes

  /// Clear cached location data
  void clearCache() {
    _cachedPosition = null;
    _cachedNearbyAreas = null;
    _cacheTimestamp = null;
  }

  /// Get current location of the user (with caching)
  Future<Position?> getCurrentLocation() async {
    try {
      // Return cached location if still valid
      if (_cachedPosition != null && 
          _cacheTimestamp != null && 
          DateTime.now().difference(_cacheTimestamp!) < _cacheExpiry) {
        return _cachedPosition;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Cache the position
      _cachedPosition = position;
      _cacheTimestamp = DateTime.now();

      return position;
    } catch (e) {
      return null;
    }
  }

  /// Get nearby areas based on current location (with caching)
  /// This uses real Nigerian location names based on coordinates
  Future<List<Map<String, dynamic>>> getNearbyAreas(Position position) async {
    try {
      // Check if we have cached nearby areas for this position
      if (_cachedNearbyAreas != null && 
          _cacheTimestamp != null && 
          DateTime.now().difference(_cacheTimestamp!) < _cacheExpiry) {
        return _cachedNearbyAreas!;
      }

      final lat = position.latitude;
      final lng = position.longitude;
      
      
      // Determine which region the user is in and return real location names
      final region = _determineRegion(lat, lng);
      final nearbyAreas = <Map<String, dynamic>>[];
      
      // Add "Near You" option first
      nearbyAreas.add({
        'title': 'Near You',
        'subtitle': 'Properties within 5km of your location',
        'icon': 'assets/icons/duo-icons_location.svg',
        'iconColor': Color(0xFF426DC2),
        'coordinates': {'lat': lat, 'lng': lng},
        'isNearYou': true,
        'locationQuery': 'near me',
      });
      
      // Get real nearby areas based on the region
      final realAreas = _getRealNearbyAreas(region);
      
      for (int i = 0; i < realAreas.length; i++) {
        final area = realAreas[i];
        nearbyAreas.add({
          'title': area['name'],
          'subtitle': 'Near you (${(i + 1) * 2}km away)',
          'icon': 'assets/icons/emojione-monotone_houses.svg',
          'iconColor': area['color'],
          'coordinates': area['coordinates'],
          'locationQuery': area['name'], // This will be used for filtering
        });
      }
      
      // Cache the nearby areas
      _cachedNearbyAreas = nearbyAreas;
      _cacheTimestamp = DateTime.now();
      
      return nearbyAreas;
    } catch (e) {
      return [];
    }
  }

  /// Determine which region the user is in based on coordinates
  String _determineRegion(double lat, double lng) {
    // Abuja region
    if (lat >= 8.8 && lat <= 9.2 && lng >= 7.3 && lng <= 7.6) {
      return 'abuja';
    }
    // Lagos region
    else if (lat >= 6.4 && lat <= 6.7 && lng >= 3.2 && lng <= 3.6) {
      return 'lagos';
    }
    // Port Harcourt region
    else if (lat >= 4.7 && lat <= 5.0 && lng >= 6.9 && lng <= 7.2) {
      return 'port_harcourt';
    }
    // Kano region
    else if (lat >= 12.0 && lat <= 12.2 && lng >= 8.5 && lng <= 8.7) {
      return 'kano';
    }
    // Default to Abuja if unknown
    else {
      return 'abuja';
    }
  }

  /// Get real nearby areas for each region
  List<Map<String, dynamic>> _getRealNearbyAreas(String region) {
    switch (region) {
      case 'abuja':
        return [
          {
            'name': 'Lugbe',
            'color': Color(0xFF63ADDC),
            'coordinates': {'lat': 8.95, 'lng': 7.45},
          },
          {
            'name': 'Kuje',
            'color': Color(0xFFE91E63),
            'coordinates': {'lat': 8.85, 'lng': 7.35},
          },
          {
            'name': 'Lokogoma',
            'color': Color(0xFF4CAF50),
            'coordinates': {'lat': 9.05, 'lng': 7.55},
          },
          {
            'name': 'Garki',
            'color': Color(0xFFFF9800),
            'coordinates': {'lat': 9.0, 'lng': 7.5},
          },
          {
            'name': 'Asokoro',
            'color': Color(0xFF9C27B0),
            'coordinates': {'lat': 9.05, 'lng': 7.48},
          },
          {
            'name': 'Maitama',
            'color': Color(0xFF795548),
            'coordinates': {'lat': 9.08, 'lng': 7.52},
          },
        ];
      
      case 'lagos':
        return [
          {
            'name': 'Lekki',
            'color': Color(0xFF63ADDC),
            'coordinates': {'lat': 6.45, 'lng': 3.45},
          },
          {
            'name': 'Ikorodu',
            'color': Color(0xFFE91E63),
            'coordinates': {'lat': 6.62, 'lng': 3.51},
          },
          {
            'name': 'Ikeja',
            'color': Color(0xFF4CAF50),
            'coordinates': {'lat': 6.6, 'lng': 3.35},
          },
          {
            'name': 'Surulere',
            'color': Color(0xFFFF9800),
            'coordinates': {'lat': 6.5, 'lng': 3.35},
          },
          {
            'name': 'Victoria Island',
            'color': Color(0xFF9C27B0),
            'coordinates': {'lat': 6.42, 'lng': 3.42},
          },
          {
            'name': 'Ikoyi',
            'color': Color(0xFF795548),
            'coordinates': {'lat': 6.45, 'lng': 3.43},
          },
        ];
      
      case 'port_harcourt':
        return [
          {
            'name': 'GRA Phase 1',
            'color': Color(0xFF63ADDC),
            'coordinates': {'lat': 4.8, 'lng': 7.0},
          },
          {
            'name': 'GRA Phase 2',
            'color': Color(0xFFE91E63),
            'coordinates': {'lat': 4.85, 'lng': 7.05},
          },
          {
            'name': 'Rumuola',
            'color': Color(0xFF4CAF50),
            'coordinates': {'lat': 4.82, 'lng': 7.02},
          },
          {
            'name': 'Rumuokoro',
            'color': Color(0xFFFF9800),
            'coordinates': {'lat': 4.88, 'lng': 6.98},
          },
          {
            'name': 'Diobu',
            'color': Color(0xFF9C27B0),
            'coordinates': {'lat': 4.78, 'lng': 7.0},
          },
          {
            'name': 'Old GRA',
            'color': Color(0xFF795548),
            'coordinates': {'lat': 4.8, 'lng': 7.0},
          },
        ];
      
      case 'kano':
        return [
          {
            'name': 'Nassarawa',
            'color': Color(0xFF63ADDC),
            'coordinates': {'lat': 12.0, 'lng': 8.52},
          },
          {
            'name': 'Fagge',
            'color': Color(0xFFE91E63),
            'coordinates': {'lat': 12.0, 'lng': 8.55},
          },
          {
            'name': 'Sabon Gari',
            'color': Color(0xFF4CAF50),
            'coordinates': {'lat': 12.0, 'lng': 8.58},
          },
          {
            'name': 'Dala',
            'color': Color(0xFFFF9800),
            'coordinates': {'lat': 11.98, 'lng': 8.52},
          },
          {
            'name': 'Gwale',
            'color': Color(0xFF9C27B0),
            'coordinates': {'lat': 12.02, 'lng': 8.52},
          },
          {
            'name': 'Tarauni',
            'color': Color(0xFF795548),
            'coordinates': {'lat': 12.02, 'lng': 8.55},
          },
        ];
      
      default:
        return [
          {
            'name': 'Lugbe',
            'color': Color(0xFF63ADDC),
            'coordinates': {'lat': 8.95, 'lng': 7.45},
          },
          {
            'name': 'Kuje',
            'color': Color(0xFFE91E63),
            'coordinates': {'lat': 8.85, 'lng': 7.35},
          },
          {
            'name': 'Lokogoma',
            'color': Color(0xFF4CAF50),
            'coordinates': {'lat': 9.05, 'lng': 7.55},
          },
        ];
    }
  }


  /// Get nearby areas without location (fallback)
  List<Map<String, dynamic>> getDefaultNearbyAreas() {
    return [
      {
        'title': 'Near You',
        'subtitle': 'Find properties around your location',
        'icon': 'assets/icons/duo-icons_location.svg',
        'iconColor': Color(0xFF426DC2),
        'isNearYou': true,
      },
      {
        'title': 'Lekki, Lagos',
        'subtitle': 'Popular area',
        'icon': 'assets/icons/emojione-monotone_houses.svg',
        'iconColor': Color(0xFF63ADDC),
      },
      {
        'title': 'Ikorodu, Lagos',
        'subtitle': 'Popular area',
        'icon': 'assets/icons/emojione-monotone_houses.svg',
        'iconColor': Color(0xFFE91E63),
      },
      {
        'title': 'Ikeja, Lagos',
        'subtitle': 'Popular area',
        'icon': 'assets/icons/emojione-monotone_houses.svg',
        'iconColor': Color(0xFF4CAF50),
      },
      {
        'title': 'Surulere, Lagos',
        'subtitle': 'Popular area',
        'icon': 'assets/icons/emojione-monotone_houses.svg',
        'iconColor': Color(0xFFFF9800),
      },
    ];
  }

  /// Filter properties by distance from user's current location
  Future<List<PropertyModel>> filterPropertiesByDistance(List<PropertyModel> properties, double maxDistanceKm) async {
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        return properties; // Return all properties if no location
      }

      
      final filteredProperties = <PropertyModel>[];
      
      for (final property in properties) {
        // Try to get property coordinates from location string or use default
        final propertyCoords = _extractCoordinatesFromLocation(property.location);
        if (propertyCoords != null) {
          final distance = _calculateDistance(
            position.latitude, 
            position.longitude,
            propertyCoords['lat']!, 
            propertyCoords['lng']!
          );
          
          if (distance <= maxDistanceKm) {
            filteredProperties.add(property);
          } else {
          }
        } else {
          // If we can't determine coordinates, include the property (fallback)
          filteredProperties.add(property);
        }
      }
      
      return filteredProperties;
    } catch (e) {
      return properties; // Return all properties if there's an error
    }
  }

  /// Extract coordinates from location string (fallback method)
  Map<String, double>? _extractCoordinatesFromLocation(String location) {
    // This is a simplified approach - in a real app, you'd use geocoding
    final locationLower = location.toLowerCase();
    
    // Abuja coordinates
    if (locationLower.contains('abuja') || locationLower.contains('fct')) {
      return {'lat': 9.0765, 'lng': 7.3986};
    }
    // Lagos coordinates
    else if (locationLower.contains('lagos')) {
      return {'lat': 6.5244, 'lng': 3.3792};
    }
    // Port Harcourt coordinates
    else if (locationLower.contains('port harcourt') || locationLower.contains('rivers')) {
      return {'lat': 4.8156, 'lng': 7.0498};
    }
    // Kano coordinates
    else if (locationLower.contains('kano')) {
      return {'lat': 12.0022, 'lng': 8.5920};
    }
    
    // If we can't determine coordinates, return null
    return null;
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
