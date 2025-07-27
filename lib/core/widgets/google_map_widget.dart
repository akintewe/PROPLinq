import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class GoogleMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? propertyTitle;
  final double height;
  final bool showMarker;

  const GoogleMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.propertyTitle,
    this.height = 200,
    this.showMarker = true,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isMapReady = false;
  bool _hasError = false;
  bool _isInitializing = false;
  bool _forceShowMap = false;
  Timer? _timeoutTimer;

  // Default location (Lagos, Nigeria) if no coordinates provided
  static const double _defaultLatitude = 6.5244;
  static const double _defaultLongitude = 3.3792;

  @override
  void initState() {
    super.initState();
    print('🗺️ GoogleMapWidget: initState called');
    print('🗺️ GoogleMapWidget: Widget properties:');
    print('  - Latitude: ${widget.latitude}');
    print('  - Longitude: ${widget.longitude}');
    print('  - Property Title: ${widget.propertyTitle}');
    print('  - Height: ${widget.height}');
    print('  - Show Marker: ${widget.showMarker}');
    
    // Start timeout timer
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      print('⏰ GoogleMapWidget: Timeout reached, showing static map');
      if (mounted && !_isMapReady) {
        setState(() {
          _forceShowMap = true;
        });
      }
    });
    
    // Delay initialization to ensure proper setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🗺️ GoogleMapWidget: Post frame callback triggered');
      _initializeMarkers();
    });
  }

  void _initializeMarkers() {
    try {
      print('🗺️ GoogleMapWidget: Initializing markers...');
      _isInitializing = true;
      
      final lat = widget.latitude ?? _defaultLatitude;
      final lng = widget.longitude ?? _defaultLongitude;
      
      print('🗺️ GoogleMapWidget: Using coordinates - Lat: $lat, Lng: $lng');
      
      if (widget.showMarker && mounted) {
        print('🗺️ GoogleMapWidget: Creating marker...');
        setState(() {
          _markers = {
            Marker(
              markerId: const MarkerId('property_location'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: widget.propertyTitle ?? 'Property Location',
                snippet: 'Tap to view details',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          };
        });
        print('🗺️ GoogleMapWidget: Marker created successfully');
      }
      
      _isInitializing = false;
      print('🗺️ GoogleMapWidget: Marker initialization completed');
    } catch (e) {
      print('❌ GoogleMapWidget: Error initializing markers: $e');
      _isInitializing = false;
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _showMapOptions() {
    final lat = widget.latitude ?? _defaultLatitude;
    final lng = widget.longitude ?? _defaultLongitude;
    final propertyTitle = widget.propertyTitle ?? 'Property Location';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            Text(
              'View Location',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              propertyTitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF868686),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Open in Google Maps
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.map,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                    title: const Text(
                      'Open in Google Maps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'View in Google Maps app',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF868686),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _openInGoogleMaps(lat, lng, propertyTitle);
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Get Directions
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                    title: const Text(
                      'Get Directions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'Navigate to this location',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF868686),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _getDirections(lat, lng, propertyTitle);
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Copy coordinates
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.copy,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                    title: const Text(
                      'Copy Coordinates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '$lat, $lng',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF868686),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _copyCoordinates(lat, lng);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openInGoogleMaps(double lat, double lng, String title) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    print('🗺️ GoogleMapWidget: Opening Google Maps URL: $url');
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open Google Maps');
      }
    } catch (e) {
      print('❌ GoogleMapWidget: Error opening Google Maps: $e');
      _showErrorSnackBar('Error opening Google Maps');
    }
  }

  void _getDirections(double lat, double lng, String title) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    print('🗺️ GoogleMapWidget: Getting directions URL: $url');
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open directions');
      }
    } catch (e) {
      print('❌ GoogleMapWidget: Error getting directions: $e');
      _showErrorSnackBar('Error opening directions');
    }
  }

  void _copyCoordinates(double lat, double lng) {
    final coordinates = '$lat, $lng';
    // You can add clipboard functionality here
    print('🗺️ GoogleMapWidget: Coordinates copied: $coordinates');
    _showSuccessSnackBar('Coordinates copied: $coordinates');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🗺️ GoogleMapWidget: build() called');
    print('🗺️ GoogleMapWidget: Current state:');
    print('  - Has Error: $_hasError');
    print('  - Is Map Ready: $_isMapReady');
    print('  - Is Initializing: $_isInitializing');
    print('  - Force Show Map: $_forceShowMap');
    print('  - Markers Count: ${_markers.length}');
    
    if (_hasError) {
      print('🗺️ GoogleMapWidget: Showing fallback UI due to error');
      return _buildFallbackUI();
    }

    final lat = widget.latitude ?? _defaultLatitude;
    final lng = widget.longitude ?? _defaultLongitude;
    
    print('🗺️ GoogleMapWidget: Building map with coordinates - Lat: $lat, Lng: $lng');

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: (_isMapReady && !_forceShowMap)
            ? _buildGoogleMap(lat, lng)
            : _buildStaticMap(lat, lng),
      ),
    );
  }

  Widget _buildGoogleMap(double lat, double lng) {
    print('🗺️ GoogleMapWidget: Building actual GoogleMap widget');
    print('🗺️ GoogleMapWidget: Map ready: $_isMapReady, Force show: $_forceShowMap');
    
    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, lng),
          zoom: 15.0,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          print('🗺️ GoogleMapWidget: onMapCreated callback triggered');
          if (mounted) {
            setState(() {
              _mapController = controller;
              _isMapReady = true;
            });
            print('🗺️ GoogleMapWidget: Map controller set and ready state updated');
          }
        },
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        mapType: MapType.normal,
        onTap: (_) {
          print('🗺️ GoogleMapWidget: Map tapped');
        },
        onCameraMove: (position) {
          // Handle camera movement if needed
        },
      );
    } catch (e) {
      print('❌ GoogleMapWidget: Error creating GoogleMap widget: $e');
      return _buildStaticMap(lat, lng);
    }
  }

  Widget _buildStaticMap(double lat, double lng) {
    print('🗺️ GoogleMapWidget: Building static map');
    
    // Create static map URL with better styling
    final apiKey = 'AIzaSyAtLvjrEcosVTq266ARbO2KBFN_9RSyobQ';
    final staticMapUrl = 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$lat,$lng&'
        'zoom=15&'
        'size=600x400&'
        'scale=2&'
        'markers=color:blue%7Clabel:P%7C$lat,$lng&'
        'key=$apiKey';
    
    print('🗺️ GoogleMapWidget: Static map URL: $staticMapUrl');
    
    return GestureDetector(
      onTap: () {
        print('🗺️ GoogleMapWidget: Static map tapped - showing options');
        _showMapOptions();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFE8F4FD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Static map image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                staticMapUrl,
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ GoogleMapWidget: Error loading static map: $error');
                  return _buildFallbackUI();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFE8F4FD),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF426DC2),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading Map...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF426DC2),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Gradient overlay for better text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                    stops: const [0.7, 1.0],
                  ),
                ),
              ),
            ),
            
            // Property info overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFF426DC2),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.propertyTitle ?? 'Property Location',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF426DC2),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Top right corner indicator
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map,
                      size: 12,
                      color: Color(0xFF426DC2),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'MAP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Tap indicator
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tap to view',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
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

  Widget _buildLoadingUI() {
    print('🗺️ GoogleMapWidget: Building loading UI');
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF426DC2),
            ),
            const SizedBox(height: 16),
            Text(
              _isInitializing ? 'Initializing Map...' : 'Loading Map...',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF426DC2),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coordinates: ${widget.latitude ?? _defaultLatitude}, ${widget.longitude ?? _defaultLongitude}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF868686),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Markers: ${_markers.length}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF868686),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackUI() {
    print('🗺️ GoogleMapWidget: Building fallback UI');
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFE8F4FD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background map-like pattern
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE8F4FD),
                  const Color(0xFFD1E7FD),
                ],
              ),
            ),
          ),
          
          // Map content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF426DC2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 30,
                    color: Color(0xFF426DC2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.propertyTitle ?? 'Property Location',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF426DC2),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Map Preview',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF868686),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF426DC2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Interactive Map Coming Soon',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF426DC2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Top right corner indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map,
                    size: 12,
                    color: Color(0xFF426DC2),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'MAP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF426DC2),
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

  @override
  void dispose() {
    print('🗺️ GoogleMapWidget: dispose() called');
    _timeoutTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
} 