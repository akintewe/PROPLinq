import '../../../core/base/base_view_model.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';

class HomeViewModel extends BaseViewModel {
  List<PropertyModel> _properties = [];
  List<PropertyModel> _featuredProperties = [];
  String _searchQuery = '';
  final PropertyService _propertyService = PropertyService();

  /// Getters
  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get featuredProperties => _featuredProperties;
  String get searchQuery => _searchQuery;

  /// Filtered properties based on search query
  List<PropertyModel> get filteredProperties {
    if (_searchQuery.isEmpty) return _properties;
    
    return _properties.where((property) {
      return property.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             property.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             property.type.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void initialize() {
    super.initialize();
    loadProperties();
  }

  /// Load properties (simulating API call)
  Future<void> loadProperties() async {
    await handleAsync(_fetchProperties());
  }

  /// Fetch properties from API
  Future<void> _fetchProperties() async {
    try {
      
      // Fetch all properties from API
      final properties = await _propertyService.fetchAllProperties();
      
      print('🏠 [HomeViewModel] Fetched properties count: ${properties.length}');
      print('🏠 [HomeViewModel] Featured properties count: ${properties.where((p) => p.isFeatured).length}');
      print('🏠 [HomeViewModel] Non-featured properties count: ${properties.where((p) => !p.isFeatured).length}');
      
      if (properties.isNotEmpty) {
        _properties = properties;
        // Set featured properties - only those with is_featured: true
        _featuredProperties = _properties.where((p) => p.isFeatured).toList();
        
      } else {
        _properties = [];
        _featuredProperties = [];
      }
      
      safeNotifyListeners();
    } catch (e) {
      _properties = [];
      _featuredProperties = [];
      safeNotifyListeners();
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    safeNotifyListeners();
  }

  /// Toggle favorite status
  void toggleFavorite(String propertyId) {
    final index = _properties.indexWhere((p) => p.id.toString() == propertyId);
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(
        isFavorite: !_properties[index].isFavorite,
      );
      
      // Update featured properties if necessary
      final featuredIndex = _featuredProperties.indexWhere((p) => p.id.toString() == propertyId);
      if (featuredIndex != -1) {
        _featuredProperties[featuredIndex] = _properties[index];
      }
      
      safeNotifyListeners();
    }
  }

  /// Get property by ID
  PropertyModel? getPropertyById(String id) {
    try {
      final propertyId = int.tryParse(id);
      if (propertyId == null) return null;
      return _properties.firstWhere((p) => p.id == propertyId);
    } catch (e) {
      return null;
    }
  }

  /// Filter properties by type
  List<PropertyModel> getPropertiesByType(String type) {
    return _properties.where((p) => p.type == type).toList();
  }

  /// Get favorite properties
  List<PropertyModel> get favoriteProperties {
    return _properties.where((p) => p.isFavorite).toList();
  }

  @override
  Future<void> refresh() async {
    await loadProperties();
  }
} 