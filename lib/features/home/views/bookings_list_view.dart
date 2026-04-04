import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/bookings_cache_service.dart';
import '../../../core/constants/api_constants.dart';
import 'booking_details_view.dart';

class BookingsListView extends StatefulWidget {
  const BookingsListView({super.key});

  @override
  State<BookingsListView> createState() => _BookingsListViewState();
}

class _BookingsListViewState extends State<BookingsListView> {
  final ApiService _apiService = ApiService();
  final BookingsCacheService _bookingsCacheService = BookingsCacheService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // GET /bookings endpoint - returns list of bookings
      print('📋 [BookingsListView] Fetching bookings...');
      final response = await _apiService.get<dynamic>(
        ApiConstants.bookings,
        requiresAuth: true,
        fromJson: (json) => json,
      );

      if (!mounted) return;

      print('📋 [BookingsListView] Response success: ${response.success}');
      print('📋 [BookingsListView] Response statusCode: ${response.statusCode}');
      print('📋 [BookingsListView] Response message: ${response.message}');
      print('📋 [BookingsListView] Response data type: ${response.data?.runtimeType}');
      
      if (response.data != null) {
        print('📋 [BookingsListView] Response data: ${response.data}');
      }

      if (response.success && response.data != null) {
        final data = response.data;
        List<dynamic> bookingsList = [];
        
        // Handle different response structures
        if (data is List) {
          // If data is directly a list
          print('📋 [BookingsListView] Data is a List with ${data.length} items');
          bookingsList = data;
        } else if (data is Map<String, dynamic>) {
          print('📋 [BookingsListView] Data is a Map with keys: ${data.keys.toList()}');
          
          // If data is a map, check various nested structures
          if (data.containsKey('data')) {
            print('📋 [BookingsListView] Found "data" key, type: ${data['data'].runtimeType}');
            final inner = data['data'];
            if (inner is List) {
              bookingsList = inner;
              print('📋 [BookingsListView] Extracted ${bookingsList.length} bookings from data.data (List)');
            } else if (inner is Map && inner['bookings'] is List) {
              bookingsList = inner['bookings'] as List<dynamic>;
              print('📋 [BookingsListView] Extracted ${bookingsList.length} bookings from data.data.bookings');
            }
          } else if (data['bookings'] is List) {
            bookingsList = data['bookings'] as List<dynamic>;
            print('📋 [BookingsListView] Extracted ${bookingsList.length} bookings from data.bookings');
          } else {
            print('📋 [BookingsListView] Data keys: ${data.keys.toList()}');
            for (var key in data.keys) {
              if (data[key] is List) {
                bookingsList = data[key] as List<dynamic>;
                print('📋 [BookingsListView] Found list in key "$key" with ${bookingsList.length} items');
                break;
              }
            }
          }
        }

        if (bookingsList.isNotEmpty) {
          print('📋 [BookingsListView] First booking structure: ${bookingsList[0]}');
        }

        setState(() {
          _bookings = bookingsList
              .map((item) {
                if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              })
              .where((item) => item.isNotEmpty)
              .toList();
          _isLoading = false;
        });
        
        print('✅ [BookingsListView] Successfully loaded ${_bookings.length} bookings');
        
        // Update bookings cache with fresh data
        _bookingsCacheService.fetchAndCacheBookings(forceRefresh: true);
        print('🔄 [BookingsListView] Bookings cache refreshed');
      } else {
        print('❌ [BookingsListView] Failed to load bookings: ${response.message}');
        setState(() {
          _errorMessage = response.message ?? 'Failed to load bookings';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      print('❌ [BookingsListView] Error loading bookings: $e');
      print('❌ [BookingsListView] Stack trace: $stackTrace');
      
      setState(() {
        _errorMessage = 'Error loading bookings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
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
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _calculateNights(String? checkIn, String? checkOut) {
    if (checkIn == null || checkOut == null) return '0 nights';
    
    try {
      final checkInDate = DateTime.parse(checkIn);
      final checkOutDate = DateTime.parse(checkOut);
      final nights = checkOutDate.difference(checkInDate).inDays;
      return '$nights ${nights == 1 ? 'night' : 'nights'}';
    } catch (e) {
      return '0 nights';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        color: const Color(0xFF426DC2),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF426DC2),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadBookings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF426DC2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : _bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Bookings',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You haven\'t made any bookings yet.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          final property = booking['property'] as Map<String, dynamic>? ?? {};
                          
                          // Extract property image
                          String propertyImage = 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center';
                          if (property['images'] != null && property['images'] is List) {
                            final images = property['images'] as List;
                            if (images.isNotEmpty && images[0] is Map) {
                              final firstImage = images[0] as Map<String, dynamic>;
                              propertyImage = firstImage['full_url'] ?? 
                                             firstImage['url'] ?? 
                                             propertyImage;
                            }
                          }
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
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
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Navigate to booking details
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => BookingDetailsView(
                                        bookingData: booking,
                                        propertyData: property,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Property image with status badge
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                          child: Container(
                                            height: 180,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: NetworkImage(propertyImage),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Status badge overlay
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                booking['status'] as String?,
                                              ).withOpacity(0.95),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              (booking['status'] as String? ?? 'Pending')
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Payment status badge
                                        if (booking['payment_status'] != null)
                                          Positioned(
                                            top: 12,
                                            left: 12,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    booking['payment_status'] == 'paid' || 
                                                    booking['payment_status'] == 'completed'
                                                        ? Icons.check_circle
                                                        : Icons.pending,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    (booking['payment_status'] as String?)
                                                        ?.toUpperCase() ?? 'PENDING',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    
                                    // Property details
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Property title
                                          Text(
                                            property['title'] ?? 'Property',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          
                                          const SizedBox(height: 8),
                                          
                                          // Location
                                          if (property['location'] != null)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    property['location'],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Divider
                                          Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: Colors.grey[200],
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Client name (if available)
                                          if (booking['user'] != null)
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8F9FA),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_outline,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Client: ${(booking['user'] as Map)['full_name'] ?? (booking['user'] as Map)['name'] ?? 'Guest'}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          
                                          if (booking['user'] != null)
                                            const SizedBox(height: 12),
                                          
                                          // Dates row
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildDateCard(
                                                  icon: Icons.login,
                                                  label: 'Check-in',
                                                  date: _formatDate(
                                                    booking['check_in'] as String?,
                                                  ),
                                                  dateTime: booking['check_in'] as String?,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildDateCard(
                                                  icon: Icons.logout,
                                                  label: 'Check-out',
                                                  date: _formatDate(
                                                    booking['check_out'] as String?,
                                                  ),
                                                  dateTime: booking['check_out'] as String?,
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 12),
                                          
                                          // Number of nights
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE3F2FD),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.nightlight_round,
                                                  size: 16,
                                                  color: Color(0xFF426DC2),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _calculateNights(
                                                    booking['check_in'] as String?,
                                                    booking['check_out'] as String?,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF426DC2),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Booking code and total revenue
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF426DC2).withOpacity(0.1),
                                                  const Color(0xFF426DC2).withOpacity(0.05),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFF426DC2).withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                if (booking['booking_code'] != null)
                                                  Expanded(
                                                    child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Booking Code',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                      Text(
                                                        booking['booking_code'],
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.black,
                                                            letterSpacing: 1.0,
                                                        ),
                                                      ),
                                                  ],
                                                    ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.account_balance_wallet,
                                                          size: 14,
                                                          color: Colors.grey[600],
                                                        ),
                                                        const SizedBox(width: 4),
                                                    Text(
                                                          'Total Revenue',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _formatPrice(booking['amount']?.toString()),
                                                      style: const TextStyle(
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF426DC2),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Cancel Booking Button
                                          if (booking['status'] != null && 
                                              (booking['status'] as String).toLowerCase() != 'cancelled')
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
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                                label: const Text(
                                                  'Cancel Booking',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  side: const BorderSide(color: Colors.red, width: 1.5),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildDateCard({
    required IconData icon,
    required String label,
    required String date,
    String? dateTime,
  }) {
    String dayName = '';
    if (dateTime != null && dateTime.isNotEmpty) {
      try {
        final dt = DateTime.parse(dateTime);
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        dayName = weekdays[dt.weekday - 1];
      } catch (e) {
        // Ignore parse errors
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF426DC2)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (dayName.isNotEmpty) ...[
            Text(
              dayName,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            date,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

