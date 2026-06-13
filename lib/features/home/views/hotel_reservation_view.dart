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
  bool _datesSelected = false; // user hasn't picked dates yet

  final HotelService _hotelService = HotelService();
  Set<String> _blockedDates = {};
  Set<String> _bookedDates = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Do NOT pre-select today — _datesSelected stays false until user taps
    _loadAvailabilityFromRooms();
  }

  void _scrollToCalendar() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          300,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _loadAvailabilityFromRooms() {
    final rooms = widget.propertyData['rooms'];
    final roomList = rooms is List ? rooms : <dynamic>[];

    // Find the selected room (or cheapest as fallback)
    Map<String, dynamic>? targetRoom;
    final selectedRoomId = widget.propertyData['selected_room_uuid']?.toString()
        ?? widget.propertyData['selected_room_id']?.toString();

    if (selectedRoomId != null && selectedRoomId.isNotEmpty && roomList.isNotEmpty) {
      for (final r in roomList) {
        if (r is Map &&
            (r['uuid']?.toString() == selectedRoomId ||
             r['id']?.toString() == selectedRoomId)) {
          targetRoom = Map<String, dynamic>.from(r);
          break;
        }
      }
    }

    if (targetRoom == null && roomList.isNotEmpty) {
      final sorted = List<dynamic>.from(roomList)
        ..sort((a, b) {
          final pa = double.tryParse(a['price']?.toString() ?? '0') ?? 0;
          final pb = double.tryParse(b['price']?.toString() ?? '0') ?? 0;
          return pa.compareTo(pb);
        });
      targetRoom = Map<String, dynamic>.from(sorted.first as Map);
    }

    // Use available_dates from the room directly if present and non-empty.
    // Empty list means the agent hasn't set availability — show all dates open.
    if (targetRoom != null) {
      final roomAvailableDates = targetRoom['available_dates'];
      if (roomAvailableDates is List && roomAvailableDates.isNotEmpty) {
        _computeBlockedFromAvailableDates(roomAvailableDates);
        // Also try the API in parallel to get more up-to-date data
        final roomUuid = targetRoom['uuid']?.toString() ?? targetRoom['id']?.toString();
        if (roomUuid != null) _loadAvailability(roomUuid);
        return;
      }
    }

    // No available_dates on room — fall back to API only
    if (targetRoom != null) {
      final roomUuid = targetRoom['uuid']?.toString() ?? targetRoom['id']?.toString();
      if (roomUuid != null) _loadAvailability(roomUuid);
    }
  }

  /// Builds _blockedDates from a property-level available_dates list.
  /// Every date from today up to 12 months ahead that is NOT in the
  /// available list is marked as blocked.
  void _computeBlockedFromAvailableDates(List<dynamic> availableDates) {
    final available = <String>{};
    for (final entry in availableDates) {
      // Each entry may be a plain "YYYY-MM-DD" string or a map with a 'date' key
      if (entry is String) {
        available.add(entry);
      } else if (entry is Map) {
        final d = entry['date']?.toString();
        if (d != null) available.add(d);
      }
    }

    final blocked = <String>{};
    final today = DateTime.now();
    final limit = DateTime(today.year, today.month + 12, today.day);
    for (DateTime d = DateTime(today.year, today.month, today.day);
        d.isBefore(limit);
        d = d.add(const Duration(days: 1))) {
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (!available.contains(key)) {
        blocked.add(key);
      }
    }

    if (mounted) {
      setState(() {
        _blockedDates = blocked;
      });
    }
  }

  Future<void> _loadAvailability(String roomUuid) async {
    final now = DateTime.now();
    final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final end3Months = DateTime(now.year, now.month + 3, 0);
    final end = '${end3Months.year}-${end3Months.month.toString().padLeft(2, '0')}-${end3Months.day.toString().padLeft(2, '0')}';
    try {
      // Use agent calendar endpoint — it returns authoritative blocked/booked state per date
      final response = await _hotelService.getAgentCalendar(
        roomUuid: roomUuid,
        startDate: start,
        endDate: end,
      );

      if (response.success && response.data != null && mounted) {
        final blocked = <String>{};
        final booked = <String>{};
        for (final entry in response.data!) {
          final date = entry['date'] as String?;
          if (date == null) continue;
          final status = entry['status'] as String?;
          final isBooked = entry['is_booked'] == true;
          final availableCount = (entry['available_count'] as num?)?.toInt()
              ?? (entry['metadata'] is Map ? (entry['metadata']['available_count'] as num?)?.toInt() : null)
              ?? 1;

          // A date is only unavailable to guests when ALL inventory is gone (availableCount == 0).
          // Partial agent blocks (some rooms blocked but others still free) leave the date bookable.
          if (availableCount == 0) {
            booked.add(date);
          } else if (isBooked || status == 'booked') {
            booked.add(date);
          }
        }
        debugPrint('🗓️ [Calendar] agent calendar: ${response.data!.length} entries → blocked=${blocked.length}, booked=${booked.length}');
        if (response.data!.isNotEmpty) debugPrint('🗓️ [Calendar] sample entry: ${response.data!.first}');
        // Only override room-level data if the API actually returned useful entries
        if (response.data!.isNotEmpty) {
          setState(() {
            _blockedDates = blocked;
            _bookedDates = booked;
          });
        }
      } else {
        // Fallback to public availability endpoint if agent calendar fails (e.g. not logged in)
        await _loadAvailabilityPublic(roomUuid, start, end);
      }
    } catch (e) {
      await _loadAvailabilityPublic(roomUuid, start, end);
    }
  }

  Future<void> _loadAvailabilityPublic(String roomUuid, String start, String end) async {
    try {
      final response = await _hotelService.getRoomAvailability(
        roomUuid: roomUuid,
        startDate: start,
        endDate: end,
      );
      if (response.success && response.data != null && mounted) {
        final blocked = <String>{};
        final booked = <String>{};
        for (final entry in response.data!) {
          final date = entry['date'] as String?;
          if (date == null) continue;
          final status = entry['status'] as String?;
          final metadata = entry['metadata'];
          final availableCount = metadata is Map
              ? (metadata['available_count'] as num?)?.toInt() ?? 1
              : 1;
          // Only block the date for guests when all inventory is exhausted.
          if (availableCount == 0 || status == 'booked') {
            booked.add(date);
          }
        }
        debugPrint('🗓️ [Calendar] public availability: ${response.data!.length} entries → blocked=${blocked.length}, booked=${booked.length}');
        if (response.data!.isNotEmpty) debugPrint('🗓️ [Calendar] sample entry: ${response.data!.first}');
        if (response.data!.isNotEmpty) {
          setState(() {
            _blockedDates = blocked;
            _bookedDates = booked;
          });
        }
      }
    } catch (_) {
      // Non-critical — calendar still works without availability data
    }
  }

  void _updateCheckOutDate() {
    _checkOutDate = _checkInDate.add(Duration(days: _nights));
  }

  @override
  Widget build(BuildContext context) {
    final pricePerNight = _extractPrice(
      (widget.propertyData['selected_room_price'] ?? widget.propertyData['price'] ?? '0').toString(),
    );
    final totalCost = pricePerNight * _nights;

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
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Price display (no stepper — nights come from calendar)
                    _buildPriceDisplay(pricePerNight),

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
                    _buildTotalCostSummary(pricePerNight),

                    const SizedBox(height: 100),
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

  Widget _buildPriceDisplay(double price) {
    return Text(
      '₦${_formatPrice(price)}/night',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
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
            // Check-in — tapping resets selection so user can pick fresh
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _datesSelected = false;
                    _selectingCheckout = false;
                  });
                  _scrollToCalendar();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: (_selectingCheckout || _datesSelected) ? const Color(0xFF426DC2) : const Color(0xFFE9ECEF),
                      width: (_selectingCheckout || _datesSelected) ? 1.5 : 1,
                    ),
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
                              color: (_selectingCheckout || _datesSelected) ? const Color(0xFF426DC2) : const Color(0xFFCED4DA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.calendar_today, size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Check-in',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectingCheckout || _datesSelected
                            ? '${_checkInDate.day.toString().padLeft(2, '0')}/${_checkInDate.month.toString().padLeft(2, '0')}/${_checkInDate.year}'
                            : 'Select date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectingCheckout || _datesSelected ? Colors.black : const Color(0xFFADB5BD),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Check-out
            Expanded(
              child: GestureDetector(
                onTap: (_datesSelected || _selectingCheckout) ? () async {
                  // If only check-in picked, scroll to calendar so user taps checkout there
                  if (_selectingCheckout && !_datesSelected) {
                    _scrollToCalendar();
                    return;
                  }
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _checkOutDate.isAfter(_checkInDate) ? _checkOutDate : _checkInDate.add(const Duration(days: 1)),
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
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (_datesSelected || _selectingCheckout) ? Colors.white : const Color(0xFFF8F9FA),
                    border: Border.all(
                      color: _datesSelected ? const Color(0xFF426DC2) : (_selectingCheckout ? const Color(0xFFB0C4DE) : const Color(0xFFE9ECEF)),
                      width: _datesSelected ? 1.5 : 1,
                    ),
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
                              color: _datesSelected ? const Color(0xFF426DC2) : (_selectingCheckout ? const Color(0xFFB0C4DE) : const Color(0xFFCED4DA)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.calendar_today, size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Check-out',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _datesSelected
                            ? '${_checkOutDate.day.toString().padLeft(2, '0')}/${_checkOutDate.month.toString().padLeft(2, '0')}/${_checkOutDate.year}'
                            : 'Select date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _datesSelected ? Colors.black : const Color(0xFFADB5BD),
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
              _calendarLegendToday(),
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

  Widget _calendarLegendToday() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF426DC2), width: 2),
          ),
        ),
        const SizedBox(width: 4),
        const Text('Today', style: TextStyle(fontSize: 11, color: Color(0xFF6C757D))),
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

      // Show check-in highlight as soon as user taps it, and keep it after checkout is chosen
      final isCheckIn = (_selectingCheckout || _datesSelected) &&
                        date.year == _checkInDate.year &&
                        date.month == _checkInDate.month &&
                        date.day == _checkInDate.day;
      // Show checkout highlight and range only after both dates are fully selected
      final isCheckOut = _datesSelected &&
                         date.year == _checkOutDate.year &&
                         date.month == _checkOutDate.month &&
                         date.day == _checkOutDate.day;
      final isInRange = _datesSelected && date.isAfter(_checkInDate) && date.isBefore(_checkOutDate);
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
                // First tap: set check-in only, do NOT auto-set checkout
                _checkInDate = date;
                _selectedDay = day;
                _datesSelected = false; // checkout not chosen yet
                _selectingCheckout = true;
              } else {
                // Second tap: set check-out (must be after check-in)
                if (date.isAfter(_checkInDate)) {
                  _checkOutDate = date;
                  _nights = _checkOutDate.difference(_checkInDate).inDays;
                  _datesSelected = true;
                  _selectingCheckout = false;
                } else {
                  // Tapped same day or before check-in: restart from this date
                  _checkInDate = date;
                  _selectedDay = day;
                  _datesSelected = false;
                  _selectingCheckout = true;
                }
              }
            });
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isCheckIn && !isCheckOut
                  ? Border.all(color: const Color(0xFF426DC2), width: 2)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                      decoration: isUnavailable ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (isToday)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isCheckIn || isCheckOut) ? Colors.white : const Color(0xFF426DC2),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
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

  Widget _buildTotalCostSummary(double pricePerNight) {
    if (!_datesSelected) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFFADB5BD)),
            const SizedBox(width: 10),
            Text(
              'Select dates to see total price',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final totalCost = pricePerNight * _nights;
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
              Text(
                '₦${_formatPrice(pricePerNight)} × $_nights night${_nights == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D), fontWeight: FontWeight.w500),
              ),
              Text(
                '₦${_formatPrice(totalCost)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF426DC2)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Text('Total', style: TextStyle(fontSize: 12, color: Color(0xFF6C757D))),
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
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: _datesSelected
                        ? const [Color(0xFF426DC2), Color(0xFF75CFEA)]
                        : const [Color(0xFFB0BEC5), Color(0xFFCFD8DC)],
                  ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: ElevatedButton(
            onPressed: _datesSelected ? _showPaymentScreen : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Continue Booking',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _datesSelected ? Colors.white : Colors.white60,
              ),
            ),
          ),
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
          isGuest: widget.isGuest,
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
    return double.tryParse(cleanPrice) ?? 0.0;
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
  final bool isGuest;

  const HotelPaymentView({
    super.key,
    required this.propertyData,
    required this.nights,
    required this.guests,
    required this.adults,
    required this.checkInDate,
    required this.checkOutDate,
    this.isGuest = false,
  });

  @override
  State<HotelPaymentView> createState() => _HotelPaymentViewState();
}

