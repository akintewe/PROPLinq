import '../../../core/base/base_view_model.dart';
import '../models/property_model.dart';

class HomeViewModel extends BaseViewModel {
  List<PropertyModel> _properties = [];
  List<PropertyModel> _featuredProperties = [];
  String _searchQuery = '';

  /// Getters
  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get featuredProperties => _featuredProperties;
  String get searchQuery => _searchQuery;

  /// Filtered properties based on search query
  List<PropertyModel> get filteredProperties {
    if (_searchQuery.isEmpty) return _properties;
    
    return _properties.where((property) {
      return property.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             property.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             property.propertyType.toLowerCase().contains(_searchQuery.toLowerCase());
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

  /// Simulate fetching properties from API
  Future<void> _fetchProperties() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock data
    _properties = [
      const PropertyModel(
        id: '1',
        title: 'Modern Downtown Apartment',
        address: '123 Main St, Downtown, NY 10001',
        price: 850000,
        imageUrl: 'https://example.com/property1.jpg',
        bedrooms: 2,
        bathrooms: 2,
        area: 1200,
        propertyType: 'Apartment',
        agentName: 'Sarah Johnson',
        agentPhone: '+1 (555) 123-4567',
      ),
      const PropertyModel(
        id: '2',
        title: 'Luxury Villa with Pool',
        address: '456 Oak Avenue, Beverly Hills, CA 90210',
        price: 2500000,
        imageUrl: 'https://example.com/property2.jpg',
        bedrooms: 4,
        bathrooms: 3,
        area: 3500,
        propertyType: 'Villa',
        agentName: 'Michael Chen',
        agentPhone: '+1 (555) 987-6543',
      ),
      const PropertyModel(
        id: '3',
        title: 'Cozy Suburban House',
        address: '789 Pine Street, Suburbia, TX 75001',
        price: 450000,
        imageUrl: 'https://example.com/property3.jpg',
        bedrooms: 3,
        bathrooms: 2,
        area: 2000,
        propertyType: 'House',
        agentName: 'Emily Davis',
        agentPhone: '+1 (555) 456-7890',
      ),
      const PropertyModel(
        id: '4',
        title: 'Penthouse with City View',
        address: '321 Sky Tower, Manhattan, NY 10022',
        price: 4200000,
        imageUrl: 'https://example.com/property4.jpg',
        bedrooms: 3,
        bathrooms: 3,
        area: 2800,
        propertyType: 'Penthouse',
        agentName: 'David Rodriguez',
        agentPhone: '+1 (555) 234-5678',
      ),
      const PropertyModel(
        id: '5',
        title: 'Beach House Paradise',
        address: '567 Ocean Drive, Miami Beach, FL 33139',
        price: 1800000,
        imageUrl: 'https://example.com/property5.jpg',
        bedrooms: 4,
        bathrooms: 4,
        area: 2600,
        propertyType: 'Beach House',
        agentName: 'Jessica Martinez',
        agentPhone: '+1 (555) 345-6789',
      ),
    ];

    // Set featured properties (first 3)
    _featuredProperties = _properties.take(3).toList();
    
    safeNotifyListeners();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    safeNotifyListeners();
  }

  /// Toggle favorite status
  void toggleFavorite(String propertyId) {
    final index = _properties.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      _properties[index] = _properties[index].copyWith(
        isFavorite: !_properties[index].isFavorite,
      );
      
      // Update featured properties if necessary
      final featuredIndex = _featuredProperties.indexWhere((p) => p.id == propertyId);
      if (featuredIndex != -1) {
        _featuredProperties[featuredIndex] = _properties[index];
      }
      
      safeNotifyListeners();
    }
  }

  /// Get property by ID
  PropertyModel? getPropertyById(String id) {
    try {
      return _properties.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Filter properties by type
  List<PropertyModel> getPropertiesByType(String type) {
    return _properties.where((p) => p.propertyType == type).toList();
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