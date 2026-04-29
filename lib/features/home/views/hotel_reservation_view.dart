import 'package:flutter/material.dart';
import 'package:proplinq/core/services/api_service.dart';
import 'package:proplinq/core/constants/api_constants.dart';
import 'package:proplinq/core/widgets/payment_webview_dialog.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'dart:convert';
import '../services/hotel_service.dart';
import 'guest_home_view.dart';
import 'tenant_home_view.dart';
import 'agent_home_view.dart';
import '../../auth/views/login_view.dart';

class HotelReservationView extends StatefulWidget {
  final Map<String, dynamic> propertyData;
  final bool isGuest;

  const HotelReservationView({super.key, required this.propertyData, this.isGuest = false});

  @override
  State<HotelReservationView> createState() => _HotelReservationViewState();
}

class _HotelReservationViewState extends State<HotelReservationView> {
  int _nights = 2;
  int _guests = 1;
  int _adults = 1;
  DateTime _checkInDate = DateTime.now();
  DateTime _checkOutDate = DateTime.now();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int? _selectedDay;
  bool _selectingCheckout = false; // false = picking check-in, true = picking check-out

  final HotelService _hotelService = HotelService();
  Set<String> _blockedDates = {};
  Set<String> _bookedDates = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().day;
    _updateCheckOutDate();
    _loadAvailabilityFromRooms();
  }

  void _loadAvailabilityFromRooms() {
    // Prefer the specific room the user tapped "Book Room" on
    final selectedRoomId = widget.propertyData['selected_room_id'];
    if (selectedRoomId != null) {
      final id = int.tryParse(selectedRoomId.toString());
      if (id != null) {
        _loadAvailability(id);
        return;
      }
    }

    // Fallback: pick the cheapest room
    final rooms = widget.propertyData['rooms'];
    if (rooms == null || rooms is! List || rooms.isEmpty) return;
    final sortedRooms = List<dynamic>.from(rooms);
    sortedRooms.sort((a, b) {
      final pa = double.tryParse(a['price']?.toString() ?? '0') ?? 0;
      final pb = double.tryParse(b['price']?.toString() ?? '0') ?? 0;
      return pa.compareTo(pb);
    });
    final roomId = sortedRooms.first['id'];
    if (roomId == null) return;
    _loadAvailability(int.parse(roomId.toString()));
  }

  Future<void> _loadAvailability(int roomId) async {
    final now = DateTime.now();
    final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final end3Months = DateTime(now.year, now.month + 3, 0);
    final end = '${end3Months.year}-${end3Months.month.toString().padLeft(2, '0')}-${end3Months.day.toString().padLeft(2, '0')}';
    try {
      final response = await _hotelService.getRoomAvailability(
        roomId: roomId,
        startDate: start,
        endDate: end,
      );
      if (response.success && response.data != null && mounted) {
        final blocked = <String>{};
        final booked = <String>{};
        for (final entry in response.data!) {
          final date = entry['date'] as String?;
          if (date == null) continue;
          final isBlocked = entry['is_blocked'] == true;
          final status = entry['status'] as String?;
          final metadata = entry['metadata'];
          final availableCount = metadata is Map
              ? (metadata['available_count'] as num?)?.toInt() ?? 1
              : 1;
          if (isBlocked || status == 'blocked' || availableCount <= 0) {
            blocked.add(date);
          } else if (status == 'booked') {
            booked.add(date);
          }
        }
        setState(() {
          _blockedDates = blocked;
          _bookedDates = booked;
        });
      }
    } catch (e) {
      // Availability load failure is non-critical — calendar still works
    }
  }

  void _updateCheckOutDate() {
    _checkOutDate = _checkInDate.add(Duration(days: _nights));
  }

  @override
  Widget build(BuildContext context) {
    final price = _extractPrice(widget.propertyData['price'] as String);
    final totalCost = price * _nights;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Price and Quantity
                    _buildPriceAndQuantity(price),
                    
                    const SizedBox(height: 32),
                    
                    // Date Selection
                    _buildDateSelection(),
                    
                    const SizedBox(height: 24),
                    
                    // Calendar
                    _buildCalendar(),
                    
                    const SizedBox(height: 32),
                    
                    // Guest Selection
                    _buildGuestSelection(),
                    
                    const SizedBox(height: 32),
                    
                    // Total Cost Summary
                    _buildTotalCostSummary(totalCost),
                    
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Button
      bottomNavigationBar: _buildBottomButton(totalCost),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF426DC2),
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Text(
              widget.propertyData['title'] as String,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFF6C757D),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndQuantity(double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Price
        Text(
              '₦${_formatPrice(price)}/night',
              style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
                color: Colors.black,
          ),
        ),
        
        // Quantity selector with better design
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE9ECEF)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_nights > 1) {
                    setState(() {
                      _nights--;
                      _updateCheckOutDate();
                    });
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                  ),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 18,
                    color: _nights > 1 ? const Color(0xFF426DC2) : const Color(0xFFCED4DA),
                  ),
                ),
              ),
              
              Container(
                width: 50,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: Color(0xFFE9ECEF)),
                    right: BorderSide(color: Color(0xFFE9ECEF)),
                  ),
                ),
                child: Center(
                  child: Text(
                '$_nights',
                style: const TextStyle(
                      fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                    ),
                  ),
                ),
              ),
              
              GestureDetector(
                onTap: () {
                  setState(() {
                    _nights++;
                    _updateCheckOutDate();
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 18,
                    color: Color(0xFF426DC2),
                  ),
                ),
              ),
            ],
          ),
      ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            // Check-in
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF426DC2), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF426DC2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                          Icons.calendar_today,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Check-in',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C757D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_checkInDate.day.toString().padLeft(2, '0')}/${_checkInDate.month.toString().padLeft(2, '0')}/${_checkInDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Check-out
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _checkOutDate,
                    firstDate: _checkInDate.add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF426DC2),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    // Check that no blocked/booked date falls within the range
                    bool rangeHasUnavailable = false;
                    for (int i = 1; i < pickedDate.difference(_checkInDate).inDays; i++) {
                      final d = _checkInDate.add(Duration(days: i));
                      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                      if (_blockedDates.contains(key) || _bookedDates.contains(key)) {
                        rangeHasUnavailable = true;
                        break;
                      }
                    }
                    if (rangeHasUnavailable) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Your selected range includes unavailable dates. Please choose different dates.'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      setState(() {
                        _checkOutDate = pickedDate;
                        _nights = _checkOutDate.difference(_checkInDate).inDays;
                      });
                    }
                  }
                },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C757D),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                          Icons.calendar_today,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Check-out',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C757D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_checkOutDate.day.toString().padLeft(2, '0')}/${_checkOutDate.month.toString().padLeft(2, '0')}/${_checkOutDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Calendar header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    size: 14,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ),
              
              GestureDetector(
                onTap: () {
                  // Show month/year picker
                },
                child: Row(
                children: [
                    Text(
                      '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                      style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                        color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Color(0xFF6C757D),
                    ),
                  ],
                ),
              ),
              
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Days of week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('Mon', style: TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
              Text('Tue', style: TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
              Text('Wed', style: TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
              Text('Thur', style: TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
              Text('Fri', style: TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
              Text('Sat', style: TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
              Text('Sun', style: TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
            ],
          ),
          
          const SizedBox(height: 16),

          // Tap-hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF426DC2)),
                const SizedBox(width: 6),
                Text(
                  _selectingCheckout
                      ? 'Now tap a date to set check-out'
                      : 'Tap a date to set check-in',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF426DC2)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Calendar grid
          _buildCalendarGrid(),

          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _calendarLegendDot(const Color(0xFFEEEEEE), 'Blocked'),
              _calendarLegendDot(const Color(0xFFFFCDD2), 'Booked'),
              _calendarLegendDot(const Color(0xFF426DC2), 'Check-in/out'),
              _calendarLegendDot(const Color(0xFFD6E4F7), 'Range'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calendarLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6C757D))),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    List<Widget> dayWidgets = [];
    
    // Add empty spaces for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }
    
    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateKey = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final isBlocked = _blockedDates.contains(dateKey);
      final isBooked = _bookedDates.contains(dateKey);
      final isUnavailable = isBlocked || isBooked;
      final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
      final isDisabled = isUnavailable || isPast;

      final isCheckIn = date.year == _checkInDate.year &&
                        date.month == _checkInDate.month &&
                        date.day == _checkInDate.day;
      final isCheckOut = date.year == _checkOutDate.year &&
                         date.month == _checkOutDate.month &&
                         date.day == _checkOutDate.day;
      final isInRange = date.isAfter(_checkInDate) && date.isBefore(_checkOutDate);
      final isToday = date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;

      Color bgColor;
      Color textColor;
      if (isCheckIn || isCheckOut) {
        bgColor = const Color(0xFF426DC2);
        textColor = Colors.white;
      } else if (isInRange) {
        bgColor = const Color(0xFFD6E4F7);
        textColor = const Color(0xFF426DC2);
      } else if (isBooked) {
        bgColor = const Color(0xFFFFCDD2);
        textColor = Colors.grey.shade400;
      } else if (isBlocked) {
        bgColor = const Color(0xFFEEEEEE);
        textColor = Colors.grey.shade400;
      } else if (isToday) {
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF426DC2);
      } else {
        bgColor = Colors.transparent;
        textColor = isDisabled ? Colors.grey.shade400 : Colors.black;
      }

      dayWidgets.add(
        GestureDetector(
          onTap: isDisabled ? null : () {
            setState(() {
              if (!_selectingCheckout) {
                // First tap: set check-in
                _checkInDate = date;
                _checkOutDate = date.add(Duration(days: _nights));
                _selectedDay = day;
                _selectingCheckout = true;
              } else {
                // Second tap: set check-out (must be after check-in)
                if (date.isAfter(_checkInDate)) {
                  _checkOutDate = date;
                  _nights = _checkOutDate.difference(_checkInDate).inDays;
                } else {
                  // Tapped before check-in: restart
                  _checkInDate = date;
                  _checkOutDate = date.add(Duration(days: _nights));
                  _selectedDay = day;
                }
                _selectingCheckout = false;
              }
            });
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  decoration: isUnavailable ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: dayWidgets,
    );
  }

  Widget _buildGuestSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guests',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Total guests
        _buildGuestRow('Guests', _guests, (value) {
                      setState(() {
            _guests = value;
                        if (_adults > _guests) _adults = _guests;
                      });
        }),
        
        const SizedBox(height: 16),
        
        // Adults
        _buildGuestRow('Adults', _adults, (value) {
                    setState(() {
            _adults = value;
          });
        }),
      ],
    );
  }

  Widget _buildGuestRow(String label, int value, Function(int) onChanged) {
    return Row(
          children: [
        Expanded(
              child: Text(
            label,
            style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
              fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE9ECEF)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                  if (value > 1) {
                    onChanged(value - 1);
                    }
                  },
                  child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Icon(
                      Icons.remove,
                    size: 18,
                    color: value > 1 ? const Color(0xFF426DC2) : const Color(0xFFCED4DA),
                    ),
                  ),
                ),
                
              Container(
                width: 50,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: Color(0xFFE9ECEF)),
                    right: BorderSide(color: Color(0xFFE9ECEF)),
                  ),
                ),
                child: Center(
                  child: Text(
                    value.toString(),
                  style: const TextStyle(
                      fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    ),
                  ),
                  ),
                ),
                
                GestureDetector(
                  onTap: () {
                  if (label == 'Adults' && value < _guests) {
                    onChanged(value + 1);
                  } else if (label == 'Guests') {
                    onChanged(value + 1);
                    }
                  },
                  child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    ),
                    child: const Icon(
                      Icons.add,
                    size: 18,
                      color: Color(0xFF426DC2),
                    ),
                  ),
                ),
              ],
            ),
        ),
      ],
    );
  }

  Widget _buildTotalCostSummary(double totalCost) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total cost/night',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C757D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₦${_formatPrice(totalCost)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF426DC2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                'per night',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(double totalCost) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF426DC2),
                      Color(0xFF75CFEA),
                    ],
                  ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: ElevatedButton(
            onPressed: () {
              if (widget.isGuest) {
                _showGuestLoginPrompt();
              } else {
                _showPaymentScreen();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
                    'Continue Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _showGuestLoginPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
            ),
            const Icon(Icons.lock_outline, size: 48, color: Color(0xFF426DC2)),
            const SizedBox(height: 16),
            const Text('Sign in to continue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Create an account or log in to complete your booking.',
              style: TextStyle(fontSize: 14, color: Color(0xFF868686)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF426DC2), Color(0xFF75CFEA)]),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    final navigator = Navigator.of(context);
                    navigator.push(MaterialPageRoute(
                      builder: (_) => LoginView(
                        onLoginSuccess: (loginCtx, userType) {
                          final isAgent = userType != null && userType != 'home_seeker';
                          final nav = Navigator.of(loginCtx);
                          nav.pushReplacement(MaterialPageRoute(
                            builder: (_) => isAgent ? const AgentHomeView() : const TenantHomeView(),
                          ));
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            nav.push(MaterialPageRoute(
                              builder: (_) => HotelReservationView(propertyData: widget.propertyData),
                            ));
                          });
                        },
                      ),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: const Text('Log In / Sign Up', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Continue Browsing', style: TextStyle(color: Color(0xFF868686), fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HotelPaymentView(
          propertyData: widget.propertyData,
          nights: _nights,
          guests: _guests,
          adults: _adults,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  double _extractPrice(String priceString) {
    // Remove currency symbols and non-numeric characters, then parse
    final cleanPrice = priceString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanPrice) ?? 90000.0;
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},'
      );
    } else {
      return price.toStringAsFixed(0);
    }
  }
}

