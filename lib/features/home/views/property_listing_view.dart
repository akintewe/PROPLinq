import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/location_autocomplete_field.dart';
import '../services/property_service.dart';
import '../services/hotel_service.dart';
import '../models/room_model.dart';
import '../../../core/utils/csv_utils.dart';
import 'property_listing_success_view.dart';
import '../../auth/services/auth_service.dart';
import '../../finance/views/agent_kyc_view.dart';
import '../../finance/views/complete_kyc_view.dart';

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
  bool _isShortletType = false;
  String _gatedStatus = '';
  String _parkingStatus = '';
  
  // Hotel amenities state
  List<String> _selectedAmenities = [];

  // Hotel rooms state
  List<RoomModel> _hotelRooms = [];
  String? _roomsCsvPath; // Path to uploaded CSV file for rooms

  // Room form controllers for manual entry
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomTypeController = TextEditingController();
  final TextEditingController _roomPriceController = TextEditingController();
  final TextEditingController _roomCapacityController = TextEditingController();
  final TextEditingController _roomCountController = TextEditingController();
  final TextEditingController _roomFeaturesController = TextEditingController();

  // File upload state
  List<File> _selectedImages = [];
  List<File> _selected360Images = [];
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
    _roomNameController.dispose();
    _roomTypeController.dispose();
    _roomPriceController.dispose();
    _roomCapacityController.dispose();
    _roomCountController.dispose();
    _roomFeaturesController.dispose();
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
      _isShortletType = newValue == 'Shortlet';
      
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
      
      if (_isHotelType || _isShortletType) {
        _listingType = 'For rent'; // Hotels and shortlets are always for rent
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
      // Hotels need amenities AND rooms
      return _selectedAmenities.isNotEmpty && _hotelRooms.isNotEmpty;
    } else if (_isShortletType) {
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
                      ? ((_isHotelType || _isShortletType) ? 'What will your guest get' : 'What will your tenants get')
                      : ((_isHotelType || _isShortletType) ? 'Upload property' : 'Upload property'),
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
                      ? ((_isHotelType || _isShortletType) ? 'Let us know what you have to offer your guest' : 'Let us know what your property has')
                      : ((_isHotelType || _isShortletType) ? 'kindly upload pictures and video of your property' : 'kindly upload pictures and video of your property'),
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
        return (_isHotelType || _isShortletType) ? _buildStep2Hotel() : _buildStep2Regular();
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
          hintText: (_isHotelType || _isShortletType) ? 'Enter title' : 'Enter property title',
          controller: _propertyTitleController,
        ),
        
        if (!_isHotelType && !_isShortletType) ...[
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
          label: (_isHotelType || _isShortletType) ? 'Price per night' : 'Price',
          hintText: (_isHotelType || _isShortletType) ? 'Enter property price' : 'Enter property price',
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
                              apiKey: 'AIzaSyAtLvjrEcosVTq266ARbO2KBFN_9RSyobQ',
          onLocationSelected: (location) {
            // Optional: Add any additional logic when location is selected
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
        // Hotel Amenities Section
        const Text(
          'Hotel Amenities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),

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

        // Divider
        const Divider(height: 1, color: Color(0xFFE0E0E0)),

        const SizedBox(height: 40),

        // Hotel Rooms Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hotel Rooms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _hotelRooms.isNotEmpty ? const Color(0xFF426DC2) : const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_hotelRooms.length} ${_hotelRooms.length == 1 ? 'room' : 'rooms'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hotelRooms.isNotEmpty ? Colors.white : const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Rooms List
        if (_hotelRooms.isNotEmpty) ...[
          ..._hotelRooms.asMap().entries.map((entry) {
            final index = entry.key;
            final room = entry.value;
            return _buildRoomCard(room, index);
          }).toList(),
          const SizedBox(height: 16),
        ],

        // Add Room Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showAddRoomDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Room Manually'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF426DC2),
                  side: const BorderSide(color: Color(0xFF426DC2)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploadCsvFile,
                icon: const Icon(Icons.upload_file, size: 20),
                label: const Text('Upload CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF426DC2),
                  side: const BorderSide(color: Color(0xFF426DC2)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Download Sample CSV Button
        Center(
          child: TextButton.icon(
            onPressed: _downloadSampleCsv,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download Sample CSV'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF426DC2),
            ),
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

  Widget _buildRoomCard(RoomModel room, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _hotelRooms.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${room.type} • Price: ₦${room.price.toStringAsFixed(2)}/night',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Capacity: ${room.capacity} • Available: ${room.count}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          if (room.features.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: room.features.map((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF426DC2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF426DC2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddRoomDialog() {
    // Clear controllers
    _roomNameController.clear();
    _roomTypeController.clear();
    _roomPriceController.clear();
    _roomCapacityController.clear();
    _roomCountController.clear();
    _roomFeaturesController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Add Room',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Room Name',
                  hintText: 'e.g., Deluxe Suite',
                  controller: _roomNameController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Room Type',
                  hintText: 'e.g., Suite, Single, Double',
                  controller: _roomTypeController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Price per Night (₦)',
                  hintText: 'Enter price',
                  controller: _roomPriceController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Capacity',
                  hintText: 'Number of guests',
                  controller: _roomCapacityController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Number of Rooms Available',
                  hintText: 'e.g., 5',
                  controller: _roomCountController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Features (comma-separated)',
                  hintText: 'e.g., wifi, ac, balcony',
                  controller: _roomFeaturesController,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addRoomManually();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF426DC2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Room'),
            ),
          ],
        );
      },
    );
  }

  void _addRoomManually() {
    try {
      // Validate fields
      if (_roomNameController.text.trim().isEmpty ||
          _roomTypeController.text.trim().isEmpty ||
          _roomPriceController.text.trim().isEmpty ||
          _roomCapacityController.text.trim().isEmpty ||
          _roomCountController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Parse features
      final featuresText = _roomFeaturesController.text.trim();
      final features = featuresText.isNotEmpty
          ? featuresText.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList()
          : <String>[];

      // Create room
      final room = RoomModel(
        name: _roomNameController.text.trim(),
        type: _roomTypeController.text.trim(),
        price: double.parse(_roomPriceController.text.trim()),
        capacity: int.parse(_roomCapacityController.text.trim()),
        count: int.parse(_roomCountController.text.trim()),
        features: features,
      );

      setState(() {
        _hotelRooms.add(room);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding room: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read file'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Parse CSV
      final rows = await CsvUtils.parseCsvFile(file.path!);

      if (rows.isEmpty || rows.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV file is empty or invalid'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Skip header row and parse rooms
      final newRooms = <RoomModel>[];
      for (int i = 1; i < rows.length; i++) {
        try {
          final room = RoomModel.fromCsvRow(rows[i]);
          newRooms.add(room);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error parsing row ${i + 1}: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (newRooms.isNotEmpty) {
        setState(() {
          _hotelRooms.addAll(newRooms);
          _roomsCsvPath = file.path; // Store CSV path for submission
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newRooms.length} room(s) imported from CSV!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadSampleCsv() async {
    try {
      await CsvUtils.downloadRoomsSampleCsv();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample CSV ready to share!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading sample: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    if (_isHotelType || _isShortletType) {
      return _buildStep3Hotel();
    } else {
      return _buildStep3Regular();
    }
  }

  Widget _buildStep3Hotel() {
    final String labelText = _isShortletType 
        ? 'Upload shortlet images${_selectedImages.isNotEmpty ? ' (${_selectedImages.length} selected)' : ''} (Max 10 images)'
        : 'Upload hotel images${_selectedImages.isNotEmpty ? ' (${_selectedImages.length} selected)' : ''} (Max 10 images)';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
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
        // Section 1: Regular Property Images
        _buildMediaSection(
          title: 'Property Images',
          subtitle: 'Upload photos of your property (bedrooms, living areas, exterior, etc.)',
          count: _selectedImages.length,
          maxCount: 10,
          type: 'images',
        ),
        
        const SizedBox(height: 40),
        
        // Section 2: 360 Panorama Images
        _buildMediaSection(
          title: '360° Panorama Images',
          subtitle: 'Upload 360-degree panoramic images for virtual tour',
          count: _selected360Images.length,
          maxCount: 5,
          type: '360_images',
        ),
        
        const SizedBox(height: 40),
        
        // Section 3: Property Video
        _buildMediaSection(
          title: 'Property Video',
          subtitle: 'Upload a video showcasing your property (optional)',
          count: _selectedVideo != null ? 1 : 0,
          maxCount: 1,
          type: 'video',
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Submit',
          onPressed: _submitListing,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildMediaSection({
    required String title,
    required String subtitle,
    required int count,
    required int maxCount,
    required String type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: count > 0 ? const Color(0xFF426DC2) : const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count/$maxCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: count > 0 ? Colors.white : const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // File Upload Area
        _buildFileUploadArea(type),
      ],
    );
  }

  Widget _buildFileUploadArea(String type) {
    final hasFiles = type == 'images' || type == 'hotel_images' 
        ? _selectedImages.isNotEmpty 
        : type == '360_images'
            ? _selected360Images.isNotEmpty
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
                      : type == '360_images'
                          ? 'Selected 360° Images (${_selected360Images.length})'
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
                  
                  // Add More Images button for images
                  if ((type == 'images' || type == 'hotel_images') && _selectedImages.length < 10) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _pickFile(type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF426DC2),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add,
                              size: 16,
                              color: Color(0xFF426DC2),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Add More Images (${10 - _selectedImages.length} remaining)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF426DC2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ] else if (type == '360_images') ...[
                  ..._selected360Images.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.threesixty,
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
                                _selected360Images.removeAt(index);
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
                  
                  // Add More 360 Images button
                  if (_selected360Images.length < 5) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _pickFile(type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF426DC2),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add,
                              size: 16,
                              color: Color(0xFF426DC2),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Add More 360° Images (${5 - _selected360Images.length} remaining)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF426DC2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              
              const SizedBox(height: 8),
              
              Text(
                (type == 'images' || type == 'hotel_images') 
                    ? 'Choose multiple images'
                    : type == '360_images'
                        ? 'Choose multiple 360° images'
                        : 'Choose a file',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 4),
              
              Text(
                type == 'hotel_images'
                    ? 'JPEG, PNG formats'
                    : type == 'images' 
                        ? 'JPEG, PNG formats'
                        : type == '360_images'
                            ? 'JPEG, PNG formats (360° images)'
                            : 'MP4, MOV, AVI formats',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              GestureDetector(
                onTap: () => _pickFile(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromRGBO(176, 181, 187, 1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (type == 'images' || type == 'hotel_images') 
                        ? 'Browse Images'
                        : type == '360_images'
                            ? 'Browse 360° Images'
                            : 'Browse Video',
                    style: const TextStyle(
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
      // Show bottom sheet for image/video source selection
      if (fileType == 'images' || fileType == 'hotel_images' || fileType == '360_images' || fileType == 'video') {
        final ImageSource? source = await _showImageSourceBottomSheet(fileType == 'video');
        if (source == null) return; // User cancelled

        final ImagePicker picker = ImagePicker();
        
        if (fileType == 'video') {
          // Pick video from selected source
          final XFile? pickedVideo = await picker.pickVideo(source: source);

          if (pickedVideo != null) {
            setState(() {
              _selectedVideo = File(pickedVideo.path);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video selected successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Pick images - only gallery allows multiple selection
          List<XFile> pickedFiles = [];
          
          if (source == ImageSource.gallery) {
            // Gallery - multiple selection
            pickedFiles = await picker.pickMultiImage();
          } else {
            // Camera - single image
            final XFile? image = await picker.pickImage(source: source);
            if (image != null) {
              pickedFiles = [image];
            }
          }

          if (pickedFiles.isNotEmpty) {
        setState(() {
          if (fileType == 'images' || fileType == 'hotel_images') {
            // Check if adding these files would exceed the limit
                final totalImages = _selectedImages.length + pickedFiles.length;
            if (totalImages > 10) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maximum 10 images allowed. Please select fewer images.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            
            // Add images to the list
                for (var file in pickedFiles) {
                  _selectedImages.add(File(file.path));
            }
          } else if (fileType == '360_images') {
            // Check if adding these files would exceed the limit
                final total360Images = _selected360Images.length + pickedFiles.length;
            if (total360Images > 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maximum 5 360° images allowed. Please select fewer images.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            
            // Add 360 images to the list
                for (var file in pickedFiles) {
                  _selected360Images.add(File(file.path));
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                content: Text('${pickedFiles.length} image(s) selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
          }
        }
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

  Future<ImageSource?> _showImageSourceBottomSheet(bool isVideo) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVideo ? 'Select Video Source' : 'Select Image Source',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            
            // Gallery Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF426DC2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF426DC2),
                ),
              ),
              title: Text(
                isVideo ? 'Choose from Gallery' : 'Choose from Gallery',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isVideo ? 'Select a video from your device' : 'Select multiple images from your device',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF868686),
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            
            const SizedBox(height: 12),
            
            // Camera Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF426DC2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF426DC2),
                ),
              ),
              title: Text(
                isVideo ? 'Record Video' : 'Take Photo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isVideo ? 'Record a new video' : 'Take a new photo with camera',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF868686),
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            
            const SizedBox(height: 12),
            
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF868686),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      if (!_isHotelType && !_isShortletType) {
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
      if (_isHotelType || _isShortletType) {
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

      // Create property/hotel using the appropriate service
      dynamic response;

      if (_isHotelType) {
        // Use HotelService for hotels
        final hotelService = HotelService();

        // Prepare hotel fields
        final Map<String, String> hotelFields = {
          'type': _selectedPropertyType.toLowerCase(),
          'title': _propertyTitleController.text,
          'description': _descriptionController.text,
          'price': cleanPrice,
          'category': _selectedPropertyType.toLowerCase(),
          'location': _locationController.text,
          'bedrooms': '1',
          'bathrooms': '1',
          'gated': '0',
          'parking': '0',
        };

        // Add features as indexed fields
        for (int i = 0; i < features.length; i++) {
          hotelFields['features[$i]'] = features[i];
        }

        // Prepare image files
        final Map<String, File> hotelFiles = {};
        for (int i = 0; i < _selectedImages.length; i++) {
          hotelFiles['images[$i]'] = _selectedImages[i];
        }

        // Check if CSV was used for rooms
        if (_roomsCsvPath != null && _roomsCsvPath!.isNotEmpty) {
          // Use CSV upload method
          response = await hotelService.createHotelWithCsv(
            fields: hotelFields,
            propertyImages: hotelFiles,
            csvFilePath: _roomsCsvPath!,
          );
        } else {
          // Use manual rooms entry method
          response = await hotelService.createHotel(
            fields: hotelFields,
            files: hotelFiles,
            rooms: _hotelRooms,
          );
        }
      } else {
        // Use PropertyService for regular properties and shortlets
        final propertyService = PropertyService();

        // For Shortlets, use the property type as category
        // For Apartments, use the listing type (For rent/For sale)
        final String propertyCategory = _isShortletType
            ? _selectedPropertyType
            : _listingType;

        response = await propertyService.createProperty(
          type: _selectedPropertyType,
          title: _propertyTitleController.text,
          description: _descriptionController.text,
          price: cleanPrice,
          category: propertyCategory,
          location: _locationController.text,
          bedrooms: _isShortletType ? '1' : _roomsController.text,
          bathrooms: _isShortletType ? '1' : _bathroomsController.text,
          gated: _isShortletType ? 'No' : _gatedStatus,
          parking: _isShortletType ? 'No' : _parkingStatus,
          features: features,
          images: _selectedImages,
          images360: _isShortletType ? [] : _selected360Images,
          video: _isShortletType ? null : _selectedVideo,
        );
      }

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.success && response.data != null) {
        // Success - navigate to success screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PropertyListingSuccessView(),
      ),
    );
      } else {
        // Check if this is a 403 error related to KYC verification or property limit
        final message = response.message?.toLowerCase() ?? '';
        final isKycLimitError = response.statusCode == 403 && 
            response.message != null && 
            (message.contains('kyc') || 
             message.contains('maximum limit') || 
             message.contains('property limit') ||
             (message.contains('limit') && message.contains('property')));
        
        if (isKycLimitError) {
          // Show KYC-specific dialog with navigation option
          _showKycLimitDialog(response.message!);
        } else {
          // Other errors - show generic error message
          final errorMessage = response.message ?? 
              'Failed to create property. Please ensure:\n\n• Images are in JPG, JPEG, or PNG format\n• Images have reasonable dimensions (300px minimum)\n• All required fields are filled\n• Images are not corrupted or invalid\n\nPlease try with a different image.';
          _showErrorDialog(errorMessage);
        }
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

  void _showKycLimitDialog(String message) async {
    if (!mounted) return;
    
    final authService = AuthService();
    final userType = await authService.getUserType();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Property Limit Reached',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete your KYC verification to list unlimited properties.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to appropriate KYC screen based on user type
                if (userType == 'agent') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AgentKycView(),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CompleteKycView(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete KYC'),
            ),
          ],
        );
      },
    );
  }
} 