import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'saved_view.dart';
import 'profile_view.dart';
import 'settings_view.dart';
import '../../../core/widgets/kyc_dialog.dart';
import '../../../core/widgets/search_bottom_sheet.dart';
import '../../../core/widgets/filter_bottom_sheet.dart';
import 'package:proplinq/features/home/views/property_details_view.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    // Show KYC dialog after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showKycDialogIfNeeded();
    });
  }

  void _showKycDialogIfNeeded() {
    if (!_hasShownKycDialog) {
      _hasShownKycDialog = true;
      KycDialog.show(
        context,
        onGetStarted: () {
          // Handle KYC start action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('KYC process started!')),
          );
        },
        onRemindLater: () {
          // Handle remind later action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('KYC reminder set for later')),
          );
        },
      );
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Home Tab
          SafeArea(
            child: _isShowingSearchResults ? _buildSearchResults() : _buildHomeContent(),
          ),
          // Saved Tab
          const SavedView(isAgent: true),
          // Profile Tab
          const ProfileView(isAgent: true),
          // Settings Tab
          const SettingsView(isAgent: true),
        ],
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
                      child: const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 16,
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
              Container(
                width: 20,
                height: 20,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFF426DC2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.business,
                  size: 14,
                  color: isSelected ? const Color(0xFF426DC2) : Colors.white,
                ),
              ),
            if (title == 'Hotels')
              Container(
                width: 20,
                height: 20,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.hotel,
                  size: 14,
                  color: isSelected ? const Color(0xFFE91E63) : Colors.white,
                ),
              ),
            if (title == 'Shortlets')
              Container(
                width: 20,
                height: 20,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.apartment,
                  size: 14,
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                ),
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
    final allProperties = [
      {
        'badges': ['For sale', 'Verified Agent'],
        'title': 'Luxury 4-Bedroom Apartment',
        'location': _selectedLocation,
        'rating': '(4.8)',
        'price': '#3,500,000',
        'type': 'Apartment',
        'category': 'Real Estate',
        'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badges': ['Verified Agent'],
        'title': 'Executive Hotel Suite',
        'location': _selectedLocation,
        'rating': '(4.9)',
        'price': '#120,000',
        'type': 'Hotel',
        'category': 'Hotels',
        'period': 'per night',
        'image': 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badges': ['Verified Agent'],
        'title': 'Premium Shortlet',
        'location': _selectedLocation,
        'rating': '(4.6)',
        'price': '#65,000',
        'type': 'Shortlet',
        'category': 'Shortlets',
        'period': 'per night',
        'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badges': ['For sale', 'Verified Agent'],
        'title': 'Modern 2-Bedroom Flat',
        'location': _selectedLocation,
        'rating': '(4.7)',
        'price': '#1,800,000',
        'type': 'Apartment',
        'category': 'Real Estate',
        'image': 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600&h=400&fit=crop&crop=center'
      },
    ];

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
                        width: 16,
                        height: 16,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Color(0xFF868686),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property['location'] as String,
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
                          if (property.containsKey('period'))
                            Text(
                              property['period'] as String,
                              style: const TextStyle(
                                fontSize: 11,
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
                          const Text(
                            'Welcome John ',
                            style: TextStyle(
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
                      const Text(
                        'Agent',
                        style: TextStyle(
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
                            child: const Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 16,
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
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  final properties = <Map<String, String>>[
                    {
                      'badge': 'Verified Agent',
                      'title': '3-Bedroom Apartment',
                      'location': 'Lekki Phase 1, Lagos Nigeria',
                      'rating': '(5.0)',
                      'price': '#1,500,000',
                      'image': 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=400&h=200&fit=crop'
                    },
                    {
                      'badge': 'Verified Agent',
                      'title': '3-Bedroom Duplex',
                      'location': 'Lekki Phase 1, Lagos Nigeria',
                      'rating': '(5.0)',
                      'price': '#2,500,000',
                      'image': 'https://images.unsplash.com/photo-1560184897-ae75f418493e?w=400&h=200&fit=crop'
                    },
                    {
                      'badge': 'Verified Agent',
                      'title': '2-Bedroom Flat',
                      'location': 'Ikeja, Lagos Nigeria',
                      'rating': '(4.8)',
                      'price': '#1,200,000',
                      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400&h=200&fit=crop'
                    },
                  ];
                  final property = properties[index];
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
                      'badges': [property['badge']!],
                      'title': property['title']!,
                      'location': property['location']!,
                      'rating': property['rating']!,
                      'price': property['price']!,
                      'type': 'Apartment',
                      'category': 'Real Estate',
                      'description': 'Step into luxury with this fully furnished ${property['title']!.toLowerCase()} located in the heart of ${property['location']!}. With modern finishes, spacious rooms, a fitted kitchen, and round-the-clock security, it\'s perfect for professionals, small families, or remote workers seeking comfort and convenience.',
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
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  final List<Map<String, dynamic>> properties = [
                    {
                      'badges': ['For sale', 'Verified Agent'],
                      'title': 'Luxury 4-Bedroom Apartment',
                      'location': 'Victoria Island, Lagos Nigeria',
                      'rating': '(4.8)',
                      'price': '#3,500,000',
                      'type': 'Apartment',
                      'category': 'Real Estate',
                      'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'
                    },
                    {
                      'badges': ['Verified Agent'],
                      'title': 'Executive Hotel Suite',
                      'location': 'Ikoyi, Lagos Nigeria',
                      'rating': '(4.9)',
                      'price': '#120,000',
                      'type': 'Hotel',
                      'category': 'Hotels',
                      'period': 'per night',
                      'image': 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600&h=400&fit=crop&crop=center'
                    },
                    {
                      'badges': ['Verified Agent'],
                      'title': 'Modern 2-Bedroom Flat',
                      'location': 'Banana Island, Lagos Nigeria',
                      'rating': '(4.7)',
                      'price': '#1,800,000',
                      'type': 'Apartment',
                      'category': 'Real Estate',
                      'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=600&h=400&fit=crop&crop=center'
                    },
                  ];
                  final property = properties[index];
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
                child: _buildPropertyListItem(index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPropertyCard(int index) {
    final properties = <Map<String, String>>[
      {
        'badge': 'Verified Agent',
        'title': '3-Bedroom Apartment',
        'location': 'Lekki Phase 1, Lagos Nigeria',
        'rating': '(5.0)',
        'price': '#1,500,000',
        'image': 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=400&h=200&fit=crop'
      },
      {
        'badge': 'Verified Agent',
        'title': '3-Bedroom Duplex',
        'location': 'Lekki Phase 1, Lagos Nigeria',
        'rating': '(5.0)',
        'price': '#2,500,000',
        'image': 'https://images.unsplash.com/photo-1560184897-ae75f418493e?w=400&h=200&fit=crop'
      },
      {
        'badge': 'Verified Agent',
        'title': '2-Bedroom Flat',
        'location': 'Ikeja, Lagos Nigeria',
        'rating': '(4.8)',
        'price': '#1,200,000',
        'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400&h=200&fit=crop'
      },
    ][index];
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
            'badges': [properties['badge']!],
            'title': properties['title']!,
            'location': properties['location']!,
            'rating': properties['rating']!,
            'price': properties['price']!,
            'type': 'Apartment',
            'category': 'Real Estate',
            'description': 'Step into luxury with this fully furnished ${properties['title']!.toLowerCase()} located in the heart of ${properties['location']!}. With modern finishes, spacious rooms, a fitted kitchen, and round-the-clock security, it\'s perfect for professionals, small families, or remote workers seeking comfort and convenience.',
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
                image: NetworkImage(properties['image']!),
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
                          properties['title']!,
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
                                properties['location']!,
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
                              properties['rating']!,
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
                              properties['price']!,
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
                          Text(
                            properties['badge']!,
                            style: const TextStyle(
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
            Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF426DC2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.business,
                size: 14,
                color: isSelected ? const Color(0xFF426DC2) : Colors.white,
              ),
            ),
          if (title == 'Hotels')
            Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.hotel,
                size: 14,
                color: isSelected ? const Color(0xFFE91E63) : Colors.white,
              ),
            ),
          if (title == 'Shortlets')
            Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.apartment,
                size: 14,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
              ),
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
    final Map<String, dynamic> properties = [
      {
        'badges': ['For sale', 'Verified Agent'],
        'title': 'Luxury 4-Bedroom Apartment',
        'location': 'Victoria Island, Lagos Nigeria',
        'rating': '(4.8)',
        'price': '#3,500,000',
        'type': 'Apartment',
        'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badges': ['Verified Agent'],
        'title': 'Executive Hotel Suite',
        'location': 'Ikoyi, Lagos Nigeria',
        'rating': '(4.9)',
        'price': '#120,000',
        'type': 'Hotel',
        'period': 'per night',
        'image': 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badges': ['Verified Agent'],
        'title': 'Modern 2-Bedroom Flat',
        'location': 'Banana Island, Lagos Nigeria',
        'rating': '(4.7)',
        'price': '#1,800,000',
        'type': 'Apartment',
        'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=600&h=400&fit=crop&crop=center'
      },
    ][index];
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PropertyDetailsView(propertyData: {
            'badges': properties['badges'],
            'title': properties['title'],
            'location': properties['location'],
            'rating': properties['rating'],
            'price': properties['price'],
            'type': properties['type'],
            'category': properties['type'] == 'Hotel' ? 'Hotels' : 'Real Estate',
            'period': properties['period'],
            'description': properties['type'] == 'Hotel' 
                ? 'Step into luxury with this fully furnished hotel room located in the heart of ${properties['location']}. With modern finishes, spacious rooms, a fitted kitchen, and round-the-clock security, it\'s perfect for professionals, small families, or remote workers seeking comfort and convenience.'
                : 'Step into luxury with this fully furnished ${properties['type'].toLowerCase()} located in the heart of ${properties['location']}. With modern finishes, spacious rooms, a fitted kitchen, and round-the-clock security, it\'s perfect for professionals, small families, or remote workers seeking comfort and convenience.',
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
                    image: NetworkImage(properties['image'] as String),
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
                          children: (properties['badges'] as List<String>).map((badge) {
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
                            properties['title'] as String,
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
                            properties['type'] as String,
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
                       ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            properties['location'] as String,
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
                          properties['rating'] as String,
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
                              properties['price'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF426DC2),
                              ),
                            ),
                            if (properties.containsKey('period'))
                              Text(
                                properties['period'] as String,
                                style: const TextStyle(
                                  fontSize: 11,
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
} 