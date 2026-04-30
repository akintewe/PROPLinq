import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/location_service.dart';
import '../services/user_preferences_service.dart';

/// Dialog for users outside Nigeria to select their discovery location
class LocationSelectionDialog extends StatefulWidget {
  const LocationSelectionDialog({super.key});

  @override
  State<LocationSelectionDialog> createState() => _LocationSelectionDialogState();
}

class _LocationSelectionDialogState extends State<LocationSelectionDialog> {
  final LocationService _locationService = LocationService.instance;
  final UserPreferencesService _prefsService = UserPreferencesService();

  List<Map<String, dynamic>> _nigerianAreas = [];
  String? _selectedLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNigerianAreas();
  }

  void _loadNigerianAreas() {
    setState(() {
      _nigerianAreas = _locationService.getDefaultNigerianAreas();
      _isLoading = false;
    });
  }

  Future<void> _selectLocation(Map<String, dynamic> area) async {
    final location = area['locationQuery'] as String;
    final coordinates = area['coordinates'] as Map<String, double>?;

    // Save the selected location
    await _prefsService.saveSelectedLocation(location, coordinates: coordinates);

    if (mounted) {
      // Return the selected location
      Navigator.of(context).pop(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECF0F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF426DC2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose a location in Nigeria to explore properties',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info banner
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
                      'You\'re viewing from outside Nigeria. Select a location to discover properties.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF663C00),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Locations list
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _nigerianAreas.length,
                  itemBuilder: (context, index) {
                    final area = _nigerianAreas[index];
                    return _buildLocationItem(area);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(Map<String, dynamic> area) {
    final title = area['title'] as String;
    final subtitle = area['subtitle'] as String;
    final icon = area['icon'] as String;
    final iconColor = area['iconColor'] as Color;

    return InkWell(
      onTap: () => _selectLocation(area),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                icon,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  iconColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 16),
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }
}
