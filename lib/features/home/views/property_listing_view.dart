import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/location_autocomplete_field.dart';
import '../services/property_service.dart';
import 'property_listing_success_view.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digits
    String digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format with commas
    String formatted = _addCommas(digits);
    
    // Add naira symbol
    String finalText = '₦$formatted';

    return newValue.copyWith(
      text: finalText,
      selection: TextSelection.collapsed(offset: finalText.length),
    );
  }

  String _addCommas(String value) {
    String result = '';
    int counter = 0;
    
    for (int i = value.length - 1; i >= 0; i--) {
      if (counter == 3) {
        result = ',$result';
        counter = 0;
      }
      result = value[i] + result;
      counter++;
    }
    
    return result;
  }
}

class PropertyListingView extends StatefulWidget {
  const PropertyListingView({super.key});

  @override
  State<PropertyListingView> createState() => _PropertyListingViewState();
}

class _PropertyListingViewState extends State<PropertyListingView> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Property form controllers
  final TextEditingController _propertyTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _roomsController = TextEditingController();
  final TextEditingController _bathroomsController = TextEditingController();
  
  // Property type and form state
  String _selectedPropertyType = '';
  String _listingType = 'For rent'; // 'For rent' or 'For sale'
  bool _isHotelType = false;
  String _gatedStatus = '';
  String _parkingStatus = '';
  
  // Hotel amenities state
  List<String> _selectedAmenities = [];
  
  // File upload state
  List<File> _selectedImages = [];
  File? _selectedVideo;
  
  final List<Map<String, dynamic>> _hotelAmenities = [
    {'name': 'Queen-size Bed', 'svg': 'assets/icons/material-symbols_bed-outline-rounded.svg'},
    {'name': 'En-suite Bathroom', 'svg': 'assets/icons/mdi_bathroom (1).svg'},
    {'name': 'Complimentary Breakfast', 'svg': 'assets/icons/fluent_food-16-regular (1).svg'},
    {'name': 'Free High-Speed Wi-Fi', 'svg': 'assets/icons/material-symbols_wifi-rounded (1).svg'},
    {'name': 'Smart TV with Streaming', 'svg': 'assets/icons/mage_television (1).svg'},
    {'name': '24/7 Security & Keycard Access', 'svg': 'assets/icons/uil_padlock (1).svg'},
    {'name': 'Housekeeping', 'svg': 'assets/icons/healthicons_cleaning-outline (1).svg'},
    {'name': 'Wardrobe', 'svg': 'assets/icons/hugeicons_wardrobe-01.svg'},
  ];

  @override
  void initState() {
    super.initState();
    // Add listeners to text controllers to update button state
    _propertyTitleController.addListener(() => setState(() {}));
    _priceController.addListener(() => setState(() {}));
    _locationController.addListener(() => setState(() {}));
    _roomsController.addListener(() => setState(() {}));
    _bathroomsController.addListener(() => setState(() {}));
  }

  void dispose() {
    _propertyTitleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _roomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _onPropertyTypeChanged(String? newValue) {
    setState(() {
      _selectedPropertyType = newValue ?? '';
      _isHotelType = newValue == 'Hotel';
      
      // Reset form when property type changes
      _propertyTitleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _locationController.clear();
      _roomsController.clear();
      _bathroomsController.clear();
      _selectedAmenities.clear();
      _selectedImages.clear();
      _selectedVideo = null;
      _gatedStatus = '';
      _parkingStatus = '';
      
      if (_isHotelType) {
        _listingType = 'For rent'; // Hotels are always for rent
      }
    });
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
  }

  bool _isStep1Valid() {
    return _selectedPropertyType.isNotEmpty && 
           _propertyTitleController.text.isNotEmpty &&
           _priceController.text.isNotEmpty &&
           _locationController.text.isNotEmpty;
  }

  bool _isStep2Valid() {
    if (_isHotelType) {
      return _selectedAmenities.isNotEmpty;
    } else {
      return _roomsController.text.isNotEmpty &&
             _bathroomsController.text.isNotEmpty &&
             _gatedStatus.isNotEmpty &&
             _parkingStatus.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and close button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _currentStep > 0 ? _previousStep : () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildProgressBar(),
            ),

            const SizedBox(height: 32),

            // Title and subtitle
            Text(
              _currentStep == 0 
                  ? 'Tell us about your property'
                  : _currentStep == 1
                      ? (_isHotelType ? 'What will your guest get' : 'What will your tenants get')
                      : (_isHotelType ? 'Upload property' : 'Upload property'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              _currentStep == 0 
                  ? 'Let us know the type of property you want to list'
                  : _currentStep == 1
                      ? (_isHotelType ? 'Let us know what you have to offer your guest' : 'Let us know what your property has')
                      : (_isHotelType ? 'kindly upload pictures and video of your property' : 'kindly upload pictures and video of your property'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),

            // Content based on current step
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildStepContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    double progressValue = (_currentStep + 1) / _totalSteps;
    
    return Container(
      width: double.infinity,
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progressValue,
          child: Container(
            height: 9,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF426DC2),
                  Color(0xFF63ADDC),
                  Color(0xFF75CFEA),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _isHotelType ? _buildStep2Hotel() : _buildStep2Regular();
      case 2:
        return _buildStep3();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property Type Dropdown
        const Text(
          'Property type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFECF0F9),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPropertyType.isEmpty ? null : _selectedPropertyType,
              hint: const Text(
                'Select',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF868686),
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF868686),
              ),
              isExpanded: true,
              items: ['Apartment', 'Shortlet', 'Hotel'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _onPropertyTypeChanged,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Property Title
        CustomTextField(
          label: 'Property title',
          hintText: _isHotelType ? 'Enter title' : 'Enter property title',
          controller: _propertyTitleController,
        ),
        
        if (!_isHotelType) ...[
          const SizedBox(height: 24),
          
          // For Rent/For Sale Radio Buttons (only for non-hotel properties)
          Row(
            children: [
              // For rent option
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _listingType = 'For rent';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _listingType == 'For rent' 
                                  ? const Color(0xFF426DC2)
                                  : const Color(0xFF868686),
                              width: 2,
                            ),
                            color: _listingType == 'For rent' 
                                ? const Color(0xFF426DC2)
                                : Colors.transparent,
                          ),
                          child: _listingType == 'For rent'
                              ? const Center(
                                  child: Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'For rent',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 24),
              
              // For sale option
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _listingType = 'For sale';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _listingType == 'For sale' 
                                  ? const Color(0xFF426DC2)
                                  : const Color(0xFF868686),
                              width: 2,
                            ),
                            color: _listingType == 'For sale' 
                                ? const Color(0xFF426DC2)
                                : Colors.transparent,
                          ),
                          child: _listingType == 'For sale'
                              ? const Center(
                                  child: Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'For sale',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
        
        const SizedBox(height: 24),
        
        // Description
        CustomTextField(
          label: 'Description',
          hintText: 'Type description here',
          controller: _descriptionController,
          maxLines: 4,
        ),
        
        const SizedBox(height: 24),
        
        // Price
        CustomTextField(
          label: _isHotelType ? 'Price per night' : 'Price',
          hintText: _isHotelType ? 'Enter property price' : 'Enter property price',
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
        ),
        
        const SizedBox(height: 24),
        
        // Location with Google Places Autocomplete
        LocationAutocompleteField(
          label: 'Location',
          hintText: 'Enter property location',
          controller: _locationController,
                              apiKey: 'AIzaSyDLvqz3w_9ASjj--fmcfBz9CH7S_R1gZnM',
          onLocationSelected: () {
            // Optional: Add any additional logic when location is selected
            print('📍 Location selected: ${_locationController.text}');
          },
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Next',
          onPressed: _isStep1Valid() ? _nextStep : null,
          isEnabled: _isStep1Valid(),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep2Hotel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hotel Amenities Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: _hotelAmenities.length,
          itemBuilder: (context, index) {
            final amenity = _hotelAmenities[index];
            final isSelected = _selectedAmenities.contains(amenity['name']);
            
            return GestureDetector(
              onTap: () => _toggleAmenity(amenity['name']),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFFECF0F9)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF426DC2)
                        : const Color(0xFFE0E0E0),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      amenity['svg'],
                      width: 32,
                      height: 32,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.hotel,
                          size: 32,
                          color: Colors.black,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      amenity['name'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Next',
          onPressed: _isStep2Valid() ? _nextStep : null,
          isEnabled: _isStep2Valid(),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep2Regular() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'How many rooms',
          hintText: 'Enter number of rooms',
          controller: _roomsController,
          keyboardType: TextInputType.number,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset(
              'assets/icons/material-symbols_bed-outline-rounded.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.bed,
                  color: Colors.black,
                  size: 20,
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        CustomTextField(
          label: 'How many bathrooms',
          hintText: 'Enter number of bathrooms',
          controller: _bathroomsController,
          keyboardType: TextInputType.number,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset(
              'assets/icons/mdi_bathroom.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.bathroom,
                  color: Colors.black,
                  size: 20,
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Gated dropdown
        const Text(
          'Gated or not',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFECF0F9),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: SvgPicture.asset(
                  'assets/icons/game-icons_gate.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.security,
                      color: Colors.black,
                      size: 20,
                    );
                  },
                ),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _gatedStatus.isEmpty ? null : _gatedStatus,
                    hint: const Text(
                      'Select',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF868686),
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF868686),
                    ),
                    isExpanded: true,
                    items: ['Yes', 'No'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _gatedStatus = newValue ?? '';
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Parking dropdown
        const Text(
          'Does it have parking space',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFECF0F9),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: SvgPicture.asset(
                  'assets/icons/tabler_car.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.local_parking,
                      color: Colors.black,
                      size: 20,
                    );
                  },
                ),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _parkingStatus.isEmpty ? null : _parkingStatus,
                    hint: const Text(
                      'Select',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF868686),
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF868686),
                    ),
                    isExpanded: true,
                    items: ['Yes', 'No'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _parkingStatus = newValue ?? '';
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Next',
          onPressed: _isStep2Valid() ? _nextStep : null,
          isEnabled: _isStep2Valid(),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep3() {
    if (_isHotelType) {
      return _buildStep3Hotel();
    } else {
      return _buildStep3Regular();
    }
  }

  Widget _buildStep3Hotel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload hotel images${_selectedImages.isNotEmpty ? ' (${_selectedImages.length} selected)' : ''}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        _buildFileUploadArea('hotel_images'),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Next',
          onPressed: _submitListing,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep3Regular() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload images${_selectedImages.isNotEmpty ? ' (${_selectedImages.length} selected)' : ''}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        _buildFileUploadArea('images'),
        
        const SizedBox(height: 32),
        
        const Text(
          'Upload property video or 360 degree view',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        _buildFileUploadArea('video'),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Submit',
          onPressed: _submitListing,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFileUploadArea(String type) {
    final hasFiles = type == 'images' || type == 'hotel_images' 
        ? _selectedImages.isNotEmpty 
        : _selectedVideo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasFiles) ...[
          // Show selected files
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == 'images' || type == 'hotel_images'
                      ? 'Selected Images (${_selectedImages.length})'
                      : 'Selected Video',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                if (type == 'images' || type == 'hotel_images') ...[
                  ..._selectedImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.image,
                            size: 16,
                            color: Color(0xFF426DC2),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file.path.split('/').last,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ] else if (_selectedVideo != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.video_file,
                        size: 16,
                        color: Color(0xFF426DC2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedVideo!.path.split('/').last,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedVideo = null;
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Upload area
        GestureDetector(
      onTap: () => _pickFile(type),
      child: DottedBorder(
        color: const Color(0xFFD0D0D0),
        strokeWidth: 1.5,
        dashPattern: const [6, 3],
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        child: Container(
          width: double.infinity,
          height: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/cloud-add.svg',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.cloud_upload_outlined,
                    size: 32,
                    color: Color(0xFF868686),
                  );
                },
              ),
              
              const SizedBox(height: 12),
              
              const Text(
                'Choose a file or drag & drop it here',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                type == 'hotel_images'
                    ? 'JPEG, PNG, PDF, and MP4 formats, up to 50MB'
                    : type == 'images' 
                        ? 'JPEG, PNG, PDF, and MP4 formats, up to 50MB'
                        : 'JPEG, PNG, PDF, and MP4 formats, up to 50MB',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                ),
              ),
              
              const SizedBox(height: 12),
              
              GestureDetector(
                onTap: () => _pickFile(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromRGBO(176, 181, 187, 1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Browse File',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(84, 87, 92, 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ],
    );
  }

  Future<void> _pickFile(String fileType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: (fileType == 'images' || fileType == 'hotel_images')
            ? ['jpg', 'jpeg', 'png']
            : ['mp4', 'mov', 'avi'],
        allowMultiple: (fileType == 'images' || fileType == 'hotel_images'),
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          if (fileType == 'images' || fileType == 'hotel_images') {
            // Add images to the list
            for (var file in result.files) {
              if (file.path != null) {
                _selectedImages.add(File(file.path!));
              }
            }
          } else if (fileType == 'video') {
            // Set video file
            if (result.files.first.path != null) {
              _selectedVideo = File(result.files.first.path!);
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.length} file(s) selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitListing() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF426DC2)),
          ),
        );
      },
    );

    try {
      // Validate required fields
      if (_selectedPropertyType.isEmpty ||
          _propertyTitleController.text.isEmpty ||
          _descriptionController.text.isEmpty ||
          _priceController.text.isEmpty ||
          _locationController.text.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog('Please fill in all required fields');
        return;
      }

      // Validate step 2 fields based on property type
      if (!_isHotelType) {
        if (_roomsController.text.isEmpty ||
            _bathroomsController.text.isEmpty ||
            _gatedStatus.isEmpty ||
            _parkingStatus.isEmpty) {
          Navigator.of(context).pop(); // Close loading dialog
          _showErrorDialog('Please fill in all required fields');
          return;
        }
      }

      // Validate images
      if (_selectedImages.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog('Please upload at least one image');
        return;
      }

      // Validate image formats
      for (final image in _selectedImages) {
        final extension = image.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          Navigator.of(context).pop(); // Close loading dialog
          _showErrorDialog('Please upload only JPG, JPEG, or PNG images');
          return;
        }
      }

      // Show processing message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing images... This may take a moment.'),
          duration: Duration(seconds: 2),
        ),
      );

      // Prepare features list
      List<String> features = [];
      if (_isHotelType) {
        features = _selectedAmenities;
      } else {
        // For regular properties, add basic features based on form data
        if (_gatedStatus.toLowerCase() == 'yes') {
          features.add('Gated & Secured Estate');
        }
        if (_parkingStatus.toLowerCase() == 'yes') {
          features.add('Dedicated Parking');
        }
        features.add('${_roomsController.text}-bedroom');
        features.add('${_bathroomsController.text} Bathrooms');
      }

      // Clean price (remove currency symbols and commas)
      String cleanPrice = _priceController.text.replaceAll(RegExp(r'[^\d]'), '');

      // Create property using the service
      final propertyService = PropertyService();
      final result = await propertyService.createProperty(
        type: _selectedPropertyType,
        title: _propertyTitleController.text,
        description: _descriptionController.text,
        price: cleanPrice,
        category: _listingType,
        location: _locationController.text,
        bedrooms: _roomsController.text,
        bathrooms: _bathroomsController.text,
        gated: _gatedStatus,
        parking: _parkingStatus,
        features: features,
        images: _selectedImages,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (result != null) {
        // Success - navigate to success screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PropertyListingSuccessView(),
      ),
    );
      } else {
        // Error - show more specific error message
        _showErrorDialog('Failed to create property. Please ensure:\n\n• Images are in JPG, JPEG, or PNG format\n• Images have reasonable dimensions (300px minimum)\n• All required fields are filled\n• Images are not corrupted or invalid\n\nPlease try with a different image.');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
} 