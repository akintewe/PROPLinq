import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'property_listing_view.dart';
import '../../finance/views/agent_kyc_view.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';

class ProfileView extends StatefulWidget {
  final bool isAgent;
  
  const ProfileView({super.key, this.isAgent = false});
  
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      print('🔄 Fetching user profile for profile screen...');
      
      final response = await _authService.getProfile();
      
      print('📋 Profile Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');
      
      if (response.success && response.data != null) {
        setState(() {
          _currentUser = response.data;
          _isLoadingProfile = false;
        });
        
        print('👤 User Profile Data for Profile Screen:');
        print('  - ID: ${_currentUser!.id}');
        print('  - Name: ${_currentUser!.fullName}');
        print('  - Email: ${_currentUser!.email}');
        print('  - User Type: "${_currentUser!.userType}"');
        print('  - Location: ${_currentUser!.location}');
        print('  - Phone: ${_currentUser!.phoneNumber}');
        if (_currentUser!.agencyName != null) {
          print('  - Agency: ${_currentUser!.agencyName}');
        }
        if (_currentUser!.agentType != null) {
          print('  - Agent Type: ${_currentUser!.agentType}');
        }
        if (_currentUser!.whatsappNumber != null) {
          print('  - WhatsApp: ${_currentUser!.whatsappNumber}');
        }
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
        print('❌ Failed to fetch profile: ${response.message}');
        if (response.errors != null && response.errors!.isNotEmpty) {
          print('❌ Errors: ${response.errors}');
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
      print('❌ Profile fetch error: $e');
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
      return _currentUser!.userType?.replaceAll('_', ' ') ?? 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                
                        // Contact Details Section
        widget.isAgent ? _buildAgentContactDetailsSection() : _buildContactDetailsSection(),
        
        const SizedBox(height: 40),
        
        // Apply for Agent Button (only for tenants)
        if (!widget.isAgent) _buildApplyForAgentButton(),
        
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
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: _isLoadingProfile 
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
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
                        Icons.camera_alt_outlined,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
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

  Widget _buildApplyForAgentButton() {
    return Container(
      width: double.infinity,
      height: 56,
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
        borderRadius: BorderRadius.circular(28),
      ),
      child: ElevatedButton(
        onPressed: () {
          // Handle apply for agent action
          _showApplyForAgentDialog();
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
          'Apply for agent',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showApplyForAgentDialog() {
    // This would typically show a dialog or navigate to agent application screen
    // For now, we'll just show a simple dialog
  }

  Widget _buildAgentActionButtons(BuildContext context) {
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AgentKycView(),
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
                'Complete KYC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF426DC2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKycInfoMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 32),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF426DC2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You are currently limited to listing 3 properties. To list more, please complete your KYC process.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF426DC2),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildCurrentListingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current listing',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildPropertyCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(int index) {
    final properties = [
      {
        'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center',
        'title': '3-Bedroom Apartment',
        'location': 'Lekki Phase 1, Lagos Nigeria',
        'rating': '5.0',
        'price': '#2,500,000',
        'badge': 'For sale'
      },
      {
        'image': 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600&h=400&fit=crop&crop=center',
        'title': '3-Bedroom Duplex',
        'location': 'Lekki Phase 1, Lagos Nigeria',
        'rating': '5.0',
        'price': '#3,200,000',
        'badge': 'For sale'
      },
    ];

    final property = properties[index];

    return Container(
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
                image: NetworkImage(property['image']!),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Badge
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
                      property['badge']!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // Favorite and More buttons
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
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
                      Container(
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
                          property['title']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Apartment',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF426DC2),
                          ),
                        ),
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
                          property['location']!,
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
                      Text(
                        '(${property['rating']!})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.green,
                      ),
                      const Spacer(),
                      Text(
                        property['price']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF426DC2),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () {},
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
            'Want to subscribe to monthly unlimited listing of properties?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
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
} 