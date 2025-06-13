import 'package:flutter/material.dart';
import 'gradient_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FilterBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersApplied;

  const FilterBottomSheet({
    super.key,
    required this.onFiltersApplied,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();

  static void show(
    BuildContext context, {
    required Function(Map<String, dynamic>) onFiltersApplied,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        onFiltersApplied: onFiltersApplied,
      ),
    );
  }
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _selectedRating = 'All';
  String _fromPrice = '';
  String _toPrice = '';
  String _location = '';

  final TextEditingController _fromPriceController = TextEditingController();
  final TextEditingController _toPriceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _fromPriceController.dispose();
    _toPriceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedStatus = 'All';
      _selectedRating = 'All';
      _fromPrice = '';
      _toPrice = '';
      _location = '';
      _fromPriceController.clear();
      _toPriceController.clear();
      _locationController.clear();
    });
  }

  void _applyFilters() {
    final filters = {
      'category': _selectedCategory,
      'status': _selectedStatus,
      'rating': _selectedRating,
      'fromPrice': _fromPrice,
      'toPrice': _toPrice,
      'location': _location,
    };
    
    widget.onFiltersApplied(filters);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories
                  _buildSectionTitle('Categories'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildCategoryChip('All', _selectedCategory == 'All'),
                      _buildCategoryChip('Real Estate', _selectedCategory == 'Real Estate'),
                      _buildCategoryChip('Hotels', _selectedCategory == 'Hotels'),
                      _buildCategoryChip('Shortlets', _selectedCategory == 'Shortlets'),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Price Range
                  _buildSectionTitle('Price range'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'From',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFF426DC2),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _fromPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF868686),
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _fromPrice = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 20,
                        height: 1,
                        color: const Color(0xFF426DC2),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'To',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFF426DC2),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _toPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF868686),
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _toPrice = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Status
                  _buildSectionTitle('Status'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatusChip('All', _selectedStatus == 'All'),
                      _buildStatusChip('For sale', _selectedStatus == 'For sale'),
                      _buildStatusChip('For rent', _selectedStatus == 'For rent'),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Location
                  _buildSectionTitle('Location'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF426DC2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/location.svg',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              hintText: 'Enter location',
                              hintStyle: TextStyle(
                                color: Color(0xFF868686),
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _location = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Rating
                  _buildSectionTitle('Rating'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildRatingChip('All', _selectedRating == 'All'),
                      _buildRatingChip('5.0', _selectedRating == '5.0'),
                      _buildRatingChip('4.0', _selectedRating == '4.0'),
                      _buildRatingChip('3.0', _selectedRating == '3.0'),
                      _buildRatingChip('2.0', _selectedRating == '2.0'),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Color(0xFFF0F0F0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _resetFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GradientButton(
                    text: 'Apply',
                    onPressed: _applyFilters,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildCategoryChip(String title, bool isSelected) {
    String? svgAsset;
    Color? iconColor;
    switch (title) {
      case 'Real Estate':
        svgAsset = 'assets/icons/emojione_houses.svg';
       // blue
        break;
      case 'Hotels':
        svgAsset = 'assets/icons/emojione_houses.svg'; 
      
        break;
      case 'Shortlets':
        svgAsset = 'assets/icons/emojione_houses.svg'; // placeholder, replace with correct shortlet SVG if available
     
        break;
      default:
        svgAsset = null;
        iconColor = null;
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF426DC2),
                    Color(0xFF63ADDC),
                    Color(0xFF75CFEA),
                  ],
                  stops: [0.0, 1.0, 1.0],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFF426DC2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset,
                width: 16,
                height: 16,
              ),
            if (svgAsset != null) const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF426DC2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF426DC2),
                    Color(0xFF63ADDC),
                    Color(0xFF75CFEA),
                  ],
                  stops: [0.0, 1.0, 1.0],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFF426DC2),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF426DC2),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingChip(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRating = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF426DC2),
                    Color(0xFF63ADDC),
                    Color(0xFF75CFEA),
                  ],
                  stops: [0.0, 1.0, 1.0],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFF4CAF50),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 