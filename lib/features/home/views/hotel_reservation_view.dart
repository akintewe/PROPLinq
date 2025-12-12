import 'package:flutter/material.dart';
import 'package:proplinq/core/services/api_service.dart';
import 'package:proplinq/core/constants/api_constants.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'dart:convert';

class HotelReservationView extends StatefulWidget {
  final Map<String, dynamic> propertyData;
  
  const HotelReservationView({super.key, required this.propertyData});

  @override
  State<HotelReservationView> createState() => _HotelReservationViewState();
}

class _HotelReservationViewState extends State<HotelReservationView> {
  int _nights = 2;
  int _guests = 1;
  int _adults = 1;
  DateTime _checkInDate = DateTime(2025, 8, 25);
  DateTime _checkOutDate = DateTime(2025, 8, 25);
  DateTime _currentMonth = DateTime(2025, 8, 1);
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = 25;
    _updateCheckOutDate();
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
                    setState(() {
                      _checkOutDate = pickedDate;
                      _nights = _checkOutDate.difference(_checkInDate).inDays;
                    });
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
          
          // Calendar grid
          _buildCalendarGrid(),
        ],
      ),
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
      final isSelected = day == _selectedDay && 
                        _currentMonth.month == _checkInDate.month && 
                        _currentMonth.year == _checkInDate.year;
      final isToday = day == DateTime.now().day && 
                     _currentMonth.month == DateTime.now().month && 
                     _currentMonth.year == DateTime.now().year;
      
      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = day;
              _checkInDate = DateTime(_currentMonth.year, _currentMonth.month, day);
              _updateCheckOutDate();
            });
          },
          child: Container(
            height: 40,
                  decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF426DC2)
                  : isToday 
                      ? const Color(0xFFE3F2FD)
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                day.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? Colors.white 
                      : isToday 
                          ? const Color(0xFF426DC2)
                          : Colors.black,
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
              _showPaymentScreen();
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
                    'Continue',
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
  final ApiService _apiService = ApiService();

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
                    // Payment options
                    _buildPaymentOption(
                      'pay_now',
                      'Pay Now (Recommended)',
                      'Secure your booking by paying the full amount now.Your\nbooking is 100% guaranteed',
                      true,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildPaymentOption(
                      'pay_arrival',
                      'Pay on Arrival',
                      'Pay 10% deposit now to secure your booking. The\nremaining 90% will be paid directly at the hotel/shortlet',
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
                        : const Text(
                            'Pay now',
                            style: TextStyle(
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

      // Prepare booking payload
      final bookingPayload = {
        'property_id': propertyId is int ? propertyId : int.tryParse(propertyId.toString()) ?? 0,
        'check_in_date': checkInDateStr,
        'check_out_date': checkOutDateStr,
        'guests': widget.guests,
        'adults': widget.adults,
        'special_requests': _selectedPaymentMethod == 'pay_arrival' 
            ? 'Pay on arrival - 10% deposit paid' 
            : null,
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
        
        final errorMessage = response.message ?? 'Failed to create booking';
        print('❌ Booking failed: $errorMessage');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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

  Future<void> _showPaymentWebView(String paymentUrl, Map<String, dynamic> bookingData) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentWebViewDialog(
        paymentUrl: paymentUrl,
        onPaymentComplete: () {
          // Close the dialog
          Navigator.of(context).pop();
          // Navigate to success view with booking data
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HotelBookingSuccessView(
                  bookingData: bookingData,
                  propertyData: widget.propertyData,
                ),
              ),
            );
          }
        },
        onPaymentCancelled: () {
          // Close the dialog only, stay on payment screen
          Navigator.of(context).pop();
        },
      ),
    );
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
              
              const SizedBox(height: 32),
              
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
}

/// Payment WebView Dialog for handling Flutterwave payment
class PaymentWebViewDialog extends StatefulWidget {
  final String paymentUrl;
  final VoidCallback onPaymentComplete;
  final VoidCallback onPaymentCancelled;

  const PaymentWebViewDialog({
    super.key,
    required this.paymentUrl,
    required this.onPaymentComplete,
    required this.onPaymentCancelled,
  });

  @override
  State<PaymentWebViewDialog> createState() => _PaymentWebViewDialogState();
}

class _PaymentWebViewDialogState extends State<PaymentWebViewDialog> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('🔗 Payment WebView: Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('✅ Payment WebView: Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
            
            // Check if payment is successful based on URL patterns
            _checkPaymentStatus(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ Payment WebView: Error loading page: ${error.description}');
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentStatus(String url) {
    print('🔍 Checking payment status from URL: $url');
    
    // Check for Flutterwave success indicators
    // Common patterns: success, callback, status=successful, tx_ref, etc.
    final lowerUrl = url.toLowerCase();
    
    if (lowerUrl.contains('callback') || 
        lowerUrl.contains('success') || 
        lowerUrl.contains('status=successful') ||
        lowerUrl.contains('transaction_id') ||
        lowerUrl.contains('tx_ref')) {
      
      // Check if it's actually a success (not just callback page)
      if (lowerUrl.contains('success') || 
          lowerUrl.contains('status=successful') ||
          lowerUrl.contains('transaction_id=')) {
        print('✅ Payment successful detected!');
        
        // Wait a moment to ensure page is fully loaded
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            widget.onPaymentComplete();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Complete Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        // Show confirmation before closing
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Cancel Payment?'),
                            content: const Text(
                              'Are you sure you want to cancel this payment?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  widget.onPaymentCancelled();
                                },
                                child: const Text('Yes, Cancel'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // WebView
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      Container(
                        color: Colors.white,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF426DC2),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading payment page...',
                                style: TextStyle(
                                  color: Color(0xFF6C757D),
                                ),
                              ),
                            ],
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
                    _buildDetailRow('Booking code', bookingCode),
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
