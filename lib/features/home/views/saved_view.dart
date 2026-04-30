import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/services/bookings_cache_service.dart';
import '../../../core/services/wishlist_notifier.dart';
import '../services/favorite_service.dart';
import '../services/recently_viewed_service.dart';
import '../models/property_model.dart';
import 'property_details_view.dart';

class SavedView extends StatefulWidget {
  final bool isAgent;
  final VoidCallback? onExploreHome;
  
  const SavedView({super.key, this.isAgent = false, this.onExploreHome});

  @override
  State<SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<SavedView> {
  bool _isSavedProperties = true; // Toggle between Recently Viewed and Saved Properties
  final FavoriteService _favoriteService = FavoriteService();
  final RecentlyViewedService _recentlyViewedService = RecentlyViewedService();
  List<PropertyModel> _savedProperties = [];
  List<Map<String, dynamic>> _recentlyViewedProperties = [];
  // ignore: unused_field
  bool _isLoadingSavedProperties = true;
  bool _isLoadingRecentlyViewed = false; // Start as false to avoid showing loading initially

  @override
  void initState() {
    super.initState();
    _loadSavedProperties();
    _loadRecentlyViewed();
    WishlistNotifier().addListener(_onWishlistChanged);
  }

  void _onWishlistChanged() {
    if (mounted) _loadSavedPropertiesForRefresh();
  }

  @override
  void dispose() {
    WishlistNotifier().removeListener(_onWishlistChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-refresh recently viewed when the widget becomes visible (e.g., when returning from another screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isSavedProperties) {
        _loadRecentlyViewedForRefresh();
      }
    });
  }

