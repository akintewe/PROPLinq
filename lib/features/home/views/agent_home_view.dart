import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'saved_view.dart';
import 'profile_view.dart';
import 'settings_view.dart';
import '../../../core/widgets/kyc_dialog.dart';
import '../../../core/widgets/search_bottom_sheet.dart';
import '../../../core/widgets/filter_bottom_sheet.dart';
import 'package:proplinq/features/home/views/property_details_view.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';
import '../../finance/views/agent_kyc_view.dart';
import '../../finance/views/complete_kyc_view.dart';
import '../services/property_service.dart';
import '../models/property_model.dart';

class AgentHomeView extends StatefulWidget {
  const AgentHomeView({super.key});

  @override
  State<AgentHomeView> createState() => _AgentHomeViewState();
}

class _AgentHomeViewState extends State<AgentHomeView> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  bool _hasShownKycDialog = false;
  bool _isShowingSearchResults = false;
  String _selectedLocation = '';
  String _selectedCategory = 'All';
  
  final AuthService _authService = AuthService();
  final PropertyService _propertyService = PropertyService();
  UserModel? _currentUser;
  bool _isLoadingProfile = true;
  List<PropertyModel> _properties = [];
  bool _isLoadingProperties = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    // Fetch user profile, properties, and show KYC dialog after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchUserProfile();
      await _fetchProperties();
      await _showKycDialogIfNeeded();
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      print('🔄 Fetching user profile...');
      
      final response = await _authService.getProfile();
      
      print('📋 Profile Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');
      
      if (response.success && response.data != null) {
        setState(() {
          _currentUser = response.data;
          _isLoadingProfile = false;
        });
        
        print('👤 User Profile Data:');
        print('  - ID: ${_currentUser!.id}');
        print('  - Name: ${_currentUser!.fullName}');
        print('  - Email: ${_currentUser!.email}');
        print('  - User Type: "${_currentUser!.userType}"');
        print('  - Location: ${_currentUser!.location}');
        print('  - Phone: ${_currentUser!.phoneNumber}');
        if (_currentUser!.agencyName != null) {
          print('  - Agency: ${_currentUser!.agencyName}');
        }
        if (_currentUser!.agentType != null) {
          print('  - Agent Type: ${_currentUser!.agentType}');
        }
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
        print('❌ Failed to fetch profile: ${response.message}');
        if (response.errors != null && response.errors!.isNotEmpty) {
          print('❌ Errors: ${response.errors}');
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
      print('❌ Profile fetch error: $e');
    }
  }

  Future<void> _fetchProperties() async {
    try {
      print('🔄 Fetching properties...');
      setState(() {
        _isLoadingProperties = true;
      });

      final properties = await _propertyService.fetchAllProperties();
      
      print('✅ Properties fetched successfully: ${properties.length} properties');
      
      setState(() {
        _properties = properties;
        _isLoadingProperties = false;
      });
    } catch (e) {
      print('❌ Error fetching properties: $e');
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

  Future<void> _showKycDialogIfNeeded() async {
    if (_hasShownKycDialog) {
      return; // Already shown in this session
    }

    try {
      print('🔄 Checking KYC status for agent...');
      final response = await _authService.getKycStatus();
      
      print('📋 KYC Status Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');
      
      if (response.success) {
        // If data is null, it means KYC is not started/incomplete - show dialog
        if (response.data == null) {
          print('🎯 KYC Status: No data returned - KYC not started or incomplete');
          print('✅ Showing KYC dialog because data is null (KYC incomplete)');
          
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
          
          print('🎯 KYC Status Data:');
          print('  - Status: ${kycStatus.status}');
          print('  - Is Required: ${kycStatus.isRequired}');
          print('  - Should Show Dialog: ${kycStatus.shouldShowKycDialog()}');
          print('  - Message: ${kycStatus.message}');
          
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
            print('✅ KYC is verified or not required - dialog not shown');
          }
        }
      } else {
        print('❌ API call failed - Status Code: ${response.statusCode}');
        print('❌ Failed to get KYC status: ${response.message}');
        if (response.errors != null && response.errors!.isNotEmpty) {
          print('❌ Errors: ${response.errors}');
        }
        
        // If API call fails, don't show dialog to avoid spam
        print('⚠️ KYC status check failed - dialog not shown');
      }
    } catch (e) {
      print('❌ KYC status check error: $e');
      // If there's an error, don't show dialog
    }
  }

  // Test method to fetch property details
  Future<void> _testPropertyDetails(int propertyId) async {
    try {
      print('🧪 Testing property details for ID: $propertyId');
      final propertyDetails = await _propertyService.fetchPropertyDetails(propertyId);
      
      if (propertyDetails != null) {
        print('✅ Property details fetched successfully:');
        print('Title: ${propertyDetails.title}');
        print('Location: ${propertyDetails.location}');
        print('Price: ${propertyDetails.price}');
        print('Type: ${propertyDetails.type}');
        print('Category: ${propertyDetails.category}');
        print('Description: ${propertyDetails.description}');
        print('Bedrooms: ${propertyDetails.bedrooms}');
        print('Bathrooms: ${propertyDetails.bathrooms}');
        print('Image URL: ${propertyDetails.imageUrl}');
      } else {
        print('❌ Failed to fetch property details');
      }
    } catch (e) {
      print('❌ Error testing property details: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchBottomSheet(
        onLocationSelected: (location) {
          setState(() {
            _isShowingSearchResults = true;
            _selectedLocation = location;
            _selectedCategory = 'All';
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
        // Handle filter application
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filters applied: ${filters.toString()}'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh properties data
          await _fetchProperties();
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
              isAgent: true,
              onExploreHome: () {
                setState(() {
                  _currentIndex = 0; // Switch to home tab
                });
              },
            ),
            // Profile Tab
            const ProfileView(isAgent: true),
            // Settings Tab
            const SettingsView(isAgent: true),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
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
    return Column(
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
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _getFilteredSearchResults().length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  final property = _getFilteredSearchResults()[index];
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
                      'badges': property['badges'],
                      'title': property['title'],
                      'location': property['location'],
                      'rating': property['rating'],
                      'price': property['price'],
                      'type': property['type'],
                      'category': property['category'],
                      'period': property['period'],
                      'description': property['type'] == 'Hotel' 
                          ? 'Step into luxury with this fully furnished hotel room located in the heart of ${property['location']}. With modern finishes, spacious rooms, a fitted kitchen, and round-the-clock security, it\'s perfect for professionals, small families, or remote workers seeking comfort and convenience.'
                          : 'Step into luxury with this fully furnished ${property['type'].toLowerCase()} located in the heart of ${property['location']}. With modern finishes, spacious rooms, a fitted kitchen, and round-the-clock security, it\'s perfect for professionals, small families, or remote workers seeking comfort and convenience.',
                      'agent': {
                        'name': 'James Mark',
                        'title': 'Agent',
                        'phone': '09011111111',
                        'email': 'jamesmark@gmail.com',
                        'whatsapp': '08111111111',
                      },
                    })),
                  );
                },
                child: _buildSearchPropertyCard(_getFilteredSearchResults()[index]),
              );
            },
          ),
        ),
      ],
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

  List<Map<String, dynamic>> _getFilteredSearchResults() {
    // Convert PropertyModel to Map format for compatibility with existing UI
    final allProperties = _properties.map((property) => {
      'badges': ['Verified Agent'], // Default badge
      'title': property.title,
      'location': property.location,
      'rating': '(5.0)', // Default rating
      'price': property.price,
      'type': property.type,
      'category': property.category,
      'image': property.imageUrl ?? 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'
    }).toList();

    if (_selectedCategory == 'All') {
      return allProperties;
    } else {
      return allProperties.where((property) => 
        property['category'] == _selectedCategory
      ).toList();
    }
  }

  Widget _buildSearchPropertyCard(Map<String, dynamic> property) {
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
            // Property image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(property['image'] as String),
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
                      child: Row(
                        children: (property['badges'] as List<String>).map((badge) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (badge == 'Verified Agent')
                                  const Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                if (badge == 'Verified Agent') const SizedBox(width: 4),
                                Text(
                                  badge,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: Color(0xFF868686),
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
                          property['title'] as String,
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
                          property['type'] as String,
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
                        child: Text(
                          property['location'] as String,
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
                        property['rating'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF868686),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.green,
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            property['price'] as String,
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
              Row(
                children: [
                  // Profile Image
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: const Color(0xFFECF0F9),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Welcome text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _isLoadingProfile 
                                ? 'Welcome User '
                                : 'Welcome ${_currentUser?.fullName?.split(' ').first ?? 'User'} ',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
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
                            : _currentUser?.agentType?.replaceAll('_', ' ') ?? 
                              (_currentUser?.userType == 'agent' ? 'Agent' : 'User'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF868686),
                        ),
                      ),
                    ],
                  ),
                ],
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
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 24.0, right: 0),
            itemCount: _isLoadingProperties ? 3 : _properties.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (_isLoadingProperties) {
                return _buildShimmerFeaturedProperty();
              }
              return GestureDetector(
                onTap: () async {
                  final property = _properties[index];
                  // Test property details endpoint first
                  await _testPropertyDetails(property.id);
                  
                  // Then navigate to property details
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
                      'badges': ['Verified Agent'],
                      'title': property.title,
                      'location': property.location,
                      'rating': '(5.0)',
                      'price': property.price,
                      'type': property.type,
                      'category': property.category,
                      'description': property.description,
                      'agent': {
                        'name': 'James Mark',
                        'title': 'Agent',
                        'phone': '09011111111',
                        'email': 'jamesmark@gmail.com',
                        'whatsapp': '08111111111',
                      },
                    })),
                  );
                },
                child: _buildFeaturedPropertyCard(index),
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
                _buildCategoryButton('All', true),
                const SizedBox(width: 12),
                _buildCategoryButton('Real Estate', false),
                const SizedBox(width: 12),
                _buildCategoryButton('Hotels', false),
                const SizedBox(width: 12),
                _buildCategoryButton('Shortlets', false),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Property list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _isLoadingProperties ? 3 : _properties.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (_isLoadingProperties) {
                return _buildShimmerPropertyItem();
              }
              return GestureDetector(
                onTap: () async {
                  final property = _properties[index];
                  // Test property details endpoint first
                  await _testPropertyDetails(property.id);
                  
                  // Then navigate to property details
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
                      'badges': ['Verified Agent'],
                      'title': property.title,
                      'location': property.location,
                      'rating': '(5.0)',
                      'price': property.price,
                      'type': property.type,
                      'category': property.category,
                      'description': property.description,
                      'agent': {
                        'name': 'James Mark',
                        'title': 'Agent',
                        'phone': '09011111111',
                        'email': 'jamesmark@gmail.com',
                        'whatsapp': '08111111111',
                      },
                    })),
                  );
                },
                child: _buildPropertyListItem(index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPropertyCard(int index) {
    // Show loading if properties are still loading
    if (_isLoadingProperties) {
      return SizedBox(
        width: 284,
        height: 176,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Use real properties data if available, otherwise show placeholder
    if (_properties.isEmpty) {
      return SizedBox(
        width: 284,
        height: 176,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Text('No properties available'),
          ),
        ),
      );
    }

    // Get property at index, or use first property if index is out of bounds
    final propertyIndex = index < _properties.length ? index : 0;
    final property = _properties[propertyIndex];
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
            'badges': ['Verified Agent'],
            'title': property.title,
            'location': property.location,
            'rating': '(5.0)',
            'price': property.price,
            'type': property.type,
            'category': property.category,
            'description': property.description,
            'agent': {
              'name': 'James Mark',
              'title': 'Agent',
              'phone': '09011111111',
              'email': 'jamesmark@gmail.com',
              'whatsapp': '08111111111',
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
                              child: Text(
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
                              '(5.0)',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                               const SizedBox(width: 4),
                               const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.green,
                            ),
                         
                            const Spacer(),
                            Text(
                              property.price,
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
                  ),
                  // Badge
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Verified Agent',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: Colors.black,
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
    return Container(
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
    );
  }

  Widget _buildPropertyListItem(int index) {
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

    // Get property at index, or use first property if index is out of bounds
    final propertyIndex = index < _properties.length ? index : 0;
    final property = _properties[propertyIndex];
    
    return GestureDetector(
              onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
              'badges': ['Verified Agent'],
              'title': property.title,
              'location': property.location,
              'rating': '(5.0)',
              'price': property.price,
              'type': property.type,
              'category': property.category,
              'description': property.description,
              'agent': {
                'name': 'James Mark',
                'title': 'Agent',
                'phone': '09011111111',
                'email': 'jamesmark@gmail.com',
                'whatsapp': '08111111111',
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
                        child: Row(
                          children: ['Verified Agent'].map((badge) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: badge == 'For sale' 
                                    ? Colors.white
                                    :  Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (badge == 'Verified Agent')
                                    const Icon(
                                      Icons.verified,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                  if (badge == 'Verified Agent') const SizedBox(width: 4),
                                  Text(
                                    badge,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Favorite button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            size: 18,
                            color: Color(0xFF868686),
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
                          child: Text(
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
                          '(5.0)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF868686),
                          ),
                        ),
                           const SizedBox(width: 4),
                           const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.green,
                        ),
                    
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              property.price,
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
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_animationController.value * -200, 0),
              child: Row(
                children: List.generate(10, (index) => 
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'RENT-NOW, PAY LATER',
                      style: TextStyle(
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
          _buildNavItem(1, 'Saved', 'assets/icons/heartselected.svg', 'assets/icons/heartunselected.svg'),
          _buildNavItem(2, 'Profile', 'assets/icons/userselected.svg', 'assets/icons/userunselected.svg'),
          _buildNavItem(3, 'Settings', 'assets/icons/settingselected.svg', 'assets/icons/settingunselected.svg'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, String selectedIcon, String unselectedIcon) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                case 'Saved':
                  fallbackIcon = isSelected ? Icons.favorite : Icons.favorite_border;
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
            color: Colors.black.withOpacity(0.1),
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
            color: Colors.black.withOpacity(0.1),
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
} 