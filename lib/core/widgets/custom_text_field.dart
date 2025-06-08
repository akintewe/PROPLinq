import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool hasError;
  final String? errorMessage;
  final bool showVisibilityToggle;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.hasError = false,
    this.errorMessage,
    this.showVisibilityToggle = false,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isPasswordVisible = false;

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
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        
        // Text field
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          obscureText: widget.showVisibilityToggle 
              ? !_isPasswordVisible 
              : widget.obscureText,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF868686),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFFECF0F9),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: widget.hasError ? const Color(0xFFE95439) : const Color(0xFF426DC2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: widget.hasError ? const Color(0xFFE95439) : const Color(0xFFECF0F9),
                width: 1,
              ),
            ),
            suffixIcon: widget.showVisibilityToggle
                ? IconButton(
                    icon: SvgPicture.asset(
                      _isPasswordVisible 
                          ? 'assets/icons/eye.svg'
                          : 'assets/icons/eye-slash.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF868686),
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : widget.suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        
        // Error message
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