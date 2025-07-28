import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class LocationAutocompleteField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final VoidCallback? onLocationSelected;
  final String apiKey;

  const LocationAutocompleteField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.validator,
    this.onLocationSelected,
    required this.apiKey,
  });

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = false;
  bool _showPredictions = false;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _showPredictions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.length > 2) {
        _searchPlaces(value);
      } else {
        setState(() {
          _predictions = [];
          _showPredictions = false;
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&components=country:ng'
          '&key=${widget.apiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final predictions = List<Map<String, dynamic>>.from(data['predictions']);
          setState(() {
            _predictions = predictions;
            _showPredictions = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _predictions = [];
            _showPredictions = false;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPredictionSelected(Map<String, dynamic> prediction) {
    setState(() {
      widget.controller.text = prediction['description'] ?? '';
      _showPredictions = false;
    });
    
    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!();
    }
    
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Text Field with Autocomplete
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNode.hasFocus 
                  ? const Color(0xFF426DC2)
                  : const Color(0xFFE0E0E0),
              width: _focusNode.hasFocus ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Text Field
              TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    color: Color(0xFF868686),
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      'assets/icons/location.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF868686),
                        BlendMode.srcIn,
                      ),
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.location_on,
                          size: 20,
                          color: Color(0xFF868686),
                        );
                      },
                    ),
                  ),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF426DC2),
                            ),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: _onSearchChanged,
                validator: widget.validator,
              ),
              

              
              // Predictions List
              if (_showPredictions && _predictions.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _predictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      final structuredFormatting = prediction['structured_formatting'] as Map<String, dynamic>?;
                      
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Color(0xFF426DC2),
                          size: 20,
                        ),
                        title: Text(
                          structuredFormatting?['main_text'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          structuredFormatting?['secondary_text'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF868686),
                          ),
                        ),
                        onTap: () => _onPredictionSelected(prediction),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
} 