import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/bookings_cache_service.dart';
import '../../../core/constants/api_constants.dart';
import '../views/bookings_list_view.dart';

class BookingCarouselWidget extends StatefulWidget {
  const BookingCarouselWidget({super.key});

  @override
  State<BookingCarouselWidget> createState() => _BookingCarouselWidgetState();
}

class _BookingCarouselWidgetState extends State<BookingCarouselWidget> {
  final ApiService _apiService = ApiService();
  final BookingsCacheService _bookingsCacheService = BookingsCacheService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiConstants.bookings,
        requiresAuth: true,
        fromJson: (json) => json,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final data = response.data;
        List<dynamic> bookingsList = [];
        
        if (data is List) {
          bookingsList = data;
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final inner = data['data'];
            if (inner is List) {
              bookingsList = inner;
            } else if (inner is Map && inner['bookings'] is List) {
              bookingsList = inner['bookings'] as List<dynamic>;
            }
          } else if (data['bookings'] is List) {
            bookingsList = data['bookings'] as List<dynamic>;
          }
        }

        setState(() {
          _bookings = bookingsList
              .take(5) // Show max 5 recent bookings in carousel
              .map((item) {
                if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              })
              .where((item) => item.isNotEmpty)
              .toSet() // Remove any duplicates
              .toList();
          _isLoading = false;
        });
        
        // Update bookings cache with fresh data
        _bookingsCacheService.fetchAndCacheBookings(forceRefresh: true);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatPrice(String? price) {
    if (price == null || price.isEmpty) return 'N/A';
    
    try {
      final amount = double.tryParse(price);
      if (amount == null) return price;
      
      return '₦${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } catch (e) {
      return price;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'completed':
      case 'paid':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFFA726);
      case 'cancelled':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  int _calculateNights(String? checkIn, String? checkOut) {
    if (checkIn == null || checkOut == null) return 0;
    
    try {
      final checkInDate = DateTime.parse(checkIn);
      final checkOutDate = DateTime.parse(checkOut);
      return checkOutDate.difference(checkInDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _cancelBooking(int bookingId, String bookingCode) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel booking $bookingCode? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF426DC2),
        ),
      ),
    );

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.cancelBooking(bookingId),
        requiresAuth: true,
        fromJson: (json) => json,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        // Refresh bookings list
        _loadBookings();
        // Refresh cache
        _bookingsCacheService.fetchAndCacheBookings(forceRefresh: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to cancel booking'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling booking: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          color: Color(0xFF426DC2),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No Bookings Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your bookings will appear here',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _bookings.length,
          itemBuilder: (context, index, realIndex) {
            final booking = _bookings[index];
            final rawProperty = booking['property'];
            final property = rawProperty is Map ? Map<String, dynamic>.from(rawProperty) : <String, dynamic>{};

            String propertyImage = 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center';
            if (property['images'] is List) {
              final images = property['images'] as List;
              if (images.isNotEmpty && images[0] is Map) {
                final firstImage = Map<String, dynamic>.from(images[0] as Map);
                propertyImage = firstImage['full_url']?.toString() ??
                               firstImage['url']?.toString() ??
                               propertyImage;
              }
            }

            final nights = _calculateNights(
              booking['check_in'] as String?,
              booking['check_out'] as String?,
            );

            return Container(
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Navigate to full bookings list
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BookingsListView(),
                        ),
                      );
                    },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with gradient overlay
                      Stack(
                        children: [
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              image: DecorationImage(
                                image: NetworkImage(propertyImage),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Status badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  booking['status'] as String?,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (booking['status'] as String? ?? 'Pending')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Booking details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Property title
                                Text(
                                  property['title'] ?? 'Property',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                const SizedBox(height: 6),
                                
                                // Dates
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: Color(0xFF666666),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${_formatDate(booking['check_in'] as String?)} - ${_formatDate(booking['check_out'] as String?)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF666666),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 4),
                                
                                // Number of nights
                                if (nights > 0)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.nightlight_round,
                                        size: 12,
                                        color: Color(0xFF666666),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$nights ${nights == 1 ? 'night' : 'nights'}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                    ],
                                  ),
                                
                                const SizedBox(height: 12),
                                
                                // Divider
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Colors.grey[200],
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF666666),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatPrice(booking['amount']?.toString()),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF426DC2),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Cancel Booking Button
                                if (booking['status']?.toString().toLowerCase() != 'cancelled')
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        final bookingId = booking['id'];
                                        final bookingCode = booking['booking_code'] ?? 'N/A';
                                        if (bookingId != null) {
                                          _cancelBooking(
                                            bookingId is int ? bookingId : int.tryParse(bookingId.toString()) ?? 0,
                                            bookingCode.toString(),
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        side: const BorderSide(color: Colors.red, width: 1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
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
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 340,
            viewportFraction: _bookings.length == 1 ? 1.0 : 0.65,
            enlargeCenterPage: _bookings.length > 1,
            enlargeFactor: _bookings.length > 1 ? 0.15 : 0.0,
            enableInfiniteScroll: _bookings.length > 1,
            autoPlay: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Dots indicator
        if (_bookings.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bookings.length,
              (index) => Container(
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentIndex == index
                      ? const Color(0xFF426DC2)
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
