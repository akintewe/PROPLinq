import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  // Default location (Lagos, Nigeria) if no coordinates provided
  static const double _defaultLatitude = 6.5244;
  static const double _defaultLongitude = 3.3792;

  @override
  void initState() {
    super.initState();
    // Delay initialization to ensure proper setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMarkers();
    });
  }

  void _initializeMarkers() {
    try {
      final lat = widget.latitude ?? _defaultLatitude;
      final lng = widget.longitude ?? _defaultLongitude;
      
      if (widget.showMarker && mounted) {
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
      }
    } catch (e) {
      print('Error initializing markers: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildFallbackUI();
    }

    final lat = widget.latitude ?? _defaultLatitude;
    final lng = widget.longitude ?? _defaultLongitude;

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
        child: _isMapReady 
            ? GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: 15.0,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  if (mounted) {
                    setState(() {
                      _mapController = controller;
                      _isMapReady = true;
                    });
                  }
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                mapType: MapType.normal,
                onTap: (_) {
                  // Handle map tap if needed
                },
                onCameraMove: (position) {
                  // Handle camera movement if needed
                },
              )
            : _buildLoadingUI(),
      ),
    );
  }

  Widget _buildLoadingUI() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF426DC2),
            ),
            SizedBox(height: 16),
            Text(
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
  }

  Widget _buildFallbackUI() {
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
    _mapController?.dispose();
    super.dispose();
  }
} 