import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapDirectionsView extends StatefulWidget {
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? destinationAddress;
  final String propertyTitle;

  const MapDirectionsView({
    super.key,
    this.destinationLatitude,
    this.destinationLongitude,
    this.destinationAddress,
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

  // Resolved destination coordinates (set in initState from widget params or geocoding)
  late double _destLat;
  late double _destLng;

  // Google Maps API key
  static const String _googleMapsApiKey = 'AIzaSyAtLvjrEcosVTq266ARbO2KBFN_9RSyobQ';

  @override
  void initState() {
    super.initState();
    if (widget.destinationLatitude != null && widget.destinationLongitude != null) {
      _destLat = widget.destinationLatitude!;
      _destLng = widget.destinationLongitude!;
      _getCurrentLocation();
    } else if (widget.destinationAddress != null && widget.destinationAddress!.isNotEmpty) {
      _geocodeAddressThenLoad(widget.destinationAddress!);
    } else {
      // Fallback: Lagos
      _destLat = 6.5244;
      _destLng = 3.3792;
      _getCurrentLocation();
    }
  }

  Future<void> _geocodeAddressThenLoad(String address) async {
    try {
      final encoded = Uri.encodeComponent(address);
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=$encoded&key=$_googleMapsApiKey';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          _destLat = (loc['lat'] as num).toDouble();
          _destLng = (loc['lng'] as num).toDouble();
        } else {
          // Geocode failed — fallback to Lagos
          _destLat = 6.5244;
          _destLng = 3.3792;
        }
      } else {
        _destLat = 6.5244;
        _destLng = 3.3792;
      }
    } catch (_) {
      _destLat = 6.5244;
      _destLng = 3.3792;
    }
    if (mounted) _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
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

      // Try to get last known position first (faster)
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        if (position != null) {
        }
      } catch (e) {
      }

      // If no last known position, get current position
      if (position == null) {
        try {
          // Use longer timeout and better accuracy settings
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 15),
          ).timeout(
            const Duration(seconds: 20),
          );
        } catch (timeoutError) {
          // Try last known position as fallback
          position = await Geolocator.getLastKnownPosition();
          if (position == null) {
            throw Exception('Could not get location. Please ensure location services are enabled and try again.');
          }
        }
      }

      // At this point, position is guaranteed to be non-null (either from getLastKnownPosition or getCurrentPosition)
      final currentPosition = position;

      // Validate coordinates are reasonable (not 0,0 or obviously fake)
      if (currentPosition.latitude == 0.0 && currentPosition.longitude == 0.0) {
        throw Exception('Invalid location coordinates. Please ensure GPS is enabled.');
      }


      if (!mounted) return;

      setState(() {
        _currentPosition = currentPosition;
        _isLoadingLocation = false;
      });

      // Add markers
      _addMarkers();
      

      // Get directions
      await _getDirections();

      // Move camera to show both locations
      if (mounted) {
        _fitMapToRoute();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get current location: ${e.toString()}';
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
          position: LatLng(_destLat, _destLng),
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
      
      final origin = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final destination = '${_destLat},${_destLng}';
      
      final url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=$origin&'
          'destination=$destination&'
          'key=$_googleMapsApiKey';


      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        
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

          }
        } else {
          
          // Calculate straight-line distance as fallback
          _calculateStraightLineDistance();
        }
      } else {
        
        // Calculate straight-line distance as fallback
        _calculateStraightLineDistance();
      }
    } on TimeoutException catch (e) {
      _calculateStraightLineDistance();
    } catch (e, stackTrace) {
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
        _destLat,
        _destLng,
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

      // Draw a straight line between the two points
      final straightLine = [
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(_destLat, _destLng),
      ];

      setState(() {
        _distance = '$distanceStr (approx)';
        _duration = '$durationStr (approx)';
        _polylines = {
          Polyline(
            polylineId: const PolylineId('straight_line'),
            points: straightLine,
            color: const Color(0xFF426DC2).withOpacity(0.6),
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        };
      });

    } catch (e) {
    }
  }

  void _fitMapToRoute() {
    if (_mapController == null || _currentPosition == null) return;

    try {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _currentPosition!.latitude < _destLat
              ? _currentPosition!.latitude
              : _destLat,
          _currentPosition!.longitude < _destLng
              ? _currentPosition!.longitude
              : _destLng,
        ),
        northeast: LatLng(
          _currentPosition!.latitude > _destLat
              ? _currentPosition!.latitude
              : _destLat,
          _currentPosition!.longitude > _destLng
              ? _currentPosition!.longitude
              : _destLng,
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } catch (e) {
      // Fallback: just center on destination
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_destLat, _destLng),
            12,
          ),
        );
      } catch (e2) {
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
          // Map - Always show map, even if current location is not available
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition?.latitude ?? _destLat,
                _currentPosition?.longitude ?? _destLng,
              ),
              zoom: _currentPosition != null ? 14 : 15,
            ),
            markers: _markers.isEmpty && _currentPosition == null
                ? {
                    // Show at least the destination marker if current location is not available
                    Marker(
                      markerId: const MarkerId('destination'),
                      position: LatLng(_destLat, _destLng),
                      infoWindow: InfoWindow(
                        title: widget.propertyTitle,
                        snippet: 'Destination',
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    ),
                  }
                : _markers,
            polylines: _polylines,
            myLocationEnabled: _currentPosition != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              try {
                _mapController = controller;
                // Delay the camera animation to ensure map is fully initialized
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    if (_currentPosition != null) {
                      _fitMapToRoute();
                    } else {
                      // Just center on destination if current location is not available
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(_destLat, _destLng),
                          15,
                        ),
                      );
                    }
                  }
                });
              } catch (e) {
              }
            },
          ),
          
          // Loading overlay when getting location
          if (_currentPosition == null && _isLoadingLocation)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
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
                ),
              ),
            ),
          
          // Error overlay when location fails
          if (_currentPosition == null && !_isLoadingLocation && _errorMessage != null)
            Container(
              color: Colors.white.withOpacity(0.95),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
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
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // Show destination only
                          setState(() {
                            _isLoadingLocation = false;
                            _errorMessage = null;
                          });
                        },
                        child: const Text(
                          'Show destination only',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF426DC2),
                          ),
                        ),
                      ),
                    ],
                  ),
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

