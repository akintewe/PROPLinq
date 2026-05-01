import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:ui';
import 'package:proplinq/core/constants/app_colors.dart';
import '../../../core/animations/animated_list_item.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/services/bookings_cache_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../../core/widgets/location_selection_dialog.dart';
import 'saved_view.dart';
import 'messages_view.dart';
import 'profile_view.dart';
import 'settings_view.dart';
// import 'subscription_view.dart'; // disabled — subscription moved to website
import '../../../core/widgets/kyc_dialog.dart';
import '../../../core/widgets/search_bottom_sheet.dart';
import '../../../core/widgets/filter_bottom_sheet.dart';
import 'package:proplinq/features/home/views/property_details_view.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';
import '../../finance/views/agent_kyc_view.dart';
import '../../finance/views/complete_kyc_view.dart';
import '../services/property_service.dart';
import '../services/favorite_service.dart';
import '../services/chat_service.dart';
import '../models/property_model.dart';
import '../models/paginated_properties_response.dart';
import '../../../core/widgets/ai_chat_fab.dart';

// Image carousel widget for agent property cards
class _AgentPropertyImageCarousel extends StatefulWidget {
  final PropertyModel property;
  final Function(PropertyModel) onFavoriteToggle;
  final Widget Function(PropertyModel) buildVerificationBadge;

  const _AgentPropertyImageCarousel({
    super.key,
    required this.property,
    required this.onFavoriteToggle,
    required this.buildVerificationBadge,
  });

  @override
  State<_AgentPropertyImageCarousel> createState() => _AgentPropertyImageCarouselState();
}

