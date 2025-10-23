import 'package:flutter/material.dart';
import 'package:panorama/panorama.dart';

class VirtualTour360View extends StatefulWidget {
  final String title;
  final List<String>? property360Images;

  const VirtualTour360View({
    Key? key,
    this.title = '360° Virtual Tour',
    this.property360Images,
  }) : super(key: key);

  @override
  State<VirtualTour360View> createState() => _VirtualTour360ViewState();
}

class _VirtualTour360ViewState extends State<VirtualTour360View>
    with TickerProviderStateMixin {
  double _longitude = 0.0;
  double _latitude = 0.0;
  double _tilt = 0.0;
  
  // Multi-node 360° tour system
  int _currentNodeIndex = 0;
  int _nextNodeIndex = 0;
  late AnimationController _transitionController;
  late AnimationController _zoomController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _zoomAnimation;
  bool _isTransitioning = false;
  
  // Image preloading
  final Map<String, Image> _preloadedImages = {};
  bool _imagesPreloaded = false;
  
  // Define multiple 360° nodes using actual property images
  List<TourNode> _tourNodes = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize transition animations
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOutCubic,
    ));
    
    _zoomAnimation = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).animate(CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Initialize tour nodes with actual property 360 images
    _initializeTourNodes();
    
    // Set initial node to 0 (first image)
    _currentNodeIndex = 0;
    _nextNodeIndex = 0;
  }

  void _initializeTourNodes() {
    print('🖼️ VirtualTour360View: Initializing tour nodes...');
    print('🖼️ VirtualTour360View: Property 360 images: ${widget.property360Images}');
    
    if (widget.property360Images != null && widget.property360Images!.isNotEmpty) {
      // Use actual property 360 images
      _tourNodes = widget.property360Images!.asMap().entries.map((entry) {
        final index = entry.key;
        final imageUrl = entry.value;
        
        return TourNode(
          id: 'property_360_$index',
          name: '360° View ${index + 1}',
          imageUrl: imageUrl,
          description: 'Property 360° panorama view ${index + 1}',
        );
      }).toList();
      
      print('✅ VirtualTour360View: Created ${_tourNodes.length} tour nodes from property images');
    } else {
      // Fallback to dummy data if no property images
      _tourNodes = [
        TourNode(
          id: 'fallback',
          name: '360° View',
          imageUrl: 'assets/images/shot-panoramic-composition-living-room.jpg',
          description: '360° virtual tour view',
        ),
      ];
      
      print('⚠️ VirtualTour360View: No property 360 images found, using fallback data');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Preload images after dependencies are ready
    if (!_imagesPreloaded) {
      _preloadImages();
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  // Preload all images in the background
  Future<void> _preloadImages() async {
    for (final node in _tourNodes) {
      try {
        // Check if it's a network URL or asset path
        final image = node.imageUrl.startsWith('http')
            ? Image.network(
                node.imageUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
              )
            : Image.asset(
                node.imageUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
              );
        
        // Trigger image loading
        await precacheImage(image.image, context);
        
        _preloadedImages[node.id] = image;
      } catch (e) {
        print('❌ Failed to preload image: ${node.imageUrl} - $e');
      }
    }
    
    setState(() {
      _imagesPreloaded = true;
    });
    
    print('✅ All images preloaded successfully');
  }

  void _onViewChanged(double longitude, double latitude, double tilt) {
    setState(() {
      _longitude = longitude;
      _latitude = latitude;
      _tilt = tilt;
    });
  }

  // Navigate to the next panoramic image with smooth zoom transition
  Future<void> _moveToNextImage() async {
    if (_isTransitioning || !_imagesPreloaded) return;
    
    final nextIndex = (_currentNodeIndex + 1) % _tourNodes.length;
    
    setState(() {
      _isTransitioning = true;
      _nextNodeIndex = nextIndex;
    });

    // Start slow, continuous zoom animation
    _zoomController.forward();

    // Wait for zoom to complete (this gives time for smooth zoom)
    await _zoomController.forward();

    // Now that zoom is complete, start fade out to next image
    await _transitionController.forward();

    // Change to next image
    setState(() {
      _currentNodeIndex = nextIndex;
      _longitude = 0.0; // Reset view to center
      _latitude = 0.0;
      _tilt = 0.0;
    });

    // Reset zoom and fade in to new image
    _zoomController.reset();
    _transitionController.reset();
    await _transitionController.reverse();

    setState(() {
      _isTransitioning = false;
    });
  }

  // Get current tour node
  TourNode get _currentNode => _tourNodes[_currentNodeIndex];
  TourNode get _nextNode => _tourNodes[_nextNodeIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
                fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
            ),
            Text(
              _currentNode.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background layer with next image (for smooth transition)
          if (_isTransitioning && _imagesPreloaded && _preloadedImages.containsKey(_nextNode.id))
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_fadeAnimation, _zoomAnimation]),
                builder: (context, child) {
                  // Only start showing next image when zoom is nearly complete (80% done)
                  // and current image starts fading
                  final zoomProgress = _zoomAnimation.value;
                  final fadeProgress = _fadeAnimation.value;
                  
                  // Next image appears when zoom is 80% complete and fade starts
                  final nextImageOpacity = (zoomProgress > 1.64 && fadeProgress < 1.0) 
                      ? (1.0 - fadeProgress) 
                      : 0.0;
                  
                  return Opacity(
                    opacity: nextImageOpacity,
                    child: Panorama(
                      child: _preloadedImages[_nextNode.id]!,
                      onViewChanged: _onViewChanged,
                      onTap: (longitude, latitude, tilt) {
                        // Disable tap during transition
                      },
                      animSpeed: 1.0,
                      sensorControl: SensorControl.None,
                      sensitivity: 1.0,
                    ),
                  );
                },
              ),
            ),

          // Main 360° panoramic viewer with zoom effect
          AnimatedBuilder(
            animation: Listenable.merge([_fadeAnimation, _zoomAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _zoomAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Panorama(
                    child: _imagesPreloaded && _preloadedImages.containsKey(_currentNode.id)
                        ? _preloadedImages[_currentNode.id]!
                        : _currentNode.imageUrl.startsWith('http')
                            ? Image.network(
                                _currentNode.imageUrl,
               fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                isAntiAlias: true,
                                cacheWidth: null,
                                cacheHeight: null,
               errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1e3c72),
                        Color(0xFF2a5298),
                        Color(0xFF426DC2),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load panoramic image',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please check your internet connection',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                            : Image.asset(
                                _currentNode.imageUrl,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                isAntiAlias: true,
                                cacheWidth: null,
                                cacheHeight: null,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF1e3c72),
                                          Color(0xFF2a5298),
                                          Color(0xFF426DC2),
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 64,
                                            color: Colors.white,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Failed to load panoramic image',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Asset image not found',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
                         onViewChanged: _onViewChanged,
             onTap: (longitude, latitude, tilt) {
                      // This is the key - use Panorama's onTap to detect taps
                      print('🎯 Panorama tapped at: $longitude, $latitude');
                      _moveToNextImage();
             },
             animSpeed: 1.0,
                    sensorControl: SensorControl.None,
                    sensitivity: 1.0,
                  ),
                ),
              );
            },
          ),

          // Top overlay with viewing instructions
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.threed_rotation,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                     child: Text(
                      'Drag to explore • Tap anywhere to move to next area • ${_currentNode.description}',
                      style: const TextStyle(
                         color: Colors.white,
                         fontSize: 14,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                   ),
                  IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () {
                      _showInstructions(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom overlay with minimal info
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentNodeIndex + 1}/${_tourNodes.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                ),
                ],
              ),
            ),
          ),

          // Loading indicator while images are being preloaded
          if (!_imagesPreloaded)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                        'Loading Virtual Tour...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Debug info (temporary - remove this later)
          if (_imagesPreloaded)
            Positioned(
              top: 100,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Tap to move!\nCurrent: ${_currentNode.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showInstructions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.threed_rotation,
                    color: Color(0xFF426DC2),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'How to Navigate',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _instructionItem(
                Icons.pan_tool,
                'Drag to Look Around',
                'Swipe in any direction to rotate the view and explore different areas.',
              ),
              const SizedBox(height: 16),
                             _instructionItem(
                Icons.touch_app,
                'Tap to Move',
                'Tap anywhere on the image to move to the next panoramic view.',
               ),
              const SizedBox(height: 16),
              _instructionItem(
                Icons.info,
                'Current Location',
                'The bottom indicator shows your current position in the tour.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF426DC2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _instructionItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF426DC2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF426DC2),
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Simplified data model for tour nodes
class TourNode {
  final String id;
  final String name;
  final String imageUrl;
  final String description;

  TourNode({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
  });
}



 