class HotelPaymentView extends StatefulWidget {
  final Map<String, dynamic> propertyData;
  final int nights;
  final int guests;
  final int adults;
  final DateTime checkInDate;
  final DateTime checkOutDate;

  const HotelPaymentView({
    super.key,
    required this.propertyData,
    required this.nights,
    required this.guests,
    required this.adults,
    required this.checkInDate,
    required this.checkOutDate,
  });

  @override
  State<HotelPaymentView> createState() => _HotelPaymentViewState();
}

class _HotelPaymentViewState extends State<HotelPaymentView> {
  String _selectedPaymentMethod = 'pay_now';
  bool _isLoading = false;
  bool _isLoadingBreakdown = true;
  Map<String, dynamic>? _priceBreakdown;
  final ApiService _apiService = ApiService();

  double get _pricePerNight {
    final raw = widget.propertyData['price']?.toString() ?? '0';
    final clean = raw.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(clean) ?? 0;
  }

  double get _totalCost {
    final apiTotal = _priceBreakdown?['total'];
    if (apiTotal != null) return (apiTotal as num).toDouble();
    return _pricePerNight * widget.nights;
  }

  double get _depositAmount => (_totalCost * 0.10).ceilToDouble();
  double get _remainingAmount => _totalCost - _depositAmount;

