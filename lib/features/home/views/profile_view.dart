import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/utils/format_utils.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'property_listing_view.dart';
import 'property_details_view.dart';
import 'agent_calendar_view.dart';
import '../models/room_model.dart';
// import 'subscription_view.dart'; // disabled — subscription moved to website
import 'all_properties_view.dart';
import 'edit_property_view.dart';
import '../../finance/views/agent_kyc_view.dart';
import '../../finance/views/kyc_status_review_view.dart';
import '../../finance/views/user_kyc_status_review_view.dart';
import '../../finance/views/complete_kyc_view.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/models/kyc_status_response.dart';
import '../services/property_service.dart';
import '../services/hotel_service.dart';
import '../models/property_model.dart';
import '../widgets/booking_carousel_widget.dart';
import 'bookings_list_view.dart';

class ProfileView extends StatefulWidget {
  final bool isAgent;
  
  const ProfileView({super.key, this.isAgent = false});
  
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final PropertyService _propertyService = PropertyService();
  final HotelService _hotelService = HotelService();
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  UserModel? _currentUser;
  bool _isLoadingProfile = true;
  bool _isUploadingImage = false;
  KycStatusResponse? _kycStatus;
  bool _isLoadingKycStatus = true;
  List<PropertyModel> _myProperties = [];
  bool _isLoadingMyProperties = true;
  bool _showAllListings = false;

  // Ratings and Reviews
  List<Map<String, dynamic>> _agentRatings = [];
  bool _isLoadingRatings = true;

  bool _contactExpanded = false;

