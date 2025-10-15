import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/chat_service.dart';
import '../../auth/services/auth_service.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedFilePath;
  String? _selectedFileType;
  String? _currentUserProfileImage;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    print('🎯 InAppChatView: initState called');
    print('🎯 InAppChatView: Agent data: ${widget.agentData}');
    print('🎯 InAppChatView: Property ID: ${widget.propertyId}');
    print('🎯 InAppChatView: Property Title: ${widget.propertyTitle}');
    
    _loadChatHistory();
    _loadPropertyDetails();
    _loadCurrentUserProfile();
    _startWhatsAppTimer();
    _markMessagesAsRead(); // Mark messages as read when chat is opened
  }

  Future<void> _loadChatHistory() async {
    try {
      print('🔄 Loading chat history...');
      print('🔄 Agent data: ${widget.agentData}');
      print('🔄 Property ID: ${widget.propertyId}');
      
      // Extract agent ID from user data
      final user = widget.agentData['user'] as Map<String, dynamic>?;
      final agentId = user?['id']?.toString() ?? widget.agentData['id']?.toString() ?? widget.agentData['user_id']?.toString();
      print('🔄 Extracted agent ID: $agentId');
      
      final chatHistory = await _chatService.getChatHistory(
        agentId: agentId ?? '',
        propertyId: widget.propertyId ?? '',
      );
      
      print('🔄 Chat history result: ${chatHistory.length} messages');
      print('🔄 Chat history data: $chatHistory');
      
      // Get current user ID once for all messages
      final currentUser = await _authService.getCurrentUser();
      final currentUserId = currentUser?.id.toString();
      
      setState(() {
        _messages.clear();
        
        // Convert API chat history to ChatMessage objects
        for (final chat in chatHistory) {
          print('🔄 Processing chat: $chat');
          
          // Extract sender_id and message data from the new API format
          final senderId = chat['sender_id']?.toString();
          final message = chat['message'] ?? '';
          // Use updated_at for sorting as it reflects the latest activity
          final sentAt = chat['updated_at'] ?? chat['sent_at'] ?? chat['created_at'] ?? '';
          final filePath = chat['file'] as String?;
          final receivedAt = chat['received_at'] as String?;
          
          print('🔄 Chat - Sender: $senderId, Current User: $currentUserId');
          print('🔄 Chat - Message: $message, File: $filePath');
          
          // Determine if this message is from the current authenticated user
          // The authenticated user is always the sender, so if sender_id matches current user, it's from user
          final isFromCurrentUser = senderId == currentUserId;
          print('🔄 Chat - Is from current user: $isFromCurrentUser');
          
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
          ));
        }
        
        // Sort messages by timestamp (oldest first, newest last for chat display)
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        print('🔄 Final messages count: ${_messages.length}');
        print('🔄 Messages sorted by timestamp (oldest to newest)');
        
        // Debug: Print message timestamps to verify sorting
        for (int i = 0; i < _messages.length; i++) {
          final msg = _messages[i];
          print('🔄 Message $i: ${msg.timestamp} - ${msg.text.length > 20 ? "${msg.text.substring(0, 20)}..." : msg.text}');
        }
        
        // If no chat history, add welcome message
        if (_messages.isEmpty) {
          print('🔄 No chat history found, adding welcome message');
          _addWelcomeMessage();
        }
        
        _isLoadingChats = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      print('❌ Error loading chat history: $e');
      setState(() {
        _messages.clear();
        _addWelcomeMessage();
        _isLoadingChats = false;
      });
    }
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
      ));
    });
    
    _scrollToBottom();
  }

  Future<void> _loadPropertyDetails() async {
    if (widget.propertyId == null || widget.propertyId!.isEmpty) {
      print('🏠 No property ID provided, skipping property details fetch');
      setState(() {
        _isLoadingProperty = false;
      });
      return;
    }

    try {
      print('🏠 Loading property details for ID: ${widget.propertyId}');
      final propertyData = await _chatService.getPropertyDetails(widget.propertyId!);
      
      setState(() {
        _propertyDetails = propertyData;
        _isLoadingProperty = false;
      });
      
      print('🏠 Property details loaded: ${propertyData != null ? "Success" : "Failed"}');
      
      // If no data from API, create mock data for testing
      if (propertyData == null) {
        print('🏠 Creating mock property data for testing');
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
      print('❌ Error loading property details: $e');
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
        print('⏰ 3 minutes elapsed, showing WhatsApp banner');
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
      print('✅ Message sent successfully via webhook');
    } else {
      print('❌ Failed to send message via webhook');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openWhatsApp() {
    final phoneNumber = _getAgentWhatsApp();
    if (phoneNumber.isNotEmpty) {
      final whatsappUrl = "https://wa.me/$phoneNumber?text=Hi! I'm interested in the ${widget.propertyTitle} property.";
      
      // In a real app, you would use url_launcher here
      print('🔗 Opening WhatsApp with: $whatsappUrl');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening WhatsApp...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _attachFile() {
    print('📎 File attachment button tapped');
    
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

  void _pickImageFromGallery() async {
    try {
      print('📷 Picking image from gallery...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        print('📷 Image selected: ${image.path}');
        setState(() {
          _selectedFilePath = image.path;
          _selectedFileType = 'image';
        });
      } else {
        print('📷 No image selected');
      }
    } catch (e) {
      print('❌ Error picking image from gallery: $e');
      _showErrorMessage('Failed to pick image from gallery');
    }
  }

  void _pickImageFromCamera() async {
    try {
      print('📷 Taking photo with camera...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        print('📷 Photo taken: ${image.path}');
        setState(() {
          _selectedFilePath = image.path;
          _selectedFileType = 'image';
        });
      } else {
        print('📷 No photo taken');
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
      _showErrorMessage('Failed to take photo');
    }
  }

  void _pickVideo() async {
    try {
      print('🎥 Picking video...');
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        print('🎥 Video selected: ${video.path}');
        setState(() {
          _selectedFilePath = video.path;
          _selectedFileType = 'video';
        });
      } else {
        print('🎥 No video selected');
      }
    } catch (e) {
      print('❌ Error picking video: $e');
      _showErrorMessage('Failed to pick video');
    }
  }

  void _pickDocument() async {
    try {
      print('📄 Picking document...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('📄 Document selected: ${file.name}');
        
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
        print('📄 No document selected');
      }
    } catch (e) {
      print('❌ Error picking document: $e');
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
      print('👤 Loading current user profile...');
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _currentUserProfileImage = currentUser.profilePicture;
          _currentUserName = currentUser.fullName;
        });
        print('👤 Current user profile image: $_currentUserProfileImage');
        print('👤 Current user name: $_currentUserName');
      }
    } catch (e) {
      print('❌ Error loading current user profile: $e');
    }
  }

  void _markMessagesAsRead() {
    // Mark all received messages as read when chat is opened
    setState(() {
      for (int i = 0; i < _messages.length; i++) {
        if (!_messages[i].isFromUser && !_messages[i].isRead) {
          _messages[i] = ChatMessage(
            text: _messages[i].text,
            isFromUser: _messages[i].isFromUser,
            timestamp: _messages[i].timestamp,
            filePath: _messages[i].filePath,
            fileType: _messages[i].fileType,
            isRead: true, // Mark as read
            receivedAt: _messages[i].receivedAt,
          );
        }
      }
    });
  }

  String _getAgentWhatsApp() {
    // Extract WhatsApp number from agent data
    final user = widget.agentData['user'] as Map<String, dynamic>?;
    if (user != null && user['whatsapp_number'] != null) {
      return user['whatsapp_number'].toString().replaceAll(RegExp(r'[^\d]'), '');
    }
    if (user != null && user['phone_number'] != null) {
      return user['phone_number'].toString().replaceAll(RegExp(r'[^\d]'), '');
    }
    
    // Fallback to agent data
    final agent = widget.agentData['agent'] as Map<String, dynamic>?;
    if (agent != null && agent['whatsapp'] != null) {
      return agent['whatsapp'].toString().replaceAll(RegExp(r'[^\d]'), '');
    }
    if (agent != null && agent['phone'] != null) {
      return agent['phone'].toString().replaceAll(RegExp(r'[^\d]'), '');
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
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
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
                    color: const Color(0xFF426DC2).withOpacity(0.1),
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
                      color: const Color(0xFF426DC2).withOpacity(0.1),
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
                color: const Color(0xFF426DC2).withOpacity(0.1),
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
                color: const Color(0xFF426DC2).withOpacity(0.1),
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
                color: Colors.red.withOpacity(0.1),
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
            color: const Color(0xFF25D366).withOpacity(0.3),
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
            const Text(
              'Online',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF00C851),
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
                  color: Colors.black.withOpacity(0.1),
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
          child: Image.network(
            profileImageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
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
                      child: Image.file(
                        File(message.filePath!),
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
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
                        color: Colors.black.withOpacity(0.8),
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
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
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
                        fontSize: 14,
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _whatsAppTimer?.cancel();
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

  ChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.filePath,
    this.fileType,
    this.isRead = true,
    this.receivedAt,
  });
}
