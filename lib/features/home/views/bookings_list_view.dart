import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/bookings_cache_service.dart';
import '../../../core/services/storage_service.dart';
import 'booking_details_view.dart';

class BookingsListView extends StatefulWidget {
  const BookingsListView({super.key});

  @override
  State<BookingsListView> createState() => _BookingsListViewState();
}

class _BookingsListViewState extends State<BookingsListView> {
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await StorageService().getToken();
      final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.bookings}');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (!mounted) return;

      debugPrint('📋 [Bookings] Status: ${response.statusCode}');
      debugPrint('📋 [Bookings] Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonBody = json.decode(response.body);
        List<dynamic> list = [];

        debugPrint('📋 [Bookings] Top-level keys: ${jsonBody is Map ? jsonBody.keys.toList() : "IS_LIST"}');
        if (jsonBody is Map && jsonBody['data'] != null) {
          debugPrint('📋 [Bookings] data type: ${jsonBody['data'].runtimeType}');
          if (jsonBody['data'] is Map) {
            debugPrint('📋 [Bookings] data keys: ${(jsonBody['data'] as Map<dynamic, dynamic>).keys.toList()}');
          }
        }

        if (jsonBody['data'] is List) {
          list = jsonBody['data'] as List;
        } else if (jsonBody['data'] is Map && jsonBody['data']['data'] is List) {
          list = jsonBody['data']['data'] as List;
        } else if (jsonBody is List) {
          list = jsonBody;
        }

        debugPrint('📋 [Bookings] Parsed list length: ${list.length}');
        if (list.isNotEmpty) {
          final first = list[0] as Map;
          debugPrint('📋 [Bookings] First item keys: ${first.keys.toList()}');
          debugPrint('📋 [Bookings] booking_code: ${first['booking_code']}');
          debugPrint('📋 [Bookings] checkin_code: ${first['checkin_code']}');
          debugPrint('📋 [Bookings] status: ${first['status']}');
        }

        final all = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        // Only show accepted/confirmed/paid bookings — hide pending and cancelled
        setState(() {
          _bookings = all.where((b) {
            final status = b['status']?.toString().toLowerCase();
            final paymentStatus = b['payment_status']?.toString().toLowerCase();
            return status == 'accepted' ||
                status == 'confirmed' ||
                paymentStatus == 'paid' ||
                paymentStatus == 'successful' ||
                paymentStatus == 'completed';
          }).toList();
          _isLoading = false;
        });

        _bookingsCacheService.fetchAndCacheBookings(forceRefresh: true);
      } else {
        final jsonBody = json.decode(response.body);
        setState(() {
          _errorMessage = jsonBody['message']?.toString() ?? 'Failed to load bookings';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('📋 [Bookings] Error: $e');
      setState(() {
        _errorMessage = 'Error loading bookings';
        _isLoading = false;
      });
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8, right: 8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEFF0F2), width: 1.14),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back, color: Color(0xFF426DC2), size: 20),
              ),
            ),
          ),
        ),
        title: const Text(
          'My Bookings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF426DC2)))
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  color: const Color(0xFF426DC2),
                  onRefresh: _loadBookings,
                  child: _bookings.isEmpty
                      ? _buildEmpty()
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_bookings.length} active ${_bookings.length == 1 ? 'booking' : 'bookings'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF868686),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 20),
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
                            ],
                          ),
                        ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Color(0xFF868686))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF426DC2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 72, color: Color(0xFFDDDDDD)),
              SizedBox(height: 16),
              Text('No Pending Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
              SizedBox(height: 8),
              Text(
                'Your upcoming bookings will appear here.',
                style: TextStyle(fontSize: 14, color: Color(0xFF868686)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 90,
                  height: 90,
                  color: const Color(0xFFEFF0F2),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF426DC2))),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  color: const Color(0xFFEFF0F2),
                  child: const Icon(Icons.image_outlined, size: 32, color: Color(0xFFBBBBBB)),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          property['title']?.toString() ?? 'Property',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                          maxLines: 2,
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
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Location
                  if (property['location'] != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Color(0xFF868686)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            property['location'].toString(),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF868686)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // Date range + nights
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 12, color: Color(0xFF426DC2)),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(booking['check_in']?.toString())} → ${_formatDate(booking['check_out']?.toString())}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF426DC2), fontWeight: FontWeight.w500),
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
                        const SizedBox(width: 8),
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