  String _fmt(double amount) => '₦${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  String get _buttonLabel => _selectedPaymentMethod == 'pay_now'
      ? 'Pay ${_fmt(_totalCost)}'
      : 'Pay ${_fmt(_depositAmount)} Deposit';

  @override
  void initState() {
    super.initState();
    _fetchPriceBreakdown();
  }

  Future<void> _fetchPriceBreakdown() async {
    try {
      final propertyId = widget.propertyData['id']?.toString() ?? '';
      if (propertyId.isEmpty) {
        setState(() => _isLoadingBreakdown = false);
        return;
      }
      final checkIn = '${widget.checkInDate.year}-${widget.checkInDate.month.toString().padLeft(2, '0')}-${widget.checkInDate.day.toString().padLeft(2, '0')}';
      final checkOut = '${widget.checkOutDate.year}-${widget.checkOutDate.month.toString().padLeft(2, '0')}-${widget.checkOutDate.day.toString().padLeft(2, '0')}';
      final paymentType = _selectedPaymentMethod == 'pay_arrival' ? 'pay_on_arrival' : 'full';

      final selectedRoomId = widget.propertyData['selected_room_id']?.toString();
      final response = await _apiService.get<Map<String, dynamic>>(
        '${ApiConstants.bookings}/price-breakdown',
        requiresAuth: true,
        queryParams: {
          'property_id': propertyId,
          'check_in_date': checkIn,
          'check_out_date': checkOut,
          'payment_type': paymentType,
          if (selectedRoomId != null && selectedRoomId.isNotEmpty) 'room_id': selectedRoomId,
        },
        fromJson: (json) => json,
      );

      if (mounted && response.success && response.data != null) {
        setState(() {
          _priceBreakdown = response.data;
          _isLoadingBreakdown = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingBreakdown = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBreakdown = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF426DC2),
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Expanded(
                    child: Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF6C757D),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Price breakdown / total summary
                    _isLoadingBreakdown
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF426DC2))),
                              ),
                            ),
                          )
                        : _buildPriceSummaryCard(),

                    // Payment options
                    _buildPaymentOption(
                      'pay_now',
                      'Pay Now (Recommended)',
                      'Pay ${_fmt(_totalCost)} now. Your booking is 100% guaranteed.',
                      true,
                    ),

                    const SizedBox(height: 16),

                    _buildPaymentOption(
                      'pay_arrival',
                      'Pay on Arrival',
                      'Pay ${_fmt(_depositAmount)} (10%) now to secure your booking. Remaining ${_fmt(_remainingAmount)} paid on arrival.',
                      false,
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
            
            // Bottom button
                    Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF426DC2),
                        Color(0xFF75CFEA),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _buttonLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                                  ),
                                ),
                              ],
                            ),
                          ),
    );
  }
                        
  Widget _buildPriceSummaryCard() {
    final breakdown = _priceBreakdown;

    // API-provided breakdown fields (all optional — fall back to client calc)
    final basePrice = breakdown != null ? (breakdown['base_price'] as num?)?.toDouble() : null;
    final serviceFee = breakdown != null ? (breakdown['service_fee'] as num?)?.toDouble() : null;
    final cautionFee = breakdown != null ? (breakdown['caution_fee'] as num?)?.toDouble() : null;
    final tax = breakdown != null ? (breakdown['tax'] as num?)?.toDouble() : null;
    final discount = breakdown != null ? (breakdown['discount'] as num?)?.toDouble() : null;

    final hasBreakdown = breakdown != null &&
        (basePrice != null || serviceFee != null || cautionFee != null || tax != null);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBreakdown) ...[
            if (basePrice != null)
              _breakdownRow('${_fmt(_pricePerNight)} × ${widget.nights} night${widget.nights == 1 ? '' : 's'}', _fmt(basePrice)),
            if (serviceFee != null && serviceFee > 0) ...[
              const SizedBox(height: 6),
              _breakdownRow('Service fee', _fmt(serviceFee)),
            ],
            if (cautionFee != null && cautionFee > 0) ...[
              const SizedBox(height: 6),
              _breakdownRow('Caution fee', _fmt(cautionFee)),
            ],
            if (tax != null && tax > 0) ...[
              const SizedBox(height: 6),
              _breakdownRow('Tax', _fmt(tax)),
            ],
            if (discount != null && discount > 0) ...[
              const SizedBox(height: 6),
              _breakdownRow('Discount', '-${_fmt(discount)}', valueColor: const Color(0xFF2E7D32)),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Color(0xFFD0D8F0), height: 1),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 13, color: Color(0xFF6C757D))),
                  Text(_fmt(_totalCost), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF426DC2))),
                ],
              ),
              Text('${widget.nights} night${widget.nights == 1 ? '' : 's'} · ${widget.guests} guest${widget.guests == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6C757D))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6C757D))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? Colors.black)),
      ],
    );
  }

  Widget _buildPaymentOption(String value, String title, String subtitle, bool isRecommended) {
    final isSelected = _selectedPaymentMethod == value;
                        
    return GestureDetector(
                          onTap: () {
                            setState(() {
          _selectedPaymentMethod = value;
                            });
                          },
                          child: Container(
        padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                              border: Border.all(
            color: isSelected ? const Color(0xFF426DC2) : const Color(0xFFE9ECEF),
            width: isSelected ? 2 : 1,
                              ),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
                      ),
                      child: Row(
                        children: [
                                Container(
              width: 24,
              height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF426DC2) : Colors.transparent,
                                    border: Border.all(
                  color: isSelected ? const Color(0xFF426DC2) : const Color(0xFFCED4DA),
                  width: 2,
                                    ),
                                  ),
              child: isSelected
                                      ? const Icon(
                                          Icons.check,
                      size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                          ),
                                
                          const SizedBox(width: 16),
                                
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w500,
                      ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processBooking() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Extract property ID (similar to share functionality)
      String? propertyId;
      final property = widget.propertyData;
      final idValue = property['id'];
      
      if (idValue != null) {
        if (idValue is int) {
          propertyId = idValue.toString();
        } else if (idValue is String) {
          propertyId = idValue;
        } else {
          propertyId = idValue.toString();
        }
      }
      
      // If still not found, try to extract from images array
      if ((propertyId == null || propertyId.isEmpty) && property['images'] != null) {
        final images = property['images'];
        if (images is List && images.isNotEmpty) {
          final first = images.first;
          if (first is Map<String, dynamic> && first['property_id'] != null) {
            propertyId = first['property_id'].toString();
          }
        }
      }
      
      if (propertyId == null || propertyId.isEmpty) {
        print('❌ Property ID not found in propertyData');
        print('📋 Property data keys: ${property.keys.toList()}');
        print('📋 Property data: $property');
        
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to process booking: Property ID not found. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      print('✅ Extracted property ID: $propertyId');

      // Format dates as YYYY-MM-DD
      final checkInDateStr = '${widget.checkInDate.year}-${widget.checkInDate.month.toString().padLeft(2, '0')}-${widget.checkInDate.day.toString().padLeft(2, '0')}';
      final checkOutDateStr = '${widget.checkOutDate.year}-${widget.checkOutDate.month.toString().padLeft(2, '0')}-${widget.checkOutDate.day.toString().padLeft(2, '0')}';

      // Extract room_id (if a specific room was selected)
      final selectedRoomId = widget.propertyData['selected_room_id'];
      final roomIdInt = selectedRoomId != null ? int.tryParse(selectedRoomId.toString()) : null;

      // Prepare booking payload
      final bookingPayload = <String, dynamic>{
        'property_id': int.tryParse(propertyId.toString()) ?? 0,
        'check_in_date': checkInDateStr,
        'check_out_date': checkOutDateStr,
        'guests': widget.guests,
        'adults': widget.adults,
        'payment_type': _selectedPaymentMethod == 'pay_arrival' ? 'pay_on_arrival' : 'full',
        if (roomIdInt != null) 'room_id': roomIdInt,
      };

      print('📋 Creating booking with payload: $bookingPayload');

      // Call booking API
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.bookings,
        body: bookingPayload,
        requiresAuth: true,
        fromJson: (json) => json,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final data = response.data!;
        print('✅ Booking created successfully');
        print('📋 Response data: ${json.encode(data)}');
        print('📋 Response data keys: ${data.keys.toList()}');

        // Extract payment authorization URL
        // The response.data already contains the 'data' object from API response
        // Structure: response.data = { "booking": {...}, "payment": {...} }
        Map<String, dynamic>? paymentData;
        if (data.containsKey('payment')) {
          paymentData = data['payment'] as Map<String, dynamic>?;
          print('📋 Payment data: ${json.encode(paymentData)}');
        }
        
        // Also try accessing data['data']['payment'] in case response structure is different
        if (paymentData == null && data.containsKey('data')) {
          final innerData = data['data'];
          if (innerData is Map && innerData.containsKey('payment')) {
            paymentData = innerData['payment'] as Map<String, dynamic>?;
            print('📋 Payment data (from nested): ${json.encode(paymentData)}');
          }
        }
        
        final authorizationUrl = paymentData?['authorization_url'] as String?;
        print('🔗 Authorization URL: $authorizationUrl');

        if (authorizationUrl != null && authorizationUrl.isNotEmpty) {
          print('🔗 Opening payment URL: $authorizationUrl');
          
          // Extract booking data to pass to success screen
          final bookingInfo = data['booking'] as Map<String, dynamic>? ?? {};
          
          // Add guests and adults to booking data if not already present
          // (in case API doesn't return them, we use what we sent)
          final enrichedBookingData = Map<String, dynamic>.from(bookingInfo);
          if (!enrichedBookingData.containsKey('guests') || enrichedBookingData['guests'] == null) {
            enrichedBookingData['guests'] = widget.guests;
          }
          if (!enrichedBookingData.containsKey('adults') || enrichedBookingData['adults'] == null) {
            enrichedBookingData['adults'] = widget.adults;
          }
          
          // Close loading and show payment webview
          setState(() {
            _isLoading = false;
          });

          // Attach payment method so success screen can show deposit/remaining
          enrichedBookingData['_payment_type'] = _selectedPaymentMethod;
          enrichedBookingData['_total_cost'] = _totalCost;
          enrichedBookingData['_deposit_amount'] = _depositAmount;
          enrichedBookingData['_remaining_amount'] = _remainingAmount;

          // Show payment webview dialog with enriched booking data
          await _showPaymentWebView(authorizationUrl, enrichedBookingData);
        } else {
          setState(() {
            _isLoading = false;
          });
          throw Exception('Payment URL not found in response');
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 409) {
          _showUnavailableDatesDialog();
        } else {
          final rawMessage = response.message ?? 'Failed to create booking';
          print('❌ Booking failed: $rawMessage');

          // Translate backend payment gateway errors into user-friendly messages
          final String userMessage;
          if (rawMessage.toLowerCase().contains('flutterwave') ||
              rawMessage.toLowerCase().contains('payment') ||
              rawMessage.toLowerCase().contains('cannot post') ||
              rawMessage.toLowerCase().contains('gateway')) {
            userMessage = 'Payment gateway is currently unavailable. Please try again later or contact support.';
          } else {
            userMessage = rawMessage;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      print('❌ Error processing booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showUnavailableDatesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dates Unavailable'),
        content: const Text(
          'This property is not available for the selected dates. Please choose different check-in or check-out dates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentWebView(String paymentUrl, Map<String, dynamic> bookingData) async {
    if (!mounted) return;

    final paid = await showPaymentWebView(
      context: context,
      paymentUrl: paymentUrl,
      title: 'Complete Payment',
    );

    if (paid && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HotelBookingSuccessView(
            bookingData: bookingData,
            propertyData: widget.propertyData,
          ),
        ),
      );
    }
  }
}

class HotelBookingSuccessView extends StatelessWidget {
  final Map<String, dynamic>? bookingData;
  final Map<String, dynamic>? propertyData;
  
  const HotelBookingSuccessView({
    super.key,
    this.bookingData,
    this.propertyData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF6C757D),
                      size: 20,
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Success icon with decorative elements
              Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative circles
                  Positioned(
                    top: -20,
                    right: 10,
                    child: Icon(
                      Icons.add,
                      size: 16,
                        color: const Color(0xFF426DC2).withOpacity(0.3),
                    ),
                  ),
                  Positioned(
                    bottom: -15,
                    left: -10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF75CFEA).withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: -25,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2).withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: -20,
                    child: Icon(
                      Icons.add,
                      size: 12,
                      color: const Color(0xFF75CFEA).withOpacity(0.6),
                    ),
                  ),
                  
                  // Main success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF426DC2), Color(0xFF75CFEA)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Success message
              const Text(
                'Booking Successful',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Thanks for booking with us! Your booking has been successfully scheduled.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6C757D),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),

              // Payment summary card
              _buildPaymentSummary(),

              const SizedBox(height: 16),

              // Warning banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF426DC2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your booking will be cancelled if you don\'t check in within 48 hours of your scheduled check-in date.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1976D2),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF426DC2),
                              Color(0xFF75CFEA),
                            ],
                          ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (bookingData != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BookingDetailsView(
                                  bookingData: bookingData!,
                                  propertyData: propertyData,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                            'View booking details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: const BorderSide(color: Color(0xFF426DC2), width: 1.5),
                        ),
                      ),
                      child: const Text(
                        'Contact support',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF426DC2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtAmt(double amount) => '₦${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  Widget _buildPaymentSummary() {
    final data = bookingData ?? {};
    final paymentType = data['_payment_type'] as String?;
    final totalCost = (data['_total_cost'] as num?)?.toDouble();
    final depositAmount = (data['_deposit_amount'] as num?)?.toDouble();
    final remainingAmount = (data['_remaining_amount'] as num?)?.toDouble();

    if (totalCost == null) return const SizedBox.shrink();

    final isPayOnArrival = paymentType == 'pay_arrival';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _summaryRow('Total amount', _fmtAmt(totalCost), bold: false),
          if (isPayOnArrival && depositAmount != null) ...[
            const SizedBox(height: 8),
            _summaryRow('Paid now (10% deposit)', _fmtAmt(depositAmount), color: const Color(0xFF2E7D32)),
            const SizedBox(height: 8),
            _summaryRow('Remaining on arrival', _fmtAmt(remainingAmount ?? 0), color: const Color(0xFFE65100)),
          ] else ...[
            const SizedBox(height: 8),
            _summaryRow('Amount paid', _fmtAmt(totalCost), color: const Color(0xFF2E7D32), bold: true),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6C757D))),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }
}

