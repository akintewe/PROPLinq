import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proplinq/core/constants/app_colors.dart';

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
                    onPressed: () {
                      _showBookingSuccess();
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

  void _showBookingSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HotelBookingSuccessView(),
      ),
    );
  }
}

class HotelBookingSuccessView extends StatelessWidget {
  const HotelBookingSuccessView({super.key});

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
                        onPressed: () {},
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