  // KYC Approval Animation
  bool _showKycApprovedAnimation = false;
  AnimationController? _approvalAnimationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize approval animation controller
    _approvalAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _approvalAnimationController!,
      curve: Curves.elasticOut,
    );

    _fetchUserProfile();
    // Fetch KYC status for both agents and tenants
    _fetchKycStatus();
    // Fetch agent's properties if they are an agent
    if (widget.isAgent) {
      _fetchMyProperties();
      _fetchAgentRatings();
    }
  }

  @override
  void dispose() {
    _approvalAnimationController?.dispose();
    super.dispose();
  }
  
  /// Refresh all profile data (called after KYC submission)
  Future<void> _refreshProfile() async {
    print('🔄 [ProfileView] Refreshing all profile data...');
    setState(() {
      _isLoadingProfile = true;
      _isLoadingKycStatus = true;
    });
    
    // Refresh user profile
    await _fetchUserProfile();
    
    // Refresh KYC status
    await _fetchKycStatus();
    
    // Refresh properties for agents
    if (widget.isAgent) {
      await _fetchMyProperties();
      await _fetchAgentRatings();
    }
    
    print('✅ [ProfileView] Profile refresh complete!');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh KYC status when the profile view becomes visible
    // This will be called when user returns from KYC submission
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKycStatusIfNeeded();
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _authService.getProfile();

      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _currentUser = response.data;
            _isLoadingProfile = false;
          });
        }
      } else {
        // API failed — load from local storage as fallback
        final cachedUser = await _authService.getCurrentUser();
        if (mounted) {
          setState(() {
            _currentUser = cachedUser;
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      // On error, still try local storage
      final cachedUser = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = cachedUser;
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _fetchKycStatus() async {
    try {
      print('🔵🔵🔵 [ProfileView] ========================================');
      print('🔵 [ProfileView] Fetching KYC status...');
      print('🔵 [ProfileView] User type: ${widget.isAgent ? "Agent" : "Home Seeker"}');

      final response = await _authService.getKycStatus();

      print('🔵 [ProfileView] KYC Status Response:');
      print('🔵 [ProfileView] - Success: ${response.success}');
      print('🔵 [ProfileView] - Status Code: ${response.statusCode}');
      print('🔵 [ProfileView] - Message: ${response.message}');
      print('🔵 [ProfileView] - Data: ${response.data}');

      if (response.data != null) {
        print('🔵 [ProfileView] KYC Data Details:');
        print('🔵 [ProfileView] - status: ${response.data!.status}');
        print('🔵 [ProfileView] - isRequired: ${response.data!.isRequired}');
        print('🔵 [ProfileView] - message: ${response.data!.message}');
        print('🔵 [ProfileView] - details: ${response.data!.details}');
        print('🔵 [ProfileView] - isKycVerified(): ${response.data!.isKycVerified()}');
        print('🔵 [ProfileView] - isKycPending(): ${response.data!.isKycPending()}');
        print('🔵 [ProfileView] - isKycRejected(): ${response.data!.isKycRejected()}');
        print('🔵 [ProfileView] - shouldShowKycDialog(): ${response.data!.shouldShowKycDialog()}');
      }

      if (response.success) {
        final previousStatus = _kycStatus?.status;
        print('🔵 [ProfileView] - Previous status: $previousStatus');

        setState(() {
          _kycStatus = response.data;
          _isLoadingKycStatus = false;
        });

        // Handle verified KYC status
        if (_kycStatus != null && _kycStatus!.isKycVerified()) {
          print('🔵 [ProfileView] KYC is VERIFIED!');
          // Only trigger animation if status just changed (not on first load)
          if (previousStatus != null && previousStatus != 'verified' && previousStatus != 'approved') {
            print('🔵 [ProfileView] Status changed to verified/approved - triggering animation');
            // Status just changed to verified/approved - show approval animation
            _triggerApprovalAnimation();
          } else {
            print('🔵 [ProfileView] KYC already verified (first load or refresh)');
          }
        } else {
          print('🔵 [ProfileView] KYC is NOT verified');
        }
      } else {
        print('🔵 [ProfileView] Response not successful');
        setState(() {
          _isLoadingKycStatus = false;
        });
      }

      print('🔵 [ProfileView] ========================================');
    } catch (e) {
      print('🔴 [ProfileView] Error fetching KYC status: $e');
      setState(() {
        _isLoadingKycStatus = false;
      });
    }
  }

  void _triggerApprovalAnimation() {
    setState(() {
      _showKycApprovedAnimation = true;
    });

    // Start scale animation
    _approvalAnimationController?.forward();

    // Wait 2 seconds then hide the animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showKycApprovedAnimation = false;
        });
      }
    });
  }

  // Refresh KYC status when profile view becomes visible
  Future<void> _refreshKycStatusIfNeeded() async {
    try {
      final response = await _authService.getKycStatus();
      
      if (response.success) {
        final newKycStatus = response.data;
        
        // Only update if the status has changed
        if (_kycStatus?.status != newKycStatus?.status) {
          setState(() {
            _kycStatus = newKycStatus;
            _isLoadingKycStatus = false;
          });
          
          if (newKycStatus != null) {
            
            // Show success message if KYC was just submitted
            if (newKycStatus.status == 'pending') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('KYC submitted successfully! Your verification is under review.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
    }
  }

  Future<void> _fetchMyProperties() async {
    if (!mounted) return; // Check mounted before starting
    
    try {
      if (mounted) {
        setState(() {
          _isLoadingMyProperties = true;
        });
      }

      final properties = await _propertyService.fetchMyProperties();
      
      if (!mounted) return; // Check mounted after async operation
      
      
      if (mounted) {
        setState(() {
          _myProperties = properties;
          _isLoadingMyProperties = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Check mounted before setState
      
      setState(() {
        _isLoadingMyProperties = false;
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load your properties: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getUserTypeDisplay() {
    if (_currentUser == null) return 'User';
    
    final userType = _currentUser!.userType.trim();
    
    print('🔵 [ProfileView] _getUserTypeDisplay called:');
    print('  - userType: "$userType"');
    print('  - agentType: "${_currentUser!.agentType}"');
    
    if (userType.isEmpty) {
      // If userType is empty, try to infer from isAgent widget property
      return widget.isAgent ? 'Agent' : 'Home Seeker';
    }
    
    if (userType != 'home_seeker') {
      // For agents, show their specific agent type if available
      if (_currentUser!.agentType != null && _currentUser!.agentType!.trim().isNotEmpty) {
        final display = _currentUser!.agentType!
            .replaceAll('_', ' ')
            .split(' ')
            .where((word) => word.isNotEmpty) // Filter out empty strings
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
        print('  - Returning agentType display: "$display"');
        return display;
      }
      return 'Agent';
    } else if (userType == 'home_seeker') {
      return 'Home Seeker';
    } else {
      // Format other user types
      final display = userType.replaceAll('_', ' ');
      print('  - Returning formatted display: "$display"');
      return display;
    }
  }

  // bool _isSubscriptionEligible() {
  //   final agentType = _currentUser?.agentType?.toLowerCase().replaceAll(' ', '_') ?? '';
  //   return agentType != 'hotel' && agentType != 'shortlet';
  // }

  /// Refresh all data (profile, KYC status, and properties)
  Future<void> _refreshAllData() async {
    
    // Refresh user profile
    await _fetchUserProfile();
    
    // Refresh KYC status
    await _fetchKycStatus();
    
    // Refresh agent properties if user is an agent
    if (widget.isAgent) {
      await _fetchMyProperties();
      await _fetchAgentRatings();
    }
    
  }
  
  /// Fetch agent ratings and reviews
  Future<void> _fetchAgentRatings() async {
    if (!widget.isAgent) return;
    
    try {
      setState(() {
        _isLoadingRatings = true;
      });
      
      print('⭐ [ProfileView] Fetching agent ratings...');
      print('⭐ [ProfileView] Endpoint: ${ApiConstants.agentPropertiesRatings}');
      
      final response = await _apiService.get<dynamic>(
        ApiConstants.agentPropertiesRatings,
        requiresAuth: true,
        fromJson: (json) => json,
      );
      
      if (!mounted) return;
      
      print('⭐ [ProfileView] Response success: ${response.success}');
      print('⭐ [ProfileView] Response statusCode: ${response.statusCode}');
      print('⭐ [ProfileView] Response message: ${response.message}');
      print('⭐ [ProfileView] Response data type: ${response.data?.runtimeType}');
      
      if (response.data != null) {
        print('⭐ [ProfileView] Response data: ${response.data}');
        print('⭐ [ProfileView] Response data (pretty):');
        _printPrettyJson(response.data);
      }
      
      if (response.success && response.data != null) {
        final data = response.data;
        List<dynamic> ratingsList = [];
        
        print('⭐ [ProfileView] Processing response data...');
        
        // Handle different response structures
        if (data is List) {
          print('⭐ [ProfileView] Data is a List with ${data.length} items');
          ratingsList = data;
        } else if (data is Map<String, dynamic>) {
          print('⭐ [ProfileView] Data is a Map with keys: ${data.keys.toList()}');
          
          if (data.containsKey('data')) {
            print('⭐ [ProfileView] Found "data" key, type: ${data['data'].runtimeType}');
            if (data['data'] is List) {
              ratingsList = data['data'] as List<dynamic>;
              print('⭐ [ProfileView] Extracted ${ratingsList.length} ratings from data.data (List)');
            } else if (data['data'] is Map && (data['data'] as Map).containsKey('ratings')) {
              ratingsList = (data['data'] as Map)['ratings'] as List<dynamic>;
              print('⭐ [ProfileView] Extracted ${ratingsList.length} ratings from data.data.ratings');
            }
          } else if (data.containsKey('ratings')) {
            ratingsList = data['ratings'] as List<dynamic>;
            print('⭐ [ProfileView] Extracted ${ratingsList.length} ratings from data.ratings');
          } else {
            // Check all keys to see what we have
            print('⭐ [ProfileView] Data keys: ${data.keys.toList()}');
            // Try to find any list in the map
            for (var key in data.keys) {
              if (data[key] is List) {
                ratingsList = data[key] as List<dynamic>;
                print('⭐ [ProfileView] Found list in key "$key" with ${ratingsList.length} items');
                break;
              }
            }
          }
        }
        
        if (ratingsList.isNotEmpty) {
          print('⭐ [ProfileView] First rating structure: ${ratingsList.first}');
        }
        
        setState(() {
          _agentRatings = ratingsList
              .map((item) {
                if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              })
              .where((item) => item.isNotEmpty)
              .toList();
          _isLoadingRatings = false;
        });
        
        print('✅ [ProfileView] Successfully loaded ${_agentRatings.length} ratings');
        print('✅ [ProfileView] Processed ratings:');
        for (int i = 0; i < _agentRatings.length; i++) {
          print('  Rating $i: ${_agentRatings[i]}');
        }
      } else {
        setState(() {
          _isLoadingRatings = false;
        });
        print('⚠️ [ProfileView] Failed to fetch ratings: ${response.message}');
        if (response.errors != null) {
          print('⚠️ [ProfileView] Response errors: ${response.errors}');
        }
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      setState(() {
        _isLoadingRatings = false;
      });
      
      print('❌ [ProfileView] Error fetching ratings: $e');
      print('❌ [ProfileView] Stack trace: $stackTrace');
    }
  }
  
  /// Helper method to print JSON in a readable format
  void _printPrettyJson(dynamic data, {int indent = 0}) {
    final indentStr = '  ' * indent;
    
    if (data is Map) {
      print('$indentStr{');
      data.forEach((key, value) {
        if (value is Map || value is List) {
          print('$indentStr  "$key":');
          _printPrettyJson(value, indent: indent + 2);
        } else {
          print('$indentStr  "$key": $value');
        }
      });
      print('$indentStr}');
    } else if (data is List) {
      print('$indentStr[');
      for (var item in data) {
        if (item is Map || item is List) {
          _printPrettyJson(item, indent: indent + 2);
        } else {
          print('$indentStr  $item');
        }
      }
      print('$indentStr]');
    } else {
      print('$indentStr$data');
    }
  }

  /// Show image picker options (camera or gallery)
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF0F2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              
              // Image options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF426DC2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF426DC2),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Pick image from camera
  void _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        await _uploadProfileImage(File(image.path));
      } else {
      }
    } catch (e) {
      _showErrorMessage('Failed to take photo');
    }
  }

  /// Pick image from gallery
  void _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        await _uploadProfileImage(File(image.path));
      } else {
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image from gallery');
    }
  }

  /// Upload profile image to server
  Future<void> _uploadProfileImage(File imageFile) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final response = await _authService.uploadProfileImage(imageFile);
      
      if (response.success) {
        
        // Refresh user profile to get updated data
        await _fetchUserProfile();
        
        _showSuccessMessage('Profile picture updated successfully!');
      } else {
        _showErrorMessage(response.message ?? 'Failed to upload profile image');
      }
    } catch (e) {
      _showErrorMessage('Failed to upload profile image');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  /// Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAllData,
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                    fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
                
                const SizedBox(height: 40),
                
                // Profile Section
                _buildProfileSection(),
                
                const SizedBox(height: 48),
                
                // Agent Action Buttons (only for agents)
                if (widget.isAgent) _buildAgentActionButtons(context),
                
                // KYC Info Message (only for agents)
                if (widget.isAgent) _buildKycInfoMessage(),
                
                // Tenant KYC Section (only for tenants)
                if (!widget.isAgent) _buildTenantKycSection(context),
                
                        // Contact Details Section
        widget.isAgent ? _buildAgentContactDetailsSection() : _buildContactDetailsSection(),
        
        const SizedBox(height: 40),
        
        // Bookings Section (for both agents and home seekers)
        _buildBookingsSection(),
        
        const SizedBox(height: 40),
        
        // Agent-specific sections
        if (widget.isAgent) ...[
          _buildCurrentListingSection(),
          const SizedBox(height: 32),
          _buildVerifyCheckinSection(),
          const SizedBox(height: 32),
          _buildCalendarSection(),
          // Subscription disabled — moved to website (Apple IAP policy)
          // if (_isSubscriptionEligible()) ...[
          //   const SizedBox(height: 32),
          //   _buildSubscriptionSection(),
          // ],
          const SizedBox(height: 32),
          _buildReviewSection(),
        ],
        
        const SizedBox(height: 24),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 0.3, // Increased elevation for box shadow
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
              // Profile Picture with camera icon
              GestureDetector(
                onTap: _isUploadingImage ? null : _showImagePickerOptions,
                child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                        color: const Color(0xFF426DC2),
                      ),
                      child: _isLoadingProfile || _isUploadingImage
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                              child: Center(
                                child: _isUploadingImage
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      )
                                    : const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                          : _currentUser?.profilePicture != null && _currentUser!.profilePicture!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: _currentUser!.profilePicture!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      width: 120,
                                      height: 120,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFECF0F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF426DC2))),
                                    ),
                                    errorWidget: (context, url, error) {
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF426DC2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _currentUser?.fullName.isNotEmpty == true
                                                ? _currentUser!.fullName[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 48,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF426DC2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _currentUser?.fullName.isNotEmpty == true
                                          ? _currentUser!.fullName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                        width: 32,
                        height: 32,
                      decoration: BoxDecoration(
                            color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                        child: Icon(
                          _isUploadingImage ? Icons.upload : Icons.camera_alt_outlined,
                          size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
                ),
              ),
              
              const SizedBox(height: 20),

              // Verified Badge (show if KYC is approved)
              if (!_isLoadingKycStatus && _kycStatus != null && _kycStatus!.isKycVerified())
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                    // Name
                    Text(
                      _isLoadingProfile
                          ? 'Loading...'
                          : FormatUtils.toTitleCase(_currentUser?.fullName ?? 'User Name'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    
                    // Email
                    Text(
                      _isLoadingProfile 
                          ? 'Loading...' 
                          : _currentUser?.email ?? 'user@email.com',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF999999),
                      ),
                    ),
              
              const SizedBox(height: 12),
              
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isAgent ? Color.fromRGBO(229, 253, 244, 1) : Color.fromRGBO(241, 250, 253, 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isLoadingProfile 
                      ? 'Loading...'
                      : _getUserTypeDisplay(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.isAgent ? AppColors.black : AppColors.primary600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _contactExpanded = !_contactExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contact details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              AnimatedRotation(
                turns: _contactExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF426DC2), size: 28),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _contactExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: 24),
              _buildContactDetailItem(
                icon: Icons.person,
                iconColor: const Color(0xFF426DC2),
                label: 'Full Name',
                value: _isLoadingProfile ? 'Loading...' : _currentUser?.fullName ?? 'Not provided',
              ),
              const SizedBox(height: 24),
              _buildContactDetailItem(
                icon: Icons.email,
                iconColor: const Color(0xFF426DC2),
                label: 'Email',
                value: _isLoadingProfile ? 'Loading...' : _currentUser?.email ?? 'Not provided',
              ),
              const SizedBox(height: 24),
              _buildContactDetailItem(
                icon: Icons.phone,
                iconColor: const Color(0xFF426DC2),
                label: 'Phone number',
                value: _isLoadingProfile ? 'Loading...' : _currentUser?.phoneNumber ?? 'Not provided',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactDetailItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      height: 51,
        decoration: BoxDecoration(
        color: Color.fromRGBO(250, 250, 250, 1),
        borderRadius: BorderRadius.circular(10),
       
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Icon
            Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
            
            const SizedBox(width: 16),
            
            // Label
            Expanded(
              flex: 1,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Value
            Expanded(
              flex: 2,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF999999),
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentActionButtons(BuildContext context) {
    // Determine button text and layout based on KYC status
    String kycButtonText = 'Complete KYC';
    bool isKycApproved = false;

    if (!_isLoadingKycStatus && _kycStatus != null) {
      if (_kycStatus!.isKycVerified()) {
        kycButtonText = 'View KYC Status';
        isKycApproved = true;
      } else if (_kycStatus!.isKycPending()) {
        kycButtonText = 'View KYC Status';
      } else if (_kycStatus!.isKycRejected()) {
        kycButtonText = 'Resubmit KYC';
      } else {
        kycButtonText = 'Complete KYC';
      }
    } else if (_isLoadingKycStatus) {
      kycButtonText = 'Loading...';
    }

    // If KYC is approved, only show "List a property" button
    if (isKycApproved) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-1.0, -0.02),
            end: Alignment(1.0, 0.02),
            stops: [0.0113, 0.4555, 1.1245],
            colors: [
              Color(0xFF426DC2),
              Color(0xFF75CFEA),
              Color.fromRGBO(51, 204, 153, 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PropertyListingView(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text(
            'List a property',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    
    // Show both buttons for other KYC statuses
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment(-1.0, -0.02),
                end: Alignment(1.0, 0.02),
                stops: [0.0113, 0.4555, 1.1245],
                colors: [
                  Color(0xFF426DC2),
                  Color(0xFF75CFEA),
                  Color.fromRGBO(51, 204, 153, 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PropertyListingView(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'List a property',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _showKycApprovedAnimation
              ? ScaleTransition(
                  scale: _scaleAnimation!,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-1.0, -0.02),
                        end: Alignment(1.0, 0.02),
                        stops: [0.0113, 0.4555, 1.1245],
                        colors: [
                          Color(0xFF33CC99),
                          Color(0xFF66D9B0),
                          Color(0xFF99E6C7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Color(0xFF33CC99),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Approved',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF426DC2), width: 1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoadingKycStatus ? null : () async {
                      // Navigate based on KYC status
                      if (_kycStatus?.status == 'pending') {
                        // Show KYC status review screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => KycStatusReviewView(
                              statusMessage: _kycStatus?.message,
                            ),
                          ),
                        );
                      } else {
                        // Navigate to KYC form and refresh on return
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AgentKycView(),
                          ),
                        );

                        // Refresh profile if KYC was submitted
                        if (result == true && mounted) {
                          print('🔄 [ProfileView] Refreshing after agent KYC submission...');
                          _refreshProfile();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      kycButtonText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isLoadingKycStatus
                            ? const Color(0xFF868686)
                            : const Color(0xFF426DC2),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildKycInfoMessage() {
    // Don't show info message if KYC is approved, but add spacing
    if (!_isLoadingKycStatus && _kycStatus != null && _kycStatus!.isKycVerified()) {
      return const SizedBox(height: 32);
    }
    
    String message = 'You are currently limited to listing 3 properties. To list more, please complete your KYC process.';
    Color backgroundColor = const Color(0xFFE3F2FD);
    Color iconColor = const Color(0xFF426DC2);
    Color textColor = const Color(0xFF426DC2);
    
    if (!_isLoadingKycStatus && _kycStatus != null) {
      if (_kycStatus!.isKycPending()) {
        message = 'Your KYC verification is under review. You can still list up to 3 properties while waiting.';
        backgroundColor = const Color(0xFFFFF3E0);
        iconColor = const Color(0xFFFF9800);
        textColor = const Color(0xFFE65100);
      } else if (_kycStatus!.isKycRejected()) {
        message = 'Your KYC submission was rejected. Please resubmit with valid documents to unlock unlimited property listing.';
        backgroundColor = const Color(0xFFFFEBEE);
        iconColor = const Color(0xFFF44336);
        textColor = const Color(0xFFC62828);
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 32),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isLoadingKycStatus ? Icons.hourglass_empty : Icons.info,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isLoadingKycStatus 
                  ? 'Loading KYC status...'
                  : message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantKycSection(BuildContext context) {
    // Determine button text and layout based on KYC status
    String kycButtonText = 'Complete KYC';
    bool isKycApproved = false;

    if (!_isLoadingKycStatus && _kycStatus != null) {
      if (_kycStatus!.isKycVerified()) {
        kycButtonText = 'View KYC Status';
        isKycApproved = true;
      } else if (_kycStatus!.isKycPending()) {
        kycButtonText = 'View KYC Status';
      } else if (_kycStatus!.isKycRejected()) {
        kycButtonText = 'Resubmit KYC';
      } else {
        kycButtonText = 'Complete KYC';
      }
    } else if (_isLoadingKycStatus) {
      kycButtonText = 'Loading...';
    }

    // Hide entire KYC section if approved
    if (isKycApproved) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KYC Verification',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 16),

        // KYC Status Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE9ECEF),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status message
              Text(
                _isLoadingKycStatus
                    ? 'Loading KYC status...'
                    : _getTenantKycStatusMessage(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // KYC Action Button
              _showKycApprovedAnimation
                  ? ScaleTransition(
                      scale: _scaleAnimation!,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment(-1.0, -0.02),
                            end: Alignment(1.0, 0.02),
                            stops: [0.0113, 0.4555, 1.1245],
                            colors: [
                              Color(0xFF33CC99),
                              Color(0xFF66D9B0),
                              Color(0xFF99E6C7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Color(0xFF33CC99),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Approved',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF426DC2)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoadingKycStatus ? null : () async {
                          // Navigate based on KYC status
                          if (_kycStatus?.status == 'pending') {
                            // Show KYC status review screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => UserKycStatusReviewView(
                                  statusMessage: _kycStatus?.message,
                                ),
                              ),
                            );
                          } else {
                            // Navigate to KYC form and refresh on return
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const CompleteKycView(),
                              ),
                            );

                            // Refresh profile if KYC was submitted
                            if (result == true && mounted) {
                              print('🔄 [ProfileView] Refreshing after homeseeker KYC submission...');
                              _refreshProfile();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          kycButtonText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isLoadingKycStatus
                                ? const Color(0xFF868686)
                                : const Color(0xFF426DC2),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTenantKycStatusMessage() {
    if (_kycStatus == null) {
      return 'Complete your KYC verification to unlock Rent-Now, Pay-Later features and access to more properties.';
    }
    
    switch (_kycStatus!.status) {
      case 'verified':
        return 'Your KYC is verified! You can now access Rent-Now, Pay-Later features and all properties.';
      case 'pending':
        return 'Your KYC verification is under review. We\'ll notify you once the review is complete.';
      case 'rejected':
        return 'Your KYC submission was rejected. Please resubmit with valid documents to unlock Rent-Now, Pay-Later features.';
      default:
        return 'Complete your KYC verification to unlock Rent-Now, Pay-Later features and access to more properties.';
    }
  }

  Widget _buildAgentContactDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _contactExpanded = !_contactExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contact details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              AnimatedRotation(
                turns: _contactExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF426DC2), size: 28),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _contactExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: 24),
              _buildContactDetailItem(
                icon: Icons.person,
                iconColor: const Color(0xFF426DC2),
                label: 'Full Name',
                value: _isLoadingProfile ? 'Loading...' : _currentUser?.fullName ?? 'Not provided',
              ),
              if (_currentUser?.agencyName != null || _isLoadingProfile) ...[
                const SizedBox(height: 24),
                _buildContactDetailItem(
                  icon: Icons.business,
                  iconColor: const Color(0xFF426DC2),
                  label: 'Agency Name',
                  value: _isLoadingProfile ? 'Loading...' : _currentUser?.agencyName ?? 'Not provided',
                ),
              ],
              const SizedBox(height: 24),
              _buildContactDetailItem(
                icon: Icons.email,
                iconColor: const Color(0xFF426DC2),
                label: 'Email',
                value: _isLoadingProfile ? 'Loading...' : _currentUser?.email ?? 'Not provided',
              ),
              const SizedBox(height: 24),
              _buildContactDetailItem(
                icon: Icons.phone,
                iconColor: const Color(0xFF426DC2),
                label: 'Phone number',
                value: _isLoadingProfile ? 'Loading...' : _currentUser?.phoneNumber ?? 'Not provided',
              ),
              const SizedBox(height: 24),
              _buildContactDetailItem(
                icon: Icons.chat,
                iconColor: const Color(0xFF426DC2),
                label: 'Whatsapp number',
                value: _isLoadingProfile ? 'Loading...' : _currentUser?.whatsappNumber ?? _currentUser?.phoneNumber ?? 'Not provided',
              ),
              const SizedBox(height: 24),
              _buildContactDetailItem(
                icon: Icons.location_on,
                iconColor: const Color(0xFF426DC2),
                label: 'Location',
                value: _isLoadingProfile ? 'Loading...' : _currentUser?.location ?? 'Not provided',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with View All button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () async {
                // Navigate to bookings list and wait for return
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BookingsListView(),
                  ),
                );
                
                // Refresh the profile view to update carousel
                if (mounted) {
                  setState(() {
                    // Trigger rebuild to refresh BookingCarouselWidget
                  });
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF426DC2),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Color(0xFF426DC2),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Bookings carousel (key ensures rebuild on navigation back)
        BookingCarouselWidget(
          key: ValueKey('bookings_carousel_${DateTime.now().millisecondsSinceEpoch}'),
        ),
      ],
    );
  }

  Widget _buildCurrentListingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Current listing',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
            ),
            if (!_isLoadingMyProperties && _myProperties.isNotEmpty)
              Row(
                children: [
              Text(
                    '${_myProperties.length} ${_myProperties.length == 1 ? 'property' : 'properties'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AllPropertiesView(
                            properties: _myProperties,
                            currentUser: _currentUser,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF426DC2),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        
        const SizedBox(height: 16),

        if (_isLoadingMyProperties)
          const Center(child: CircularProgressIndicator())
        else if (_myProperties.isEmpty)
          _buildEmptyPropertiesState()
        else ...[
          _buildPropertyCard(0),
          if (_myProperties.length > 1) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _showAllListings = !_showAllListings),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF426DC2).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAllListings
                          ? 'Show Less'
                          : 'View More (${_myProperties.length - 1} ${_myProperties.length - 1 == 1 ? "listing" : "listings"})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF426DC2)),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _showAllListings ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF426DC2),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (_showAllListings) ...[
              const SizedBox(height: 12),
              ...List.generate(_myProperties.length - 1, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPropertyCard(i + 1),
              )),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildEmptyPropertiesState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 48,
            color: Color(0xFF999999),
          ),
          const SizedBox(height: 16),
          const Text(
            'No properties listed yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by listing your first property',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 140,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF426DC2),
                    Color(0xFF63ADDC),
                    Color(0xFF75CFEA),
                  ],
                  stops: [0.0, 1.0, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PropertyListingView(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'List a property',
                    style: TextStyle(
                      fontSize: 14,
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

  Widget _buildPropertyCard(int index) {
    if (index >= _myProperties.length) {
      return const SizedBox.shrink();
    }

    final property = _myProperties[index];
    
    // Check if property has is_promoted value
    final isPromoted = property.rawJson?['is_promoted'] as bool? ?? false;
    print('🏠 [ProfileView] Property ${property.id} - is_promoted: $isPromoted');

    return GestureDetector(
      onTap: () {
        // Navigate to property details
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PropertyDetailsView(
              propertyData: {
                'id': property.id, // Pass property ID
                'badges': ['Verified Agent'],
                'title': property.title,
                'location': property.location,
                'average_rating': property.rawJson?['average_rating']?.toString() ?? '0.0',
                'rating_count': property.rawJson?['rating_count'] ?? 0,
                'price': property.price,
                'type': property.type,
                'category': property.category,
                'description': property.description,
                'features': property.features,
                'is_promoted': property.rawJson?['is_promoted'] as bool? ?? false, // Pass is_promoted from rawJson
                'imageUrl': property.imageUrl, // Pass actual image URL from API
                'images': property.images ?? (property.imageUrl != null ? [{'full_url': property.imageUrl}] : null), // Pass all images
                'property360_images': property.property360Images, // Pass 360 images
                'video_url': property.videoUrl, // Pass video URL
                'user': property.user?.toJson() ?? {
                  'id': _currentUser?.id,
                  'full_name': _currentUser?.fullName ?? 'Agent',
                  'email': _currentUser?.email ?? '',
                  'phone_number': _currentUser?.phoneNumber ?? '',
                  'whatsapp_number': _currentUser?.whatsappNumber ?? _currentUser?.phoneNumber ?? '',
                  'profile_image_full_url': _currentUser?.profilePicture,
                }, // Pass user data with ID for ownership check
                'agent': {
                  'name': _currentUser?.fullName ?? 'Agent',
                  'title': 'Agent',
                  'phone': _currentUser?.phoneNumber ?? '',
                  'email': _currentUser?.email ?? '',
                  'whatsapp': _currentUser?.whatsappNumber ?? _currentUser?.phoneNumber ?? '',
                },
              },
              isHomeSeeker: false, // Agents viewing their own properties
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Property Image
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: DecorationImage(
                  image: NetworkImage(property.imageUrl ?? 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Badge - Only show for rent/for sale for apartments and shortlets (not hotels)
                if ((property.category.toLowerCase() == 'for_rent' || property.category.toLowerCase() == 'for_sale') &&
                    property.type.toLowerCase() != 'hotel')
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                        property.category.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // Promote, Favorite and More buttons
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      // Promote button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isPromoted ? null : () {
                            _promoteProperty(property);
                          },
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isPromoted ? const Color(0xFF426DC2) : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.star,
                              size: 16,
                              color: isPromoted ? Colors.white : const Color(0xFFFFA726),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _showPropertyOptionsMenu(context, property);
                              },
                              customBorder: const CircleBorder(),
                              child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.more_vert,
              size: 16,
                              color: Colors.black,
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
          
          // Property Details
          Padding(
            padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                            FormatUtils.toTitleCase(property.title),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                          child: Text(
                            property.type,
                            style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF426DC2),
                          ),
                        ),
                          ),
                          // Show "For Rent" or "For Sale" only for apartments and shortlets (not hotels)
                          if ((property.category.toLowerCase() == 'for_rent' || property.category.toLowerCase() == 'for_sale') &&
                              property.type.toLowerCase() != 'hotel')
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                property.category.toLowerCase() == 'for_rent' ? 'For Rent' : 'For Sale',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF868686),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Color(0xFF666666),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                            property.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF666666),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Listing status tag
                          Builder(builder: (_) {
                            final rawStatus = property.rawJson?['status']?.toString().toLowerCase() ?? '';
                            String label;
                            Color bgColor;
                            Color textColor;
                            if (rawStatus == 'available' || rawStatus == 'approved' || rawStatus == 'active' || rawStatus == 'live') {
                              label = 'Approved & Live';
                              bgColor = const Color(0xFFCCFBEA);
                              textColor = const Color(0xFF008D5A);
                            } else if (rawStatus == 'rejected' || rawStatus == 'declined') {
                              label = 'Rejected';
                              bgColor = const Color(0xFFFFE5E5);
                              textColor = Colors.red;
                            } else {
                              label = 'Pending';
                              bgColor = const Color(0xFFFFF3CD);
                              textColor = const Color(0xFFF59E0B);
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(70),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                          const SizedBox(height: 4),
                          // Star rating below the tag
                          Row(
                            children: [
                              Text(
                                property.rawJson?['average_rating']?.toString() ?? '0.0',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              if (property.rawJson?['rating_count'] != null) ...[
                                const SizedBox(width: 3),
                                Text(
                                  '(${property.rawJson!['rating_count']})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (property.type.toLowerCase() == 'hotel')
                            const Text(
                              'From',
                              style: TextStyle(fontSize: 11, color: Color(0xFF868686)),
                            ),
                          Text(
                            FormatUtils.formatPrice(property.price),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF426DC2),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Show buttons for hotels and shortlets
                  if (property.type.toLowerCase() == 'hotel' || property.type.toLowerCase() == 'shortlet')
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: OutlinedButton(
                                  onPressed: isPromoted ? null : () {
                                    _promoteProperty(property);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: isPromoted ? const Color(0xFF426DC2) : Colors.white,
                                    foregroundColor: isPromoted ? Colors.white : const Color(0xFF426DC2),
                                    side: const BorderSide(color: Color(0xFF426DC2), width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  ),
                                  child: Text(
                                    isPromoted ? 'Promoted' : 'Promote',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isPromoted ? Colors.white : const Color(0xFF426DC2),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: OutlinedButton(
                                  onPressed: () => _openCalendarForProperty(property),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF426DC2),
                                    side: const BorderSide(color: Color(0xFF426DC2), width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.calendar_month, size: 13),
                                      SizedBox(width: 4),
                                      Text(
                                        'Calendar',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    // For non-hotels, show only Promote property button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton(
                        onPressed: isPromoted ? null : () {
                          _promoteProperty(property);
                        },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isPromoted ? const Color(0xFF426DC2) : Colors.white,
                        foregroundColor: isPromoted ? Colors.white : const Color(0xFF426DC2),
                        side: BorderSide(
                          color: isPromoted ? const Color(0xFF426DC2) : const Color(0xFF426DC2),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        isPromoted ? 'Already Promoted' : 'Promote property',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isPromoted ? Colors.white : const Color(0xFF426DC2),
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

  Widget _buildVerifyCheckinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Check-in',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        const SizedBox(height: 4),
        const Text(
          'Confirm a guest\'s check-in by entering their booking code',
          style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF426DC2).withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              const Icon(Icons.how_to_reg_outlined, size: 40, color: Color(0xFF426DC2)),
              const SizedBox(height: 12),
              const Text(
                'Ready to verify a guest?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap below to enter the guest\'s check-in code',
                style: TextStyle(fontSize: 13, color: Color(0xFF868686)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _showCheckInVerificationSheet(null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF426DC2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.how_to_reg_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Verify Check-in', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    final calendarProperties = _myProperties
        .where((p) =>
            p.type.toLowerCase() == 'hotel' ||
            p.type.toLowerCase() == 'shortlet')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Availability Calendar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage booking availability for your hotel & shortlet rooms',
          style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 16),
        if (_isLoadingMyProperties)
          const Center(child: CircularProgressIndicator())
        else if (calendarProperties.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Column(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 40, color: Color(0xFF999999)),
                const SizedBox(height: 12),
                const Text(
                  'No hotel or shortlet listings yet',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'List a hotel or shortlet to manage room availability',
                  style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PropertyListingView()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF426DC2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('List a property', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          )
        else
          ...calendarProperties.map((property) {
            final rawRooms = property.rawJson?['rooms'] as List<dynamic>?;
            final hasRooms = rawRooms != null && rawRooms.isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF0F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month, color: Color(0xFF426DC2), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasRooms
                              ? '${rawRooms.length} ${rawRooms.length == 1 ? 'room' : 'rooms'}'
                              : 'No rooms set up yet',
                          style: TextStyle(fontSize: 12, color: hasRooms ? const Color(0xFF666666) : Colors.orange),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: hasRooms ? () => _openCalendarForProperty(property) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF426DC2),
                        disabledBackgroundColor: const Color(0xFFCCCCCC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                      ),
                      child: const Text('Manage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // _buildSubscriptionSection removed — subscription moved to website (Apple IAP policy)

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
              'Ratings & Reviews',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
            ),
            if (_agentRatings.isNotEmpty)
              Text(
                '${_agentRatings.length} ${_agentRatings.length == 1 ? 'review' : 'reviews'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (_isLoadingRatings)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_agentRatings.isEmpty)
        Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: const Center(
              child: Text(
                'No ratings yet. Your reviews will appear here once customers rate your properties.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._agentRatings.map((rating) => _buildRatingCard(rating)).toList(),
      ],
    );
  }
  
  Widget _buildRatingCard(Map<String, dynamic> rating) {
    // Extract rating data based on actual API structure
    final ratingValue = (rating['rating'] ?? 0) is int
        ? (rating['rating'] ?? 0) as int
        : ((rating['rating'] ?? 0) as num).toInt();
    
    final comment = rating['comment'] ?? '';
    final user = rating['user'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? 'Anonymous';
    final userProfileImage = user?['profile_image'] as String?;
    final createdAt = rating['created_at'] ?? '';
    final property = rating['property'] as Map<String, dynamic>?;
    final propertyTitle = property?['title'] ?? '';
    
    // Get first letter of name for avatar fallback
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFECF0F9),
          width: 1,
        ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
              // User avatar with profile image
                  Container(
                    width: 40,
                    height: 40,
                decoration: BoxDecoration(
                  color: userProfileImage == null 
                      ? const Color(0xFF426DC2) 
                      : null,
                      shape: BoxShape.circle,
                  image: userProfileImage != null
                      ? DecorationImage(
                          image: NetworkImage(userProfileImage),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            // Handle image load error
                          },
                        )
                      : null,
                    ),
                child: userProfileImage == null
                    ? Center(
                      child: Text(
                          firstLetter,
                          style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      )
                    : null,
                  ),
                  const SizedBox(width: 12),
              Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                      userName,
                      style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                    const Text(
                          'Home Seeker',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
              // Star rating
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                    index < ratingValue ? Icons.star : Icons.star_border,
                        size: 16,
                    color: index < ratingValue 
                        ? Colors.amber 
                        : Colors.grey[300]!,
                      );
                    }),
                  ),
                ],
              ),
          if (propertyTitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Property: $propertyTitle',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF426DC2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),
            ],
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _formatDate(createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
          ),
        ),
      ],
        ],
      ),
    );
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  void _openCalendarForProperty(PropertyModel property) {
    final rawRooms = property.rawJson?['rooms'] as List<dynamic>?;
    if (rawRooms == null || rawRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rooms found for this property.')),
      );
      return;
    }

    // Build RoomModel list from rawJson rooms
    final rooms = rawRooms
        .whereType<Map>()
        .map((r) {
          try { return RoomModel.fromJson(Map<String, dynamic>.from(r)); }
          catch (_) { return null; }
        })
        .whereType<RoomModel>()
        .toList();

    if (rooms.length == 1) {
      // Only one room — open calendar directly
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AgentCalendarView(
          room: rooms.first,
          propertyData: property.rawJson ?? {},
        ),
      ));
    } else {
      // Multiple rooms — show picker
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select a Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ...rooms.map((room) => ListTile(
              leading: const Icon(Icons.hotel_outlined, color: Color(0xFF426DC2)),
              title: Text(room.name),
              subtitle: Text('₦${room.price.toStringAsFixed(0)}/night · ${room.count} left'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AgentCalendarView(
                    room: room,
                    propertyData: property.rawJson ?? {},
                  ),
                ));
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
  }

  Future<void> _promoteProperty(PropertyModel property) async {
    try {
      print('⭐ [ProfileView] Promoting property ID: ${property.id}');
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF426DC2),
          ),
        ),
      );

      final response = await _propertyService.promoteProperty(property.id);
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      print('⭐ [ProfileView] Promote property response:');
      print('   - Success: ${response.success}');
      print('   - Status Code: ${response.statusCode}');
      print('   - Message: ${response.message}');
      print('   - Data: ${response.data}');

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Property promoted successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Refresh properties to show updated status
          _fetchMyProperties();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to promote property. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ [ProfileView] Error promoting property: $e');
      print('❌ [ProfileView] Stack trace: $stackTrace');
      
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error promoting property: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showPropertyOptionsMenu(BuildContext context, PropertyModel property) {
    showModalBottomSheet(
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
            const Text(
              'Property Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            
            // Edit Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF426DC2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF426DC2),
                ),
              ),
              title: const Text(
                'Edit Property',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Update property details',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF868686),
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                // Navigate to edit property screen
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditPropertyView(property: property),
                  ),
                );
                
                // Refresh property list if edit was successful
                if (result == true) {
                  _fetchMyProperties();
                }
              },
            ),
            
            const SizedBox(height: 12),
            
            // Promote Property Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (property.rawJson?['is_promoted'] as bool? ?? false)
                      ? const Color(0xFF426DC2).withValues(alpha: 0.1)
                      : const Color(0xFFFFA726).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.star,
                  color: (property.rawJson?['is_promoted'] as bool? ?? false)
                      ? const Color(0xFF426DC2)
                      : const Color(0xFFFFA726),
                ),
              ),
              title: Text(
                (property.rawJson?['is_promoted'] as bool? ?? false)
                    ? 'Already Promoted'
                    : 'Promote Property',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: (property.rawJson?['is_promoted'] as bool? ?? false)
                      ? const Color(0xFF426DC2)
                      : Colors.black,
                ),
              ),
              subtitle: Text(
                (property.rawJson?['is_promoted'] as bool? ?? false)
                    ? 'This property is already featured in promoted listings'
                    : 'Feature this property in promoted listings',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF868686),
                ),
              ),
              onTap: (property.rawJson?['is_promoted'] as bool? ?? false) ? null : () {
                Navigator.pop(context);
                _promoteProperty(property);
              },
            ),
            
            const SizedBox(height: 12),
            
            // Delete Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
              ),
              title: const Text(
                'Delete Property',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              subtitle: const Text(
                'Remove this property listing',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF868686),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, property);
              },
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

  void _showCheckInVerificationSheet(PropertyModel? property) {
    final codeController = TextEditingController();
    bool isVerifying = false;
    String? resultMessage;
    bool? resultSuccess;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Verify Guest Check-in',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (property != null)
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF868686),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Result banner
                    if (resultMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: resultSuccess == true
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              resultSuccess == true
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: resultSuccess == true
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                resultMessage!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: resultSuccess == true
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Code input
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '------',
                        hintStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 6,
                          color: Colors.grey[300],
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF426DC2),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        // Clear result on new input
                        if (resultMessage != null) {
                          setSheetState(() {
                            resultMessage = null;
                            resultSuccess = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Enter the 6-character code provided by the guest',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isVerifying
                            ? null
                            : () async {
                                final code = codeController.text.trim();
                                if (code.length < 6) {
                                  setSheetState(() {
                                    resultMessage = 'Please enter the full 6-character code.';
                                    resultSuccess = false;
                                  });
                                  return;
                                }
                                setSheetState(() => isVerifying = true);
                                try {
                                  final response = await _hotelService.verifyCheckIn(code);
                                  setSheetState(() {
                                    isVerifying = false;
                                    resultSuccess = response.success;
                                    resultMessage = response.success
                                        ? (response.message ?? 'Guest checked in successfully!')
                                        : (response.message ?? 'Invalid or expired check-in code.');
                                  });
                                } catch (e) {
                                  setSheetState(() {
                                    isVerifying = false;
                                    resultSuccess = false;
                                    resultMessage = 'Something went wrong. Please try again.';
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF426DC2),
                          disabledBackgroundColor:
                              const Color(0xFF426DC2).withValues(alpha: 0.6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: isVerifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Verify Check-in',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, PropertyModel property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text('Are you sure you want to delete "${property.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close confirmation dialog first
              Navigator.of(context).pop();
              
              // Show loading indicator and store its context
              BuildContext? loadingDialogContext;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  loadingDialogContext = dialogContext;
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF426DC2)),
                    ),
                  );
                },
              );
              
              try {
                final propertyService = PropertyService();
                final success = await propertyService.deleteProperty(property.id);
                
                // Close loading indicator first, using the stored context
                if (loadingDialogContext != null) {
                  Navigator.of(loadingDialogContext!).pop();
                }
                
                if (mounted) {
                  if (success) {
                    // Refresh the property list first (this will rebuild the widget)
                    await _fetchMyProperties();
                    
                    // Wait for next frame to ensure widget tree is stable
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Property deleted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      });
                    }
                  } else {
                    // Wait for next frame before showing error message
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to delete property. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                  }
                }
              } catch (e) {
                // Always close loading indicator even on error
                if (loadingDialogContext != null) {
                  Navigator.of(loadingDialogContext!).pop();
                }
                
                // Wait for next frame before showing error message
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting property: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  });
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 