class _HotelPaymentViewState extends State<HotelPaymentView> {
  String _selectedPaymentMethod = 'pay_now';
  String _selectedGateway = 'paystack';
  bool _isLoading = false;
  bool _isLoadingBreakdown = true;
  Map<String, dynamic>? _priceBreakdown;
  final ApiService _apiService = ApiService();
  late bool _isGuest;

  double get _pricePerNight {
    final raw = (widget.propertyData['selected_room_price'] ?? widget.propertyData['price'])?.toString() ?? '0';
    final clean = raw.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(clean) ?? 0;
  }

  // Reads a numeric field that may appear under multiple key names (preview API vs booking response)
  double? _bd(List<String> keys) {
    for (final k in keys) {
      final v = _priceBreakdown?[k];
      if (v == null) continue;
      if (v is num) return v.toDouble();
      final parsed = double.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  double get _baseAmount =>
      _bd(['base_price', 'base_amount']) ?? _pricePerNight * widget.nights;

  double get _serviceFee =>
      _bd(['service_fee', 'platform_fee']) ?? (_baseAmount * 0.02).roundToDouble();
  double get _vatAmount =>
      _bd(['tax', 'vat_on_fee']) ?? (_serviceFee * 0.075).roundToDouble();
  double get _totalCost =>
      _bd(['total', 'total_due']) ?? _baseAmount + _serviceFee + _vatAmount;

  // Pay on arrival: 10% of base + full service fee + full VAT
  // e.g. ₦200k → deposit ₦20k + service fee ₦4k + VAT ₦300 = ₦24,300
  double get _depositBase => (_baseAmount * 0.10).roundToDouble();
  double get _depositAmount => _depositBase + _serviceFee + _vatAmount;
  double get _remainingAmount => _baseAmount - _depositBase;

  String _fmt(double amount) => '₦${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  String get _buttonLabel => _selectedPaymentMethod == 'pay_now'
      ? 'Pay ${_fmt(_totalCost)}'
      : 'Pay ${_fmt(_depositAmount)}';

  @override
  void initState() {
    super.initState();
    _isGuest = widget.isGuest;
    _fetchPriceBreakdown();
  }

  Future<void> _fetchPriceBreakdown() async {
    try {
      final uuid = widget.propertyData['uuid']?.toString();
      final propertyId = (uuid != null && uuid.isNotEmpty)
          ? uuid
          : widget.propertyData['id']?.toString() ?? '';
      if (propertyId.isEmpty) {
        setState(() => _isLoadingBreakdown = false);
        return;
      }
      final checkIn = '${widget.checkInDate.year}-${widget.checkInDate.month.toString().padLeft(2, '0')}-${widget.checkInDate.day.toString().padLeft(2, '0')}';
      final checkOut = '${widget.checkOutDate.year}-${widget.checkOutDate.month.toString().padLeft(2, '0')}-${widget.checkOutDate.day.toString().padLeft(2, '0')}';
      final paymentType = _selectedPaymentMethod == 'pay_arrival' ? 'pay_on_arrival' : 'full';

      final selectedRoomId = widget.propertyData['selected_room_uuid']?.toString()
          ?? widget.propertyData['selected_room_id']?.toString();
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
              child: SingleChildScrollView(
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
                      'Pay the full amount of ${_fmt(_totalCost)} now to instantly secure this property for your stay. This total includes the booking rate, service fee, and all applicable taxes.',
                      true,
                    ),

                    const SizedBox(height: 16),

                    _buildPaymentOption(
                      'pay_arrival',
                      'Pay on Arrival',
                      'Pay a secure deposit of ${_fmt(_depositAmount)} now to lock in your booking dates. The remaining balance of ${_fmt(_remainingAmount)} will be paid directly to the host when you arrive.',
                      false,
                    ),

                    const SizedBox(height: 24),

                    // Gateway selection
                    const Text('Payment Gateway', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildGatewayOption('paystack', 'Paystack')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildGatewayOption('flutterwave', 'Flutterwave')),
                      ],
                    ),

                    const SizedBox(height: 16),
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
                    onPressed: _isLoading ? null : () {
                      if (_isGuest) {
                        _showGuestLoginPrompt();
                      } else {
                        _processBooking();
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
                    // Capture booking data before pushing login
                    final propertyData = widget.propertyData;
                    final nights = widget.nights;
                    final guests = widget.guests;
                    final adults = widget.adults;
                    final checkIn = widget.checkInDate;
                    final checkOut = widget.checkOutDate;
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LoginView(
                        onLoginSuccess: (loginCtx, userType) {
                          final isAgent = userType != null && userType != 'home_seeker';
                          // Clear the entire guest stack, go to authenticated home,
                          // then push the payment screen inside the authenticated context
                          Navigator.of(loginCtx).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => isAgent
                                  ? const AgentHomeView()
                                  : const TenantHomeView(),
                            ),
                            (_) => false,
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.of(loginCtx).push(MaterialPageRoute(
                              builder: (_) => HotelPaymentView(
                                propertyData: propertyData,
                                nights: nights,
                                guests: guests,
                                adults: adults,
                                checkInDate: checkIn,
                                checkOutDate: checkOut,
                                isGuest: false,
                              ),
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

  Widget _buildPriceSummaryCard() {
    final breakdown = _priceBreakdown;

    // API-provided breakdown fields — accept both preview and booking response key names
    double? pick(List<String> keys) {
      for (final k in keys) {
        final v = breakdown?[k];
        if (v != null) return (v as num).toDouble();
      }
      return null;
    }
    final basePrice = pick(['base_price', 'base_amount']);
    final serviceFee = pick(['service_fee', 'platform_fee']);
    final cautionFee = pick(['caution_fee']);
    final tax = pick(['tax', 'vat_on_fee']);
    final discount = pick(['discount']);

    final hasApiBreakdown = breakdown != null &&
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
          if (hasApiBreakdown) ...[
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
          ] else if (_selectedPaymentMethod == 'pay_arrival') ...[
            // Pay on arrival: deposit breakdown
            _breakdownRow(
              '${_fmt(_pricePerNight)} × ${widget.nights} night${widget.nights == 1 ? '' : 's'}',
              _fmt(_baseAmount),
            ),
            const SizedBox(height: 6),
            _breakdownRow('Deposit (10%)', _fmt(_depositBase)),
            const SizedBox(height: 6),
            _breakdownRow('Service fee (2%)', _fmt(_serviceFee)),
            const SizedBox(height: 6),
            _breakdownRow('VAT (7.5%)', _fmt(_vatAmount)),
          ] else ...[
            // Pay now: full breakdown
            _breakdownRow(
              '${_fmt(_pricePerNight)} × ${widget.nights} night${widget.nights == 1 ? '' : 's'}',
              _fmt(_baseAmount),
            ),
            const SizedBox(height: 6),
            _breakdownRow('Service fee', _fmt(_serviceFee)),
            const SizedBox(height: 6),
            _breakdownRow('VAT (7.5%)', _fmt(_vatAmount)),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFD0D8F0), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPaymentMethod == 'pay_arrival' ? 'Due now (deposit)' : 'Total',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6C757D)),
                  ),
                  Text(
                    _selectedPaymentMethod == 'pay_arrival' ? _fmt(_depositAmount) : _fmt(_totalCost),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF426DC2)),
                  ),
                ],
              ),
              Text('${widget.nights} night${widget.nights == 1 ? '' : 's'} · ${widget.guests} guest${widget.guests == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6C757D))),
            ],
          ),
          if (_selectedPaymentMethod == 'pay_arrival') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Remaining on arrival', style: TextStyle(fontSize: 13, color: Color(0xFF6C757D))),
                Text(_fmt(_remainingAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFE65100))),
              ],
            ),
          ],
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
                            if (_selectedPaymentMethod == value) return;
                            setState(() {
          _selectedPaymentMethod = value;
          _isLoadingBreakdown = true;
          _priceBreakdown = null;
                            });
                            _fetchPriceBreakdown();
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

  Widget _buildGatewayOption(String value, String label) {
    final isSelected = _selectedGateway == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGateway = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF426DC2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF426DC2) : const Color(0xFFE9ECEF),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
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
      final property = widget.propertyData;
      String? propertyId = property['uuid']?.toString();
      if (propertyId == null || propertyId.isEmpty) {
        propertyId = property['id']?.toString();
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

      // Extract room_id (UUID string — prefer selected_room_uuid, fall back to selected_room_id)
      final selectedRoomId = widget.propertyData['selected_room_uuid']?.toString()
          ?? widget.propertyData['selected_room_id']?.toString();

      // Prepare booking payload
      final bookingPayload = <String, dynamic>{
        'property_id': propertyId,
        'check_in_date': checkInDateStr,
        'check_out_date': checkOutDateStr,
        'guests': widget.guests,
        'adults': widget.adults,
        'payment_type': _selectedPaymentMethod == 'pay_arrival' ? 'pay_on_arrival' : 'full',
        'gateway': _selectedGateway,
        if (selectedRoomId != null && selectedRoomId.isNotEmpty) 'room_id': selectedRoomId,
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

          // Fields may arrive as String or num — parse either
          double? parseAmt(dynamic v) {
            if (v == null) return null;
            if (v is num) return v.toDouble();
            return double.tryParse(v.toString());
          }

          // Use breakdown from booking response — these are the exact figures Flutterwave charges
          // charge_now is the exact amount Flutterwave will charge:
          // - pay_now:    charge_now = full total (e.g. 221500)
          // - pay_arrival: charge_now = 10% deposit (e.g. 20000)
          final chargeNow = parseAmt(bookingInfo['charge_now'])
              ?? parseAmt(bookingInfo['guest_total'])
              ?? (_selectedPaymentMethod == 'pay_arrival' ? _depositAmount : _totalCost);

          final fullTotal = parseAmt(bookingInfo['guest_total']) ?? _totalCost;

          enrichedBookingData['_payment_type'] = _selectedPaymentMethod;
          enrichedBookingData['_total_cost'] = fullTotal;
          enrichedBookingData['_deposit_amount'] = chargeNow;
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
        title: const Text('Dates Not Available'),
        content: const Text(
          'These dates are already booked or temporarily held by another guest. Please go back and select different dates.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // back to date selection
            },
            child: const Text('Change Dates'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentWebView(String paymentUrl, Map<String, dynamic> bookingData, {String? reference}) async {
    if (!mounted) return;

    final paid = await showPaymentWebView(
      context: context,
      paymentUrl: paymentUrl,
      title: 'Complete Payment',
      reference: reference,
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
                        color: const Color(0xFF426DC2).withValues(alpha: 0.3),
                    ),
                  ),
                  Positioned(
                    bottom: -15,
                    left: -10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF75CFEA).withValues(alpha: 0.5),
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
                        color: const Color(0xFF426DC2).withValues(alpha: 0.4),
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
                      color: const Color(0xFF75CFEA).withValues(alpha: 0.6),
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
      return '₦${price.toStringAsFixed(0).replaceAllMapped(
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
