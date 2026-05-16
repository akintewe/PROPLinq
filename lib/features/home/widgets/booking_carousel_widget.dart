import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/bookings_cache_service.dart';
import '../../../core/services/storage_service.dart';
import '../views/bookings_list_view.dart';
import '../views/booking_details_view.dart';

class BookingCarouselWidget extends StatefulWidget {
  const BookingCarouselWidget({super.key});

  @override
  State<BookingCarouselWidget> createState() => _BookingCarouselWidgetState();
}

class _BookingCarouselWidgetState extends State<BookingCarouselWidget> {
  final BookingsCacheService _bookingsCacheService = BookingsCacheService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final token = await StorageService().getToken();
      final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.bookings}');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonBody = json.decode(response.body);
        List<dynamic> list = [];

        if (jsonBody['data'] is List) {
          list = jsonBody['data'] as List;
        } else if (jsonBody['data'] is Map && jsonBody['data']['data'] is List) {
          list = jsonBody['data']['data'] as List;
        } else if (jsonBody is List) {
          list = jsonBody as List;
        }

        final all = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        setState(() {
          _bookings = all
              .where((b) => b['status']?.toString().toLowerCase() != 'cancelled')
              .take(5)
              .toList();
          _isLoading = false;
        });

        _bookingsCacheService.fetchAndCacheBookings(forceRefresh: true);
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(String bookingUuid, String bookingCode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to cancel booking $bookingCode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No', style: TextStyle(color: Color(0xFF868686))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF426DC2))),
    );

    try {
      final token = await StorageService().getToken();
      final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.cancelBooking(bookingUuid)}');
      final response = await http.post(url, headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (!mounted) return;
      Navigator.of(context).pop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully'), backgroundColor: Colors.green),
        );
        setState(() => _bookings = []);
        _loadBookings();
        _bookingsCacheService.fetchAndCacheBookings(forceRefresh: true);
      } else {
        final jsonBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonBody['message']?.toString() ?? 'Failed to cancel booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(raw);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _formatPrice(dynamic value) {
    if (value == null) return 'N/A';
    final amount = value is num ? value.toDouble() : double.tryParse(value.toString());
    if (amount == null) return value.toString();
    return '₦${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  int _calculateNights(String? checkIn, String? checkOut) {
    if (checkIn == null || checkOut == null) return 0;
    try {
      return DateTime.parse(checkOut).difference(DateTime.parse(checkIn)).inDays;
    } catch (_) {
      return 0;
    }
  }

  String _extractImage(Map<String, dynamic> property) {
    const fallback = 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center';
    final images = property['images'];
    if (images is List && images.isNotEmpty) {
      final first = images[0];
      if (first is Map) {
        return first['full_url']?.toString() ?? first['url']?.toString() ?? fallback;
      }
    }
    return property['image']?.toString() ?? property['thumbnail']?.toString() ?? fallback;
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return const Color(0xFF008D5A);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF868686);
    }
  }

  Color _statusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return const Color(0xFFCCFBEA);
      case 'pending':
        return const Color(0xFFFFF3CD);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF426DC2), strokeWidth: 2)),
      );
    }

    if (_bookings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: Color(0xFFDDDDDD)),
            SizedBox(height: 12),
            Text('No pending bookings', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
            SizedBox(height: 4),
            Text('Your upcoming bookings will appear here', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF868686))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_bookings.length, (index) {
          final isLast = index == _bookings.length - 1;
          return Column(
            children: [
              _buildBookingRow(_bookings[index]),
              if (!isLast) ...[
                const SizedBox(height: 8),
                Divider(height: 1, thickness: 1, color: Colors.grey[100]),
                const SizedBox(height: 8),
              ],
            ],
          );
        }),
        if (_bookings.length >= 5) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BookingsListView()),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('View all bookings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF426DC2))),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: Color(0xFF426DC2)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBookingRow(Map<String, dynamic> booking) {
    final property = booking['property'] is Map
        ? Map<String, dynamic>.from(booking['property'] as Map)
        : <String, dynamic>{};
    final status = booking['status']?.toString();
    final nights = _calculateNights(booking['check_in']?.toString(), booking['check_out']?.toString());
    final imageUrl = _extractImage(property);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingDetailsView(bookingData: booking, propertyData: property),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(imageUrl: 
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFEFF0F2),
                  child: const Icon(Icons.image_outlined, size: 28, color: Color(0xFFBBBBBB)),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          property['title']?.toString() ?? 'Property',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusBgColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status != null
                              ? status[0].toUpperCase() + status.substring(1).toLowerCase()
                              : 'Pending',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date range
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 12, color: Color(0xFF426DC2)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_formatDate(booking['check_in']?.toString())} → ${_formatDate(booking['check_out']?.toString())}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF426DC2), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price + nights + cancel
                  Row(
                    children: [
                      Text(
                        _formatPrice(booking['amount']),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                      if (nights > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· $nights ${nights == 1 ? 'night' : 'nights'}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF868686)),
                        ),
                      ],
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          final uuid = booking['uuid']?.toString();
                          final code = booking['booking_code']?.toString() ?? 'N/A';
                          if (uuid != null && uuid.isNotEmpty) {
                            _cancelBooking(uuid, code);
                          }
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red),
                        ),
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
}