  Future<void> _loadSavedProperties() async {
    try {
      setState(() {
        _isLoadingSavedProperties = true;
      });

      final properties = await _favoriteService.getFavorites();
      
      
      setState(() {
        _savedProperties = properties;
        _isLoadingSavedProperties = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSavedProperties = false;
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load saved properties: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Load saved properties without setting loading state (for refresh)
  Future<void> _loadSavedPropertiesForRefresh() async {
    try {
      
      final properties = await _favoriteService.getFavorites();
      
      
      setState(() {
        _savedProperties = properties;
      });
    } catch (e) {
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh saved properties: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadRecentlyViewed() async {
    try {
      setState(() {
        _isLoadingRecentlyViewed = true;
      });

      final properties = await _recentlyViewedService.getRecentlyViewed();
      
      if (mounted) {
        setState(() {
          _recentlyViewedProperties = properties;
          _isLoadingRecentlyViewed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecentlyViewed = false;
        });
      }
    }
  }

  /// Load recently viewed without showing loading state (for auto-refresh)
  Future<void> _loadRecentlyViewedForRefresh() async {
    try {
      final properties = await _recentlyViewedService.getRecentlyViewed();
      
      if (mounted) {
        setState(() {
          _recentlyViewedProperties = properties;
          // Don't change loading state for refresh
        });
      }
    } catch (e) {
      // Silently handle errors during refresh
    }
  }

  Future<void> _removeFromRecentlyViewed(Map<String, dynamic> property) async {
    try {
      final propertyId = property['id'];
      if (propertyId != null) {
        await _recentlyViewedService.removeFromRecentlyViewed(
          propertyId is int ? propertyId : int.tryParse(propertyId.toString()) ?? 0,
        );
        setState(() {
          _recentlyViewedProperties.removeWhere((p) => p['id']?.toString() == propertyId.toString());
        });
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Refresh data based on current tab
  Future<void> _refreshData() async {
    if (_isSavedProperties) {
      // Refresh saved properties without loading state
      await _loadSavedPropertiesForRefresh();
    } else {
      // Refresh recently viewed without loading state
      await _loadRecentlyViewedForRefresh();
    }
  }

  Future<void> _removeFromFavorites(PropertyModel property) async {
    try {
      final success = await _favoriteService.removeFromFavorites(property.id);
      if (success) {
        setState(() {
          _savedProperties.removeWhere((p) => p.id == property.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Property removed from favorites'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove from favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Check if address should be blurred for PropertyModel
  bool _shouldBlurAddress(PropertyModel property) {
    // Only blur for shortlets
    if (property.type.toLowerCase() != 'shortlet') return false;

    // Check if user has booked this property
    final bookingsCacheService = BookingsCacheService();
    return !bookingsCacheService.hasBookedProperty(property.id.toString());
  }

  /// Check if address should be blurred for Map-based property
  bool _shouldBlurAddressFromMap(Map<String, dynamic> property) {
    final type = property['type'] as String?;
    if (type == null) return false;

    final isShortlet = type.toLowerCase() == 'shortlet';
    if (!isShortlet) return false;

    final propertyId = property['id']?.toString();
    if (propertyId == null) return false;

    final bookingsCacheService = BookingsCacheService();
    return !bookingsCacheService.hasBookedProperty(propertyId);
  }

  /// Build blurred text widget
  Widget _buildBlurredText(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Book to view',
            style: TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF426DC2),
          backgroundColor: Colors.white,
          strokeWidth: 3,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Wishlist',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tab switcher
              Center(
                child: Container(
                  width: 300,
                  height: 44,
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECF0F9),
                    borderRadius: BorderRadius.circular(300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSavedProperties = false;
                            });
                            // Reload recently viewed when switching to that tab (without loading state if we have data)
                            if (_recentlyViewedProperties.isEmpty) {
                              _loadRecentlyViewed();
                            } else {
                              _loadRecentlyViewedForRefresh();
                            }
                          },
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: !_isSavedProperties 
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
                              borderRadius: BorderRadius.circular(300),
                            ),
                            child: Center(
                              child: Text(
                                'Recently Viewed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: !_isSavedProperties ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSavedProperties = true;
                            });
                          },
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: _isSavedProperties 
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
                              borderRadius: BorderRadius.circular(300),
                            ),
                            child: Center(
                              child: Text(
                                'Wishlist',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _isSavedProperties ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Content based on selected tab
              Expanded(
                child: _isSavedProperties 
                    ? _buildSavedPropertiesContent() 
                    : _buildRecentlyViewedContent(),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedPropertiesContent() {
    if (_savedProperties.isEmpty) {
    // Empty state for saved properties
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Original illustration
          SizedBox(
            width: 180,
            height: 180,
            child: Image.asset(
              'assets/icons/Frame 171.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 60,
                    color: Color(0xFFCCCCCC),
                  ),
                );
              },
            ),
          ),
            
          // Title
          const Text(
            'Your Wishlist is Empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
            // Subtitle
            const Text(
              'You haven\'t added any properties to your wishlist yet.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF868686),
            ),
          ),
          
          const SizedBox(height: 32),
          
            // Explore button
            GradientButton(
              text: 'Explore Properties',
              onPressed: widget.onExploreHome,
            ),
          ],
        ),
      );
    }

    // Show saved properties grid
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _savedProperties.length,
      itemBuilder: (context, index) {
        final property = _savedProperties[index];
        return _buildSavedPropertyCard(property);
      },
    );
  }

  Widget _buildSavedPropertyCard(PropertyModel property) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
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
            'images': property.imageUrl != null ? [{'full_url': property.imageUrl}] : null,
            'user': property.user?.toJson(),
            'agent': {
              'name': property.user?.fullName ?? 'Agent',
              'title': 'Agent',
              'phone': property.user?.phoneNumber ?? '',
              'email': property.user?.email ?? '',
              'whatsapp': property.user?.whatsappNumber ?? property.user?.phoneNumber ?? '',
            },
          }, isHomeSeeker: true)),
        );
        // Auto-refresh recently viewed when returning (property might have been viewed)
        if (mounted && !_isSavedProperties) {
          _loadRecentlyViewedForRefresh();
        }
      },
      child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property image
              Expanded(
                flex: 3,
                child: Container(
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
                        // Verification badge
                        if (property.user?.verificationStatus == 'verified')
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Favorite button (filled heart)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeFromFavorites(property),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                size: 14,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Property details (reduced height)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              property.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECF0F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              property.type,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF426DC2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 11,
                            color: Color(0xFF868686),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: _shouldBlurAddress(property)
                                ? _buildBlurredText(property.location)
                                : Text(
                                    property.location,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF868686),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            property.rawJson?['average_rating']?.toString() ?? '0.0',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF868686),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.star,
                            size: 11,
                            color: Colors.amber,
                          ),
                          if (property.rawJson?['rating_count'] != null) ...[
                            const SizedBox(width: 2),
                            Text(
                              '(${property.rawJson!['rating_count']})',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF868686),
                              ),
                          ),
                          ],
                          const Spacer(),
                          Flexible(
                            child: Text(
                              property.formattedPrice,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF426DC2),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      // Removed "Contact agent" button - tapping the card already opens property details
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyViewedContent() {
    // Show loading indicator only on initial load, not during refresh
    if (_isLoadingRecentlyViewed && _recentlyViewedProperties.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF426DC2),
        ),
      );
    }

    if (_recentlyViewedProperties.isEmpty) {
      // Empty state for recently viewed
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Same illustration for recently viewed
            SizedBox(
              width: 180,
              height: 180,
              child: Image.asset(
                'assets/icons/Frame 171.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.visibility_off,
                      size: 60,
                      color: Color(0xFFCCCCCC),
                    ),
                  );
                },
              ),
            ),
              
            // Title
            const Text(
              'No Viewed Property',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'You haven\'t viewed any listings yet. Head to the homepage to start your search.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Explore home button
            SizedBox(
              width: 250,
              child: GradientButton(
                text: 'Explore home',
                onPressed: widget.onExploreHome ?? () {
                  // Fallback: try to navigate back if no callback provided
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    // Show recently viewed properties grid
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _recentlyViewedProperties.length,
      itemBuilder: (context, index) {
        final property = _recentlyViewedProperties[index];
        return _buildRecentlyViewedPropertyCard(property);
      },
    );
  }

  Widget _buildRecentlyViewedPropertyCard(Map<String, dynamic> property) {
    final imageUrl = property['imageUrl'] as String? ?? 
                     (property['images'] as List?)?.first?['full_url'] as String? ??
                     'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center';
    
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PropertyDetailsView(
              propertyData: property,
              isHomeSeeker: !widget.isAgent,
            ),
          ),
        );
        // Auto-refresh recently viewed when returning from property details
        if (mounted) {
          _loadRecentlyViewedForRefresh();
        }
      },
      child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
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
                        // Verification badge
                        if ((property['badges'] as List?)?.contains('Verified Agent') == true ||
                            property['user']?['verification_status'] == 'verified')
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Remove button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeFromRecentlyViewed(property),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Property details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              FormatUtils.toTitleCase(property['title']?.toString() ?? 'Property'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (property['type'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECF0F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                FormatUtils.toTitleCase(property['type']?.toString() ?? ''),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF426DC2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 11,
                            color: Color(0xFF868686),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: _shouldBlurAddressFromMap(property)
                                ? _buildBlurredText(property['location'] ?? 'Location')
                                : Text(
                                    property['location'] ?? 'Location',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF868686),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            property['average_rating']?.toString() ?? '0.0',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF868686),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.star,
                            size: 11,
                            color: Colors.amber,
                          ),
                          if (property['rating_count'] != null) ...[
                            const SizedBox(width: 2),
                            Text(
                              '(${property['rating_count']})',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF868686),
                              ),
                          ),
                          ],
                          const Spacer(),
                          Flexible(
                            child: Text(
                              property['price'] != null
                                  ? '₦${property['price'].toString().replaceAllMapped(
                                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                      (Match m) => '${m[1]},',
                                    )}'
                                  : 'Price',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF426DC2),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 