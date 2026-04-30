import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/location_service.dart';
import '../services/property_search_service.dart';
import '../../features/home/models/property_model.dart';
import '../../features/home/services/property_service.dart';
import '../../features/home/views/property_details_view.dart';

class SearchBottomSheet extends StatefulWidget {
  final String? initialQuery;
  final Function(String)? onLocationSelected;
  final Function(List<PropertyModel>)? onPropertiesSelected;
  final List<PropertyModel> properties;

  const SearchBottomSheet({
    super.key,
    this.initialQuery,
    this.onLocationSelected,
    this.onPropertiesSelected,
    required this.properties,
  });

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PropertyService _propertyService = PropertyService();

  List<Map<String, dynamic>> _locations = [];
  List<PropertyModel> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = true;
  String _searchQuery = '';
  String? _debounceQuery;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _loadNearbyLocations();
    // Auto-focus the search field when bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  /// Load nearby locations based on user's current location
  Future<void> _loadNearbyLocations() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      final position = await LocationService.instance.getCurrentLocation();
      if (position != null) {
        final nearbyAreas = await LocationService.instance.getNearbyAreas(position);
        setState(() {
          _locations = nearbyAreas;
          _isLoadingLocation = false;
        });
      } else {
        // Fallback to default areas
        setState(() {
          _locations = LocationService.instance.getDefaultNearbyAreas();
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locations = LocationService.instance.getDefaultNearbyAreas();
        _isLoadingLocation = false;
      });
    }
  }

  /// Search properties — tries API first, falls back to local
  void _searchProperties(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _debounceQuery = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
      _debounceQuery = query;
    });

    // Debounce: wait 400ms then fire API search
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || _debounceQuery != query) return;
      _runApiSearch(query);
    });
  }

  Future<void> _runApiSearch(String query) async {
    try {
      final response = await _propertyService.searchProperties(query: query);
      if (!mounted || _debounceQuery != query) return;
      if (response.success && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _searchResults = response.data!;
          _isSearching = false;
        });
      } else {
        // Fall back to local search if API returns nothing
        final local = PropertySearchService.instance.searchPropertiesByName(
          widget.properties,
          query,
        );
        setState(() {
          _searchResults = local;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      final local = PropertySearchService.instance.searchPropertiesByName(
        widget.properties,
        query,
      );
      setState(() {
        _searchResults = local;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search properties or hotels',
                hintStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFB0B5BB),
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color(0xFF426DC2),
                    width: 1,
                  ),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SvgPicture.asset(
                    'assets/icons/search-normal (1).svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF868686),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                _searchProperties(value);
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Content area - shows search results when query is typed, locations when empty
          Expanded(
            child: _searchQuery.isNotEmpty
              ? _buildSearchResults()
              : _buildLocationSuggestions(),
          ),
        ],
      ),
    );
  }

  /// Build search results
  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF426DC2)));
    }
    if (_searchResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🔍',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'No properties found for "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Try searching with different keywords',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF868686),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final property = _searchResults[index];
        return _buildPropertyCard(property);
      },
    );
  }

  /// Build location suggestions
  Widget _buildLocationSuggestions() {
    if (_isLoadingLocation) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF426DC2),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _locations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final location = _locations[index];
        return _buildLocationItem(location);
      },
    );
  }

  /// Build property card for search results
  Widget _buildPropertyCard(PropertyModel property) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        // Navigate to property details screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PropertyDetailsView(
              propertyData: {
                'id': property.id,
                'badges': [property.user?.verificationStatus ?? 'Unverified'],
                'title': property.title,
                'location': property.location,
                'rating': '(5.0)',
                'price': property.price,
                'type': property.type,
                'category': property.category,
                'description': property.description,
                'features': property.features,
                'imageUrl': property.imageUrl,
                'images': property.imageUrl != null ? [{'full_url': property.imageUrl}] : null,
                'user': property.user?.toJson(),
                'agent': {
                  'name': property.user?.fullName ?? 'Agent',
                  'title': 'Agent',
                  'phone': property.user?.phoneNumber ?? '',
                  'email': property.user?.email ?? '',
                  'whatsapp': property.user?.whatsappNumber ?? property.user?.phoneNumber ?? '',
                },
              },
              isHomeSeeker: true,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEFF0F2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Property image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF8F9FA),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: property.imageUrl != null
                    ? CachedNetworkImage(imageUrl: 
                        property.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) {
                          return const Icon(
                            Icons.home,
                            color: Color(0xFF426DC2),
                            size: 30,
                          );
                        },
                      )
                    : const Icon(
                        Icons.home,
                        color: Color(0xFF426DC2),
                        size: 30,
                      ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Property details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property.location,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF868686),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        property.price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF426DC2),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF426DC2).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.type.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF426DC2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(Map<String, dynamic> location) {
    return GestureDetector(
      onTap: () async {
        Navigator.of(context).pop();

        // First, set the location name
        widget.onLocationSelected?.call(location['title']);

        // Then filter properties by location
        List<PropertyModel> filteredProperties;

        // Check if this is "Near You" location
        if (location['locationQuery'] == 'near me' || location['isNearYou'] == true) {
          // Get user's current position to determine their region
          final position = await LocationService.instance.getCurrentLocation();

          if (position != null && LocationService.instance.isLocationInNigeria(position.latitude, position.longitude)) {
            // Determine user's region and filter properties by that region
            final userRegion = await LocationService.instance.getUserRegionName(position);
            debugPrint('🎯 [SearchBottomSheet] User is in region: $userRegion, filtering properties...');
            debugPrint('📊 [SearchBottomSheet] Total properties to search: ${widget.properties.length}');

            // Filter properties that match the user's region
            filteredProperties = widget.properties.where((property) {
              final propertyLocation = property.location.toLowerCase();
              final regionLower = userRegion.toLowerCase();

              // Check if property location contains the user's region
              // This handles cases like "Garki, Abuja", "Lekki, Lagos", etc.
              final matches = propertyLocation.contains(regionLower);

              if (matches) {
                debugPrint('✓ Property "${property.title}" in "${property.location}" matches region $userRegion');
              }

              return matches;
            }).toList();

            debugPrint('✅ [SearchBottomSheet] Found ${filteredProperties.length} properties near you in $userRegion');

            // If no properties found, show helpful message
            if (filteredProperties.isEmpty) {
              debugPrint('⚠️ [SearchBottomSheet] No properties found in $userRegion. Check if properties have correct location data.');
            }
          } else {
            // Fallback: show all properties
            debugPrint('⚠️ [SearchBottomSheet] Could not determine user region, showing all properties');
            filteredProperties = widget.properties;
          }
        } else {
          // Use regular location search for specific locations
          filteredProperties = PropertySearchService.instance.searchPropertiesByLocation(
            widget.properties,
            location['locationQuery'] ?? location['title'],
          );
        }

        widget.onPropertiesSelected?.call(filteredProperties);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
         
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: location['iconColor'].withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  location['icon'],
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    location['iconColor'],
                    BlendMode.srcIn,
                  ),
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon
                    return Icon(
                      location['isNearYou'] == true 
                          ? Icons.my_location 
                          : Icons.location_city,
                      size: 24,
                      color: location['iconColor'],
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location['subtitle'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF868686),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    String? initialQuery,
    Function(String)? onLocationSelected,
    Function(List<PropertyModel>)? onPropertiesSelected,
    required List<PropertyModel> properties,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchBottomSheet(
        initialQuery: initialQuery,
        onLocationSelected: onLocationSelected,
        onPropertiesSelected: onPropertiesSelected,
        properties: properties,
      ),
    );
  }
} 