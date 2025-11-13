import 'package:flutter/material.dart';
import '../../../core/widgets/gradient_button.dart';
import '../services/favorite_service.dart';
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
  List<PropertyModel> _savedProperties = [];
  // ignore: unused_field
  bool _isLoadingSavedProperties = true;

  @override
  void initState() {
    super.initState();
    _loadSavedProperties();
  }

  Future<void> _loadSavedProperties() async {
    try {
      print('🔄 SavedView: Loading saved properties...');
      setState(() {
        _isLoadingSavedProperties = true;
      });

      final properties = await _favoriteService.getFavorites();
      
      print('✅ SavedView: Received ${properties.length} saved properties');
      
      setState(() {
        _savedProperties = properties;
        _isLoadingSavedProperties = false;
      });
    } catch (e) {
      print('❌ SavedView: Error loading saved properties: $e');
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
      print('🔄 SavedView: Refreshing saved properties...');
      
      final properties = await _favoriteService.getFavorites();
      
      print('✅ SavedView: Received ${properties.length} saved properties');
      
      setState(() {
        _savedProperties = properties;
      });
    } catch (e) {
      print('❌ SavedView: Error refreshing saved properties: $e');
      
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

  /// Refresh data based on current tab
  Future<void> _refreshData() async {
    print('🔄 SavedView: Refreshing data for current tab...');
    print('📊 Current tab: ${_isSavedProperties ? "Saved Properties" : "Recently Viewed"}');
    
    if (_isSavedProperties) {
      // Refresh saved properties without loading state
      print('🔄 Starting saved properties refresh...');
      await _loadSavedPropertiesForRefresh();
      print('✅ Saved properties refresh completed');
    } else {
      // Refresh recently viewed (placeholder for now)
      print('📝 Recently viewed refresh - placeholder for future implementation');
      // TODO: Implement recently viewed refresh when that feature is added
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate refresh
      print('✅ Recently viewed refresh completed');
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
      print('❌ Error removing from favorites: $e');
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
                'Saved',
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
                                'Saved Properties',
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
                child: _isSavedProperties ? _buildSavedPropertiesContent() : _buildRecentlyViewedContent(),
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
            'No Saved Property',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
            // Subtitle
            const Text(
              'You haven\'t saved any properties yet.',
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
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
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
          }, isHomeSeeker: true)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
                          Colors.black.withOpacity(0.3),
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
                                color: Colors.green.withOpacity(0.9),
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
                                color: Colors.white.withOpacity(0.9),
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
                            child: Text(
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
                          const Text(
                            '(5.0)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF868686),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.star,
                            size: 11,
                            color: Colors.green,
                          ),
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
} 