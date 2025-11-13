import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapDirectionsView extends StatefulWidget {
  final double destinationLatitude;
  final double destinationLongitude;
  final String propertyTitle;

  const MapDirectionsView({
    super.key,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.propertyTitle,
  });

  @override
  State<MapDirectionsView> createState() => _MapDirectionsViewState();
}

class _MapDirectionsViewState extends State<MapDirectionsView> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String? _errorMessage;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  String _distance = '';
  String _duration = '';
  bool _isLoadingDirections = false;

  // Google Maps API key
  static const String _googleMapsApiKey = 'AIzaSyAtLvjrEcosVTq266ARbO2KBFN_9RSyobQ';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('📍 Getting current location...');
      setState(() {
        _isLoadingLocation = true;
        _errorMessage = null;
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied. Please grant permission.';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permission permanently denied. Please enable it in settings.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Location request timed out, using default location');
          // Use a default location near the destination for simulator testing
          return Position(
            latitude: widget.destinationLatitude + 0.05, // ~5km north
            longitude: widget.destinationLongitude + 0.05,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        },
      );

      print('✅ Current location: ${position.latitude}, ${position.longitude}');

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Add markers
      _addMarkers();

      // Get directions (this might fail on simulator, but we handle it gracefully)
      await _getDirections();

      // Move camera to show both locations
      if (mounted) {
        _fitMapToRoute();
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      setState(() {
        _errorMessage = 'Failed to get current location: $e';
        _isLoadingLocation = false;
      });
    }
  }

  void _addMarkers() {
    if (_currentPosition == null) return;

    setState(() {
      _markers = {
        // Current location marker
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        // Destination marker
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(widget.destinationLatitude, widget.destinationLongitude),
          infoWindow: InfoWindow(
            title: widget.propertyTitle,
            snippet: 'Destination',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });
  }

  Future<void> _getDirections() async {
    if (_currentPosition == null) return;

    if (!mounted) return;
    
    setState(() {
      _isLoadingDirections = true;
    });

    try {
      print('🗺️ Getting directions...');
      
      final origin = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final destination = '${widget.destinationLatitude},${widget.destinationLongitude}';
      
      final url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=$origin&'
          'destination=$destination&'
          'key=$_googleMapsApiKey';

      print('🌐 Directions API URL: $url');

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Directions API request timed out');
          throw TimeoutException('Request timed out');
        },
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('🔍 API Status: ${data['status']}');
        
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Get distance and duration safely
          final distance = leg['distance']?['text'] ?? 'N/A';
          final duration = leg['duration']?['text'] ?? 'N/A';
          
          if (!mounted) return;
          
          setState(() {
            _distance = distance;
            _duration = duration;
          });

          print('✅ Distance: $_distance, Duration: $_duration');

          // Decode polyline safely
          final overviewPolyline = route['overview_polyline'];
          if (overviewPolyline != null && overviewPolyline['points'] != null) {
            final points = overviewPolyline['points'] as String;
            final polylinePoints = PolylinePoints();
            final result = polylinePoints.decodePolyline(points);

            if (!mounted) return;

            setState(() {
              _polylineCoordinates = result
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList();
              
              if (_polylineCoordinates.isNotEmpty) {
                _polylines = {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: _polylineCoordinates,
                    color: const Color(0xFF426DC2),
                    width: 5,
                  ),
                };
              }
            });

            print('✅ Polyline created with ${_polylineCoordinates.length} points');
          }
        } else {
          print('❌ Directions API error: ${data['status']}');
          print('❌ Error message: ${data['error_message'] ?? 'No error message'}');
          
          // Calculate straight-line distance as fallback
          _calculateStraightLineDistance();
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        
        // Calculate straight-line distance as fallback
        _calculateStraightLineDistance();
      }
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      _calculateStraightLineDistance();
    } catch (e, stackTrace) {
      print('❌ Error getting directions: $e');
      print('❌ Stack trace: $stackTrace');
      _calculateStraightLineDistance();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDirections = false;
        });
      }
    }
  }

  void _calculateStraightLineDistance() {
    if (_currentPosition == null || !mounted) return;

    try {
      // Calculate straight-line distance in meters
      final distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        widget.destinationLatitude,
        widget.destinationLongitude,
      );

      // Convert to km if > 1000m
      final distanceStr = distanceInMeters > 1000
          ? '${(distanceInMeters / 1000).toStringAsFixed(1)} km'
          : '${distanceInMeters.toStringAsFixed(0)} m';

      // Estimate duration (assuming average speed of 40 km/h)
      final durationInMinutes = (distanceInMeters / 1000) / 40 * 60;
      final durationStr = durationInMinutes > 60
          ? '${(durationInMinutes / 60).toStringAsFixed(0)} hours ${(durationInMinutes % 60).toStringAsFixed(0)} mins'
          : '${durationInMinutes.toStringAsFixed(0)} mins';

      setState(() {
        _distance = '$distanceStr (approx)';
        _duration = '$durationStr (approx)';
      });

      print('📏 Straight-line distance: $_distance');
      print('⏱️ Estimated duration: $_duration');
    } catch (e) {
      print('❌ Error calculating distance: $e');
    }
  }

  void _fitMapToRoute() {
    if (_mapController == null || _currentPosition == null) return;

    try {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _currentPosition!.latitude < widget.destinationLatitude
              ? _currentPosition!.latitude
              : widget.destinationLatitude,
          _currentPosition!.longitude < widget.destinationLongitude
              ? _currentPosition!.longitude
              : widget.destinationLongitude,
        ),
        northeast: LatLng(
          _currentPosition!.latitude > widget.destinationLatitude
              ? _currentPosition!.latitude
              : widget.destinationLatitude,
          _currentPosition!.longitude > widget.destinationLongitude
              ? _currentPosition!.longitude
              : widget.destinationLongitude,
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } catch (e) {
      print('❌ Error fitting map to route: $e');
      // Fallback: just center on destination
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(widget.destinationLatitude, widget.destinationLongitude),
            12,
          ),
        );
      } catch (e2) {
        print('❌ Error with fallback camera move: $e2');
      }
    }
  }

  void _recenterMap() {
    _fitMapToRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map
          if (_currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 14,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                try {
                  _mapController = controller;
                  // Delay the camera animation to ensure map is fully initialized
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      _fitMapToRoute();
                    }
                  });
                } catch (e) {
                  print('❌ Error in onMapCreated: $e');
                }
              },
            )
          else
            Container(
              color: const Color(0xFFE8F4FD),
              child: Center(
                child: _isLoadingLocation
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF426DC2),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Getting your location...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF426DC2),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_off,
                            size: 60,
                            color: Color(0xFF426DC2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage ?? 'Failed to get location',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF426DC2),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _getCurrentLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF426DC2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

          // Top app bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECF0F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF426DC2),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Directions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.propertyTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF868686),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Distance and duration info card
          if (_distance.isNotEmpty && _duration.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 90,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(Icons.straighten, 'Distance', _distance),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFFECF0F9),
                    ),
                    _buildInfoItem(Icons.access_time, 'Duration', _duration),
                  ],
                ),
              ),
            ),

          // Loading directions indicator
          if (_isLoadingDirections)
            Positioned(
              top: MediaQuery.of(context).padding.top + 90,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFF426DC2),
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Calculating route...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Recenter button
          Positioned(
            bottom: 100,
            right: 24,
            child: FloatingActionButton(
              onPressed: _recenterMap,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.my_location,
                color: Color(0xFF426DC2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF426DC2),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF868686),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF426DC2),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

