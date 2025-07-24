import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:proplinq/core/widgets/google_map_widget.dart';
import 'package:proplinq/features/finance/views/rent_now_pay_later_view.dart';
import 'virtual_tour_360_view.dart';
import 'hotel_reservation_view.dart';

class PropertyDetailsView extends StatefulWidget {
  final Map<String, dynamic>? propertyData;
  
  const PropertyDetailsView({super.key, this.propertyData});

  @override
  State<PropertyDetailsView> createState() => _PropertyDetailsViewState();
}

class _PropertyDetailsViewState extends State<PropertyDetailsView> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  
  final List<String> _propertyImages = [
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center',
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600&h=400&fit=crop&crop=center',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600&h=400&fit=crop&crop=center',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=600&h=400&fit=crop&crop=center',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getDefaultProperty() {
    return {
      'badges': ['Verified Agent'],
      'title': '3-Bedroom Apartment',
      'location': 'Lekki Phase 1, Lagos Nigeria',
      'rating': '(5.0)',
      'price': '#2,500,000',
      'type': 'Apartment',
      'description': 'Step into luxury with this fully furnished 3-bedroom apartment located in the heart of Lekki Phase 1. With modern finishes, spacious rooms, a fitted kitchen, and round-the-clock security, it\'s perfect for professionals, small families, or remote workers seeking comfort and convenience.',
      'agent': {
        'name': 'James Mark',
        'title': 'Agent',
        'phone': '09011111111',
        'email': 'jamesmark@gmail.com',
        'whatsapp': '08111111111',
      },
      'features': ['3-bedroom', '3 Bathrooms', 'Dedicated Parking', 'Gated & Secured Estate'],
    };
  }

  @override
  Widget build(BuildContext context) {
    // Get property data or use defaults
    final property = widget.propertyData ?? _getDefaultProperty();
    final propertyType = property['type'] as String? ?? 'Apartment';
    final normalizedType = propertyType.toLowerCase();
    final isHotel = normalizedType == 'hotel';
    final isShortlet = normalizedType == 'shortlet';
    
    // Debug logging
    print('🏠 Property Details Debug:');
    print('Property Type: $propertyType');
    print('Normalized Type: $normalizedType');
    print('Is Hotel: $isHotel');
    print('Is Shortlet: $isShortlet');
    print('Property Data: ${property.toString()}');
    
    // Determine category based on property type
    String category;
    if (isHotel) {
      category = 'Hotels';
    } else if (isShortlet) {
      category = 'Shortlets';
    } else {
      category = 'Real Estate';
    }
    
    final isForSale = (property['badges'] as List<String>?)?.contains('For sale') ?? false;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Image carousel section
                SizedBox(
                  height: 400,
                  child: Stack(
                    children: [
                      // Image PageView
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemCount: _propertyImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: double.infinity,
                            height: 400,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(_propertyImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Top overlay buttons
                      Positioned(
                        top: 60,
                        left: 24,
                        right: 24,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Color(0xFF426DC2),
                                  size: 20,
                                ),
                              ),
                            ),
                            
                            // Share and favorite buttons
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.share,
                                    color: Color(0xFF426DC2),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_border,
                                    color: Color(0xFF426DC2),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Image dots indicator
                      Positioned(
                        bottom: 60,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _propertyImages.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.2),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Curved white container with property details
                Transform.translate(
                  offset: const Offset(0, -30), // Overlap the image
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property type badge (Hotel/Apartment) at top corner
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECF0F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  propertyType,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF426DC2),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Only show "Verified Agent" badge for non-hotel properties
                              if (!isHotel) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECF0F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 14,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified Agent',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF426DC2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Property title and rating
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  property['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  Text(
                                    property['rating'] as String,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.star,
                                    size: 18,
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Location
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Color(0xFF868686),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                property['location'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF868686),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Verified tag under location
                          Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Description
                          Text(
                            property['description'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Color(0xFF666666),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Agent Details - only show for non-hotel properties
                          if (!isHotel) ...[
                            const Text(
                              'Agent Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Agent info
                            Row(
                              children: [
                                // Agent avatar
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: const DecorationImage(
                                      image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Agent name and title
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        property['agent']['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        property['agent']['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF868686),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Verified badge positioned to the right
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E8), // Light green background
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                          Icons.verified,
                                          size: 15,
                                          color: Colors.green,
                                        ),
                                      
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2E7D32), // Dark green text
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Contact info
                            Column(
                              children: [
                                _buildContactRow('assets/icons/fluent_call-24-filled.svg', property['agent']['phone'] as String),
                                const SizedBox(height: 16),
                                _buildContactRow('assets/icons/majesticons_mail.svg', property['agent']['email'] as String),
                                const SizedBox(height: 16),
                                _buildContactRow('assets/icons/logos_whatsapp-icon.svg', property['agent']['whatsapp'] as String),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          // Action buttons for non-hotel properties
                          if (!isHotel) ...[
                            if (isShortlet) ...[
                              // Shortlet buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          stops: [0.0, 1.0, 1.0],
                                          colors: [
                                            Color(0xFF426DC2),
                                            Color(0xFF63ADDC),
                                            Color(0xFF75CFEA),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                        child: const Text(
                                          'Book shortlet',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF426DC2)),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const RentNowPayLaterView(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text(
                                    'Rent now-pay later',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF426DC2),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Apartment buttons (for rent or sale)
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          stops: [0.0, 1.0, 1.0],
                                          colors: [
                                            Color(0xFF426DC2),
                                            Color(0xFF63ADDC),
                                            Color(0xFF75CFEA),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const RentNowPayLaterView(),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                        child: const Text(
                                          'Rent now-pay later',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF426DC2)),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text(
                                    'Mark as rented',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF426DC2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                          
                          const SizedBox(height: 40),
                          
                          // What you'll get
                          const Text(
                            'What you\'ll get',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Features list
                          Column(
                            children: _buildFeaturesList(property, isHotel),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Hotel action button - only show for hotels
                          if (isHotel) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        stops: [0.0, 1.0, 1.0],
                                        colors: [
                                          Color(0xFF426DC2),
                                          Color(0xFF63ADDC),
                                          Color(0xFF75CFEA),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => HotelReservationView(
                                              propertyData: property,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                      child: const Text(
                                        'Make a reservation',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 40),
                          ],
                          
                          // Virtual Tour - only show for non-hotel properties
                          if (!isHotel) ...[
                          const Text(
                            'Virtual Tour',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Virtual tour image with play button
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VirtualTour360View(
                                    imageUrl: 'assets/images/shot-panoramic-composition-living-room.jpg',
                                    title: 'Virtual Tour - ${property['title'] as String? ?? 'Property'}',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/3af693f3bf0406d67cddf98a62526eba4c273542.jpg'), // High-resolution 360° apartment image
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Overlay gradient for better visibility
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Center play button
                                  Center(
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.threed_rotation,
                                        size: 32,
                                        color: Color(0xFF426DC2),
                                      ),
                                    ),
                                  ),
                                  
                                  // 360° label
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF426DC2).withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.threesixty,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '360°',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Bottom label
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Tap to start virtual tour',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          ],
                          
                          // Google Map
                          const Text(
                            'Google Map',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Google Maps Widget
                          Builder(
                            builder: (context) {
                              try {
                                return GoogleMapWidget(
                                  latitude: _getPropertyCoordinates(property)['latitude'],
                                  longitude: _getPropertyCoordinates(property)['longitude'],
                                  propertyTitle: property['title'] as String?,
                                  height: 200,
                                  showMarker: true,
                                );
                              } catch (e) {
                                print('Error loading Google Maps: $e');
                                // Fallback to placeholder if map fails
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: const Color(0xFFE8F4FD),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.map,
                                          size: 40,
                                          color: Color(0xFF426DC2),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Map Preview',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF426DC2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          
                          const SizedBox(height: 100), // Space for bottom bar
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isHotel ? 'Total Price' : _getPriceLabel(propertyType, isForSale),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF868686),
                        ),
                      ),
                      Text(
                        _formatPrice(property['price'] as String),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF426DC2),
                        ),
                      ),
                      if (isHotel)
                        const Text(
                          'per night',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF868686),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment(-1.0, 0.0),
                          end: Alignment(1.0, 0.0),
                          stops: [0.0113, 0.4555, 1.1245],
                          colors: [
                            Color(0xFF426DC2),
                            Color(0xFF75CFEA),
                            Color.fromRGBO(51, 204, 153, 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          _getBottomButtonText(propertyType, isForSale),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _buildContactRow(String icon, String text) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            color: AppColors.primary100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SizedBox(
            width: 12,
            height: 12,
            child: Transform.scale(
              scale: 0.8,
              child: SvgPicture.asset(
                icon,
                width: 12,
                height: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        SvgPicture.asset(
          'assets/icons/si_copy-line.svg',
          width: 16,
          height: 16,
        ),
      ],
    );
  }

    List<Widget> _buildFeaturesList(Map<String, dynamic> property, bool isHotel) {
    final propertyType = property['type'] as String? ?? 'Apartment';
    final type = propertyType.toLowerCase();
    
    // Get features from API data
    final List<dynamic> apiFeatures = property['features'] as List<dynamic>? ?? [];
    print('🏠 Features from API: $apiFeatures');
    print('🏠 Property data keys: ${property.keys.toList()}');
    print('🏠 Features type: ${property['features']?.runtimeType}');
    
    if (isHotel || type == 'hotel') {
      // Hotel features - use API data if available, otherwise fallback to defaults
      if (apiFeatures.isNotEmpty) {
        // Use features from API
        List<Widget> featureWidgets = [];
        for (int i = 0; i < apiFeatures.length; i++) {
          featureWidgets.add(_buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', apiFeatures[i].toString()));
          if (i < apiFeatures.length - 1) {
            featureWidgets.add(const SizedBox(height: 16));
          }
        }
        return featureWidgets;
      } else {
        // Fallback to default hotel features
        return [
          _buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', 'Queen-size Bed'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mdi_bathroom.svg', 'En-suite Bathroom'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/fluent_food-16-regular.svg', 'Complimentary Breakfast'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/material-symbols_wifi-rounded.svg', 'Free High-Speed Wi-Fi'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mage_television.svg', 'Smart TV with Streaming'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/uil_padlock.svg', '24/7 Security & Keycard Access'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/healthicons_cleaning-outline.svg', 'Daily Housekeeping'),
        ];
      }
    } else if (type == 'shortlet') {
      // Shortlet features - use API data if available, otherwise fallback to defaults
      if (apiFeatures.isNotEmpty) {
        List<Widget> featureWidgets = [];
        for (int i = 0; i < apiFeatures.length; i++) {
          featureWidgets.add(_buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', apiFeatures[i].toString()));
          if (i < apiFeatures.length - 1) {
            featureWidgets.add(const SizedBox(height: 16));
          }
        }
        return featureWidgets;
      } else {
        // Fallback to default shortlet features
        return [
          _buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', '3-bedroom'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mdi_bathroom.svg', '3 Bathrooms'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/tabler_car.svg', 'Dedicated Parking'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/game-icons_gate.svg', 'Gated & Secured Estate'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mdi_wifi.svg', 'Free Wi-Fi'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mdi_television.svg', 'Smart TV'),
        ];
      }
    } else {
      // Real Estate (Apartment for sale) features - use API data if available, otherwise fallback to defaults
      if (apiFeatures.isNotEmpty) {
        List<Widget> featureWidgets = [];
        for (int i = 0; i < apiFeatures.length; i++) {
          featureWidgets.add(_buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', apiFeatures[i].toString()));
          if (i < apiFeatures.length - 1) {
            featureWidgets.add(const SizedBox(height: 16));
          }
        }
        return featureWidgets;
      } else {
        // Fallback to default apartment features
        return [
          _buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', '3-bedroom'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mdi_bathroom.svg', '3 Bathrooms'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/tabler_car.svg', 'Dedicated Parking'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/game-icons_gate.svg', 'Gated & Secured Estate'),
        ];
      }
    }
  }

  Widget _buildFeatureRow(String icon, String label) {
    return Row(
      children: [
        SvgPicture.asset(
        icon,
         width: 20,
         height: 20,

        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  String _getPriceLabel(String propertyType, bool isForSale) {
    final type = propertyType.toLowerCase();
    if (type == 'hotel') {
      return 'Total Price';
    } else if (type == 'shortlet') {
      return 'Total Price';
    } else if (isForSale) {
      return 'Selling Price';
    } else {
      return 'Total Price';
    }
  }

  String _formatPrice(String price) {
    try {
      // Remove any existing currency symbols and commas
      String cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
      double priceValue = double.parse(cleanPrice);
      
      // Format in Naira with comma separators
      if (priceValue >= 1000000) {
        return '₦${(priceValue / 1000000).toStringAsFixed(1)}M';
      } else if (priceValue >= 1000) {
        return '₦${priceValue.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},'
        )}';
      } else {
        return '₦${priceValue.toStringAsFixed(0)}';
      }
    } catch (e) {
      // Fallback to original price if parsing fails
      return '₦$price';
    }
  }

  String _getBottomButtonText(String propertyType, bool isForSale) {
    final type = propertyType.toLowerCase();
    if (type == 'hotel') {
      return 'Book Now';
    } else if (type == 'shortlet') {
      return 'Book Now';
    } else if (isForSale) {
      return 'Contact agent';
    } else {
      return 'Contact agent';
    }
  }

  Map<String, double> _getPropertyCoordinates(Map<String, dynamic> property) {
    // Try to get coordinates from property data
    final coordinates = property['coordinates'] as Map<String, dynamic>?;
    if (coordinates != null) {
      return {
        'latitude': (coordinates['latitude'] as num?)?.toDouble() ?? 6.5244,
        'longitude': (coordinates['longitude'] as num?)?.toDouble() ?? 3.3792,
      };
    }

    // Try to get coordinates from location string (fallback)
    final location = property['location'] as String?;
    if (location != null) {
      // Parse location string to extract coordinates if available
      // For now, return default Lagos coordinates
      return {
        'latitude': 6.5244,
        'longitude': 3.3792,
      };
    }

    // Default coordinates (Lagos, Nigeria)
    return {
      'latitude': 6.5244,
      'longitude': 3.3792,
    };
  }
} 