import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneNumberField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool hasError;
  final String? errorMessage;

  const PhoneNumberField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.focusNode,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  final TextEditingController _displayController = TextEditingController();

  // Common country codes
  static const List<Map<String, String>> _countryCodes = [
    {'flag': '🇳🇬', 'code': '+234', 'digits': '234'},
    {'flag': '🇺🇸', 'code': '+1',   'digits': '1'},
    {'flag': '🇬🇧', 'code': '+44',  'digits': '44'},
    {'flag': '🇬🇭', 'code': '+233', 'digits': '233'},
    {'flag': '🇰🇪', 'code': '+254', 'digits': '254'},
    {'flag': '🇿🇦', 'code': '+27',  'digits': '27'},
    {'flag': '🇨🇦', 'code': '+1',   'digits': '1'},
    {'flag': '🇦🇺', 'code': '+61',  'digits': '61'},
    {'flag': '🇩🇪', 'code': '+49',  'digits': '49'},
    {'flag': '🇫🇷', 'code': '+33',  'digits': '33'},
    {'flag': '🇮🇳', 'code': '+91',  'digits': '91'},
    {'flag': '🇦🇪', 'code': '+971', 'digits': '971'},
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Pre-populate display from existing value
    if (widget.controller.text.isNotEmpty) {
      final raw = widget.controller.text.replaceAll(RegExp(r'[^\d]'), '');
      // Try to match country code
      bool matched = false;
      for (int i = 0; i < _countryCodes.length; i++) {
        final digits = _countryCodes[i]['digits']!;
        if (raw.startsWith(digits)) {
          _selectedIndex = i;
          _displayController.text = raw.substring(digits.length);
          matched = true;
          break;
        }
      }
      if (!matched) _displayController.text = raw;
    }
    _displayController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _displayController.removeListener(_onChanged);
    _displayController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final local = _displayController.text.replaceAll(RegExp(r'[^\d]'), '');
    final code = _countryCodes[_selectedIndex]['code']!; // e.g. '+234'
    widget.controller.text = local.isEmpty ? '' : '$code$local';
  }

  void _selectCountry() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView.builder(
        itemCount: _countryCodes.length,
        itemBuilder: (_, i) {
          final c = _countryCodes[i];
          return ListTile(
            leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
            title: Text('${c['flag']} ${c['code']}'),
            onTap: () => Navigator.pop(context, i),
          );
        },
      ),
    );
    if (picked != null) {
      setState(() => _selectedIndex = picked);
      _onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCode = _countryCodes[_selectedIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.hasError ? const Color(0xFFE95439) : const Color(0xFFECF0F9),
            ),
          ),
          child: Row(
            children: [
              // Country code picker
              GestureDetector(
                onTap: _selectCountry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Row(
                    children: [
                      Text(selectedCode['flag']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(selectedCode['code']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: const Color(0xFFECF0F9)),
              Expanded(
                child: TextField(
                  controller: _displayController,
                  focusNode: widget.focusNode,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF868686)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.hasError && widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.errorMessage!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFE32908)),
            ),
          ),
      ],
    );
  }
}
