import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:proplinq/core/constants/app_dimensions.dart';
import 'package:proplinq/core/constants/app_typography.dart';

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
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 3));

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(widget.propertyData['price'] as String) ?? 0.0;
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
                    
                    const SizedBox(height: 32),
                    
                    // Calendar
                    _buildCalendar(),
                    
                    const SizedBox(height: 32),
                    
                    // Guest Selection
                    _buildGuestSelection(),
                    
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
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
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
                fontSize: 20,
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
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFF426DC2),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndQuantity(double price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Price
          Expanded(
            child: Text(
              '₦${_formatPrice(price)}/night',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          
          // Quantity selector
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_nights > 1) {
                    setState(() {
                      _nights--;
                      _checkOutDate = _checkInDate.add(Duration(days: _nights));
                    });
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 16,
                    color: Color(0xFF426DC2),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Text(
                '$_nights',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(width: 16),
              
              GestureDetector(
                onTap: () {
                  setState(() {
                    _nights++;
                    _checkOutDate = _checkInDate.add(Duration(days: _nights));
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: Color(0xFF426DC2),
                  ),
                ),
              ),
            ],
          ),
        ],
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
            // Check-in
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF426DC2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF426DC2),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Check-in',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF868686),
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
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF868686),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Check-out',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF868686),
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
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Calendar header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.arrow_back_ios, size: 16),
              Row(
                children: [
                  const Text(
                    'August 2025',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Days of week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('Mon', style: TextStyle(fontSize: 12, color: Color(0xFF868686))),
              Text('Tue', style: TextStyle(fontSize: 12, color: Color(0xFF868686))),
              Text('Wed', style: TextStyle(fontSize: 12, color: Color(0xFF868686))),
              Text('Thur', style: TextStyle(fontSize: 12, color: Color(0xFF868686))),
              Text('Fri', style: TextStyle(fontSize: 12, color: Color(0xFF868686))),
              Text('Sat', style: TextStyle(fontSize: 12, color: Color(0xFF868686))),
              Text('Sun', style: TextStyle(fontSize: 12, color: Color(0xFF868686))),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Calendar grid (simplified)
          Container(
            height: 200,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: 35,
              itemBuilder: (context, index) {
                final day = index - 3; // Adjust for calendar offset
                final isSelected = day == 25; // Highlight day 25
                final isCurrentMonth = day > 0 && day <= 31;
                
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF426DC2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      day > 0 ? day.toString() : '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? Colors.white 
                            : isCurrentMonth 
                                ? Colors.black 
                                : Colors.grey[400],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
        Row(
          children: [
            const Expanded(
              child: Text(
                'Guests',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_guests > 1) {
                      setState(() {
                        _guests--;
                        if (_adults > _guests) _adults = _guests;
                      });
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: Color(0xFF426DC2),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Text(
                  '$_guests',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _guests++;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Color(0xFF426DC2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Adults
        Row(
          children: [
            const Expanded(
              child: Text(
                'Adults',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_adults > 1) {
                      setState(() {
                        _adults--;
                      });
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: Color(0xFF426DC2),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Text(
                  '$_adults',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                GestureDetector(
                  onTap: () {
                    if (_adults < _guests) {
                      setState(() {
                        _adults++;
                      });
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Color(0xFF426DC2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButton(double totalCost) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total cost
          Row(
            children: [
              const Text(
                'Total cost/night',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF868686),
                ),
              ),
              const Spacer(),
              Text(
                '₦${_formatPrice(totalCost)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF426DC2),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _showPaymentScreen();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
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
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: Text(
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
          ),
        ],
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
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
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
                        fontSize: 20,
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
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF426DC2),
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
                  children: [
                    // Payment options
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pay Now option
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = 'pay_now';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedPaymentMethod == 'pay_now' 
                                    ? const Color(0xFF426DC2) 
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                    Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedPaymentMethod == 'pay_now' 
                                        ? const Color(0xFF426DC2) 
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _selectedPaymentMethod == 'pay_now' 
                                          ? const Color(0xFF426DC2) 
                                          : Colors.grey[400]!,
                                    ),
                                  ),
                                  child: _selectedPaymentMethod == 'pay_now'
                                      ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                
                                const SizedBox(width: 16),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pay Now (Recommended)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Secure your booking by paying now',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF868686),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Pay on Arrival option
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethod = 'pay_arrival';
                            });
                          },
                          child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedPaymentMethod == 'pay_arrival' 
                                    ? const Color(0xFF426DC2) 
                                    : Colors.grey[300]!,
                              ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedPaymentMethod == 'pay_arrival' 
                                        ? const Color(0xFF426DC2) 
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _selectedPaymentMethod == 'pay_arrival' 
                                          ? const Color(0xFF426DC2) 
                                          : Colors.grey[400]!,
                                    ),
                                  ),
                                  child: _selectedPaymentMethod == 'pay_arrival'
                                      ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        )
                                      : null,
                          ),
                                
                          const SizedBox(width: 16),
                                
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                      const Text(
                                        'Pay on Arrival',
                                        style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                      const Text(
                                        'Pay full amount when you arrive',
                                        style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF868686),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                          ),
                        ),
                      ],
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
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _showBookingSuccess();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
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
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Text(
                        'Book now',
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
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HotelBookingSuccessView(),
      ),
    );
  }
}

class HotelBookingSuccessView extends StatelessWidget {
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
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF426DC2),
                      size: 20,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Success icon with gradient and decorative elements
              Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative circles
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -15,
                    left: -15,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF75CFEA).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: -20,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
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
              
              const SizedBox(height: 24),
              
              // Success message
              const Text(
                'Booking Successful',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 12),
              
              const Text(
                'Thanks for booking with us! Your appointment has been successfully scheduled.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF868686),
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
                        'Your booking will be cancelled after 48hrs of your checking date if you don\'t show up',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1976D2),
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
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
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
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: Text(
                            'Confirm availability',
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
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: const BorderSide(color: Color(0xFF426DC2)),
                        ),
                      ),
                      child: const Text(
                        'Report an issue',
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