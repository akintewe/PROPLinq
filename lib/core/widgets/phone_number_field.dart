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

  @override
  void initState() {
    super.initState();
    
    // Initialize display controller with existing value
    if (widget.controller.text.isNotEmpty) {
      if (widget.controller.text.startsWith('234')) {
        // Remove 234 prefix to show only the phone number part
        _displayController.text = widget.controller.text.substring(3);
      } else if (widget.controller.text.startsWith('+234')) {
        // Remove +234 prefix to show only the phone number part
        _displayController.text = widget.controller.text.substring(4);
      } else {
        _displayController.text = widget.controller.text;
      }
    }

    // Listen to display controller changes
    _displayController.addListener(_onPhoneNumberChanged);
  }

  @override
  void dispose() {
    _displayController.removeListener(_onPhoneNumberChanged);
    _displayController.dispose();
    super.dispose();
  }

  void _onPhoneNumberChanged() {
    String phoneNumber = _displayController.text.trim();
    
    // Remove any non-digit characters except the leading 0
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle Nigerian phone number format
    if (phoneNumber.isNotEmpty) {
      // If starts with 0, replace with 234
      if (phoneNumber.startsWith('0')) {
        phoneNumber = '234${phoneNumber.substring(1)}';
      } 
      // If doesn't start with country code, add 234
      else if (!phoneNumber.startsWith('234')) {
        phoneNumber = '234$phoneNumber';
      }
      // If already starts with 234, use as is
      // (no need to add +)
      
      widget.controller.text = phoneNumber;
    } else {
      widget.controller.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label - matching CustomTextField exactly
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        
        // Text field container - matching CustomTextField exactly
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.hasError 
                  ? const Color(0xFFE95439) 
                  : const Color(0xFFECF0F9),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Country code prefix
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: const Text(
                  '+234',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 24,
                color: const Color(0xFFECF0F9),
              ),
              // Phone number input
              Expanded(
                child: TextField(
                  controller: _displayController,
                  focusNode: widget.focusNode,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11), // Max 11 digits
                  ],
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF868686),
                    ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Error message - matching CustomTextField exactly
        if (widget.hasError && widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFFE32908),
              ),
            ),
          ),
      ],
    );
  }
} 