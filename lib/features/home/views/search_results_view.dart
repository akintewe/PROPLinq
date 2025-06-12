import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchResultsView extends StatefulWidget {
  final String selectedLocation;
  final String? searchQuery;

  const SearchResultsView({
    super.key,
    required this.selectedLocation,
    this.searchQuery,
  });

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Real Estate', 'Hotels', 'Shortlets'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
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
                    widget.selectedLocation,
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
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFECF0F9),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.tune,
              color: Color(0xFF426DC2),
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories section
          Padding(
            padding: const EdgeInsets.all(24.0),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildCategoryButton(category, isSelected),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Search results
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _getFilteredProperties().length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final property = _getFilteredProperties()[index];
                return _buildPropertyCard(property);
              },
            ),
          ),
        ],
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

  Widget _buildPropertyCard(Map<String, dynamic> property) {
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
                        'assets/icons/location.svg',
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

  List<Map<String, dynamic>> _getFilteredProperties() {
    // Sample properties for the selected location
    final allProperties = [
      {
        'badges': ['For sale', 'Verified Agent'],
        'title': '3-Bedroom Apartment in ${widget.selectedLocation}',
        'location': widget.selectedLocation,
        'rating': '(5.0)',
        'price': '#2,500,000',
        'type': 'Apartment',
        'category': 'Real Estate',
        'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badges': ['Verified Agent'],
        'title': 'Luxury Hotel in ${widget.selectedLocation}',
        'location': widget.selectedLocation,
        'rating': '(4.8)',
        'price': '#85,000',
        'type': 'Hotel',
        'category': 'Hotels',
        'period': 'per night',
        'image': 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badges': ['Verified Agent'],
        'title': 'Modern Shortlet in ${widget.selectedLocation}',
        'location': widget.selectedLocation,
        'rating': '(4.9)',
        'price': '#45,000',
        'type': 'Shortlet',
        'category': 'Shortlets',
        'period': 'per night',
        'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=600&h=400&fit=crop&crop=center'
      },
      {
        'badges': ['For sale', 'Verified Agent'],
        'title': '4-Bedroom Duplex in ${widget.selectedLocation}',
        'location': widget.selectedLocation,
        'rating': '(4.7)',
        'price': '#4,200,000',
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
} 