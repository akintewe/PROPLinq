import 'package:flutter/material.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/utils/format_utils.dart';
import 'property_listing_view.dart';
import 'property_details_view.dart';
import 'subscription_view.dart';
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
import '../models/property_model.dart';
import '../widgets/booking_carousel_widget.dart';
import 'bookings_list_view.dart';

class ProfileView extends StatefulWidget {
  final bool isAgent;
  
  const ProfileView({super.key, this.isAgent = false});
  
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthService _authService = AuthService();
  final PropertyService _propertyService = PropertyService();
  final ImagePicker _imagePicker = ImagePicker();
  
  UserModel? _currentUser;
  bool _isLoadingProfile = true;
  bool _isUploadingImage = false;
  KycStatusResponse? _kycStatus;
  bool _isLoadingKycStatus = true;
  List<PropertyModel> _myProperties = [];
  bool _isLoadingMyProperties = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    // Fetch KYC status for both agents and tenants
    _fetchKycStatus();
    // Fetch agent's properties if they are an agent
    if (widget.isAgent) {
      _fetchMyProperties();
    }
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
        setState(() {
          _currentUser = response.data;
          _isLoadingProfile = false;
        });
        
        if (_currentUser!.agencyName != null) {
        }
        if (_currentUser!.agentType != null) {
        }
        if (_currentUser!.whatsappNumber != null) {
        }
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
        if (response.errors != null && response.errors!.isNotEmpty) {
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _fetchKycStatus() async {
    try {
      final userType = widget.isAgent ? 'agent' : 'tenant/home seeker';
      
      final response = await _authService.getKycStatus();
      
      
      if (response.success) {
        setState(() {
          _kycStatus = response.data;
          _isLoadingKycStatus = false;
        });
        
        if (_kycStatus != null) {
        } else {
        }
      } else {
        setState(() {
          _isLoadingKycStatus = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingKycStatus = false;
      });
    }
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
    
    if (_currentUser!.userType == 'agent') {
      // For agents, show their specific agent type if available
      if (_currentUser!.agentType != null) {
        return _currentUser!.agentType!
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
      }
      return 'Agent';
    } else if (_currentUser!.userType == 'home_seeker') {
      return 'Home Seeker';
    } else {
      return _currentUser!.userType.replaceAll('_', ' ');
    }
  }

  /// Refresh all data (profile, KYC status, and properties)
  Future<void> _refreshAllData() async {
    
    // Refresh user profile
    await _fetchUserProfile();
    
    // Refresh KYC status
    await _fetchKycStatus();
    
    // Refresh agent properties if user is an agent
    if (widget.isAgent) {
      await _fetchMyProperties();
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
              color: const Color(0xFF426DC2).withOpacity(0.1),
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
          _buildSubscriptionSection(),
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
                              color: Colors.black.withOpacity(0.3),
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
                                  child: Image.network(
                                    _currentUser!.profilePicture!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
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
                            color: Colors.black.withOpacity(0.1),
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
                    
                    // Name
                    Text(
                      _isLoadingProfile 
                          ? 'Loading...' 
                          : _currentUser?.fullName ?? 'User Name',
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
        const Text(
          'Contact details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Full Name
        _buildContactDetailItem(
          icon: Icons.person,
          iconColor: const Color(0xFF426DC2),
          label: 'Full Name',
          value: _isLoadingProfile 
              ? 'Loading...' 
              : _currentUser?.fullName ?? 'Not provided',
        ),
        
        const SizedBox(height: 24),
        
        // Email
        _buildContactDetailItem(
          icon: Icons.email,
          iconColor: const Color(0xFF426DC2),
          label: 'Email',
          value: _isLoadingProfile 
              ? 'Loading...' 
              : _currentUser?.email ?? 'Not provided',
        ),
        
        const SizedBox(height: 24),
        
        // Phone Number
        _buildContactDetailItem(
          icon: Icons.phone,
          iconColor: const Color(0xFF426DC2),
          label: 'Phone number',
          value: _isLoadingProfile 
              ? 'Loading...' 
              : _currentUser?.phoneNumber ?? 'Not provided',
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
    
    // If KYC is approved, only show the "List a property" button
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
          child: Container(
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
    // Don't show info message if KYC is approved
    if (!_isLoadingKycStatus && _kycStatus != null && _kycStatus!.isKycVerified()) {
      return const SizedBox.shrink();
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
    
    if (!_isLoadingKycStatus && _kycStatus != null) {
      if (_kycStatus!.isKycVerified()) {
        kycButtonText = 'View KYC Status';
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
              Container(
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
        const Text(
          'Contact details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Full Name
        _buildContactDetailItem(
          icon: Icons.person,
          iconColor: const Color(0xFF426DC2),
          label: 'Full Name',
          value: _isLoadingProfile 
              ? 'Loading...' 
              : _currentUser?.fullName ?? 'Not provided',
        ),
        
        const SizedBox(height: 24),
        
        // Agency Name (only for agents)
        if (_currentUser?.agencyName != null || _isLoadingProfile) ...[
          _buildContactDetailItem(
            icon: Icons.business,
            iconColor: const Color(0xFF426DC2),
            label: 'Agency Name',
            value: _isLoadingProfile 
                ? 'Loading...' 
                : _currentUser?.agencyName ?? 'Not provided',
          ),
          
          const SizedBox(height: 24),
        ],
        
        // Email
        _buildContactDetailItem(
          icon: Icons.email,
          iconColor: const Color(0xFF426DC2),
          label: 'Email',
          value: _isLoadingProfile 
              ? 'Loading...' 
              : _currentUser?.email ?? 'Not provided',
        ),
        
        const SizedBox(height: 24),
        
        // Phone Number
        _buildContactDetailItem(
          icon: Icons.phone,
          iconColor: const Color(0xFF426DC2),
          label: 'Phone number',
          value: _isLoadingProfile 
              ? 'Loading...' 
              : _currentUser?.phoneNumber ?? 'Not provided',
        ),
        
        const SizedBox(height: 24),
        
        // WhatsApp Number (only for agents)
        _buildContactDetailItem(
          icon: Icons.chat,
          iconColor: const Color(0xFF426DC2),
          label: 'Whatsapp number',
          value: _isLoadingProfile 
              ? 'Loading...' 
              : _currentUser?.whatsappNumber ?? _currentUser?.phoneNumber ?? 'Not provided',
        ),
        
        const SizedBox(height: 24),
        
        // Location
        _buildContactDetailItem(
          icon: Icons.location_on,
          iconColor: const Color(0xFF426DC2),
          label: 'Location',
          value: _isLoadingProfile 
              ? 'Loading...' 
              : _currentUser?.location ?? 'Not provided',
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BookingsListView(),
                  ),
                );
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
        
        // Bookings carousel
        const BookingCarouselWidget(),
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
        
        SizedBox(
          height: 300,
          child: _isLoadingMyProperties
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _myProperties.isEmpty
                  ? _buildEmptyPropertiesState()
                  : ListView.separated(
            scrollDirection: Axis.horizontal,
                      itemCount: _myProperties.length, // Show all properties with horizontal scrolling
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildPropertyCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPropertiesState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Column(
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
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                if ((property.category == 'for_rent' || property.category == 'for_sale') &&
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
                          onTap: () {
                            _promoteProperty(property);
                          },
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.star,
                              size: 16,
                              color: Color(0xFFFFA726),
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                            property.title,
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
                          if ((property.category == 'for_rent' || property.category == 'for_sale') &&
                              property.type.toLowerCase() != 'hotel')
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                property.category == 'for_rent' ? 'For Rent' : 'For Sale',
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
                      // Approved & live tag
                      Container(
                        width: 90,
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFBEA), // rgba(204, 251, 234, 1)
                          borderRadius: BorderRadius.circular(70),
                        ),
                        child: const Center(
                          child: Text(
                            'Approved & live',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF008D5A), // rgba(0, 141, 90, 1)
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        property.rawJson?['average_rating']?.toString() ?? '0.0',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber,
                      ),
                      if (property.rawJson?['rating_count'] != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${property.rawJson!['rating_count']})',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF666666),
                          ),
                      ),
                      ],
                      const Spacer(),
                      Flexible(
                        child: Text(
                        FormatUtils.formatPrice(property.price),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF426DC2),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Show both buttons side by side only for hotels
                  if (property.type.toLowerCase() == 'hotel')
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              onPressed: () {
                                _promoteProperty(property);
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF426DC2),
                                side: const BorderSide(color: Color(0xFF426DC2), width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                              child: const Text(
                                'Promote property',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF426DC2),
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
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment(-0.99, 0.0),
                                  end: Alignment(0.99, 0.0),
                                  stops: [0.0113, 0.4555, 1.1245],
                                  colors: [
                                    Color(0xFF426DC2),
                                    Color(0xFF75CFEA),
                                    Color(0xCC33CC99),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                ),
                                child: const Text(
                                  'Confirm check-in',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // For non-hotels, show only Promote property button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () {
                          _promoteProperty(property);
                        },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF426DC2),
                        side: const BorderSide(color: Color(0xFF426DC2), width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text(
                        'Promote property',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF426DC2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Unlock Unlimited Listings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
            const Text(
            'Subscribe for boundess property uploads',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionView(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child:  Text(
                'Subscribe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF426DC2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
           
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF426DC2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'J',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'James',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Home Seeker',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < 4 ? Icons.star : Icons.star_border,
                        size: 16,
                        color: index < 4 ? Colors.green : Colors.grey,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Very professional and reliable. [Agent\'s Name] made the entire process smooth and stress-free. I found the perfect apartment within a week!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
                  color: const Color(0xFF426DC2).withOpacity(0.1),
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
                  color: const Color(0xFFFFA726).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(0xFFFFA726),
                ),
              ),
              title: const Text(
                'Promote Property',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Feature this property in promoted listings',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF868686),
                ),
              ),
              onTap: () {
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
                  color: Colors.red.withOpacity(0.1),
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