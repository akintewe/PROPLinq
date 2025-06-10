import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'saved_view.dart';
import 'profile_view.dart';
import 'settings_view.dart';

class TenantHomeView extends StatefulWidget {
  const TenantHomeView({super.key});

  @override
  State<TenantHomeView> createState() => _TenantHomeViewState();
}

class _TenantHomeViewState extends State<TenantHomeView> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
            child: SingleChildScrollView(
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
            ),
          ),
          // Saved Tab
          const SavedView(isAgent: false),
          // Profile Tab
          const ProfileView(isAgent: false),
          // Settings Tab
          const SettingsView(isAgent: false),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
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
                    ),
                    child: const Center(
                      child: Text(
                        'JD',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
                        'Home seeker',
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
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search properties or hotels',
                                      hintStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB0B5BB), // rgba(176, 181, 187, 1)
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA), // rgba(250, 250, 250, 1)
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
                    borderSide: BorderSide.none,
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
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
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
              return _buildFeaturedPropertyCard(index);
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
          Row(
            children: [
              _buildCategoryButton('All', true),
              const SizedBox(width: 12),
              _buildCategoryButton('Apartments', false),
              const SizedBox(width: 12),
              _buildCategoryButton('Hotels', false),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Property list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildPropertyListItem(index);
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
        'image': 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badge': 'Verified Agent',
        'title': '3-Bedroom Duplex',
        'location': 'Lekki Phase 1, Lagos Nigeria',
        'rating': '(5.0)',
        'price': '#2,500,000',
        'image': 'https://images.unsplash.com/photo-1560184897-ae75f418493e?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badge': 'Verified Agent',
        'title': '2-Bedroom Flat',
        'location': 'Ikeja, Lagos Nigeria',
        'rating': '(4.8)',
        'price': '#1,200,000',
        'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600&h=400&fit=crop&crop=center'
      },
    ][index];
    
    return SizedBox(
      width: 284,
      height: 176,
      child: Container(
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
            width: double.infinity,
            height: double.infinity,
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
                                fontWeight: FontWeight.w800,
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
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title == 'Apartments')
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
          if (title == 'Apartments' || title == 'Hotels') const SizedBox(width: 8),
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
        'title': '3-Bedroom Apartment',
        'location': 'Lekki Phase 1, Lagos Nigeria',
        'rating': '(5.0)',
        'price': '#2,500,000',
        'type': 'Apartment',
        'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badges': ['Verified Agent'],
        'title': 'Rome in Rollace Hotel',
        'location': 'Lekki Phase 1, Lagos Nigeria',
        'rating': '(5.0)',
        'price': '#90,000',
        'type': 'Hotel',
        'period': 'per night',
        'image': 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badges': ['Verified Agent'],
        'title': '3-Bedroom Apartment',
        'location': 'Lekki Phase 1, Lagos Nigeria',
        'rating': '(5.0)',
        'price': '#2,500,000',
        'type': 'Apartment',
        'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=600&h=400&fit=crop&crop=center'
      },
    ][index];
    
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
                                  ? const Color(0xFF2196F3) 
                                  : const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (badge == 'Verified Agent')
                                  const Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                if (badge == 'Verified Agent') const SizedBox(width: 4),
                                Text(
                                  badge,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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
                    'assets/icons/location.svg',
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