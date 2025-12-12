import '../../features/home/models/property_model.dart';

class PropertySearchService {
  static PropertySearchService? _instance;
  static PropertySearchService get instance => _instance ??= PropertySearchService._();
  
  PropertySearchService._();

  /// Search properties by name/title
  List<PropertyModel> searchPropertiesByName(List<PropertyModel> properties, String searchQuery) {
    if (searchQuery.trim().isEmpty) {
      return [];
    }

    final query = searchQuery.toLowerCase().trim();
    
    return properties.where((property) {
      // Search in title
      if (property.title.toLowerCase().contains(query)) {
        return true;
      }
      
      // Search in location
      if (property.location.toLowerCase().contains(query)) {
        return true;
      }
      
      // Search in description
      if (property.description?.toLowerCase().contains(query) ?? false) {
        return true;
      }
      
      // Search in type
      if (property.type.toLowerCase().contains(query)) {
        return true;
      }
      
      return false;
    }).toList();
  }

  /// Search properties by location
  List<PropertyModel> searchPropertiesByLocation(List<PropertyModel> properties, String location) {
    if (location.trim().isEmpty) {
      return properties;
    }

    final query = location.toLowerCase().trim();
    
    final results = properties.where((property) {
      final propertyLocation = property.location.toLowerCase();
      final propertyTitle = property.title.toLowerCase();
      
      // For "near me", this should not be called from PropertySearchService
      // The search bottom sheet should handle "near me" with LocationService directly
      if (query == 'near me') {
        return false; // Don't match any properties here
      }
      
      // For specific locations, be very precise
      // Check if the location name appears as a standalone word in the property location
      final locationWords = propertyLocation.split(RegExp(r'[,\s]+'));
      final titleWords = propertyTitle.split(RegExp(r'[,\s]+'));
      
      // Check for exact location match in location field
      final matchesLocation = locationWords.contains(query);
      
      // Check for location match in title (but be more restrictive)
      final matchesTitle = titleWords.contains(query);
      
      // Only match if it's an exact location match
      final matches = matchesLocation || matchesTitle;
      
      if (matches) {
      } else {
      }
      
      return matches;
    }).toList();
    
    return results;
  }

  /// Determine user's region from available properties (fallback method)
  String _determineUserRegionFromProperties(List<PropertyModel> properties) {
    // Count occurrences of each region in the properties
    final regionCounts = <String, int>{};
    
    for (final property in properties) {
      final location = property.location.toLowerCase();
      
      if (location.contains('abuja') || location.contains('fct')) {
        regionCounts['abuja'] = (regionCounts['abuja'] ?? 0) + 1;
      } else if (location.contains('lagos')) {
        regionCounts['lagos'] = (regionCounts['lagos'] ?? 0) + 1;
      } else if (location.contains('port harcourt') || location.contains('rivers')) {
        regionCounts['port_harcourt'] = (regionCounts['port_harcourt'] ?? 0) + 1;
      } else if (location.contains('kano')) {
        regionCounts['kano'] = (regionCounts['kano'] ?? 0) + 1;
      }
    }
    
    // Return the region with the most properties, default to 'abuja'
    if (regionCounts.isEmpty) return 'abuja';
    
    return regionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Check if a property matches the user's region
  bool _propertyMatchesRegion(PropertyModel property, String region) {
    final location = property.location.toLowerCase();
    final title = property.title.toLowerCase();
    
    switch (region) {
      case 'abuja':
        return location.contains('abuja') || location.contains('fct') || 
               title.contains('abuja') || title.contains('fct');
      case 'lagos':
        return location.contains('lagos') || title.contains('lagos');
      case 'port_harcourt':
        return location.contains('port harcourt') || location.contains('rivers') ||
               title.contains('port harcourt') || title.contains('rivers');
      case 'kano':
        return location.contains('kano') || title.contains('kano');
      default:
        return true; // If region is unknown, show all properties
    }
  }

  /// Search properties by multiple criteria
  List<PropertyModel> searchProperties({
    required List<PropertyModel> properties,
    String? nameQuery,
    String? locationQuery,
    String? category,
  }) {
    List<PropertyModel> results = properties;

    // Filter by name/title if provided
    if (nameQuery != null && nameQuery.trim().isNotEmpty) {
      results = searchPropertiesByName(results, nameQuery);
    }

    // Filter by location if provided
    if (locationQuery != null && locationQuery.trim().isNotEmpty) {
      results = searchPropertiesByLocation(results, locationQuery);
    }

    // Filter by category if provided
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      results = results.where((property) {
        final propertyType = property.type.toLowerCase();
        final propertyCategory = property.category.toLowerCase();
        final categoryFilter = category.toLowerCase();
        
        if (categoryFilter == 'hotels') {
          return propertyType == 'hotel' || propertyCategory == 'hotel' || propertyCategory.contains('hotel');
        } else if (categoryFilter == 'real estate') {
          return propertyType == 'apartment' || propertyCategory == 'for_rent' || propertyCategory == 'for_sale';
        } else if (categoryFilter == 'shortlets') {
          return propertyType == 'shortlet' || propertyCategory == 'shortlet' || propertyCategory.contains('shortlet');
        }
        return true;
      }).toList();
    }

    return results;
  }
}
