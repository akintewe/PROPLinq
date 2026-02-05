import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:proplinq/core/constants/api_constants.dart';
import 'package:proplinq/core/widgets/google_map_widget.dart';
import 'package:proplinq/core/services/bookings_cache_service.dart';
import 'package:share_plus/share_plus.dart';
import 'virtual_tour_360_view.dart';
import 'hotel_reservation_view.dart';
import 'in_app_chat_view.dart';
import '../../auth/services/auth_service.dart';
import '../services/recently_viewed_service.dart';
import '../services/property_service.dart';

class PropertyDetailsView extends StatefulWidget {
  final Map<String, dynamic>? propertyData;
  final bool isHomeSeeker;
  
  const PropertyDetailsView({
    super.key, 
    this.propertyData,
    this.isHomeSeeker = true, // Default to true for home seekers
  });

  @override
  State<PropertyDetailsView> createState() => _PropertyDetailsViewState();
}

class _PropertyDetailsViewState extends State<PropertyDetailsView> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  late AnimationController _textAnimationController;
  int _currentTextIndex = 0;
  Timer? _textTimer;
  final AuthService _authService = AuthService();
  final RecentlyViewedService _recentlyViewedService = RecentlyViewedService();
  final PropertyService _propertyService = PropertyService();
  final BookingsCacheService _bookingsCacheService = BookingsCacheService();
  bool _isOwner = false;
  Map<String, dynamic>? _currentPropertyData;
  int _inlineRating = 0;
  final TextEditingController _inlineCommentController = TextEditingController();
  bool _isSubmittingRating = false;
  late bool _hasBookedProperty;
  
  // Default fallback images for when property has no images
  final List<String> _fallbackImages = [
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600&h=400&fit=crop&crop=center',
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600&h=400&fit=crop&crop=center',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600&h=400&fit=crop&crop=center',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=600&h=400&fit=crop&crop=center',
  ];

  // Promotional messages for rotating banner
  final List<String> _promotionalMessages = [
    "Welcome to Proplinq, Nigeria's trusted home & hotel marketplace!",
    "Find your next home or hotel faster, safer, and easier with Proplinq.",
    "Verified agents, hotels, and shortlets all in one place.",
    "Start exploring now, your journey with Proplinq begins here!",
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize blur state IMMEDIATELY (before any async operations)
    _hasBookedProperty = _checkIfPropertyBookedSync();
    
    _initializeTextAnimation();
    _startTextRotation();
    _checkPropertyOwnership();
    _addToRecentlyViewed();
    _refreshPropertyData();
    
    // Refresh bookings cache in background if needed
    _refreshBookingsCacheIfNeeded();
  }
  
  /// Refresh property data to get latest ratings
  Future<void> _refreshPropertyData() async {
    try {
      final property = widget.propertyData ?? _getDefaultProperty();
      final propertyId = property['id'];
      
      if (propertyId != null) {
        final updatedProperty = await _propertyService.fetchPropertyDetails(int.parse(propertyId.toString()));
        if (updatedProperty != null && mounted) {
          setState(() {
            _currentPropertyData = updatedProperty.rawJson;
          });
        }
      }
    } catch (e) {
      print('Error refreshing property data: $e');
    }
  }

  /// Add property to recently viewed when opened
  Future<void> _addToRecentlyViewed() async {
    try {
      final property = widget.propertyData ?? _getDefaultProperty();
      print('👁️ [PropertyDetailsView] Adding to recently viewed: property=${property['id']}, title=${property['title']}');
      
      // Ensure property has an ID
      if (property['id'] == null) {
        print('⚠️ [PropertyDetailsView] Property has no ID, cannot add to recently viewed');
        return;
      }
      
      await _recentlyViewedService.addToRecentlyViewed(property);
      print('✅ [PropertyDetailsView] Successfully added to recently viewed');
    } catch (e, stackTrace) {
      print('❌ [PropertyDetailsView] Error adding to recently viewed: $e');
      print('❌ [PropertyDetailsView] Stack trace: $stackTrace');
    }
  }
  
  Future<void> _checkPropertyOwnership() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      final property = widget.propertyData ?? _getDefaultProperty();
      final propertyUser = property['user'] as Map<String, dynamic>?;
      final propertyUserId = propertyUser?['id']?.toString();
      
      
      if (currentUser != null && propertyUserId != null) {
        setState(() {
          _isOwner = currentUser.id.toString() == propertyUserId;
        });
      } else {
      }
    } catch (e) {
    }
  }
  
  /// Check if user has booked this property (SYNCHRONOUS - uses cache)
  bool _checkIfPropertyBookedSync() {
    try {
      final property = widget.propertyData ?? _getDefaultProperty();
      final propertyId = property['id']?.toString();
      final propertyType = (property['type'] as String?)?.toLowerCase() ?? '';
      
      // Only check for shortlets
      if (!propertyType.contains('shortlet')) {
        return false;
      }
      
      if (propertyId == null) {
        return false;
      }
      
      // Check cached bookings IMMEDIATELY (no async, no delay)
      final hasBooked = _bookingsCacheService.hasBookedProperty(propertyId);
      
      print(hasBooked 
          ? '✅ [PropertyDetailsView] User has booked shortlet $propertyId (cached)'
          : '🔒 [PropertyDetailsView] User has not booked shortlet $propertyId (cached)');
      
      return hasBooked;
    } catch (e) {
      print('❌ [PropertyDetailsView] Error checking cached bookings: $e');
      return false; // Default to blurred on error
    }
  }
  
  /// Refresh bookings cache in background if needed
  Future<void> _refreshBookingsCacheIfNeeded() async {
    try {
      final property = widget.propertyData ?? _getDefaultProperty();
      final propertyType = (property['type'] as String?)?.toLowerCase() ?? '';
      
      // Only refresh for shortlets
      if (!propertyType.contains('shortlet')) {
        return;
      }
      
      // Fetch and cache bookings in background
      await _bookingsCacheService.fetchAndCacheBookings();
      
      if (!mounted) return;
      
      // Re-check booking status after cache refresh
      final hasBooked = _checkIfPropertyBookedSync();
      
      // Update UI if status changed
      if (_hasBookedProperty != hasBooked) {
        setState(() {
          _hasBookedProperty = hasBooked;
        });
        print('🔄 [PropertyDetailsView] Booking status updated after cache refresh');
      }
    } catch (e) {
      print('❌ [PropertyDetailsView] Error refreshing bookings cache: $e');
    }
  }

  void _initializeTextAnimation() {
    _textAnimationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
  }

  /// Share property with deep link
  Future<void> _shareProperty(BuildContext context) async {
    try {
      final property = widget.propertyData ?? _getDefaultProperty();
      
      
      // Get property ID - property.id is an int, so handle both int and string
      String? propertyId;
      final idValue = property['id'];
      
      if (idValue != null) {
        // Handle both int and string IDs
        if (idValue is int) {
          propertyId = idValue.toString();
        } else if (idValue is String) {
          propertyId = idValue;
        } else {
          propertyId = idValue.toString();
        }
      }
      
      // Fallback: Try to get from images
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to share: Property ID not found. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Get property type for reference (not needed for OneLink, but kept for logging)
      final propertyType = (property['type'] as String? ?? 'Apartment').toLowerCase();
      
      // Generate AppsFlyer OneLink URL (HTTPS link that will be clickable)
      // This link will redirect to the app if installed, or to web if not
      final shareLinkUrl = ApiConstants.generateShareLink(
        propertyId: propertyId,
        propertyType: propertyType,
      );
      
      // Get property details for share message
      final title = property['title'] as String? ?? 'Property';
      final location = property['location'] as String? ?? '';
      final price = property['price'] as String? ?? '';
      
      // Create share text with HTTPS link prominently displayed
      final shareText = '''🏠 $title

📍 Location: $location
💰 Price: $price

━━━━━━━━━━━━━━━━━━━━
🔗 VIEW PROPERTY:
$shareLinkUrl
━━━━━━━━━━━━━━━━━━━━

Tap the link above to view this property in the Proplinq app!

If you don't have the app, the link will open in your browser where you can download it.''';
      
      
      // Show a preview dialog first to confirm the deep link is generated
      if (context.mounted) {
        final shouldShare = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share Property'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Property: $title'),
                const SizedBox(height: 8),
                const Text(
                  'Share Link:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  shareLinkUrl,
                  style: const TextStyle(
                    color: Color(0xFF426DC2),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This HTTPS link will open the property in the Proplinq app if installed, or in your browser otherwise.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF426DC2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Share'),
              ),
            ],
          ),
        );
        
        if (shouldShare != true) {
          return;
        }
      }
      
      // Share using platform share sheet
      final result = await Share.share(
        shareText,
        subject: 'Check out this property: $title',
      );
      
      if (result.status == ShareResultStatus.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Property shared! Link: $shareLinkUrl'),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () {
                  // Copy share link to clipboard
                  // Note: You'd need to add clipboard package for this
                },
              ),
            ),
          );
        }
      } else if (result.status == ShareResultStatus.dismissed) {
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing property: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _startTextRotation() {
    _textTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentTextIndex = (_currentTextIndex + 1) % _promotionalMessages.length;
        });
      }
    });
  }

  /// Show full-screen image gallery dialog
  void _showImageGallery(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => ImageGalleryDialog(
        images: images,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textAnimationController.dispose();
    _textTimer?.cancel();
    _inlineCommentController.dispose();
    super.dispose();
  }

  /// Build verification badge based on property data
  Widget _buildVerificationBadge(Map<String, dynamic> property) {
    // Check if we have user data with KYC status
    final user = property['user'] as Map<String, dynamic>?;
    final kyc = user?['kyc'] as Map<String, dynamic>?;
    final kycStatus = kyc?['status'] as String?;
    
    IconData icon;
    Color iconColor;
    String text;
    Color backgroundColor;
    Color textColor;

    switch (kycStatus) {
      case 'verified':
        icon = Icons.verified;
        iconColor = Colors.green;
        text = 'Verified';
        backgroundColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'pending':
        icon = Icons.pending;
        iconColor = Colors.orange;
        text = 'Pending';
        backgroundColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;
      case 'rejected':
        icon = Icons.cancel;
        iconColor = Colors.red;
        text = 'Rejected';
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      default:
        icon = Icons.pending;
        iconColor = Colors.orange;
        text = 'Unverified';
        backgroundColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build small verification badge for header
  Widget _buildSmallVerificationBadge(Map<String, dynamic> property) {
    // Check if we have user data with KYC status
    final user = property['user'] as Map<String, dynamic>?;
    final kyc = user?['kyc'] as Map<String, dynamic>?;
    final kycStatus = kyc?['status'] as String?;
    
    IconData icon;
    Color iconColor;
    String text;

    switch (kycStatus) {
      case 'verified':
        icon = Icons.verified;
        iconColor = Colors.green;
        text = 'Verified';
        break;
      case 'pending':
        icon = Icons.pending;
        iconColor = Colors.orange;
        text = 'Pending';
        break;
      case 'rejected':
        icon = Icons.cancel;
        iconColor = Colors.red;
        text = 'Rejected';
        break;
      default:
        icon = Icons.pending;
        iconColor = Colors.orange;
        text = 'Unverified';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECF0F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF426DC2),
            ),
          ),
        ],
      ),
    );
  }


  /// Get agent name from property data
  String _getAgentName(Map<String, dynamic> property) {
    final user = property['user'] as Map<String, dynamic>?;
    if (user != null && user['full_name'] != null) {
      return user['full_name'] as String;
    }
    // Fallback to agent data if user data not available
    final agent = property['agent'] as Map<String, dynamic>?;
    return agent?['name'] as String? ?? 'Agent';
  }

  /// Get agent title from property data
  String _getAgentTitle(Map<String, dynamic> property) {
    final user = property['user'] as Map<String, dynamic>?;
    if (user != null && user['agent_type'] != null) {
      final agentType = user['agent_type'] as String;
      return agentType.replaceAll('_', ' ').split(' ').map((word) => 
        word[0].toUpperCase() + word.substring(1)
      ).join(' ');
    }
    // Fallback to agent data if user data not available
    final agent = property['agent'] as Map<String, dynamic>?;
    return agent?['title'] as String? ?? 'Agent';
  }

  /// Get agent phone from property data
  String _getAgentPhone(Map<String, dynamic> property) {
    final user = property['user'] as Map<String, dynamic>?;
    if (user != null && user['phone_number'] != null) {
      return user['phone_number'] as String;
    }
    // Fallback to agent data if user data not available
    final agent = property['agent'] as Map<String, dynamic>?;
    return agent?['phone'] as String? ?? '';
  }

  /// Get agent email from property data
  String _getAgentEmail(Map<String, dynamic> property) {
    final user = property['user'] as Map<String, dynamic>?;
    if (user != null && user['email'] != null) {
      return user['email'] as String;
    }
    // Fallback to agent data if user data not available
    final agent = property['agent'] as Map<String, dynamic>?;
    return agent?['email'] as String? ?? '';
  }

  /// Get agent WhatsApp from property data
  String _getAgentWhatsApp(Map<String, dynamic> property) {
    final user = property['user'] as Map<String, dynamic>?;
    if (user != null && user['whatsapp_number'] != null) {
      return user['whatsapp_number'] as String;
    }
    if (user != null && user['phone_number'] != null) {
      return user['phone_number'] as String;
    }
    // Fallback to agent data if user data not available
    final agent = property['agent'] as Map<String, dynamic>?;
    return agent?['whatsapp'] as String? ?? agent?['phone'] as String? ?? '';
  }

  /// Get agent profile image from property data
  String? _getAgentProfileImage(Map<String, dynamic> property) {
    
    final user = property['user'] as Map<String, dynamic>?;
    
    if (user != null && user['profile_image_full_url'] != null) {
      final profileImageUrl = user['profile_image_full_url'] as String;
      return profileImageUrl;
    }
    
    
    // Fallback to agent data if user data not available
    final agent = property['agent'] as Map<String, dynamic>?;
    return agent?['profile_image'] as String?;
  }


  /// Mark property as rented (for agents only)
  void _markAsRented() {
    // TODO: Implement mark as rented functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mark as rented functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Show report listing dialog
  void _showRatingDialog() {
    int selectedRating = 0;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Rate Property',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How would you rate this property?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Star rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedRating = starIndex;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              starIndex <= selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 40,
                              color: starIndex <= selectedRating
                                  ? Colors.amber
                                  : Colors.grey[300],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        selectedRating > 0
                            ? _getRatingText(selectedRating)
                            : 'Tap a star to rate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Comment field
                    const Text(
                      'Add a comment (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF426DC2),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting || selectedRating == 0
                      ? null
                      : () async {
                          setDialogState(() {
                            isSubmitting = true;
                          });

                          final property = _currentPropertyData ?? widget.propertyData ?? _getDefaultProperty();
                          final propertyId = property['id'];

                          if (propertyId == null) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error: Property ID not found'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            final response = await _propertyService.rateProperty(
                              propertyId: int.parse(propertyId.toString()),
                              rating: selectedRating,
                              comment: commentController.text.trim(),
                            );

                            if (!mounted) return;

                            if (response.success) {
                              // Refresh property data to get updated ratings list
                              await _refreshPropertyData();

                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    response.message ?? 'Rating submitted successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    response.message ?? 'Failed to submit rating',
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF426DC2),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Widget _buildRatingsSection(Map<String, dynamic> property) {
    // Use updated property data if available
    final displayProperty = _currentPropertyData ?? property;
    
    // Debug: Print property data to check for ratings
    print('🔍 [RatingsSection] Property keys: ${displayProperty.keys.toList()}');
    print('🔍 [RatingsSection] Has ratings key: ${displayProperty.containsKey('ratings')}');
    print('🔍 [RatingsSection] Ratings value: ${displayProperty['ratings']}');
    print('🔍 [RatingsSection] Average rating: ${displayProperty['average_rating']}');
    print('🔍 [RatingsSection] Rating count: ${displayProperty['rating_count']}');
    
    // Extract ratings - handle different possible structures
    dynamic ratingsRaw = displayProperty['ratings'];
    List<dynamic> ratings = [];
    
    if (ratingsRaw != null) {
      if (ratingsRaw is List) {
        ratings = ratingsRaw;
        print('🔍 [RatingsSection] Found ${ratings.length} ratings');
      } else {
        print('🔍 [RatingsSection] Ratings is not a List, type: ${ratingsRaw.runtimeType}');
      }
    } else {
      print('🔍 [RatingsSection] No ratings found in property data');
    }
    
    final averageRating = displayProperty['average_rating']?.toString() ?? 
                         displayProperty['rating']?.toString() ?? 
                         '0.0';
    final ratingCount = displayProperty['rating_count']?.toString() ?? 
                       ratings.length.toString();
    
    print('🔍 [RatingsSection] Final ratings count: ${ratings.length}, average: $averageRating, count: $ratingCount');

    // Always show the section, even if empty
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ratings & Reviews',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: Colors.amber[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      averageRating,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($ratingCount ${ratingCount == 1 ? 'review' : 'reviews'})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Average rating display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber[400]!,
                    Colors.amber[600]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    averageRating,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Rate Property Form (Jumia style) - hide if owner
        if (!_isOwner) _buildInlineRatingForm(displayProperty),
        
        const SizedBox(height: 24),
        
        // Existing Ratings List
        if (ratings.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.star_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No ratings yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to rate this property',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else
          ...ratings.map((rating) => _buildRatingCard(rating as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildInlineRatingForm(Map<String, dynamic> property) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate this property',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // Star rating selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your rating:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
              ...List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _inlineRating = starIndex;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      starIndex <= _inlineRating
                          ? Icons.star
                          : Icons.star_border,
                      size: 32,
                      color: starIndex <= _inlineRating
                          ? Colors.amber[600]
                          : Colors.grey[300],
                    ),
                  ),
                );
              }),
              if (_inlineRating > 0) ...[
                const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                  _getRatingText(_inlineRating),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[700],
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Comment box
          TextField(
            controller: _inlineCommentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write your review (optional)',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF426DC2),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmittingRating || _inlineRating == 0
                  ? null
                  : () async {
                      setState(() {
                        _isSubmittingRating = true;
                      });

                      final propertyId = property['id'];

                      if (propertyId == null) {
                        setState(() {
                          _isSubmittingRating = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: Property ID not found'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        final response = await _propertyService.rateProperty(
                          propertyId: int.parse(propertyId.toString()),
                          rating: _inlineRating,
                          comment: _inlineCommentController.text.trim(),
                        );

                        if (!mounted) return;

                        if (response.success) {
                          // Refresh property data to get updated ratings list
                          await _refreshPropertyData();
                          
                          // Reset form
                            setState(() {
                              _inlineRating = 0;
                              _inlineCommentController.clear();
                            _isSubmittingRating = false;
                            });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                response.message ?? 'Rating submitted successfully!',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          setState(() {
                            _isSubmittingRating = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                response.message ?? 'Failed to submit rating',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        setState(() {
                          _isSubmittingRating = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF426DC2),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmittingRating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Rating',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final user = rating['user'] as Map<String, dynamic>? ?? {};
    final userName = user['name']?.toString() ?? 'Anonymous';
    final userImage = user['profile_image']?.toString();
    final ratingValue = rating['rating'] as int? ?? 0;
    final comment = rating['comment']?.toString() ?? '';
    final createdAt = rating['created_at']?.toString() ?? '';

    // Format date
    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(dateTime);

        if (difference.inDays == 0) {
          formattedDate = 'Today';
        } else if (difference.inDays == 1) {
          formattedDate = 'Yesterday';
        } else if (difference.inDays < 7) {
          formattedDate = '${difference.inDays} days ago';
        } else if (difference.inDays < 30) {
          final weeks = (difference.inDays / 7).floor();
          formattedDate = '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
        } else {
          formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
        }
      } catch (e) {
        formattedDate = createdAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              // User avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: userImage != null && userImage.isNotEmpty
                      ? Image.network(
                          userImage,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFECF0F9),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF426DC2),
                                size: 24,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFECF0F9),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF426DC2),
                            size: 24,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // User name and date
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
                    if (formattedDate.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Star rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < ratingValue ? Icons.star : Icons.star_border,
                    size: 18,
                    color: index < ratingValue ? Colors.amber[600] : Colors.grey[300],
                  );
                }),
              ),
            ],
          ),
          
          // Comment
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              comment,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Report Listing',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: const Text(
            'If you believe this listing violates our terms of service or contains inappropriate content, please report it. Our team will review your report.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement report submission
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted. Thank you!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF426DC2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Get 360 panorama images from property data
  List<String> _getProperty360Images() {
    final property = widget.propertyData ?? _getDefaultProperty();
    
    
    // Check if property has property360_images array
    if (property['property360_images'] != null && property['property360_images'] is List) {
      final images = property['property360_images'] as List<dynamic>;
      
      if (images.isNotEmpty) {
        final imageUrls = images.map((image) {
          
          if (image is Map<String, dynamic> && image['full_url'] != null) {
            return image['full_url'].toString();
          }
          return '';
        }).where((url) => url.isNotEmpty).toList();
        
        return imageUrls;
      }
    }
    
    // Check alternative field: property_360_images_full_urls
    if (property['property_360_images_full_urls'] != null && property['property_360_images_full_urls'] is List) {
      final images = property['property_360_images_full_urls'] as List<dynamic>;
      
      if (images.isNotEmpty) {
        final imageUrls = images.map((image) {
          
          if (image is Map<String, dynamic> && image['url'] != null) {
            return image['url'].toString();
          }
          return '';
        }).where((url) => url.isNotEmpty).toList();
        
        return imageUrls;
      }
    }
    
    // Check regular images array for 360 images (based on URL path)
    if (property['images'] != null && property['images'] is List) {
      final images = property['images'] as List<dynamic>;
      
      final imageUrls = <String>[];
      for (final image in images) {
        if (image is Map<String, dynamic> && image['full_url'] != null) {
          final url = image['full_url'].toString();
          
          // Check if this is a 360 image based on the URL path
          if (url.contains('property-360-images/')) {
            imageUrls.add(url);
          } else {
          }
        }
      }
      
      if (imageUrls.isNotEmpty) {
        return imageUrls;
      }
    }
    
    return [];
  }

  /// Get video URL from property data
  String? _getPropertyVideo() {
    final property = widget.propertyData ?? _getDefaultProperty();
    
    
    final videoUrl = property['video_url'] as String?;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      return videoUrl;
    }
    
    return null;
  }

  /// Get property images from property data, fallback to default images
  List<String> _getPropertyImages() {
    final property = widget.propertyData ?? _getDefaultProperty();
    
    
    // Check if property has multiple images array first (prioritize multiple images)
    if (property['images'] != null && property['images'] is List) {
      final images = property['images'] as List<dynamic>;
      
      if (images.isNotEmpty) {
        final imageUrls = images.map((image) {
          
          if (image is Map<String, dynamic> && image['full_url'] != null) {
            return image['full_url'].toString();
          } else if (image is String) {
            return image;
          }
          return _fallbackImages.first;
        }).toList();
        
        return imageUrls;
      }
    }
    
    // Check if property has imageUrl (fallback for single image)
    if (property['imageUrl'] != null && property['imageUrl'].toString().isNotEmpty) {
      // If we have a real property image, use it as the primary image
      return [property['imageUrl'].toString()];
    }
    
    // Fallback to default images
    return _fallbackImages;
  }

  Map<String, dynamic> _getDefaultProperty() {
    return {
      'badges': ['Verified Agent'],
      'title': '3-Bedroom Apartment',
      'location': 'Lekki Phase 1, Lagos Nigeria',
      'rating': '(5.0)',
      'price': '#2,500,000',
      'type': 'Apartment',
      'description': 'Step into luxury with this fully furnished 3-bedroom apartment located in the heart of Lekki Phase 1. With modern finishes, spacious rooms, a fitted kitchen, and round-the-clock security, it\'s perfect for professionals, small families, or remote workers seeking comfort and convenience.',
      'agent': {
        'name': 'James Mark',
        'title': 'Agent',
        'phone': '09011111111',
        'email': 'jamesmark@gmail.com',
        'whatsapp': '08111111111',
      },
      'features': ['3-bedroom', '3 Bathrooms', 'Dedicated Parking', 'Gated & Secured Estate'],
    };
  }

  @override
  Widget build(BuildContext context) {
    // Get property data or use defaults (prefer updated data from rating)
    final property = _currentPropertyData ?? widget.propertyData ?? _getDefaultProperty();
    // Derive a propertyId if missing (e.g., from images list)
    String derivedPropertyId = (property['id']?.toString()) ?? '';
    if (derivedPropertyId.isEmpty) {
      final images = property['images'];
      if (images is List && images.isNotEmpty) {
        final first = images.first;
        if (first is Map<String, dynamic>) {
          final pid = first['property_id'];
          if (pid != null) {
            derivedPropertyId = pid.toString();
          }
        }
      }
    }
    final propertyType = property['type'] as String? ?? 'Apartment';
    final normalizedType = propertyType.toLowerCase();
    final isHotel = normalizedType == 'hotel';
    final isShortlet = normalizedType == 'shortlet';
    
    // Debug: Print property data to see what's available
    
    // Get actual property images
    final propertyImages = _getPropertyImages();
    final property360Images = _getProperty360Images();
    
    // Debug logging
    
    final badges = property['badges'];
    final isForSale = (badges is List && badges.isNotEmpty) 
        ? badges.any((badge) => badge.toString().toLowerCase().contains('for sale'))
        : false;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Image carousel section
                SizedBox(
                  height: 400,
                  child: Stack(
                    children: [
                      // Image PageView - Make it clickable to open full-screen gallery
                      GestureDetector(
                        onTap: () {
                          _showImageGallery(context, propertyImages, _currentImageIndex);
                        },
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemCount: propertyImages.length,
                          itemBuilder: (context, index) {
                            return _buildImageWithLoader(
                              imageUrl: propertyImages[index],
                              height: 400,
                            );
                          },
                        ),
                      ),
                      
                      // Top overlay buttons
                      Positioned(
                        top: 60,
                        left: 24,
                        right: 24,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Color(0xFF426DC2),
                                  size: 20,
                                ),
                              ),
                            ),
                            
                            // Share and favorite buttons
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _shareProperty(context),
                                  child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.share,
                                    color: Color(0xFF426DC2),
                                    size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_border,
                                    color: Color(0xFF426DC2),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Image dots indicator
                      Positioned(
                        bottom: 60,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            propertyImages.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.2),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Curved white container with property details
                Transform.translate(
                  offset: const Offset(0, -30), // Overlap the image
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property type badge (Hotel/Apartment) at top corner
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECF0F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  propertyType,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF426DC2),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Only show verification badge for non-hotel properties
                              if (!isHotel) ...[
                                _buildSmallVerificationBadge(property),
                              ],
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Property title and rating
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  property['title'] as String? ?? 'Property',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  Text(
                                    property['average_rating']?.toString() ?? 
                                    property['rating']?.toString() ?? 
                                    '5.0',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.star,
                                    size: 18,
                                    color: Colors.amber,
                                  ),
                                  if (property['rating_count'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        '(${property['rating_count']})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Color(0xFF868686),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: (isShortlet && !_hasBookedProperty)
                                    ? _buildBlurredText(property['location'] as String? ?? 'Location not specified')
                                    : Text(
                                        property['location'] as String? ?? 'Location not specified',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF868686),
                                        ),
                                        softWrap: true,
                                      ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Promotional banner right under location
                          if (!isHotel) ...[
                            _buildScrollingPromotionalBanner(),
                            const SizedBox(height: 24),
                          ] else ...[
                            const SizedBox(height: 8),
                          ],
                          
                          // Description
                          Text(
                            property['description'] as String? ?? 'No description available',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Color(0xFF666666),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Agent Details - only show for non-hotel properties
                          if (!isHotel) ...[
                            const Text(
                              'Agent Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Agent info
                            Row(
                              children: [
                                // Agent avatar
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: _getAgentProfileImage(property) != null
                                        ? DecorationImage(
                                            image: NetworkImage(_getAgentProfileImage(property)!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: _getAgentProfileImage(property) == null 
                                        ? Colors.grey[300] 
                                        : null,
                                  ),
                                  child: _getAgentProfileImage(property) == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                          size: 24,
                                        )
                                      : null,
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Agent name and title
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getAgentName(property),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        _getAgentTitle(property),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF868686),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Verification badge positioned to the right
                                _buildVerificationBadge(property),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Info banner for blurred contacts (shortlets only)
                            if (isShortlet && !_hasBookedProperty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFFB547),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: const Color(0xFFFF9800),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Book this shortlet to view agent contact details',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: const Color(0xFF663C00),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Contact info
                            Column(
                              children: [
                                _buildContactRow(
                                  'assets/icons/fluent_call-24-filled.svg', 
                                  _getAgentPhone(property),
                                  shouldBlur: isShortlet && !_hasBookedProperty,
                                ),
                                const SizedBox(height: 16),
                                _buildContactRow('assets/icons/majesticons_mail.svg', _getAgentEmail(property)),
                                const SizedBox(height: 16),
                                _buildContactRow(
                                  'assets/icons/logos_whatsapp-icon.svg', 
                                  _getAgentWhatsApp(property),
                                  shouldBlur: isShortlet && !_hasBookedProperty,
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          // Action buttons for non-hotel properties
                          if (!isHotel) ...[
                            if (isShortlet) ...[
                              // Shortlet buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          stops: [0.0, 1.0, 1.0],
                                          colors: [
                                            Color(0xFF426DC2),
                                            Color(0xFF63ADDC),
                                            Color(0xFF75CFEA),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                        child: const Text(
                                          'Book shortlet',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Container(
                              //   width: double.infinity,
                              //   height: 50,
                              //   decoration: BoxDecoration(
                              //     border: Border.all(color: const Color(0xFF426DC2)),
                              //     borderRadius: BorderRadius.circular(25),
                              //   ),
                              //   child: ElevatedButton(
                              //     onPressed: () {
                              //       Navigator.of(context).push(
                              //         MaterialPageRoute(
                              //           builder: (context) => const RentNowPayLaterView(),
                              //         ),
                              //       );
                              //     },
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: Colors.white,
                              //       shadowColor: Colors.transparent,
                              //       elevation: 0,
                              //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              //       shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(25),
                              //       ),
                              //     ),
                              //     child: const Text(
                              //       'Rent now-pay later',
                              //       style: TextStyle(
                              //         fontSize: 15,
                              //         fontWeight: FontWeight.w600,
                              //         color: Color(0xFF426DC2),
                              //       ),
                              //     ),
                              //   ),
                              // ),
                            ] else ...[
                              // Apartment buttons (for rent or sale)
                              // Row(
                              //   children: [
                              //     Expanded(
                              //       child: Container(
                              //         height: 50,
                              //         decoration: BoxDecoration(
                              //           gradient: const LinearGradient(
                              //             begin: Alignment.centerLeft,
                              //             end: Alignment.centerRight,
                              //             stops: [0.0, 1.0, 1.0],
                              //             colors: [
                              //               Color(0xFF426DC2),
                              //               Color(0xFF63ADDC),
                              //               Color(0xFF75CFEA),
                              //             ],
                              //           ),
                              //           borderRadius: BorderRadius.circular(25),
                              //         ),
                              //         child: ElevatedButton(
                              //           onPressed: () {
                              //             Navigator.of(context).push(
                              //               MaterialPageRoute(
                              //                 builder: (context) => const RentNowPayLaterView(),
                              //               ),
                              //             );
                              //           },
                              //           style: ElevatedButton.styleFrom(
                              //             backgroundColor: Colors.transparent,
                              //             shadowColor: Colors.transparent,
                              //             elevation: 0,
                              //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              //             shape: RoundedRectangleBorder(
                              //               borderRadius: BorderRadius.circular(25),
                              //             ),
                              //           ),
                              //           child: const Text(
                              //             'Rent now-pay later',
                              //             style: TextStyle(
                              //               fontSize: 15,
                              //               fontWeight: FontWeight.w600,
                              //               color: Colors.white,
                              //             ),
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              
                          // Removed duplicate Contact Agent button - keeping only the bottom bar button
                              
                              // Mark as rented button for agents
                              if (!widget.isHomeSeeker) ...[
                                Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF426DC2)),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // For agents, mark as rented
                                      _markAsRented();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: const Text(
                                      'Mark as rented',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF426DC2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                          
                          const SizedBox(height: 1),
                          
                          // What you'll get
                          const Text(
                            'What you\'ll get',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Features list
                          Column(
                            children: _buildFeaturesList(property, isHotel),
                          ),
                            
                            const SizedBox(height: 40),
                          
                          // Virtual Tour - only show for non-hotel properties and if 360 images are available
                          if (!isHotel && property360Images.isNotEmpty) ...[
                          const Text(
                            'Virtual Tour',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Virtual tour image with play button
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VirtualTour360View(
                                    title: 'Virtual Tour - ${property['title'] as String? ?? 'Property'}',
                                    property360Images: property360Images,
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  // 360 Image with loader
                                  property360Images.isNotEmpty
                                      ? _buildImageWithLoader(
                                          imageUrl: property360Images.first,
                                          height: 200,
                                        )
                                      : Image.asset(
                                          'assets/images/3af693f3bf0406d67cddf98a62526eba4c273542.jpg',
                              height: 200,
                              width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                  // Overlay gradient for better visibility
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Center play button
                                  Center(
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.threed_rotation,
                                        size: 32,
                                        color: Color(0xFF426DC2),
                                      ),
                                    ),
                                  ),
                                  
                                  // 360° label
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF426DC2).withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.threesixty,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '360°',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Bottom label
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Tap to start virtual tour',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          ],
                          
                          // Video Section - show if video is available
                          if (_getPropertyVideo() != null) ...[
                          const Text(
                            'Property Video',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Video player
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.black,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  // Video thumbnail/placeholder
                                  Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_filled,
                                        color: Colors.white,
                                        size: 60,
                                      ),
                                    ),
                                  ),
                                  
                                  // Video URL overlay (for debugging)
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Video Available',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          ],
                          
                          // Google Map (hide if owner)
                          if (!_isOwner) ...[
                          const Text(
                            'Google Map',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Google Maps Widget
                          Builder(
                            builder: (context) {
                              try {
                                final coordinates = _getPropertyCoordinates(property);
                                final locationString = property['location'] as String?;
                                
                                return GoogleMapWidget(
                                  latitude: coordinates['latitude'],
                                  longitude: coordinates['longitude'],
                                  propertyTitle: property['title'] as String?,
                                  locationString: locationString,
                                  height: 200,
                                  showMarker: true,
                                );
                              } catch (e) {
                                // Fallback to placeholder if map fails
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: const Color(0xFFE8F4FD),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.map,
                                          size: 40,
                                          color: Color(0xFF426DC2),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Map Preview',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF426DC2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          ],
                          
                          const SizedBox(height: 40),
                          
                          // Ratings and Reviews Section - Always show
                          _buildRatingsSection(property),
                          
                          const SizedBox(height: 20),
                          
                          // Report listing button (hide if owner)
                          if (!_isOwner) ...[
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF426DC2)),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Implement report listing functionality
                                _showReportDialog();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF426DC2).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgPicture.asset('assets/icons/message-question (1).svg')
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Report listing',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF426DC2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ],
                          
                          const SizedBox(height: 100), // Space for bottom bar
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
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
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isHotel ? 'Total Price' : _getPriceLabel(propertyType, isForSale),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF868686),
                        ),
                      ),
                      Text(
                        _formatPrice(property['price'] as String? ?? '0'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF426DC2),
                        ),
                      ),
                      if (isHotel)
                        const Text(
                          'per night',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF868686),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Hide bottom button if owner
                  if (!_isOwner)
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment(-1.0, 0.0),
                          end: Alignment(1.0, 0.0),
                          stops: [0.0113, 0.4555, 1.1245],
                          colors: [
                            Color(0xFF426DC2),
                            Color(0xFF75CFEA),
                            Color.fromRGBO(51, 204, 153, 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ElevatedButton(
                          onPressed: () {
                          final property = widget.propertyData ?? _getDefaultProperty();
                          final propertyType = property['type'] as String? ?? 'Apartment';
                          final normalizedType = propertyType.toLowerCase();
                          final isHotel = normalizedType == 'hotel';
                          final isShortlet = normalizedType == 'shortlet';

                          if (isHotel || isShortlet) {
                            // Navigate to reservation screen for hotels and shortlets
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => HotelReservationView(
                                  propertyData: property,
                                ),
                              ),
                            );
                          } else {
                            // Bottom contact button: open chat for other property types
                            final user = property['user'] as Map<String, dynamic>?;
                            final agentId = user?['id']?.toString();
                            final agentData = {
                              'id': agentId,
                              'user': {
                                'id': agentId,
                                'full_name': _getAgentName(property),
                                'profile_image_url': _getAgentProfileImage(property),
                                'phone_number': _getAgentPhone(property),
                                'email': _getAgentEmail(property),
                              },
                            };
                            // Derive property id similarly
                            String bottomPropertyId = (property['id']?.toString()) ?? '';
                            if (bottomPropertyId.isEmpty) {
                              final images = property['images'];
                              if (images is List && images.isNotEmpty) {
                                final first = images.first;
                                if (first is Map<String, dynamic>) {
                                  final pid = first['property_id'];
                                  if (pid != null) {
                                    bottomPropertyId = pid.toString();
                                  }
                                }
                              }
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => InAppChatView(
                                  agentData: agentData,
                                  propertyTitle: (property['title'] as String?) ?? 'Property',
                                  propertyId: bottomPropertyId,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          _getBottomButtonText(propertyType, isForSale),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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

  Widget _buildContactRow(String icon, String text, {bool shouldBlur = false}) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            color: AppColors.primary100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SizedBox(
            width: 12,
            height: 12,
            child: Transform.scale(
              scale: 0.8,
              child: SvgPicture.asset(
                icon,
                width: 12,
                height: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: shouldBlur ? _buildBlurredText(text) : Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        if (shouldBlur)
          Tooltip(
            message: 'Book this shortlet to view contact details',
            child: Icon(
              Icons.lock_outline,
              size: 16,
              color: Colors.grey[600],
            ),
          )
        else
        SvgPicture.asset(
          'assets/icons/si_copy-line.svg',
          width: 16,
          height: 16,
          ),
      ],
    );
  }
  
  /// Build blurred text widget
  Widget _buildBlurredText(String text) {
    return Stack(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build image with percentage loading indicator
  Widget _buildImageWithLoader({
    required String imageUrl,
    required double height,
    BoxFit fit = BoxFit.cover,
  }) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background color while loading
          Container(
            color: Colors.grey[200],
          ),
          // Image
          Image.network(
            imageUrl,
            width: double.infinity,
            height: height,
            fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              // Image fully loaded
              return child;
            }
            
            // Calculate loading percentage
            final progress = loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : 0.0;
            
            final percentage = (progress * 100).toInt();
            
            // Show loading indicator with percentage
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Circular progress indicator
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF426DC2),
                              ),
                            ),
                          ),
                          // Percentage text
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF426DC2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Loading text
                    const Text(
                      'Loading image...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Show error state
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load image',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
      ),
    );
  }

    List<Widget> _buildFeaturesList(Map<String, dynamic> property, bool isHotel) {
    final propertyType = property['type'] as String? ?? 'Apartment';
    final type = propertyType.toLowerCase();
    
    // Get features from API data
    final List<dynamic> apiFeatures = property['features'] as List<dynamic>? ?? [];
    
    if (isHotel || type == 'hotel') {
      // Hotel features - use API data if available, otherwise fallback to defaults
      if (apiFeatures.isNotEmpty) {
        // Use features from API
        List<Widget> featureWidgets = [];
        for (int i = 0; i < apiFeatures.length; i++) {
          featureWidgets.add(_buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', apiFeatures[i].toString()));
          if (i < apiFeatures.length - 1) {
            featureWidgets.add(const SizedBox(height: 16));
          }
        }
        return featureWidgets;
      } else {
        // Fallback to default hotel features
        return [
          _buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', 'Queen-size Bed'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mdi_bathroom.svg', 'En-suite Bathroom'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/fluent_food-16-regular.svg', 'Complimentary Breakfast'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/material-symbols_wifi-rounded.svg', 'Free High-Speed Wi-Fi'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mage_television.svg', 'Smart TV with Streaming'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/uil_padlock.svg', '24/7 Security & Keycard Access'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/healthicons_cleaning-outline.svg', 'Daily Housekeeping'),
        ];
      }
    } else if (type == 'shortlet') {
      // Shortlet features - use API data if available, otherwise fallback to defaults
      if (apiFeatures.isNotEmpty) {
        List<Widget> featureWidgets = [];
        for (int i = 0; i < apiFeatures.length; i++) {
          featureWidgets.add(_buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', apiFeatures[i].toString()));
          if (i < apiFeatures.length - 1) {
            featureWidgets.add(const SizedBox(height: 16));
          }
        }
        return featureWidgets;
      } else {
        // Fallback to default shortlet features
        return [
          _buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', '3-bedroom'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mdi_bathroom.svg', '3 Bathrooms'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/tabler_car.svg', 'Dedicated Parking'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/game-icons_gate.svg', 'Gated & Secured Estate'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mdi_wifi.svg', 'Free Wi-Fi'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mdi_television.svg', 'Smart TV'),
        ];
      }
    } else {
      // Real Estate (Apartment for sale) features - use API data if available, otherwise fallback to defaults
      if (apiFeatures.isNotEmpty) {
        List<Widget> featureWidgets = [];
        for (int i = 0; i < apiFeatures.length; i++) {
          featureWidgets.add(_buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', apiFeatures[i].toString()));
          if (i < apiFeatures.length - 1) {
            featureWidgets.add(const SizedBox(height: 16));
          }
        }
        return featureWidgets;
      } else {
        // Fallback to default apartment features
        return [
          _buildFeatureRow('assets/icons/material-symbols_bed-outline-rounded.svg', '3-bedroom'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/mdi_bathroom.svg', '3 Bathrooms'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/tabler_car.svg', 'Dedicated Parking'),
          const SizedBox(height: 16),
          _buildFeatureRow('assets/icons/game-icons_gate.svg', 'Gated & Secured Estate'),
        ];
      }
    }
  }

  Widget _buildFeatureRow(String icon, String label) {
    return Row(
      children: [
        SvgPicture.asset(
        icon,
         width: 20,
         height: 20,

        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  String _getPriceLabel(String propertyType, bool isForSale) {
    final type = propertyType.toLowerCase();
    if (type == 'hotel') {
      return 'Total Price';
    } else if (type == 'shortlet') {
      return 'Total Price';
    } else if (isForSale) {
      return 'Selling Price';
    } else {
      return 'Total Price';
    }
  }

  String _formatPrice(String price) {
    try {
      // Remove any existing currency symbols and commas
      String cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
      double priceValue = double.parse(cleanPrice);
      
      // Format in Naira with comma separators
      if (priceValue >= 1000000) {
        return '₦${(priceValue / 1000000).toStringAsFixed(1)}M';
      } else if (priceValue >= 1000) {
        return '₦${priceValue.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},'
        )}';
      } else {
        return '₦${priceValue.toStringAsFixed(0)}';
      }
    } catch (e) {
      // Fallback to original price if parsing fails
      return '₦$price';
    }
  }

  String _getBottomButtonText(String propertyType, bool isForSale) {
    final type = propertyType.toLowerCase();
    if (type == 'hotel') {
      return 'Book Now';
    } else if (type == 'shortlet') {
      return 'Book Now';
    } else if (isForSale) {
      return 'Contact agent';
    } else {
      return 'Contact agent';
    }
  }

  Map<String, double> _getPropertyCoordinates(Map<String, dynamic> property) {
    
    // Try to get coordinates from property data
    final coordinates = property['coordinates'] as Map<String, dynamic>?;
    if (coordinates != null) {
      final lat = (coordinates['latitude'] as num?)?.toDouble();
      final lng = (coordinates['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return {
          'latitude': lat,
          'longitude': lng,
        };
      }
    }

    // Try to get coordinates from location string using geocoding
    // For now, use the location string directly in Google Maps URL
    // The Google Maps widget will handle geocoding via the location string
    final location = property['location'] as String?;
    if (location != null && location.isNotEmpty) {
      // Return default coordinates but we'll pass location string to Google Maps
      // The GoogleMapWidget will need to be updated to accept location string
      return {
        'latitude': 6.5244, // Default Lagos
        'longitude': 3.3792, // Default Lagos
      };
    }

    // Default coordinates (Lagos, Nigeria)
    return {
      'latitude': 6.5244,
      'longitude': 3.3792,
    };
  }

  /// Build scrolling promotional banner (like home screen)
  Widget _buildScrollingPromotionalBanner() {
    
    return Container(
      width: double.infinity,
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1.0, 0.0),
          end: Alignment(1.0, 0.0),
          stops: [0.0113, 0.4555, 1.1245],
          colors: [
            Color(0xFF426DC2),
            Color(0xFF75CFEA),
            Color.fromRGBO(51, 204, 153, 0.8),
          ],
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: AnimatedBuilder(
          animation: _textAnimationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_textAnimationController.value * -200, 0),
              child: Row(
                children: List.generate(10, (index) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _promotionalMessages[_currentTextIndex],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}

/// Full-screen image gallery dialog
class ImageGalleryDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageGalleryDialog({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryDialog> createState() => _ImageGalleryDialogState();
}

class _ImageGalleryDialogState extends State<ImageGalleryDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen image viewer
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white70,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Image counter indicator (only show if multiple images)
            if (widget.images.length > 1)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // Image dots indicator (optional, at the bottom)
            if (widget.images.length > 1)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
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
} 