import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookingDetailsView extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final Map<String, dynamic> propertyData;

  const BookingDetailsView({
    super.key,
    required this.bookingData,
    required this.propertyData,
  });

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                     'July', 'August', 'September', 'October', 'November', 'December'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
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

  @override
  Widget build(BuildContext context) {
    final propertyImage = _getPropertyImage();
    final nights = _calculateNights(
      bookingData['check_in'] as String?,
      bookingData['check_out'] as String?,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF426DC2),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: 
                    propertyImage,
                    fit: BoxFit.cover,
                  ),
                  Container(
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
                  ),
                  // Status badge
                  Positioned(
                    top: 60,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(bookingData['status'] as String?),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        (bookingData['status'] as String? ?? 'Pending').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property title
                  Text(
                    propertyData['title'] ?? 'Property',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  if (propertyData['location'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            propertyData['location'],
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Check-in Code Section — show checkin_code (used by agent to verify)
                  if (bookingData['checkin_code'] != null || bookingData['booking_code'] != null)
                    (() {
                      final checkinCode = (bookingData['checkin_code']?.toString()
                          ?? bookingData['booking_code']?.toString())!;
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF426DC2),
                              const Color(0xFF426DC2).withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF426DC2).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Check-in Code',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  checkinCode,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: checkinCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Check-in code copied!'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    })(),
                  
                  const SizedBox(height: 32),
                  
                  // Client Info (if available)
                  if (bookingData['user'] != null)
                    _buildInfoSection(
                      icon: Icons.person_outline,
                      title: 'Client Information',
                      content: (bookingData['user'] as Map)['full_name'] ?? 
                              (bookingData['user'] as Map)['name'] ?? 
                              'Guest',
                    ),
                  
                  if (bookingData['user'] != null)
                    const SizedBox(height: 24),

                  // Room Details
                  if (bookingData['room'] != null || bookingData['room_name'] != null) ...[
                    const Text('Room Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Column(
                        children: [
                          if (bookingData['room_name'] != null)
                            _buildDetailRow('Room Name', bookingData['room_name'].toString()),
                          if (bookingData['room_type'] != null) ...[
                            const SizedBox(height: 10),
                            _buildDetailRow('Room Type', bookingData['room_type'].toString()),
                          ],
                          if (bookingData['room'] is Map) ...() {
                            final room = bookingData['room'] as Map;
                            return [
                              if (room['room_number'] != null) ...[
                                const SizedBox(height: 10),
                                _buildDetailRow('Room Number', room['room_number'].toString()),
                              ],
                              if (room['bed_type'] != null) ...[
                                const SizedBox(height: 10),
                                _buildDetailRow('Bed Type', room['bed_type'].toString()),
                              ],
                              if (room['floor'] != null) ...[
                                const SizedBox(height: 10),
                                _buildDetailRow('Floor', room['floor'].toString()),
                              ],
                              if (room['capacity'] != null) ...[
                                const SizedBox(height: 10),
                                _buildDetailRow('Capacity', '${room['capacity']} guest${room['capacity'].toString() == "1" ? "" : "s"}'),
                              ],
                            ];
                          }(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Dates Section
                  const Text(
                    'Stay Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateCard(
                          icon: Icons.login,
                          label: 'Check-in',
                          date: _formatDate(bookingData['check_in'] as String?),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateCard(
                          icon: Icons.logout,
                          label: 'Check-out',
                          date: _formatDate(bookingData['check_out'] as String?),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Number of nights
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.nightlight_round,
                          size: 24,
                          color: Color(0xFF426DC2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$nights ${nights == 1 ? 'Night' : 'Nights'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF426DC2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Payment Section
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatPrice(bookingData['amount']?.toString()),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF426DC2),
                              ),
                            ),
                          ],
                        ),
                        if (bookingData['platform_fee'] != null) ...[
                          const SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          _buildDetailRow('Service Fee', _formatPrice(bookingData['platform_fee']?.toString())),
                        ],
                        if (bookingData['vat_on_fee'] != null) ...[
                          const SizedBox(height: 10),
                          _buildDetailRow('VAT', _formatPrice(bookingData['vat_on_fee']?.toString())),
                        ],
                        if (bookingData['guest_total'] != null) ...[
                          const SizedBox(height: 10),
                          _buildDetailRow('Total (incl. fees)', _formatPrice(bookingData['guest_total']?.toString())),
                        ],
                        if (bookingData['payment_type'] != null) ...[
                          const SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          _buildDetailRow('Payment Type',
                            bookingData['payment_type'].toString() == 'pay_on_arrival' ? 'Pay on Arrival' : 'Full Payment'),
                        ],
                        if (bookingData['payment_status'] != null) ...[
                          const SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment Status', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(bookingData['payment_status'] as String?),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (bookingData['payment_status'] as String? ?? 'Pending').toUpperCase(),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black), textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF426DC2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required IconData icon,
    required String label,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(icon, size: 16, color: const Color(0xFF426DC2)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  String _getPropertyImage() {
    if (propertyData['images'] != null && propertyData['images'] is List) {
      final images = propertyData['images'] as List;
      if (images.isNotEmpty && images[0] is Map) {
        final firstImage = images[0] as Map<String, dynamic>;
        return firstImage['full_url'] ?? 
               firstImage['url'] ?? 
               'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center';
      }
    }
    return 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center';
  }
}
