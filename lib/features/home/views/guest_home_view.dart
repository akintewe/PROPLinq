import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:ui';
import '../../../core/animations/animated_list_item.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/search_bottom_sheet.dart';
import '../../../core/widgets/filter_bottom_sheet.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../../core/widgets/location_selection_dialog.dart';
import '../../auth/views/login_view.dart';
import 'tenant_home_view.dart';
import 'agent_home_view.dart';
import '../services/property_service.dart';
import '../models/property_model.dart';
import 'property_details_view.dart';

class GuestHomeView extends StatefulWidget {
  const GuestHomeView({super.key});

  @override
  State<GuestHomeView> createState() => _GuestHomeViewState();
}

class _GuestHomeViewState extends State<GuestHomeView> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late ScrollController _homeScrollController;

  final PropertyService _propertyService = PropertyService();
  final LocationService _locationService = LocationService.instance;
  final UserPreferencesService _prefsService = UserPreferencesService();

  List<PropertyModel> _properties = [];
  List<PropertyModel> _promotedProperties = [];
  List<PropertyModel> _selectedProperties = [];
  bool _isLoadingProperties = true;
  bool _isLoadingPromotedProperties = true;
  bool _isShowingSearchResults = false;
  int _currentPage = 1;
  bool _hasMorePages = false;
  bool _isLoadingMoreProperties = false;
  String _selectedLocation = '';
  String _selectedCategory = 'All';
  List<PropertyModel> _filteredProperties = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _homeScrollController = ScrollController();
    _homeScrollController.addListener(_onHomeScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeLocationBasedDiscovery();
      await _fetchProperties();
      await _fetchPromotedProperties();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationBasedDiscovery() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        // location acquired — proximity features available if in Nigeria
        // (not needed for guest view, but permission is pre-requested for smooth UX on login)
      } else {
        final savedLocation = await _prefsService.getSelectedLocation();
        if (savedLocation != null && mounted) {
          setState(() => _selectedLocation = savedLocation);
        } else if (mounted) {
          await _showLocationSelectionDialog();
        }
      }
    } catch (_) {}
  }

  Future<void> _showLocationSelectionDialog() async {
    final selectedLocation = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocationSelectionDialog(),
    );
    if (selectedLocation != null && mounted) {
      setState(() => _selectedLocation = selectedLocation);
    }
  }

  void _onHomeScroll() {
    if (!_homeScrollController.hasClients) return;
    final pos = _homeScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400 &&
        !_isLoadingMoreProperties &&
        _hasMorePages) {
      _fetchMoreProperties();
    }
  }

  String? _categoryToApiType(String category) {
    switch (category) {
      case 'Hotels': return 'hotel';
      case 'Shortlets': return 'shortlet';
      case 'Real Estate': return 'apartment';
      default: return null;
    }
  }

  Future<void> _fetchMoreProperties() async {
    if (_isLoadingMoreProperties || !_hasMorePages) return;
    setState(() => _isLoadingMoreProperties = true);
    try {
      final nextPage = _currentPage + 1;
      final response = await _propertyService.fetchPropertiesPaginatedPublic(
        page: nextPage,
        type: _categoryToApiType(_selectedCategory),
      );
      final properties = response.getPropertiesAs<PropertyModel>(PropertyModel.fromJson);
      if (mounted) {
        setState(() {
          _properties.addAll(properties);
          _currentPage = nextPage;
          _hasMorePages = properties.length >= 12;
          _isLoadingMoreProperties = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMoreProperties = false);
    }
  }

  Future<void> _fetchProperties({bool isRefresh = false, String? categoryType}) async {
    try {
      setState(() {
        _isLoadingProperties = true;
        if (isRefresh) {
          _properties = [];
          _currentPage = 1;
          _hasMorePages = false;
        }
      });

      final response = await _propertyService.fetchPropertiesPaginatedPublic(
        page: 1,
        type: categoryType ?? _categoryToApiType(_selectedCategory),
      );
      final properties = response.getPropertiesAs<PropertyModel>(PropertyModel.fromJson);

      final featured = properties.where((p) => p.isFeatured).toList();

      if (mounted) {
        setState(() {
          _properties = properties;
          if (featured.isNotEmpty) _promotedProperties = featured;
          _currentPage = 1;
          _hasMorePages = properties.length >= 12;
          _isLoadingProperties = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProperties = false);
    }
  }

  Future<void> _fetchPromotedProperties() async {
    try {
      setState(() => _isLoadingPromotedProperties = true);
      final promoted = await _propertyService.fetchPromotedPropertiesPublic();
      final featured = promoted.where((p) => p.isFeatured).toList();
      if (mounted) {
        setState(() {
          if (featured.isNotEmpty) {
            _promotedProperties = featured;
          } else {
            _promotedProperties = _properties.where((p) => p.isFeatured).toList();
          }
          _isLoadingPromotedProperties = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPromotedProperties = false);
    }
  }

  void _openSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchBottomSheet(
        properties: _properties,
        onLocationSelected: (location) {
          setState(() {
            _isShowingSearchResults = true;
            _selectedLocation = location;
            _selectedCategory = 'All';
            _selectedProperties = [];
          });
        },
        onPropertiesSelected: (properties) {
          setState(() {
            _isShowingSearchResults = true;
            _selectedCategory = 'All';
            _selectedProperties = properties;
          });
        },
      ),
    );
  }

  void _goBackToHome() {
    setState(() {
      _isShowingSearchResults = false;
      _selectedLocation = '';
      _selectedCategory = 'All';
    });
  }

  void _openFilterBottomSheet() {
    FilterBottomSheet.show(
      context,
      onFiltersApplied: (filters) {
        setState(() {
          _filteredProperties = _applyFilters(filters);
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          _showFilteredResultsBottomSheet();
        });
      },
    );
  }

  List<PropertyModel> _applyFilters(Map<String, dynamic> filters) {
    List<PropertyModel> filtered = List.from(_properties);
    if (filters['category'] != null && filters['category'] != 'All') {
      final cat = filters['category'].toString().toLowerCase();
      filtered = filtered.where((p) {
        final t = p.type.toLowerCase();
        final c = p.category.toLowerCase();
        if (cat == 'hotels') return t.contains('hotel') || c.contains('hotel');
        if (cat == 'real estate') return t.contains('apartment') && !t.contains('hotel') && !t.contains('shortlet');
        if (cat == 'shortlets') return t.contains('shortlet') || c.contains('shortlet');
        return true;
      }).toList();
    }
    return filtered;
  }

  void _showFilteredResultsBottomSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtered Results (${_filteredProperties.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Color(0xFF868686)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filteredProperties.isEmpty
                  ? _buildEmptyFilterResults()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _filteredProperties.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            _navigateToPropertyDetails(_filteredProperties[index]);
                          },
                          child: _buildPropertyCard(index, _filteredProperties),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _buildPropertyData(PropertyModel property) {
    final data = <String, dynamic>{
      'id': property.id,
      'uuid': property.uuid,
      'badges': [property.user?.verificationStatus ?? 'Unverified'],
      'title': property.title,
      'location': property.location,
      'average_rating': property.rawJson?['average_rating']?.toString() ?? '0.0',
      'rating_count': property.rawJson?['rating_count'] ?? 0,
      'price': property.price,
      'type': property.type,
      'category': property.category,
      'description': property.description,
      'features': property.features,
      'imageUrl': property.imageUrl,
      'images': property.images ?? (property.imageUrl != null ? [{'full_url': property.imageUrl}] : null),
      'property360_images': property.property360Images,
      'video_url': property.videoUrl,
      'user': property.user?.toJson(),
      'rooms': property.rawJson?['rooms'],
      'has_units': property.rawJson?['has_units'],
      'agent': {
        'name': property.user?.fullName ?? 'Agent',
        'title': 'Agent',
        'phone': property.user?.phoneNumber ?? '',
        'email': property.user?.email ?? '',
        'whatsapp': property.user?.whatsappNumber ?? property.user?.phoneNumber ?? '',
      },
    };
    if (property.rawJson != null) {
      final raw = property.rawJson!;
      if (raw['ratings'] != null) data['ratings'] = raw['ratings'];
      if (raw['average_rating'] != null) data['average_rating'] = raw['average_rating'];
      if (raw['rating_count'] != null) data['rating_count'] = raw['rating_count'];
    }
    return data;
  }

  void _navigateToPropertyDetails(PropertyModel property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertyDetailsView(
          propertyData: _buildPropertyData(property),
          isHomeSeeker: true,
          isGuest: true,
        ),
      ),
    );
  }

  void _promptLogin({PropertyModel? property}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
            ),
            const Icon(Icons.lock_outline, size: 48, color: Color(0xFF426DC2)),
            const SizedBox(height: 16),
            const Text(
              'Sign in to continue',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an account or log in to save properties, message agents, and more.',
              style: TextStyle(fontSize: 14, color: Color(0xFF868686)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF426DC2), Color(0xFF75CFEA)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoginView(
                          onLoginSuccess: property != null
                              ? (loginCtx, userType) => _afterLoginNavigateToProperty(loginCtx, userType, property)
                              : null,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: const Text(
                    'Log In / Sign Up',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue as Guest', style: TextStyle(color: Color(0xFF868686), fontSize: 14)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _afterLoginNavigateToProperty(BuildContext loginCtx, String? userType, PropertyModel property) {
    final isAgent = userType != null && userType != 'home_seeker';
    final navigator = Navigator.of(loginCtx);
    final propertyData = _buildPropertyData(property);
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => isAgent ? const AgentHomeView() : const TenantHomeView()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => PropertyDetailsView(propertyData: propertyData, isHomeSeeker: true),
        ),
      );
    });
  }

  Widget _buildGuestVerificationBadge(PropertyModel property) {
    final categoryLower = property.category.toLowerCase();
    final typeLower = property.type.toLowerCase();
    final showForRentSale = (categoryLower == 'for_rent' || categoryLower == 'for_sale') &&
        typeLower != 'hotel' && typeLower != 'shortlet';
    final forRentSaleText = categoryLower == 'for_rent' ? 'For Rent' : 'For Sale';

    final status = property.user?.verificationStatus;
    final IconData icon;
    final Color iconColor;
    final String text;
    switch (status) {
      case 'Verified':
        icon = Icons.verified; iconColor = Colors.green; text = 'Verified';
        break;
      case 'Pending':
        icon = Icons.pending; iconColor = Colors.orange; text = 'Pending';
        break;
      case 'Rejected':
        icon = Icons.cancel; iconColor = Colors.red; text = 'Rejected';
        break;
      default:
        icon = Icons.pending; iconColor = Colors.orange; text = 'Unverified';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.black)),
            ],
          ),
        ),
        if (showForRentSale) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text(
              forRentSaleText,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF868686)),
            ),
          ),
        ],
      ],
    );
  }

  bool _isShortletProperty(PropertyModel property) {
    final t = property.type.toLowerCase();
    final c = property.category.toLowerCase();
    return t.contains('shortlet') || c.contains('shortlet');
  }

  Widget _buildBlurredAddress(String address) {
    return ClipRect(
      child: Stack(
        children: [
          Text(
            address,
            style: const TextStyle(fontSize: 13, color: Color(0xFF868686)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  bool _doesPropertyMatchCategory(PropertyModel property, String categoryFilter) {
    final f = categoryFilter.toLowerCase();
    final t = property.type.toLowerCase();
    final c = property.category.toLowerCase();
    if (f == 'hotels') return t.contains('hotel') || c.contains('hotel');
    if (f == 'shortlets') return t.contains('shortlet') || c.contains('shortlet');
    if (f == 'real estate') return t.contains('apartment') && !t.contains('hotel') && !t.contains('shortlet');
    return true;
  }

  List<PropertyModel> _getFilteredProperties() {
    List<PropertyModel> base;
    if (_isShowingSearchResults && _selectedProperties.isNotEmpty) {
      base = _selectedProperties;
    } else {
      base = _properties;
    }
    if (_selectedCategory == 'All') return base;
    return base.where((p) => _doesPropertyMatchCategory(p, _selectedCategory)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => _fetchProperties(isRefresh: true),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // Home
            SafeArea(
              child: _isShowingSearchResults ? _buildSearchResults() : _buildHomeContent(),
            ),
            // Saved — locked for guests
            _buildGuestLockedTab(
              icon: Icons.favorite_border,
              title: 'Your Wishlist',
              subtitle: 'Save properties you love and revisit them anytime.',
            ),
            // Account
            _buildGuestAccountTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildGuestBottomNavBar(),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      controller: _homeScrollController,
      child: Column(
        children: [
          _buildHeader(),
          _buildGuestBanner(),
          _buildFeaturedSection(),
          const SizedBox(height: 32),
          _buildCategoriesSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Guest avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF426DC2),
                        border: Border.all(color: const Color(0xFFECF0F9), width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  () {
                                    final hour = DateTime.now().hour;
                                    final greeting = hour >= 5 && hour < 12
                                        ? 'Good morning'
                                        : hour >= 12 && hour < 17
                                            ? 'Good afternoon'
                                            : 'Good evening';
                                    return '$greeting, Guest ';
                                  }(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const Text('👋', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          Text(
                            _isShowingSearchResults && _selectedLocation.isNotEmpty
                                ? _selectedLocation
                                : 'Find your next stay.',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF868686),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Login button instead of notification
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF426DC2), Color(0xFF75CFEA)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Search bar
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openSearchBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: SvgPicture.asset(
                            'assets/icons/search-normal (1).svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(Color(0xFF868686), BlendMode.srcIn),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Search properties, Shortlets & hotels',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFB0B5BB)),
                          ),
                        ),
                        GestureDetector(
                          onTap: _openFilterBottomSheet,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFF426DC2), Color(0xFF63ADDC), Color(0xFF75CFEA)],
                                stops: [0.0, 1.0, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/sort.svg',
                              width: 12,
                              height: 12,
                              fit: BoxFit.scaleDown,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),
        ],
      ),
    );
  }

  Widget _buildGuestBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 116,
          color: const Color(0xFFECF0F9),
          child: Row(
            children: [
              // Left: text + button
              Expanded(
                child: ClipRect(
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'List your properties on Proplinq',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A2B4A),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Start getting bookings and clients',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4A5F7A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _promptLogin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF426DC2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Start Listing',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
              // Right: illustration image cropped to right side
              ClipRect(
                child: SizedBox(
                  width: 140,
                  height: 116,
                  child: Image.asset(
                    'assets/images/banner_bg.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    if (!_isLoadingPromotedProperties && _promotedProperties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Houses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              Transform.translate(
                offset: const Offset(20, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'View all',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF426DC2)),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-20, 0),
                      child: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF426DC2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingPromotedProperties
            ? SizedBox(
                height: 176,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, __) => _buildShimmerFeaturedCard(),
                ),
              )
            : SizedBox(
                height: 176,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _promotedProperties.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => AnimatedListItem(index: index, child: _buildFeaturedCard(index)),
                ),
              ),
      ],
    );
  }

  Widget _buildFeaturedCard(int index) {
    final property = _promotedProperties[index];
    return GestureDetector(
      onTap: () => _navigateToPropertyDetails(property),
      child: Container(
        width: 284,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(imageUrl: 
                property.imageUrl ?? 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: const Color(0xFFE0E0E0)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FormatUtils.formatPrice(property.price),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final filteredProperties = _getFilteredProperties();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryButton('All'),
                const SizedBox(width: 12),
                _buildCategoryButton('Real Estate'),
                const SizedBox(width: 12),
                _buildCategoryButton('Hotels'),
                const SizedBox(width: 12),
                _buildCategoryButton('Shortlets'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoadingProperties)
            ...List.generate(3, (_) => _buildShimmerPropertyCard())
          else if (filteredProperties.isEmpty)
            _buildNoPropertiesFound()
          else ...[
            ...filteredProperties.asMap().entries.map((e) => _buildPropertyCard(e.key, filteredProperties)),
            if (_isLoadingMoreProperties)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF426DC2)),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String title) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () {
        if (_selectedCategory == title) return;
        setState(() {
          _selectedCategory = title;
          _properties = [];
          _currentPage = 1;
          _hasMorePages = false;
          _isLoadingProperties = true;
        });
        _fetchProperties(categoryType: _categoryToApiType(title));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF426DC2), Color(0xFF63ADDC), Color(0xFF75CFEA)],
                  stops: [0.0, 1.0, 1.0],
                )
              : null,
          color: isSelected ? null : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title == 'Real Estate')
              SvgPicture.asset(
                'assets/icons/emojione-monotone_houses.svg',
                width: 16,
                height: 16,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.business,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                ),
              ),
            if (title == 'Hotels')
              SvgPicture.asset(
                'assets/icons/emojione_houses.svg',
                width: 16,
                height: 16,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.hotel,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                ),
              ),
            if (title == 'Shortlets')
              SvgPicture.asset(
                'assets/icons/emojione_houses.svg',
                width: 16,
                height: 16,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.apartment,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                ),
              ),
            if (title == 'Real Estate' || title == 'Hotels' || title == 'Shortlets')
              const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(int index, List<PropertyModel> properties) {
    final property = properties[index];
    return GestureDetector(
      onTap: () => _navigateToPropertyDetails(property),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay badges (same layout as authenticated dashboard)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(property.imageUrl ?? 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Verification badge + For Rent/Sale tag on image (top-left)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _buildGuestVerificationBadge(property),
                      ),
                      // Save button (top-right)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => _promptLogin(property: property),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_border, size: 18, color: Color(0xFF868686)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECF0F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          FormatUtils.toTitleCase(property.type),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF426DC2)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF868686)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _isShortletProperty(property)
                            ? _buildBlurredAddress(property.location)
                            : Text(
                                property.location,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF868686)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        FormatUtils.formatPrice(property.price),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF426DC2)),
                      ),
                      () {
                        final summary = FormatUtils.roomsUnitsSummary(property.rawJson, property.type);
                        if (summary != null) {
                          return Row(
                            children: [
                              const Icon(Icons.meeting_room_outlined, size: 14, color: Color(0xFF426DC2)),
                              const SizedBox(width: 4),
                              Text(summary, style: const TextStyle(fontSize: 12, color: Color(0xFF426DC2), fontWeight: FontWeight.w500)),
                            ],
                          );
                        }
                        if (property.bedrooms != null && property.bedrooms! > 0) {
                          return Row(
                            children: [
                              const Icon(Icons.bed_outlined, size: 16, color: Color(0xFF868686)),
                              const SizedBox(width: 4),
                              Text('${property.bedrooms} bed', style: const TextStyle(fontSize: 12, color: Color(0xFF868686))),
                              if (property.bathrooms != null && property.bathrooms! > 0) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.bathtub_outlined, size: 16, color: Color(0xFF868686)),
                                const SizedBox(width: 4),
                                Text('${property.bathrooms} bath', style: const TextStyle(fontSize: 12, color: Color(0xFF868686))),
                              ],
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }(),
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

  Widget _buildEmptyFilterResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No properties found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters to see more results',
            style: TextStyle(fontSize: 14, color: Color(0xFF868686)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _getFilteredProperties();
    return SingleChildScrollView(
      controller: _homeScrollController,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _goBackToHome,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFEFF0F2), width: 1.14),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back, color: Color(0xFF426DC2), size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedLocation.isEmpty ? 'Search results' : _selectedLocation,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryButton('All'),
                      const SizedBox(width: 12),
                      _buildCategoryButton('Real Estate'),
                      const SizedBox(width: 12),
                      _buildCategoryButton('Hotels'),
                      const SizedBox(width: 12),
                      _buildCategoryButton('Shortlets'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          results.isEmpty
              ? _buildNoPropertiesFound()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => AnimatedListItem(index: index, child: _buildPropertyCard(index, results)),
                ),
        ],
      ),
    );
  }

  Widget _buildNoPropertiesFound() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFF0F2), width: 1),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('😔', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text('No properties found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
          SizedBox(height: 8),
          Text('Try adjusting your search or filters', style: TextStyle(fontSize: 14, color: Color(0xFF868686))),
        ],
      ),
    );
  }

  Widget _buildGuestLockedTab({required IconData icon, required String title, required String subtitle}) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFECF0F9),
                ),
                child: Icon(icon, size: 40, color: const Color(0xFF426DC2)),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF868686)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF426DC2), Color(0xFF75CFEA)]),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: const Text(
                      'Log In / Sign Up',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestAccountTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            const SizedBox(height: 24),
            // Guest profile card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF426DC2),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guest User',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Browsing as guest',
                          style: TextStyle(fontSize: 13, color: Color(0xFF868686)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Sign up / login CTA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF426DC2), Color(0xFF75CFEA)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unlock full access',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Save properties, chat with agents, book instantly, and more.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginView()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF426DC2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Log In / Sign Up',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Feature teasers
            _buildFeatureTile(Icons.favorite_border, 'Wishlist', 'Save your favourite properties'),
            _buildFeatureTile(Icons.message_outlined, 'Messages', 'Chat directly with agents'),
            _buildFeatureTile(Icons.calendar_today_outlined, 'Bookings', 'Book and manage stays'),
            _buildFeatureTile(Icons.verified_user_outlined, 'KYC Verification', 'Get verified for trust'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return GestureDetector(
      onTap: _promptLogin,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFF0F2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFECF0F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF426DC2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF868686))),
                ],
              ),
            ),
            const Icon(Icons.lock_outline, size: 16, color: Color(0xFFB0B5BB)),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestBottomNavBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x0D000000), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, 'Home', 'assets/icons/homeselected.svg', 'assets/icons/homeunselected.svg'),
          _buildNavItem(1, 'Wishlist', 'assets/icons/heartselected.svg', 'assets/icons/heartunselected.svg'),
          _buildNavItem(2, 'Account', 'assets/icons/userselected.svg', 'assets/icons/userunselected.svg'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, String selectedIcon, String unselectedIcon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0 && _currentIndex == 0) {
          Future.wait([
            _fetchProperties(isRefresh: true),
            _fetchPromotedProperties(),
          ]);
          if (_homeScrollController.hasClients) {
            _homeScrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        } else {
          setState(() => _currentIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            isSelected ? selectedIcon : unselectedIcon,
            width: 24,
            height: 24,
            errorBuilder: (_, __, ___) {
              IconData fallback;
              switch (title) {
                case 'Home': fallback = isSelected ? Icons.home : Icons.home_outlined; break;
                case 'Wishlist': fallback = isSelected ? Icons.favorite : Icons.favorite_border; break;
                default: fallback = isSelected ? Icons.person : Icons.person_outline;
              }
              return Icon(fallback, size: 24, color: isSelected ? const Color(0xFF426DC2) : const Color(0xFFB0B5BB));
            },
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFF426DC2) : const Color(0xFFB0B5BB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerFeaturedCard() {
    return Container(
      width: 280,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 8,
                      width: 100,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Row(
                    children: List.generate(3, (i) =>
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 6,
                            margin: EdgeInsets.only(right: i < 2 ? 3 : 0),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 12,
                      width: 70,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerPropertyCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 8,
                      width: 80,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(2, (i) =>
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 6,
                          width: 40,
                          margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