/// Booking Details View - Shows detailed information about a booking
class BookingDetailsView extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final Map<String, dynamic>? propertyData;

  const BookingDetailsView({
    super.key,
    required this.bookingData,
    required this.propertyData,
  });

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final hour = date.hour;
      final minute = date.minute;
      final period = hour >= 12 ? 'pm' : 'am';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}$period';
    } catch (e) {
      return 'N/A';
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

  String _formatPrice(String? priceString) {
    if (priceString == null) return 'N/A';
    try {
      final price = double.tryParse(priceString) ?? 0.0;
      return '#${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _addToCalendar(BuildContext context) async {
    try {
      final booking = bookingData;
      final property = propertyData ?? {};
      
      final checkInStr = booking['check_in'] as String?;
      final checkOutStr = booking['check_out'] as String?;
      final bookingCode = booking['booking_code'] as String? ?? 'Booking';
      final propertyTitle = property['title'] as String? ?? 'Property';
      final propertyLocation = property['location'] as String? ?? '';
      
      if (checkInStr == null || checkOutStr == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to add to calendar: Invalid dates'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final checkInDate = DateTime.parse(checkInStr);
      final checkOutDate = DateTime.parse(checkOutStr);
      
      // Create event details
      final title = 'Hotel Booking: $propertyTitle';
      final description = 'Booking Code: $bookingCode\nLocation: $propertyLocation\n\nYour booking check-in is scheduled for ${_formatDate(checkInStr)}.';
      final location = propertyLocation;
      
      // Create calendar event
      final event = Event(
        title: title,
        description: description,
        location: location,
        startDate: checkInDate,
        endDate: checkOutDate,
        allDay: false,
        iosParams: const IOSParams(
          reminder: Duration(minutes: 60), // Reminder 1 hour before
        ),
        androidParams: const AndroidParams(
          emailInvites: [],
        ),
      );

      // Add to calendar
      final result = await Add2Calendar.addEvent2Cal(event);
      
      if (context.mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking added to calendar successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add to calendar. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to calendar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = bookingData;
    final property = propertyData ?? {};
    
    final checkIn = booking['check_in'] as String?;
    final checkOut = booking['check_out'] as String?;
    final bookingCode = booking['booking_code'] as String? ?? 'N/A';
    final createdAt = booking['created_at'] as String?;
    // Handle both int and string types for guests/adults
    final guests = booking['guests'] is int 
        ? booking['guests'] as int 
        : (booking['guests'] is String 
            ? int.tryParse(booking['guests'] as String) ?? 1 
            : 1);
    final adults = booking['adults'] is int 
        ? booking['adults'] as int 
        : (booking['adults'] is String 
            ? int.tryParse(booking['adults'] as String) ?? guests 
            : guests);
    final amount = booking['amount'] as String?;
    final propertyTitle = property['title'] as String? ?? 'N/A';
    final propertyLocation = property['location'] as String? ?? 'N/A';
    final location = '$propertyTitle in $propertyLocation';
    
    final nights = _calculateNights(checkIn, checkOut);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF426DC2),
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // Just pop back to the previous screen (booking success screen)
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF6C757D),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Check-in', _formatDate(checkIn)),
                    const SizedBox(height: 16),
                    _buildDetailRow('Check-out', _formatDate(checkOut)),
                    const SizedBox(height: 16),
                    _buildDetailRow('Location', location),
                    const SizedBox(height: 16),
                    _buildDetailRow('Check-in code', bookingCode),
                    const SizedBox(height: 16),
                    _buildDetailRow('Booking time', _formatTime(createdAt)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Color(0xFFE9ECEF)),
                    ),
                    _buildDetailRow('Guests', guests.toString()),
                    const SizedBox(height: 16),
                    _buildDetailRow('Adults', adults.toString()),
                    const SizedBox(height: 16),
                    _buildDetailRow('Total night', nights.toString()),
                    const SizedBox(height: 16),
                    _buildDetailRow('Total cost', _formatPrice(amount)),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF426DC2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Your booking will be cancelled if you don\'t check in within 48 hours of your scheduled check-in date.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1976D2),
                                height: 1.4,
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF426DC2),
                            Color(0xFF75CFEA),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await _addToCalendar(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Add to calendar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: const BorderSide(color: Color(0xFF426DC2), width: 1.5),
                        ),
                      ),
                      child: const Text(
                        'Book again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF426DC2),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6C757D),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
