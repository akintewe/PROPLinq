import 'package:flutter/material.dart';
import 'package:panorama/panorama.dart';

class VirtualTour360View extends StatefulWidget {
  final String imageUrl;
  final String title;

  const VirtualTour360View({
    Key? key,
    required this.imageUrl,
    this.title = '360° Virtual Tour',
  }) : super(key: key);

  @override
  State<VirtualTour360View> createState() => _VirtualTour360ViewState();
}

class _VirtualTour360ViewState extends State<VirtualTour360View> {
  double _longitude = 0.0;
  double _latitude = 0.0;
  double _tilt = 0.0;

  void _onViewChanged(double longitude, double latitude, double tilt) {
    setState(() {
      _longitude = longitude;
      _latitude = latitude;
      _tilt = tilt;
    });
  }

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
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main 360° panoramic viewer
                     Panorama(
             child: Image.asset(
               widget.imageUrl,
               fit: BoxFit.cover,
               filterQuality: FilterQuality.high, // High quality filtering
               isAntiAlias: true, // Enable anti-aliasing for smoother edges
               cacheWidth: null, // Don't limit cache width for full quality
               cacheHeight: null, // Don't limit cache height for full quality
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
            ),
                         onViewChanged: _onViewChanged,
             onTap: (longitude, latitude, tilt) {
               // You can add hotspots or interactive elements here
               print('Tapped at: longitude: $longitude, latitude: $latitude');
             },
             animSpeed: 1.0,
             sensorControl: SensorControl.None, // Disable sensor control to avoid plugin errors
             sensitivity: 1.0, // Optimal sensitivity for smooth movement
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
                                     const Expanded(
                     child: Text(
                       'Drag to explore • Swipe to navigate 360°',
                       style: TextStyle(
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

          // Bottom overlay with coordinates (for development/debugging)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'θ: ${_longitude.toStringAsFixed(1)}° φ: ${_latitude.toStringAsFixed(1)}°',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),

          // Loading indicator overlay (shown while image loads)
          if (widget.imageUrl.isEmpty)
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading 360° Virtual Tour...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
                 Icons.zoom_out_map,
                 'Pinch to Zoom',
                 'Use pinch gestures to zoom in and out for detailed exploration.',
               ),
              const SizedBox(height: 16),
              _instructionItem(
                Icons.touch_app,
                'Tap to Interact',
                'Tap on areas of interest to discover interactive hotspots.',
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



 