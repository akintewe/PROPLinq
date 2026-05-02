import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/chat_service.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/message_notification_service.dart';

class InAppChatView extends StatefulWidget {
  final Map<String, dynamic> agentData;
  final String propertyTitle;
  final String? propertyId;
  
  const InAppChatView({
    super.key,
    required this.agentData,
    required this.propertyTitle,
    this.propertyId,
  });

  @override
  State<InAppChatView> createState() => _InAppChatViewState();
}

class _InAppChatViewState extends State<InAppChatView> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  bool _isLoadingChats = true;
  bool _isLoadingProperty = true;
  bool _showWhatsAppBanner = false;
  Map<String, dynamic>? _propertyDetails;
  Timer? _whatsAppTimer;
  Timer? _chatRefreshTimer;
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedFilePath;
  String? _selectedFileType;
  String? _currentUserProfileImage;
  String? _currentUserName;
  bool _isTypingVisible = false;
  int _lastConversationLength = 0;
  bool? _isAgentOnline;
  Timer? _onlineStatusTimer;

  @override
  void initState() {
    super.initState();

    // Tell the global notification service we're in this conversation so it
    // doesn't fire sound/banners for messages from this user.
    final user = widget.agentData['user'] as Map<String, dynamic>?;
    final agentId = user?['id']?.toString() ?? widget.agentData['id']?.toString() ?? widget.agentData['user_id']?.toString();
    MessageNotificationService().setActiveConversationUserId(agentId);
    MessageNotificationService().acknowledgeAll();

    _loadChatHistory();
    _loadPropertyDetails();
    _loadCurrentUserProfile();
    _startWhatsAppTimer();
    _updateOnlineStatus(); // Update current user's online status
    _checkAgentOnlineStatus(); // Check agent's online status
    _startOnlineStatusTimer(); // Periodically check online status

    // Poll for new messages periodically while this screen is open (faster)
    _chatRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      await _checkForIncomingMessageAndMaybeShowTyping();
    });
  }

  

  Future<void> _loadChatHistory() async {
    try {
      // Extract agent ID from user data
      final user = widget.agentData['user'] as Map<String, dynamic>?;
      final agentId = user?['id']?.toString() ?? widget.agentData['id']?.toString() ?? widget.agentData['user_id']?.toString();
      
      final chatHistory = await _chatService.getChatHistory(
        agentId: agentId ?? '',
        propertyId: widget.propertyId ?? '',
      );
      
      // Extract phone number from chat history if not already available
      String? phoneNumber;
      String? email;
      
      for (final chat in chatHistory) {
        // Check sender data
        final sender = chat['sender'] as Map<String, dynamic>?;
        if (sender?['id']?.toString() == agentId) {
          phoneNumber = sender?['phone_number'] as String?;
          email = sender?['email'] as String?;
          break;
        }
        
        // Check receiver data
        final receiver = chat['receiver'] as Map<String, dynamic>?;
        if (receiver?['id']?.toString() == agentId) {
          phoneNumber = receiver?['phone_number'] as String?;
          email = receiver?['email'] as String?;
          break;
        }
      }
      
      
      // Update agent data with phone number if found
      if ((phoneNumber != null || email != null) && mounted) {
        setState(() {
          widget.agentData['user']['phone_number'] = phoneNumber;
          widget.agentData['user']['email'] = email;
        });
      }
      
      // Get current user ID once for all messages
      final currentUser = await _authService.getCurrentUser();
      final currentUserId = currentUser?.id.toString();
      
      final previousCount = _messages.length;
      
      if (!mounted) return;
      setState(() {
        _messages.clear();

        // Convert API chat history to ChatMessage objects
        for (final chat in chatHistory) {
          // Extract sender_id and message data from the new API format
          final messageId = chat['id']?.toString();
          final senderId = chat['sender_id']?.toString();
          final message = chat['message'] ?? '';
          // Use updated_at for sorting as it reflects the latest activity
          final sentAt = chat['updated_at'] ?? chat['sent_at'] ?? chat['created_at'] ?? '';
          // Handle both 'file' and 'file_url' fields from API response
          final filePath = chat['file_url'] as String? ?? chat['file'] as String?;
          final receivedAt = chat['received_at'] as String?;
          
          // Determine if this message is from the current authenticated user
          // The authenticated user is always the sender, so if sender_id matches current user, it's from user
          final isFromCurrentUser = senderId == currentUserId;
          
          // Determine file type from file path
          String? fileType;
          if (filePath != null && filePath.isNotEmpty) {
            final fileName = filePath.split('/').last.toLowerCase();
            if (fileName.contains('.jpg') || fileName.contains('.jpeg') || fileName.contains('.png') || fileName.contains('.gif')) {
              fileType = 'image';
            } else if (fileName.contains('.mp4') || fileName.contains('.mov') || fileName.contains('.avi')) {
              fileType = 'video';
            } else {
              fileType = 'document';
            }
          }
          
          // Determine if message is read (received_at is null means not read yet)
          final isRead = receivedAt != null;
          
          _messages.add(ChatMessage(
            text: message,
            isFromUser: isFromCurrentUser,
            timestamp: DateTime.tryParse(sentAt) ?? DateTime.now(),
            filePath: filePath,
            fileType: fileType,
            isRead: isRead,
            receivedAt: receivedAt,
            messageId: messageId,
          ));
        }
        
        // Sort messages by timestamp (oldest first, newest last for chat display)
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // If no chat history, add welcome message
        if (_messages.isEmpty) {
          _addWelcomeMessage();
        }
        
        _isLoadingChats = false;
      });
      
      if (_messages.length > previousCount) {
        _scrollToBottom();
      }

      // Mark messages as read now that they are loaded
      await _markMessagesAsRead();
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.clear();
          _addWelcomeMessage();
          _isLoadingChats = false;
        });
      }
    }
  }

  String? _getAgentId() {
    final user = widget.agentData['user'] as Map<String, dynamic>?;
    final agentId = user?['id']?.toString() ?? widget.agentData['id']?.toString() ?? widget.agentData['user_id']?.toString();
    return agentId;
  }

  Future<void> _checkForIncomingMessageAndMaybeShowTyping() async {
    try {
      final agentId = _getAgentId();
      if (agentId == null || agentId.isEmpty) return;

      final conversation = await _chatService.getConversation(agentId);
      if (conversation.isEmpty) return;

      // If there are more messages on server than we last saw
      if (conversation.length > _lastConversationLength) {
        final currentUser = await _authService.getCurrentUser();
        final currentUserId = currentUser?.id.toString();
        final last = conversation.last;
        final senderId = (last['sender_id'] as dynamic)?.toString();

        if (senderId != null && senderId != currentUserId && !_isTypingVisible) {
          _showTypingThenRefresh();
          _lastConversationLength = conversation.length; // prevent duplicate typings
          return;
        }
      }

      // No new incoming message – just refresh
      if (!mounted) return;
      await _loadChatHistory();
      if (mounted) _markMessagesAsRead();
      _lastConversationLength = conversation.length;
    } catch (_) {
      // ignore polling errors
    }
  }

  void _showTypingThenRefresh() {
    if (!mounted || _isTypingVisible) return;
    setState(() {
      _isTypingVisible = true;
      _messages.add(ChatMessage(
        text: 'typing…',
        isFromUser: false,
        timestamp: DateTime.now(),
        isTyping: true,
        messageId: null, // Typing indicator doesn't have a message ID
      ));
    });
    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.isTyping == true);
        _isTypingVisible = false;
      });
      await _loadChatHistory();
      _markMessagesAsRead();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "Hi! I'm interested in the ${widget.propertyTitle} property. Could you please provide more details?",
        isFromUser: true,
        timestamp: DateTime.now(),
        messageId: null, // Welcome message doesn't have a message ID
      ));
    });
    
    _scrollToBottom();
  }

  Future<void> _loadPropertyDetails() async {
    if (widget.propertyId == null || widget.propertyId!.isEmpty) {
      setState(() {
        _isLoadingProperty = false;
      });
      return;
    }

    try {
      final propertyData = await _chatService.getPropertyDetails(widget.propertyId!);
      
      setState(() {
        _propertyDetails = propertyData;
        _isLoadingProperty = false;
      });
      
      
      // If no data from API, create mock data for testing
      if (propertyData == null) {
        setState(() {
          _propertyDetails = {
            'id': widget.propertyId,
            'title': widget.propertyTitle,
            'location': 'Lagos, Nigeria',
            'price': '₦2,500,000',
            'type': 'Apartment',
            'description': 'Beautiful property for rent/sale',
          };
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProperty = false;
        // Create fallback data
        _propertyDetails = {
          'id': widget.propertyId,
          'title': widget.propertyTitle,
          'location': 'Lagos, Nigeria',
          'price': '₦2,500,000',
          'type': 'Apartment',
          'description': 'Beautiful property for rent/sale',
        };
      });
    }
  }

  void _startWhatsAppTimer() {
    // Show WhatsApp banner after 3 minutes (180 seconds)
    _whatsAppTimer = Timer(const Duration(minutes: 3), () {
      if (mounted) {
        setState(() {
          _showWhatsAppBanner = true;
        });
      }
    });
  }

  void _sendMessage() async {
    // Check if we have a file selected or text to send
    if (_messageController.text.trim().isEmpty && _selectedFilePath == null) return;
    
    final messageText = _messageController.text.trim();
    
    // Add message to UI immediately (isFromUser = true because authenticated user is always the sender)
    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isFromUser: true, // Always true for new messages since authenticated user is the sender
        timestamp: DateTime.now(),
        filePath: _selectedFilePath,
        fileType: _selectedFileType,
        messageId: null, // New message doesn't have ID yet, will be set when response comes back
      ));
      _messageController.clear();
    });
    
    // Auto-scroll to bottom
    _scrollToBottom();
    
    // Send message via ChatService (file path sent to backend but not displayed)
    final user = widget.agentData['user'] as Map<String, dynamic>?;
    final agentId = user?['id']?.toString() ?? widget.agentData['id']?.toString() ?? widget.agentData['user_id']?.toString();
    
    final success = await _chatService.sendInAppMessage(
      message: messageText.isEmpty ? '📎 File attachment' : messageText,
      recipientId: agentId ?? '',
      propertyId: widget.propertyId ?? '',
      file: _selectedFilePath,
    );
    
    // Clear selected file after sending
    setState(() {
      _selectedFilePath = null;
      _selectedFileType = null;
    });
    
    if (success) {
    } else {
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openWhatsApp() async {
    final phoneNumber = _getAgentWhatsApp();
    if (phoneNumber.isNotEmpty) {
      final whatsappUrl = "https://wa.me/$phoneNumber?text=Hi! I'm interested in the ${widget.propertyTitle} property.";
      
      
      try {
        // Try to launch WhatsApp
        final Uri whatsappUri = Uri.parse(whatsappUrl);
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        } else {
          _showErrorSnackBar('WhatsApp is not installed or cannot be opened');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to open WhatsApp. Please try again.');
      }
    } else {
      _showErrorSnackBar('Agent WhatsApp number not available');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _attachFile() {
    
    // Show bottom sheet with file options
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
                'Attach File',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              
              // File options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFileOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                  _buildFileOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  _buildFileOption(
                    icon: Icons.videocam,
                    label: 'Video',
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo();
                    },
                  ),
                  _buildFileOption(
                    icon: Icons.description,
                    label: 'Document',
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocument();
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

  Widget _buildFileOption({
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

  void _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        setState(() {
          _selectedFilePath = image.path;
          _selectedFileType = 'image';
        });
      } else {
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image from gallery');
    }
  }

  void _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        setState(() {
          _selectedFilePath = image.path;
          _selectedFileType = 'image';
        });
      } else {
      }
    } catch (e) {
      _showErrorMessage('Failed to take photo');
    }
  }

  void _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        setState(() {
          _selectedFilePath = video.path;
          _selectedFileType = 'video';
        });
      } else {
      }
    } catch (e) {
      _showErrorMessage('Failed to pick video');
    }
  }

  void _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.path != null) {
          setState(() {
            _selectedFilePath = file.path;
            _selectedFileType = 'document';
          });
        } else {
          // Handle web platform
          _showErrorMessage('File upload not supported on web platform');
        }
      } else {
      }
    } catch (e) {
      _showErrorMessage('Failed to pick document');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _currentUserProfileImage = currentUser.profilePicture;
          _currentUserName = currentUser.fullName;
        });
      }
    } catch (e) {
    }
  }

  Future<void> _markMessagesAsRead() async {
    // Mark all unread received messages as read in local state only.
    // The backend mark-received endpoint is not available, so we skip the API call.
    for (int i = 0; i < _messages.length; i++) {
      if (!mounted) return;
      final message = _messages[i];
      if (!message.isFromUser && !message.isRead) {
        if (mounted) {
          setState(() {
            _messages[i] = ChatMessage(
              text: message.text,
              isFromUser: message.isFromUser,
              timestamp: message.timestamp,
              filePath: message.filePath,
              fileType: message.fileType,
              isRead: true,
              receivedAt: message.receivedAt,
              messageId: message.messageId,
            );
          });
        }
      }
    }
  }

  String _getAgentWhatsApp() {
    
    // Extract WhatsApp number from agent data
    final user = widget.agentData['user'] as Map<String, dynamic>?;
    
    if (user != null && user['whatsapp_number'] != null) {
      final whatsappNumber = user['whatsapp_number'].toString().replaceAll(RegExp(r'[^\d]'), '');
      return whatsappNumber;
    }
    if (user != null && user['phone_number'] != null) {
      final phoneNumber = user['phone_number'].toString().replaceAll(RegExp(r'[^\d]'), '');
      return phoneNumber;
    }
    
    // Fallback to agent data
    final agent = widget.agentData['agent'] as Map<String, dynamic>?;
    
    if (agent != null && agent['whatsapp'] != null) {
      final whatsappNumber = agent['whatsapp'].toString().replaceAll(RegExp(r'[^\d]'), '');
      return whatsappNumber;
    }
    if (agent != null && agent['phone'] != null) {
      final phoneNumber = agent['phone'].toString().replaceAll(RegExp(r'[^\d]'), '');
      return phoneNumber;
    }
    
    return '';
  }

  String _getAgentName() {
    final user = widget.agentData['user'] as Map<String, dynamic>?;
    if (user != null && user['full_name'] != null) {
      return user['full_name'] as String;
    }
    
    final agent = widget.agentData['agent'] as Map<String, dynamic>?;
    return agent?['name'] as String? ?? 'Agent';
  }

  Widget _buildPropertyDetailsCard() {
    if (_isLoadingProperty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEFF0F2),
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF426DC2),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading property details...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF868686),
              ),
            ),
          ],
        ),
      );
    }

    if (_propertyDetails == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEFF0F2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.home,
              color: Color(0xFF426DC2),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.propertyTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final property = _propertyDetails!;
    final title = property['title'] as String? ?? widget.propertyTitle;
    final location = property['location'] as String? ?? '';
    final price = property['price'] as String? ?? '';
    final type = property['type'] as String? ?? '';
    final bedrooms = property['bedrooms'] as int?;
    final bathrooms = property['bathrooms'] as int?;
    final features = property['features'] as List<dynamic>? ?? [];
    
    // Get property image
    String? imageUrl;
    if (property['images'] != null && property['images'] is List) {
      final images = property['images'] as List<dynamic>;
      if (images.isNotEmpty) {
        final firstImage = images.first as Map<String, dynamic>;
        imageUrl = firstImage['full_url'] as String?;
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEFF0F2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Property Image or Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF426DC2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(imageUrl: 
                          imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) {
                            return const Icon(
                              Icons.home,
                              color: Colors.white,
                              size: 20,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Color(0xFF868686),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF868686),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Property Details Row
          Row(
            children: [
              // Property Type Badge
              if (type.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF426DC2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF426DC2),
                    ),
                  ),
                ),
              
              const Spacer(),
              
              // Price
              if (price.isNotEmpty)
                Text(
                  '₦${price.replaceAll(RegExp(r'[^\d.]'), '').replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},'
                  )}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF426DC2),
                  ),
                ),
            ],
          ),
          
          // Bedrooms and Bathrooms
          if (bedrooms != null || bathrooms != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (bedrooms != null) ...[
                  const Icon(
                    Icons.bed,
                    size: 14,
                    color: Color(0xFF868686),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$bedrooms bed${bedrooms > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF868686),
                    ),
                  ),
                ],
                if (bathrooms != null) ...[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.bathtub,
                    size: 14,
                    color: Color(0xFF868686),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$bathrooms bath${bathrooms > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF868686),
                    ),
                  ),
                ],
              ],
            ),
          ],
          
          // Key Features
          if (features.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: features.take(3).map((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEFF0F2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    feature.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF868686),
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

  Widget _buildFilePreview() {
    if (_selectedFilePath == null) return const SizedBox.shrink();

    final fileName = _selectedFilePath!.split('/').last;
    final isImage = _selectedFileType == 'image';
    final isVideo = _selectedFileType == 'video';
    final isDocument = _selectedFileType == 'document';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEFF0F2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview thumbnail
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_selectedFilePath!),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF426DC2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Color(0xFF426DC2),
                      size: 30,
                    ),
                  );
                },
              ),
            )
          else if (isVideo)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF426DC2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.videocam,
                color: Color(0xFF426DC2),
                size: 30,
              ),
            )
          else if (isDocument)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF426DC2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description,
                color: Color(0xFF426DC2),
                size: 30,
              ),
            ),

          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedFileType?.toUpperCase() ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF868686),
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilePath = null;
                _selectedFileType = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 18,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF25D366), // WhatsApp green
            Color(0xFF128C7E), // Darker WhatsApp green
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat,
              color: Color(0xFF25D366),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue on WhatsApp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Switch to WhatsApp for easier conversation',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openWhatsApp,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF25D366),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24.0, top: 8.0, bottom: 8.0, right: 8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEFF0F2),
                  width: 1.14,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF426DC2),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getAgentName(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              _isAgentOnline == true 
                ? 'Online' 
                : _isAgentOnline == false 
                  ? 'Offline' 
                  : '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: _isAgentOnline == true 
                  ? const Color(0xFF00C851) 
                  : _isAgentOnline == false
                    ? const Color(0xFF868686)
                    : const Color(0xFF868686),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: GestureDetector(
              onTap: _openWhatsApp,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366), // WhatsApp green
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Property Details Card (shown initially)
          if (!_showWhatsAppBanner) _buildPropertyDetailsCard(),
          
          // WhatsApp Banner (shown after 3 minutes)
          if (_showWhatsAppBanner) _buildWhatsAppBanner(),
          
          // Chat Messages
          Expanded(
            child: _isLoadingChats
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF426DC2),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          
          // File Preview (shows when a file is selected)
          _buildFilePreview(),
          
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // File Attachment Button
                GestureDetector(
                  onTap: _attachFile,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.attach_file,
                      color: Color(0xFF426DC2),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF426DC2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _getCurrentUserName() {
    return _currentUserName;
  }

  String? _getOtherPersonProfileImage() {
    final user = widget.agentData['user'] as Map<String, dynamic>?;
    return user?['profile_image_url'] as String?;
  }

  String? _getOtherPersonName() {
    final user = widget.agentData['user'] as Map<String, dynamic>?;
    return user?['full_name'] as String?;
  }

  Widget _buildProfileAvatar({required bool isCurrentUser, required String? profileImageUrl, required String? userName}) {
    final size = 32.0;
    
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      // Show actual profile image
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: CachedNetworkImage(imageUrl: 
            profileImageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) {
              // Fallback to initials if image fails to load
              return _buildInitialsAvatar(size, userName);
            },
          ),
        ),
      );
    } else {
      // Fallback to initials if no profile image
      return _buildInitialsAvatar(size, userName);
    }
  }

  Widget _buildInitialsAvatar(double size, String? userName) {
    String initial = 'U';
    if (userName != null && userName.isNotEmpty) {
      initial = userName[0].toUpperCase();
    }
    
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF426DC2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  bool _isUrl(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // Message alignment logic:
    // - isFromUser = true: Message sent by authenticated user → Right side (blue)
    // - isFromUser = false: Message received from other person → Left side (gray)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isFromUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isFromUser) ...[
            _buildProfileAvatar(
              isCurrentUser: false,
              profileImageUrl: _getOtherPersonProfileImage(),
              userName: _getOtherPersonName(),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isFromUser 
                    ? const Color(0xFF426DC2)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display image if present
                  if (message.filePath != null && message.fileType == 'image') ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _isUrl(message.filePath)
                          ? CachedNetworkImage(imageUrl: 
                              message.filePath!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(message.filePath!),
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                );
                              },
                            ),
                    ),
                    if (message.text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  
                  // Display video icon if present
                  if (message.filePath != null && message.fileType == 'video') ...[
                    Container(
                      width: 200,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 50,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (message.text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  
                  // Display document icon if present
                  if (message.filePath != null && message.fileType == 'document') ...[
                    Container(
                      width: 200,
                      height: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.isFromUser 
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description,
                            color: message.isFromUser ? Colors.white : Colors.grey,
                            size: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  message.filePath!.split('/').last,
                                  style: TextStyle(
                                    color: message.isFromUser ? Colors.white : Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Document',
                                  style: TextStyle(
                                    color: message.isFromUser ? Colors.white70 : Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (message.text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  
                  // Display text message if present
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: message.isFromUser ? Colors.white : Colors.black,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (message.isFromUser) ...[
            const SizedBox(width: 8),
            _buildProfileAvatar(
              isCurrentUser: true,
              profileImageUrl: _currentUserProfileImage,
              userName: _getCurrentUserName(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateOnlineStatus() async {
    print('💚 [InAppChatView] Updating current user online status...');
    final success = await _chatService.updateOnlineStatus();
    print('💚 [InAppChatView] Update online status result: $success');
  }

  Future<void> _checkAgentOnlineStatus() async {
    try {
      final agentId = _getAgentId();
      print('💚 [InAppChatView] Checking agent online status for agentId: $agentId');
      if (agentId == null || agentId.isEmpty) {
        print('⚠️ [InAppChatView] Agent ID is null or empty');
        return;
      }
      
      final agentIdInt = int.tryParse(agentId);
      if (agentIdInt == null) {
        print('⚠️ [InAppChatView] Failed to parse agent ID as int: $agentId');
        return;
      }
      
      print('💚 [InAppChatView] Calling checkOnlineStatus with agentIdInt: $agentIdInt');
      final statusMap = await _chatService.checkOnlineStatus([agentIdInt]);
      print('💚 [InAppChatView] Received status map: $statusMap');
      
      final onlineStatus = statusMap[agentId] ?? statusMap[agentIdInt.toString()];
      print('💚 [InAppChatView] Agent online status: $onlineStatus');
      
      if (mounted) {
        setState(() {
          _isAgentOnline = onlineStatus;
        });
        print('💚 [InAppChatView] Updated _isAgentOnline to: $_isAgentOnline');
      }
    } catch (e, stackTrace) {
      print('❌ [InAppChatView] Error checking agent online status: $e');
      print('❌ [InAppChatView] Stack trace: $stackTrace');
    }
  }

  void _startOnlineStatusTimer() {
    // Update current user's online status every 30 seconds
    _onlineStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      await _updateOnlineStatus();
    });
    
    // Check agent's online status every 10 seconds
    _chatRefreshTimer ??= Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;
      await _checkAgentOnlineStatus();
    });
  }

  @override
  void dispose() {
    MessageNotificationService().setActiveConversationUserId(null);
    _chatRefreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _whatsAppTimer?.cancel();
    _onlineStatusTimer?.cancel();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final String? filePath;
  final String? fileType;
  final bool isRead;
  final String? receivedAt;
  final bool isTyping;
  final String? messageId; // Message ID from API

  ChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.filePath,
    this.fileType,
    this.isRead = true,
    this.receivedAt,
    this.isTyping = false,
    this.messageId,
  });
}