class _AgentPropertyImageCarouselState extends State<_AgentPropertyImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get all image URLs
    List<String> imageUrls = [];
    if (widget.property.images != null && widget.property.images!.isNotEmpty) {
      imageUrls = widget.property.images!.map((img) {
        return img['full_url'] as String? ?? img['url'] as String? ?? '';
      }).where((url) => url.isNotEmpty).toList();
    }
    // Fallback to imageUrl
    if (imageUrls.isEmpty && widget.property.imageUrl != null) {
      imageUrls = [widget.property.imageUrl!];
    }
    // Final fallback
    if (imageUrls.isEmpty) {
      imageUrls = ['https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'];
    }

    return Container(
      height: 200,
      width: double.infinity,
      child: Stack(
        children: [
          // Image carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrls[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Badges
          Positioned(
            top: 16,
            left: 16,
            child: widget.buildVerificationBadge(widget.property),
          ),
          // Favorite button
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => widget.onFavoriteToggle(widget.property),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.property.isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: widget.property.isFavorite ? Colors.red : const Color(0xFF868686),
                ),
              ),
            ),
          ),
          // Pagination dots (only show if more than 1 image)
          if (imageUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imageUrls.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 8 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class AgentHomeView extends StatefulWidget {
  const AgentHomeView({super.key});

  @override
  State<AgentHomeView> createState() => _AgentHomeViewState();
}

class _AgentHomeViewState extends State<AgentHomeView> with TickerProviderStateMixin {
  int _currentIndex = 3; // Start with Profile tab for agents
  final GlobalKey _savedViewKey = GlobalKey();
  late AnimationController _animationController;
  late ScrollController _featuredScrollController;
  late ScrollController _homeScrollController;
  bool _hasShownKycDialog = false;
  bool _isShowingSearchResults = false;
  String _selectedLocation = '';
  String _selectedCategory = 'Shortlets';
  int _currentPromoIndex = 0;
  Timer? _promoTimer;
  Timer? _featuredScrollTimer;
  
  // Filter state
  Map<String, dynamic> _activeFilters = {};
  bool _hasActiveFilters = false;
  List<PropertyModel> _filteredProperties = [];
  bool _isShowingFilterResults = false;
  
  final AuthService _authService = AuthService();
  final PropertyService _propertyService = PropertyService();
  final FavoriteService _favoriteService = FavoriteService();
  final ChatService _chatService = ChatService();
  final LocationService _locationService = LocationService.instance;
  final UserPreferencesService _prefsService = UserPreferencesService();

  UserModel? _currentUser;
  bool _isLoadingProfile = true;
  List<PropertyModel> _properties = [];
  List<PropertyModel> _promotedProperties = [];
  List<PropertyModel> _selectedProperties = [];
  bool _isLoadingProperties = true;
  bool _isLoadingPromotedProperties = true;
  int _unreadMessageCount = 0;
  Timer? _unreadCountTimer;

  // Location-based discovery state
  bool _useProximityDiscovery = false;
  String? _userSelectedLocation;

  // Pagination state
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMorePages = false;
  bool _isLoadingMoreProperties = false;

  // Promotional messages for rotating banner
  final List<String> _promotionalMessages = [
    "PROMOTE YOUR PROPERTY TODAY",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _featuredScrollController = ScrollController();
    _homeScrollController = ScrollController();

    // Start promotional message rotation
    _startPromoMessageRotation();
    
    // Fetch user profile, properties, and show KYC dialog after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchUserProfile();
      await _initializeLocationBasedDiscovery();
      await _fetchProperties();
      await _fetchPromotedProperties();
      await _fetchUnreadMessageCount();
      await _showKycDialogIfNeeded();
      await _showCautionFeeNoticeIfNeeded();
      _startFeaturedAutoScroll();
      
      // Pre-load bookings cache for phone number blur feature
      BookingsCacheService().fetchAndCacheBookings();
      
      // Periodically refresh unread message count
      _unreadCountTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) _fetchUnreadMessageCount();
      });
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _authService.getProfile();

      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _currentUser = response.data;
            _isLoadingProfile = false;
          });
        }
      } else {
        // API failed — load from local storage as fallback
        final cachedUser = await _authService.getCurrentUser();
        if (mounted) {
          setState(() {
            _currentUser = cachedUser;
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      final cachedUser = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = cachedUser;
          _isLoadingProfile = false;
        });
      }
    }
  }

  /// Initialize location-based discovery
  /// Handles Nigeria vs non-Nigeria users differently
  Future<void> _initializeLocationBasedDiscovery() async {
    try {
      // Proactively request location permission and get current location
      // This ensures "Near You" data is ready when user taps search
      debugPrint('🌍 [AgentHomeView] Requesting location permission...');
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        debugPrint('📍 [AgentHomeView] Location acquired: ${position.latitude}, ${position.longitude}');

        // Check if user should use proximity-based discovery (only for users in Nigeria)
        final useProximity = await _locationService.shouldUseProximityDiscovery();

        setState(() {
          _useProximityDiscovery = useProximity;
        });

        if (useProximity) {
          // User is in Nigeria - pre-load nearby areas for search
          debugPrint('🇳🇬 [AgentHomeView] User in Nigeria, loading nearby areas...');
          await _locationService.getNearbyAreas(position);
          debugPrint('✅ [AgentHomeView] Nearby areas cached and ready for search');
        } else {
          // User is outside Nigeria
          debugPrint('🌎 [AgentHomeView] User outside Nigeria');
          final savedLocation = await _prefsService.getSelectedLocation();

          if (savedLocation == null) {
            // Show location selection dialog
            if (mounted) {
              _showLocationSelectionDialog();
            }
          } else {
            // Use saved location for discovery
            setState(() {
              _userSelectedLocation = savedLocation;
              _selectedLocation = savedLocation;
            });
          }
        }
      } else {
        // Location permission denied or location services disabled
        debugPrint('⚠️ [AgentHomeView] Could not get location, using default areas');
        setState(() {
          _useProximityDiscovery = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [AgentHomeView] Error initializing location discovery: $e');
    }
  }

  /// Show location selection dialog for non-Nigeria users
  Future<void> _showLocationSelectionDialog() async {
    final selectedLocation = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocationSelectionDialog(),
    );

    if (selectedLocation != null && mounted) {
      setState(() {
        _userSelectedLocation = selectedLocation;
        _selectedLocation = selectedLocation;
      });
    }
  }

  Future<void> _fetchProperties({bool isRefresh = false}) async {
    try {
      setState(() {
        _isLoadingProperties = true;
        if (isRefresh) {
          _currentPage = 1;
          _properties = [];
        }
      });

      // Fetch ALL pages at once
      // Note: API has a bug where lastPage is always 1 and total is always 0
      // So we fetch pages until we get less than 12 items (empty or partial page)
      List<PropertyModel> allProperties = [];
      int currentPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        print('🟡🟡🟡 [AgentHomeView] ========================================');
        print('🟡 [AgentHomeView] Requesting page: $currentPage');

        final response = await _propertyService.fetchPropertiesPaginated(page: currentPage);

        print('🟡 [AgentHomeView] Response received:');
        print('   - currentPage: ${response.currentPage}');
        print('   - lastPage: ${response.lastPage}');
        print('   - total: ${response.total}');
        print('   - perPage: ${response.perPage}');
        print('   - hasMorePages: ${response.hasMorePages}');
        print('   - properties in response: ${response.properties.length}');
        print('   - nextPageUrl: ${response.nextPageUrl}');
        print('🟡 [AgentHomeView] Full response: $response');

        final properties = response.getPropertiesAs<PropertyModel>(PropertyModel.fromJson);

        // If no properties returned, stop fetching
        if (properties.isEmpty) {
          print('🟡 [AgentHomeView] No more properties, stopping at page $currentPage');
          break;
        }

        allProperties.addAll(properties);

        print('🟡 [AgentHomeView] Fetched page $currentPage with ${properties.length} properties');
        print('🟡 [AgentHomeView] Total accumulated so far: ${allProperties.length}');

        // Check if we should continue fetching
        // If we got a full page (12 items), there might be more
        if (properties.length < 12) {
          print('🟡 [AgentHomeView] Received partial page (${properties.length} < 12), no more pages');
          hasMorePages = false;
        } else {
          print('🟡 [AgentHomeView] Received full page (${properties.length}), checking next page');
          currentPage++;
        }
      }

      print('🟡 [AgentHomeView] Total properties fetched: ${allProperties.length}');
      print('🟡 [AgentHomeView] Featured properties count: ${allProperties.where((p) => p.isFeatured).length}');

      // Always update featured properties from main list
      final featuredFromMain = allProperties.where((p) => p.isFeatured).toList();
      if (featuredFromMain.isNotEmpty) {
        setState(() {
          _promotedProperties = featuredFromMain;
        });
      } else if (_promotedProperties.isNotEmpty && isRefresh) {
        // If no featured properties found but we had some before, clear them on refresh
        setState(() {
          _promotedProperties = [];
        });
      }

      if (allProperties.isNotEmpty) {
        allProperties.shuffle();
      }

      setState(() {
        _properties = allProperties;
        _currentPage = currentPage;
        _lastPage = currentPage;
        _hasMorePages = false;
        _isLoadingProperties = false;
      });

      // Start auto-scrolling after properties are loaded
      _startFeaturedAutoScroll();
    } catch (e) {
      setState(() {
        _isLoadingProperties = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load properties: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  Future<void> _fetchPromotedProperties() async {
    try {
      print('🟡 [AgentHomeView] Starting to fetch promoted properties...');
      setState(() {
        _isLoadingPromotedProperties = true;
      });

      final promotedProperties = await _propertyService.fetchPromotedProperties();
      
      print('🟡 [AgentHomeView] Promoted properties received:');
      print('   - Count: ${promotedProperties.length}');
      if (promotedProperties.isNotEmpty) {
        print('   - First property ID: ${promotedProperties[0].id}');
        print('   - First property title: ${promotedProperties[0].title}');
      }
      
      // Filter to only show properties with is_featured: true
      final featuredProperties = promotedProperties.where((p) => p.isFeatured).toList();
      
      setState(() {
        // Only update if we got results from promoted endpoint, otherwise keep/maintain from main list
        if (featuredProperties.isNotEmpty) {
          _promotedProperties = featuredProperties;
        } else {
          // If promoted endpoint returned empty, try to get from main properties list
          final featuredFromMain = _properties.where((p) => p.isFeatured).toList();
          if (featuredFromMain.isNotEmpty) {
            _promotedProperties = featuredFromMain;
          }
        }
        _isLoadingPromotedProperties = false;
      });
      
      print('✅ [AgentHomeView] Promoted properties loaded successfully');
      print('🟡🟡🟡 [AgentHomeView] ========================================');
      
      // Start auto-scrolling after promoted properties are loaded
      if (_promotedProperties.isNotEmpty) {
        _startFeaturedAutoScroll();
      } else {
        print('⚠️ [AgentHomeView] No promoted properties to display');
      }
    } catch (e, stackTrace) {
      print('❌ [AgentHomeView] Error fetching promoted properties: $e');
      print('❌ [AgentHomeView] Stack trace: $stackTrace');
      print('🟡🟡🟡 [AgentHomeView] ========================================');
      setState(() {
        _isLoadingPromotedProperties = false;
      });
    }
  }

  Future<void> _showCautionFeeNoticeIfNeeded() async {
    if (_currentUser == null) return;

    final agentType = _currentUser!.agentType?.toLowerCase().replaceAll(' ', '_') ?? '';
    if (agentType != 'shortlet') return;

    final alreadySeen = await _prefsService.hasDismissedCautionFeeNotice();
    if (alreadySeen) return;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE6A817), size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Important Notice: Caution Fee Policy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'If you charge a caution fee, it must be clearly stated in your listing with the exact amount. Hidden or undisclosed fees are not allowed and may lead to listing removal.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF444444),
            height: 1.6,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF426DC2), Color(0xFF63ADDC)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () async {
                    await _prefsService.dismissCautionFeeNotice();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text(
                    'I understand',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showKycDialogIfNeeded() async {
    if (_hasShownKycDialog) {
      return; // Already shown in this session
    }

    try {
      final response = await _authService.getKycStatus();
      
      
      if (response.success) {
        // If data is null, it means KYC is not started/incomplete - show dialog
        if (response.data == null) {
          
          _hasShownKycDialog = true;
          KycDialog.show(
            context,
            onGetStarted: () {
              // Navigate to appropriate KYC screen based on user role
              if (_currentUser?.userType == 'agent') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AgentKycView(),
                  ),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CompleteKycView(),
                  ),
                );
              }
            },
            onRemindLater: () {
              // Handle remind later action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('KYC reminder set for later')),
              );
            },
          );
        } else {
          // We have actual KYC status data - check if dialog should be shown
          final kycStatus = response.data!;
          
          
          if (kycStatus.shouldShowKycDialog()) {
            _hasShownKycDialog = true;
            KycDialog.show(
              context,
              onGetStarted: () {
                // Navigate to appropriate KYC screen based on user role
                if (_currentUser?.userType == 'agent') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AgentKycView(),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CompleteKycView(),
                    ),
                  );
                }
              },
              onRemindLater: () {
                // Handle remind later action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('KYC reminder set for later')),
                );
              },
            );
          } else {
          }
        }
      } else {
        if (response.errors != null && response.errors!.isNotEmpty) {
        }
        
        // If API call fails, don't show dialog to avoid spam
      }
    } catch (e) {
      // If there's an error, don't show dialog
    }
  }

  // Test method to fetch property details
  Future<void> _testPropertyDetails(int propertyId) async {
    try {
      final propertyDetails = await _propertyService.fetchPropertyDetails(propertyId);
      
      if (propertyDetails != null) {
      } else {
      }
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _unreadCountTimer?.cancel();
    _featuredScrollTimer?.cancel();
    _promoTimer?.cancel();
    _animationController.dispose();
    _featuredScrollController.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  void _startFeaturedAutoScroll() {
    if (_promotedProperties.isEmpty) return;
    
    // Card width (284) + separator (16) = 300 pixels per card
    const double cardWidth = 284.0;
    const double separatorWidth = 16.0;
    const double scrollDistance = cardWidth + separatorWidth;
    
    // Auto-scroll every 3-4 seconds
    _featuredScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _properties.isEmpty) {
        timer.cancel();
        return;
      }
      
      if (_featuredScrollController.hasClients) {
        final maxScroll = _featuredScrollController.position.maxScrollExtent;
        final currentScroll = _featuredScrollController.offset;
        
        // If we're at the end, scroll back to the beginning
        if (currentScroll >= maxScroll - 10) {
          _featuredScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        } else {
          // Scroll exactly one card at a time
          final nextScroll = currentScroll + scrollDistance;
          _featuredScrollController.animateTo(
            nextScroll.clamp(0, maxScroll),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _startPromoMessageRotation() {
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentPromoIndex = (_currentPromoIndex + 1) % _promotionalMessages.length;
        });
      }
    });
  }

  String _getCurrentPromotionalMessage() {
    return _promotionalMessages[_currentPromoIndex];
  }

  Future<void> _toggleFavorite(PropertyModel property) async {
    try {
      final success = await _favoriteService.toggleFavorite(property.id, property.isFavorite);
      if (success) {
        setState(() {
          // Update the property's favorite status in the list
          final index = _properties.indexWhere((p) => p.id == property.id);
          if (index != -1) {
            _properties[index] = _properties[index].copyWith(isFavorite: !property.isFavorite);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(property.isFavorite 
                ? 'Property removed from favorites' 
                : 'Property added to favorites'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message for authentication failure
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to save favorites'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorite status'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          });
        },
        onPropertiesSelected: (properties) {
          setState(() {
            _isShowingSearchResults = true;
            // Don't clear location - it should be set by onLocationSelected
            _selectedCategory = 'All';
            // Store selected properties for display
            _selectedProperties = properties;
          });
          
          // Force UI rebuild by calling _getFilteredProperties to verify state
          final filteredProps = _getFilteredProperties();
        },
      ),
    );
  }

  void _clearSearchResults() {
    setState(() {
      _isShowingSearchResults = false;
      _selectedLocation = '';
      _selectedCategory = 'All';
      _selectedProperties = [];
    });
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
          _activeFilters = filters;
          _hasActiveFilters = _checkHasActiveFilters(filters);
          _filteredProperties = _applyFilters(filters);
          _isShowingFilterResults = true;
        });
        
        
        // Add a small delay to ensure the filter bottom sheet is fully closed
        Future.delayed(const Duration(milliseconds: 300), () {
          _showSimpleBottomSheet(); // Test with a simple version first
        });
      },
    );
  }
  
  bool _checkHasActiveFilters(Map<String, dynamic> filters) {
    return filters['category'] != 'All' ||
           filters['status'] != 'All' ||
           filters['rating'] != 'All' ||
           (filters['fromPrice'] != null && filters['fromPrice'].toString().isNotEmpty) ||
           (filters['toPrice'] != null && filters['toPrice'].toString().isNotEmpty) ||
           (filters['location'] != null && filters['location'].toString().isNotEmpty);
  }
  
  bool _doesPropertyMatchCategory(PropertyModel property, String categoryFilter) {
    final normalizedFilter = categoryFilter.toLowerCase();
    final propertyType = property.type.toLowerCase();
    final propertyCategory = property.category.toLowerCase();

    if (normalizedFilter == 'hotels') {
      return propertyType.contains('hotel') || propertyCategory.contains('hotel');
    } else if (normalizedFilter == 'shortlets') {
      return propertyType.contains('shortlet') || propertyCategory.contains('shortlet');
    } else if (normalizedFilter == 'real estate') {
      final isApartment = propertyType.contains('apartment');
      final isHotelLike = propertyType.contains('hotel') || propertyCategory.contains('hotel');
      final isShortletLike = propertyType.contains('shortlet') || propertyCategory.contains('shortlet');
      return isApartment && !isHotelLike && !isShortletLike;
    }

    return true;
  }
  
  List<PropertyModel> _getFilteredProperties() {
    
    List<PropertyModel> propertiesToFilter;
    
    // If showing search results, use selected properties as base
    if (_isShowingSearchResults && _selectedProperties.isNotEmpty) {
      propertiesToFilter = _selectedProperties;
    } else {
      // Otherwise, use all properties
      propertiesToFilter = _properties;
    }
    
    // Apply category filtering to the base properties
    if (_selectedCategory == 'All') {
      return propertiesToFilter;
    } else {
      final filtered = propertiesToFilter.where((property) {
        final categoryFilter = _selectedCategory.toLowerCase();
        return _doesPropertyMatchCategory(property, categoryFilter);
      }).toList();
      return filtered;
    }
  }

  List<PropertyModel> _applyFilters(Map<String, dynamic> filters) {
    List<PropertyModel> filtered = List.from(_properties);
    
    // Debug: Print all property categories and types to understand the data
    for (int i = 0; i < _properties.length && i < 5; i++) {
      final prop = _properties[i];
    }
    
    // Apply category filter
    if (filters['category'] != null && filters['category'] != 'All') {
      final categoryFilter = filters['category'].toString().toLowerCase();
      filtered = filtered.where((property) {
        final propertyType = property.type.toLowerCase();
        final propertyCategory = property.category.toLowerCase();
        
        
        // Updated mapping logic based on actual API data
        if (categoryFilter == 'hotels') {
          // Match by type or category
          return propertyType == 'hotel' || propertyCategory == 'hotel' || propertyCategory.contains('hotel');
        } else if (categoryFilter == 'real estate') {
          // Match apartments and other real estate
          return propertyType == 'apartment' || propertyCategory == 'for_rent' || propertyCategory == 'for_sale';
        } else if (categoryFilter == 'shortlets') {
          // Match shortlets
          return propertyType == 'shortlet' || propertyCategory == 'shortlet' || propertyCategory.contains('shortlet');
        }
        return true;
      }).toList();
    }
    
    // Apply status filter (for rent, for sale)
    if (filters['status'] != null && filters['status'] != 'All') {
      final statusFilter = filters['status'].toString().toLowerCase().replaceAll(' ', '_');
      filtered = filtered.where((property) => 
        property.category.toLowerCase() == statusFilter
      ).toList();
    }
    
    // Apply location filter
    if (filters['location'] != null && filters['location'].toString().isNotEmpty) {
      final locationFilter = filters['location'].toString().toLowerCase();
      
      List<PropertyModel> beforeLocationFilter = List.from(filtered);
      filtered = filtered.where((property) {
        final propertyLocation = property.location.toLowerCase();
        // Check if property location contains filter term OR if any part of property location matches
        final locationParts = propertyLocation.split(',').map((part) => part.trim()).toList();
        final filterParts = locationFilter.split(',').map((part) => part.trim()).toList();
        
        // Check direct contains or any location part contains any filter part
        final matches = propertyLocation.contains(locationFilter) || 
                       locationParts.any((locPart) => filterParts.any((filterPart) => 
                         locPart.contains(filterPart) || filterPart.contains(locPart)));
        
        return matches;
      }).toList();
      
    }
    
    // Apply price range filter
    if (filters['fromPrice'] != null && filters['fromPrice'].toString().isNotEmpty) {
      final fromPrice = double.tryParse(filters['fromPrice'].toString().replaceAll(RegExp(r'[^\d.]'), ''));
      if (fromPrice != null) {
        filtered = filtered.where((property) {
          final propertyPrice = double.tryParse(property.price.toString().replaceAll(RegExp(r'[^\d.]'), ''));
          return propertyPrice != null && propertyPrice >= fromPrice;
        }).toList();
      }
    }
    
    if (filters['toPrice'] != null && filters['toPrice'].toString().isNotEmpty) {
      final toPrice = double.tryParse(filters['toPrice'].toString().replaceAll(RegExp(r'[^\d.]'), ''));
      if (toPrice != null) {
        filtered = filtered.where((property) {
          final propertyPrice = double.tryParse(property.price.toString().replaceAll(RegExp(r'[^\d.]'), ''));
          return propertyPrice != null && propertyPrice <= toPrice;
        }).toList();
      }
    }
    
    
    return filtered;
  }

  String _getAgentMotivation() {
    const quotes = [
      'Rise and shine. Deals await. 🌅',
      'Keep grinding. Success is close. 💪',
      'Every listing is an opportunity.',
      'Make today count. 🔥',
      'Your next deal is one call away.',
      'Stay consistent. Stay winning.',
      'Big moves happen every day. 🚀',
      'Hustle smart. Close strong.',
      'Champions show up daily. 🏆',
      'Build the future, one deal at a time.',
      'Your effort today shapes tomorrow.',
      'Keep pushing. The best is ahead.',
    ];
    final index = DateTime.now().day % quotes.length;
    return quotes[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh both properties and featured properties with shuffling
          await Future.wait([
            _fetchProperties(isRefresh: true),
            _fetchPromotedProperties(),
          ]);
        },
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // Home Tab
            SafeArea(
              child: _isShowingSearchResults ? _buildSearchResults() : _buildHomeContent(),
            ),
            // Saved Tab
            SavedView(
              key: _savedViewKey,
              isAgent: true,
              onExploreHome: () {
                setState(() {
                  _currentIndex = 0; // Switch to home tab
                });
              },
            ),
            // Messages Tab
            MessagesView(isAgent: true, onConversationRead: _fetchUnreadMessageCount),
            // Profile Tab
            const ProfileView(isAgent: true),
            // Settings Tab
            const SettingsView(isAgent: true),
          ],
        ),
      ),
      floatingActionButton: const AiChatFab(),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      controller: _homeScrollController,
      child: Column(
        children: [
          _buildHeader(),
          _buildAnimatedBanner(),
          _buildFeaturedSection(),
          const SizedBox(height: 32),
          _buildCategoriesSection(),
          const SizedBox(height: 100), // Extra space for bottom nav
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return SingleChildScrollView(
      controller: _homeScrollController,
      child: Column(
      children: [
        // Search Results Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Back button and location info
              Row(
                children: [
                  GestureDetector(
                    onTap: _goBackToHome,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEFF0F2),
                          width: 1.14,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back,
                          color: Color(0xFF426DC2),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SvgPicture.asset(
                    'assets/icons/emojione-monotone_houses.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF426DC2),
                      BlendMode.srcIn,
                    ),
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.location_city,
                        size: 24,
                        color: Color(0xFF426DC2),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedLocation,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const Text(
                          'Near you',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF868686),
                          ),
                        ),
                      ],
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
                          colors: [
                            Color(0xFF426DC2),
                            Color(0xFF63ADDC),
                            Color(0xFF75CFEA),
                          ],
                          stops: [0.0, 1.0, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/sort.svg',
                        width: 12,
                        height: 12,
                        fit: BoxFit.scaleDown,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Categories
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSearchCategoryButton('All', _selectedCategory == 'All'),
                        const SizedBox(width: 12),
                        _buildSearchCategoryButton('Real Estate', _selectedCategory == 'Real Estate'),
                        const SizedBox(width: 12),
                        _buildSearchCategoryButton('Hotels', _selectedCategory == 'Hotels'),
                        const SizedBox(width: 12),
                        _buildSearchCategoryButton('Shortlets', _selectedCategory == 'Shortlets'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Search Results List
        Builder(
          builder: (context) {
            final filteredResults = _getFilteredSearchResults();
            
            return filteredResults.isEmpty
                ? _buildNoPropertiesFound()
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    key: ValueKey('search_results_${filteredResults.length}_${_selectedCategory}'),
            padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  final property = filteredResults[index];

                  // DEBUG: Check property user data before navigation
                  print('🔍 [AgentHome-Search] Property ID: ${property.id}');
                  print('🔍 [AgentHome-Search] Has user: ${property.user != null}');
                  print('🔍 [AgentHome-Search] Verification status: ${property.user?.verificationStatus}');
                  print('🔍 [AgentHome-Search] User KYC: ${property.user?.kyc}');
                  print('🔍 [AgentHome-Search] User KYC status: ${property.user?.kyc?.status}');
                  print('🔍 [AgentHome-Search] User.toJson(): ${property.user?.toJson()}');

                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
                      'id': property.id,
                      'badges': [property.user?.verificationStatus ?? 'Unverified'],
                      'title': property.title,
                      'location': property.location,
                      'average_rating': property.rawJson?['average_rating']?.toString() ?? '0.0',
                      'rating_count': property.rawJson?['rating_count'] ?? 0,
                      'price': property.price,
                      'type': property.type,
                      'category': property.category,
                      'period': property.category,
                      'features': property.features, // Pass features from API
                      'imageUrl': property.imageUrl, // Pass image URL from search data
                      'images': property.images ?? (property.imageUrl != null ? [{'full_url': property.imageUrl}] : null), // Pass all images from API
                      'property360_images': property.property360Images, // Pass 360 images from API
                      'video_url': property.videoUrl, // Pass video URL from API
                      'description': property.type == 'Hotel'
                          ? 'Step into luxury with this fully furnished hotel room located in the heart of ${property.location}. With modern finishes, spacious rooms, a fitted kitchen, and round-the-clock security, it\'s perfect for professionals, small families, or remote workers seeking comfort and convenience.'
                          : 'Step into luxury with this fully furnished ${property.type.toLowerCase()} located in the heart of ${property.location}. With modern finishes, spacious rooms, a fitted kitchen, and round-the-clock security, it\'s perfect for professionals, small families, or remote workers seeking comfort and convenience.',
                      'user': property.user?.toJson(), // Pass actual user data with KYC info
                      'rooms': property.rawJson?['rooms'],
                      'agent': {
                        'name': property.user?.fullName ?? 'Agent',
                        'title': 'Agent',
                        'phone': property.user?.phoneNumber ?? '',
                        'email': property.user?.email ?? '',
                        'whatsapp': property.user?.whatsappNumber ?? property.user?.phoneNumber ?? '',
                      },
                    })),
                  );
                },
                child: _buildSearchPropertyCard(filteredResults[index]),
              );
            },
          );
          },
        ),
      ],
      ),
    );
  }

  Widget _buildSearchCategoryButton(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF426DC2),
                    Color(0xFF63ADDC),
                    Color(0xFF75CFEA),
                  ],
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
              
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.business,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF666666),
                  );
                },
              ),
            if (title == 'Hotels')
              SvgPicture.asset(
                'assets/icons/emojione_houses.svg',
                width: 16,
                height: 16,
               
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.hotel,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF666666),
                  );
                },
              ),
            if (title == 'Shortlets')
              SvgPicture.asset(
                'assets/icons/emojione_houses.svg',
                width: 16,
                height: 16,
               
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.apartment,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF666666),
                  );
                },
              ),
            if (title == 'Real Estate' || title == 'Hotels' || title == 'Shortlets') const SizedBox(width: 8),
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

  List<PropertyModel> _getFilteredSearchResults() {
    
    // Use the same filtering logic as _getFilteredProperties
    List<PropertyModel> propertiesToFilter;
    
    // If showing search results, use selected properties as base (even if empty)
    if (_isShowingSearchResults) {
      propertiesToFilter = _selectedProperties; // Use selected properties even if empty
    } else {
      // Otherwise, use all properties
      propertiesToFilter = _properties;
    }
    
    // Apply category filtering to the base properties
    if (_selectedCategory == 'All') {
      return propertiesToFilter;
    } else {
      final filtered = propertiesToFilter.where((property) {
        final categoryFilter = _selectedCategory.toLowerCase();
        return _doesPropertyMatchCategory(property, categoryFilter);
        }).toList();
      return filtered;
    }
  }

  Widget _buildAgentImageCarousel(PropertyModel property) {
    return _AgentPropertyImageCarousel(
      key: ValueKey('carousel_${property.id}'),
      property: property,
      onFavoriteToggle: _toggleFavorite,
      buildVerificationBadge: _buildVerificationBadge,
    );
  }

  Widget _buildSearchPropertyCard(PropertyModel property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Property image carousel
            _buildAgentImageCarousel(property),
            
            // Property details
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF426DC2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/location (3).svg',
                        color: Colors.black,
                        width: 16,
                        height: 16,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.black,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _shouldBlurAddress(property)
                            ? _buildBlurredText(property.location)
                            : Text(
                                property.location,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.black,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        property.rawJson?['average_rating']?.toString() ?? '0.0',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF868686),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      if (property.rawJson?['rating_count'] != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${property.rawJson!['rating_count']})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF868686),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (property.type.toLowerCase() == 'hotel')
                            const Text(
                              'From',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF868686),
                              ),
                            ),
                          Text(
                            FormatUtils.formatPrice(property.price),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF426DC2),
                            ),
                          ),
                        ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User greeting and notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                children: [
                  // Profile Image
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF426DC2),
                      border: Border.all(
                        color: const Color(0xFFECF0F9),
                        width: 2,
                      ),
                    ),
                    child: _currentUser?.profilePicture != null && _currentUser!.profilePicture!.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(imageUrl: 
                              _currentUser!.profilePicture!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF426DC2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _currentUser != null && _currentUser!.fullName.isNotEmpty
                                          ? _currentUser!.fullName[0].toUpperCase()
                                          : 'A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF426DC2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _currentUser != null && _currentUser!.fullName.isNotEmpty
                                    ? _currentUser!.fullName[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Welcome text
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
                                  if (_isLoadingProfile) return '$greeting, User ';
                                  final name = _currentUser != null && _currentUser!.fullName.isNotEmpty
                                      ? _currentUser!.fullName.split(' ').first
                                      : 'User';
                                  return '$greeting, $name ';
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
                            const Text(
                              '👋',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Text(
                          _isLoadingProfile
                              ? 'Loading...'
                              : _isShowingSearchResults && _selectedLocation.isNotEmpty
                                  ? _selectedLocation
                                  : _getAgentMotivation(),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFECF0F9),
                    width: 1,
                  ),
                ),
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: SvgPicture.asset(
                    'assets/icons/notification (2).svg',
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Row with search bar and filter button
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openSearchBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF868686),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Search properties or hotels',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFB0B5BB),
                            ),
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
                                colors: [
                                  Color(0xFF426DC2),
                                  Color(0xFF63ADDC),
                                  Color(0xFF75CFEA),
                                ],
                                stops: [0.0, 1.0, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/sort.svg',
                              width: 12,
                              height: 12,
                              fit: BoxFit.scaleDown,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
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

  Widget _buildFeaturedSection() {
    // Hide the entire section if not loading and no featured properties
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              Transform.translate(
                offset: Offset(20, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF426DC2),
                        ),
                      ),
                    ),
                     Transform.translate(
                      offset: Offset(-20, 0),
                      child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF426DC2),)),
                  ],
                ),
              ),

            ],
          ),
        ),

        const SizedBox(height: 16),

        // Featured properties carousel
        _isLoadingPromotedProperties
            ? SizedBox(
                height: 176,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 24.0, right: 0),
                  itemCount: 3,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => _buildShimmerFeaturedProperty(),
                ),
              )
            : SizedBox(
                    height: 176,
                    child: ListView.separated(
                      controller: _featuredScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 24.0, right: 0),
                      itemCount: _promotedProperties.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        return AnimatedListItem(
                          index: index,
                          child: GestureDetector(
                          onTap: () async {
                            final property = _promotedProperties[index];

                            // DEBUG: Check property user data before navigation
                            print('🔍 [AgentHome-Featured] Property ID: ${property.id}');
                            print('🔍 [AgentHome-Featured] Has user: ${property.user != null}');
                            print('🔍 [AgentHome-Featured] Verification status: ${property.user?.verificationStatus}');
                            print('🔍 [AgentHome-Featured] User KYC: ${property.user?.kyc}');
                            print('🔍 [AgentHome-Featured] User KYC status: ${property.user?.kyc?.status}');
                            print('🔍 [AgentHome-Featured] User.toJson(): ${property.user?.toJson()}');

                            // Test property details endpoint first
                            await _testPropertyDetails(property.id);

                            // Then navigate to property details
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
                                'id': property.id,
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
                                'agent': {
                                  'name': property.user?.fullName ?? 'Agent',
                                  'title': 'Agent',
                                  'phone': property.user?.phoneNumber ?? '',
                                  'email': property.user?.email ?? '',
                                  'whatsapp': property.user?.whatsappNumber ?? property.user?.phoneNumber ?? '',
                                },
                              })),
                            );
                          },
                          child: _buildFeaturedPropertyCard(index),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Category buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryButton('All', _selectedCategory == 'All'),
                const SizedBox(width: 12),
                _buildCategoryButton('Real Estate', _selectedCategory == 'Real Estate'),
                const SizedBox(width: 12),
                _buildCategoryButton('Hotels', _selectedCategory == 'Hotels'),
                const SizedBox(width: 12),
                _buildCategoryButton('Shortlets', _selectedCategory == 'Shortlets'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Property list
          _isLoadingProperties 
            ? ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _buildShimmerPropertyItem(),
              )
            : () {
                final filteredProperties = _getFilteredProperties();
                return filteredProperties.isEmpty
                    ? _buildNoPropertiesFound()
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredProperties.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) => AnimatedListItem(index: index, child: _buildPropertyListItem(index, filteredProperties)),
                      );
              }(),
        ],
      ),
    );
  }

  /// Check if address should be blurred for shortlets
  bool _shouldBlurAddress(PropertyModel property) {
    final isShortlet = property.type.toLowerCase() == 'shortlet';
    if (!isShortlet) return false;
    
    final bookingsCacheService = BookingsCacheService();
    return !bookingsCacheService.hasBookedProperty(property.id.toString());
  }

  /// Build blurred text widget
  Widget _buildBlurredText(String text) {
    return Stack(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF868686),
          ),
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationBadge(PropertyModel property) {
    final user = property.user;
    
    // Check if we should show "For Rent" or "For Sale"
    // Exclude shortlet and hotel from showing "For Rent" tag
    final categoryLower = property.category.toLowerCase();
    final showForRentSale = (categoryLower == 'for_rent' || categoryLower == 'for_sale') &&
        property.type.toLowerCase() != 'hotel' &&
        property.type.toLowerCase() != 'shortlet';
    final forRentSaleText = categoryLower == 'for_rent' ? 'For Rent' : 'For Sale';
    
    IconData icon;
    Color iconColor;
    String text;

    if (user == null) {
      icon = Icons.pending;
      iconColor = Colors.orange;
      text = 'Unverified';
    } else {
      switch (user.verificationStatus) {
        case 'Verified':
          icon = Icons.verified;
          iconColor = Colors.green;
          text = 'Verified';
          break;
        case 'Pending':
          icon = Icons.pending;
          iconColor = Colors.orange;
          text = 'Pending';
          break;
        case 'Rejected':
          icon = Icons.cancel;
          iconColor = Colors.red;
          text = 'Rejected';
          break;
        default:
          icon = Icons.pending;
          iconColor = Colors.orange;
          text = 'Unverified';
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: iconColor,
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        if (showForRentSale) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              forRentSaleText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF868686),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeaturedPropertyCard(int index) {
    // Use promoted properties
    if (index >= _promotedProperties.length) {
      return const SizedBox.shrink();
    }

    final property = _promotedProperties[index];
    
    return GestureDetector(
      onTap: () {
        // DEBUG: Check what imageUrl we're passing
        
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
            'id': property.id,
            'badges': [property.user?.verificationStatus ?? 'Unverified'],
            'title': property.title,
            'location': property.location,
            'average_rating': property.rawJson?['average_rating']?.toString() ?? '0.0',
            'rating_count': property.rawJson?['rating_count'] ?? 0,
            'price': property.price,
            'type': property.type,
            'category': property.category,
            'description': property.description,
            'features': property.features, // Pass actual features from API
            'imageUrl': property.imageUrl, // Pass actual image URL from API
            'images': property.images ?? (property.imageUrl != null ? [{'full_url': property.imageUrl}] : null), // Pass all images from API
                      'property360_images': property.property360Images, // Pass 360 images from API
                      'video_url': property.videoUrl, // Pass video URL from API
            'user': property.user?.toJson(), // Pass actual user data from API
            'rooms': property.rawJson?['rooms'],
            'agent': {
              'name': property.user?.fullName ?? 'Agent',
              'title': 'Agent',
              'phone': property.user?.phoneNumber ?? '',
              'email': property.user?.email ?? '',
              'whatsapp': property.user?.whatsappNumber ?? property.user?.phoneNumber ?? '',
            },
          })),
        );
      },
      child: Container(
        width: 284,
        height: 176,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 176,
            width: double.infinity,
                          decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(property.imageUrl ?? 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'),
                  fit: BoxFit.cover,
                ),
              ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Property title and details overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                              SvgPicture.asset(
                        'assets/icons/location (3).svg',
                        width: 16,
                        height: 16,
                       ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _shouldBlurAddress(property)
                                  ? _buildBlurredText(property.location)
                                  : Text(
                                      property.location,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              property.rawJson?['average_rating']?.toString() ?? '0.0',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            if (property.rawJson?['rating_count'] != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${property.rawJson!['rating_count']})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (property.type.toLowerCase() == 'hotel')
                                  const Text(
                                    'From',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                Text(
                                  FormatUtils.formatPrice(property.price),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildVerificationBadge(property),
                  ),
                  // Favorite button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(property),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                        child: Icon(
                          property.isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                          color: property.isFavorite ? Colors.red : const Color(0xFF868686),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF426DC2),
                  Color(0xFF63ADDC),
                  Color(0xFF75CFEA),
                ],
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
             
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.business,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                );
              },
            ),
          if (title == 'Hotels')
            SvgPicture.asset(
              'assets/icons/emojione_houses.svg',
              width: 16,
              height: 16,
            
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.hotel,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                );
              },
            ),
          if (title == 'Shortlets')
            SvgPicture.asset(
              'assets/icons/emojione_houses.svg',
              width: 16,
              height: 16,
            
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.apartment,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                );
              },
            ),
          if (title == 'Real Estate' || title == 'Hotels' || title == 'Shortlets') const SizedBox(width: 8),
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

  Widget _buildPropertyListItem(int index, List<PropertyModel> filteredProperties) {
    
    // Show loading if properties are still loading
    if (_isLoadingProperties) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Use real properties data if available, otherwise show placeholder
    if (_properties.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('No properties available'),
          ),
        ),
      );
    }

    // Get property at index from filtered properties
    final propertyIndex = index < filteredProperties.length ? index : 0;
    final property = filteredProperties[propertyIndex];
    
    return GestureDetector(
              onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
              'id': property.id,
              'badges': [property.user?.verificationStatus ?? 'Unverified'],
              'title': property.title,
              'location': property.location,
              'average_rating': property.rawJson?['average_rating']?.toString() ?? '0.0',
              'rating_count': property.rawJson?['rating_count'] ?? 0,
              'price': property.price,
              'type': property.type,
              'category': property.category,
              'description': property.description,
              'features': property.features, // Pass actual features from API
              'imageUrl': property.imageUrl, // Pass actual image URL from API
              'images': property.images ?? (property.imageUrl != null ? [{'full_url': property.imageUrl}] : null), // Pass all images from API
                      'property360_images': property.property360Images, // Pass 360 images from API
                      'video_url': property.videoUrl, // Pass video URL from API
              'user': property.user?.toJson(), // Pass actual user data from API
              'rooms': property.rawJson?['rooms'],
              'agent': {
                'name': property.user?.fullName ?? 'Agent',
                'title': 'Agent',
                'phone': property.user?.phoneNumber ?? '',
                'email': property.user?.email ?? '',
                'whatsapp': property.user?.whatsappNumber ?? property.user?.phoneNumber ?? '',
              },
            })),
          );
        },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Property image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                                  image: DecorationImage(
                  image: NetworkImage(property.imageUrl ?? 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'),
                  fit: BoxFit.cover,
                ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Badges
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _buildVerificationBadge(property),
                      ),
                      // Favorite button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => _toggleFavorite(property),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                            child: Icon(
                              property.isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                              color: property.isFavorite ? Colors.red : const Color(0xFF868686),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Property details
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECF0F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            property.type,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF426DC2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                             SvgPicture.asset(
                        'assets/icons/location (3).svg',
                        width: 16,
                        height: 16,
                        color: AppColors.grey400
                       ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _shouldBlurAddress(property)
                              ? _buildBlurredText(property.location)
                              : Text(
                                  property.location,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF868686),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          property.rawJson?['average_rating']?.toString() ?? '0.0',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF868686),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        if (property.rawJson?['rating_count'] != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${property.rawJson!['rating_count']})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF868686),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (property.type.toLowerCase() == 'hotel')
                              const Text(
                                'From',
                                style: TextStyle(fontSize: 11, color: Color(0xFF868686)),
                              ),
                            Text(
                              FormatUtils.formatPrice(property.price),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF426DC2),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildAnimatedBanner() {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1.0, 0.0),
          end: Alignment(1.0, 0.0),
          stops: [0.0113, 0.4555, 1.1245],
          colors: [
            Color(0xFF426DC2),
            Color(0xFF75CFEA),
            Color.fromRGBO(51, 204, 153, 0.8),
          ],
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_animationController.value * -200, 0),
              child: Row(
                children: List.generate(10, (index) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _getCurrentPromotionalMessage(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _fetchUnreadMessageCount() async {
    try {
      final chatData = await _chatService.getUserChats();
      final currentUser = await _authService.getCurrentUser();
      final currentUserId = currentUser?.id.toString();
      
      if (currentUserId == null) {
        setState(() {
          _unreadMessageCount = 0;
        });
        return;
      }
      
      // Group conversations and count unread ones
      Map<String, Map<String, dynamic>> conversationMap = {};
      
      for (final chat in chatData) {
        final user = chat['user'] as Map<String, dynamic>?;
        final otherPersonId = user?['id']?.toString() ?? '';
        final receivedAt = chat['received_at'] as String?;
        
        // Extract sender_id to determine if current user sent this message
        final senderId = chat['sender_id']?.toString();
        final isSentByCurrentUser = senderId == currentUserId;
        
        // Message is unread only if received_at is null AND current user is NOT the sender
        final isUnread = receivedAt == null && !isSentByCurrentUser;
        
        if (otherPersonId.isEmpty) continue;
        
        String conversationKey = otherPersonId;
        
        if (!conversationMap.containsKey(conversationKey)) {
          conversationMap[conversationKey] = {
            'has_unread': isUnread,
          };
        } else {
          if (isUnread) {
            conversationMap[conversationKey]!['has_unread'] = true;
          }
        }
      }
      
      // Count conversations with unread messages
      int unreadCount = 0;
      for (final conversation in conversationMap.values) {
        if (conversation['has_unread'] == true) {
          unreadCount++;
        }
      }
      
      if (mounted) {
        setState(() {
          _unreadMessageCount = unreadCount;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unreadMessageCount = 0;
        });
      }
    }
  }

  Widget _buildCustomBottomNavBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, 'Home', 'assets/icons/homeselected.svg', 'assets/icons/homeunselected.svg'),
          _buildNavItem(1, 'Wishlist', 'assets/icons/heartselected.svg', 'assets/icons/heartunselected.svg'),
          _buildNavItem(2, 'Messages', 'assets/icons/tabler_message (1).svg', 'assets/icons/tabler_message.svg'),
          _buildNavItem(3, 'Profile', 'assets/icons/userselected.svg', 'assets/icons/userunselected.svg'),
          _buildNavItem(4, 'Settings', 'assets/icons/settingselected.svg', 'assets/icons/settingunselected.svg'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, String selectedIcon, String unselectedIcon) {
    final isSelected = _currentIndex == index;
    final showBadge = index == 2 && _unreadMessageCount > 0 && _currentIndex != 2; // Messages tab (index 2), hide badge when viewing messages
    
    return GestureDetector(
      onTap: () {
        // If clicking on home tab (index 0) when already on home, scroll to top and refresh
        if (index == 0 && _currentIndex == 0) {
          // Refresh both properties and featured properties with shuffling
          Future.wait([
            _fetchProperties(isRefresh: true),
            _fetchPromotedProperties(),
          ]);
          // Scroll to top
          if (_homeScrollController.hasClients) {
            _homeScrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        } else {
          // Clear unread count when navigating to messages tab
          if (index == 2) {
            setState(() {
              _unreadMessageCount = 0; // Clear badge when viewing messages
            });
          }
          // Clear unread count when leaving messages tab
          if (_currentIndex == 2 && index != 2) {
            setState(() {
              _unreadMessageCount = 0; // Clear badge when leaving messages
            });
          }
          
          setState(() {
            _currentIndex = index;
          });
          
          // Fetch unread count only when NOT coming from or going to messages tab
          // (avoids immediately restoring badge after user visits messages)
          if (index != 2 && _currentIndex != 2) {
            _fetchUnreadMessageCount();
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SvgPicture.asset(
                isSelected ? selectedIcon : unselectedIcon,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to Material icons if SVG fails
                  IconData fallbackIcon;
                  switch (title) {
                    case 'Home':
                      fallbackIcon = isSelected ? Icons.home : Icons.home_outlined;
                      break;
                    case 'Wishlist':
                      fallbackIcon = isSelected ? Icons.favorite : Icons.favorite_border;
                      break;
                    case 'Messages':
                      fallbackIcon = isSelected ? Icons.message : Icons.message_outlined;
                      break;
                    case 'Profile':
                      fallbackIcon = isSelected ? Icons.person : Icons.person_outline;
                      break;
                    case 'Settings':
                      fallbackIcon = isSelected ? Icons.settings : Icons.settings_outlined;
                      break;
                    default:
                      fallbackIcon = Icons.circle;
                  }
                  return Icon(
                    fallbackIcon,
                    size: 24,
                    color: isSelected ? const Color(0xFF426DC2) : const Color(0xFFB0B5BB),
                  );
                },
              ),
              // Badge for unread messages
              if (showBadge)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF426DC2),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadMessageCount > 99 ? '99+' : '$_unreadMessageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSelected 
                  ? const Color(0xFF426DC2)  
                  : const Color(0xFFB0B5BB),
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer loading widgets
  Widget _buildShimmerFeaturedProperty() {
    return Container(
      width: 280,
      height: 180, // Further reduced height
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
          // Shimmer for image
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100, // Further reduced height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10), // Further reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shimmer for title
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 12, // Further reduced height
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Shimmer for location
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 8, // Further reduced height
                      width: 100, // Further reduced width
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Shimmer for features
                  Row(
                    children: List.generate(3, (index) => 
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 6, // Further reduced height
                            margin: EdgeInsets.only(right: index < 2 ? 3 : 0), // Further reduced margin
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Shimmer for price
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 12, // Further reduced height
                      width: 70, // Further reduced width
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
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

  Widget _buildShimmerPropertyItem() {
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
        padding: const EdgeInsets.all(10), // Further reduced padding
        child: Row(
          children: [
            // Shimmer for property image
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 65, // Further reduced width
                height: 65, // Further reduced height
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 10), // Further reduced spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shimmer for title
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 12, // Further reduced height
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4), // Further reduced spacing
                  // Shimmer for location
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 8, // Further reduced height
                      width: 80, // Further reduced width
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4), // Further reduced spacing
                  // Shimmer for features
                  Row(
                    children: List.generate(2, (index) => 
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 6, // Further reduced height
                          width: 40, // Further reduced width
                          margin: EdgeInsets.only(right: index < 1 ? 8 : 0), // Further reduced margin
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Shimmer for price
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 12, // Further reduced height
                width: 60, // Further reduced width
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Simple test method to verify bottom sheet functionality
  void _showSimpleBottomSheet() {
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Filtered Properties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text('Found ${_filteredProperties.length} properties'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Show the full bottom sheet
                  _showFilteredResultsBottomSheet();
                },
                child: const Text('Show Full Results'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showFilteredResultsBottomSheet() {
    
    if (!mounted) {
      return;
    }
    
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
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
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtered Results (${_filteredProperties.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF868686),
                    ),
                  ),
                ],
              ),
            ),
            
            // Filtered properties list
            Expanded(
              child: _filteredProperties.isEmpty
                  ? _buildEmptyFilterResults()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _filteredProperties.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            final property = _filteredProperties[index];
                            Navigator.of(context).pop(); // Close bottom sheet
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
                                'id': property.id,
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
                                'imageUrl': property.imageUrl, // Pass actual image URL from API
                                'images': property.images ?? (property.imageUrl != null ? [{'full_url': property.imageUrl}] : null), // Pass all images from API
                      'property360_images': property.property360Images, // Pass 360 images from API
                      'video_url': property.videoUrl, // Pass video URL from API
                                'user': property.user?.toJson(), // Pass actual user data from API
                                'rooms': property.rawJson?['rooms'],
                                'agent': {
                                  'name': property.user?.fullName ?? 'Agent',
                                  'title': 'Agent',
                                  'phone': property.user?.phoneNumber ?? '',
                                  'email': property.user?.email ?? '',
                                  'whatsapp': property.user?.whatsappNumber ?? property.user?.phoneNumber ?? '',
                                },
                              })),
                            );
                          },
                          child: _buildFilteredPropertyCard(_filteredProperties[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ).then((value) {
    }).catchError((error) {
    });
    
    } catch (e) {
    }
  }
  
  Widget _buildEmptyFilterResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Color(0xFF999999),
            ),
            const SizedBox(height: 16),
            const Text(
              'No properties found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters to see more results',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilteredPropertyCard(PropertyModel property) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Property image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(property.imageUrl ?? 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Badge
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildVerificationBadge(property),
                    ),
                    // Favorite button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(property),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            property.isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: property.isFavorite ? Colors.red : const Color(0xFF868686),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Property details
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF426DC2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF868686),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _shouldBlurAddress(property)
                            ? _buildBlurredText(property.location)
                            : Text(
                                property.location,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF868686),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        property.rawJson?['average_rating']?.toString() ?? '0.0',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF868686),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      if (property.rawJson?['rating_count'] != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${property.rawJson!['rating_count']})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF868686),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (property.type.toLowerCase() == 'hotel')
                            const Text(
                              'From',
                              style: TextStyle(fontSize: 11, color: Color(0xFF868686)),
                            ),
                          Text(
                            FormatUtils.formatPrice(property.price),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF426DC2),
                            ),
                          ),
                        ],
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

  Widget _buildNoPropertiesFound() {
    // Debug logging
    
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEFF0F2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '😔',
            style: TextStyle(
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _isShowingSearchResults && _selectedLocation.isNotEmpty
                  ? (_selectedCategory != 'All' 
                      ? 'No ${_selectedCategory.toLowerCase()} properties found in $_selectedLocation'
                      : 'No properties found in $_selectedLocation')
                  : (_selectedCategory != 'All'
                      ? 'No ${_selectedCategory.toLowerCase()} properties found'
                      : 'No properties found in this category'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isShowingSearchResults && _selectedLocation.isNotEmpty
                ? 'Try selecting a different category or location'
                : 'Try selecting a different category',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 