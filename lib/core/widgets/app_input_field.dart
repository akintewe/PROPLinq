import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_dimensions.dart';

enum AppInputFieldSize {
  small,
  medium,
  large,
}

class AppInputField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final bool isPassword;
  final bool isRequired;
  final bool isReadOnly;
  final bool isEnabled;
  final AppInputFieldSize size;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;

  const AppInputField({
    super.key,
    this.label,
    this.hintText,
    this.errorText,
    this.helperText,
    this.controller,
    this.isPassword = false,
    this.isRequired = false,
    this.isReadOnly = false,
    this.isEnabled = true,
    this.size = AppInputFieldSize.medium,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.focusNode,
    this.validator,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  bool _isObscured = true;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          _buildLabel(),
          const SizedBox(height: AppDimensions.spacing8),
        ],
        _buildTextField(),
        if (widget.errorText != null || widget.helperText != null) ...[
          const SizedBox(height: AppDimensions.spacing4),
          _buildHelperText(),
        ],
      ],
    );
  }

  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.label!,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.onSurface,
        ),
        children: [
          if (widget.isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error600),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      height: _getInputHeight(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        boxShadow: [
          if (_focusNode.hasFocus)
            BoxShadow(
              color: AppColors.primary600.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.isPassword && _isObscured,
        readOnly: widget.isReadOnly,
        enabled: widget.isEnabled,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        onTap: widget.onTap,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        style: _getTextStyle(),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: _getHintStyle(),
          prefixIcon: widget.prefixIcon,
          suffixIcon: _buildSuffixIcon(),
          filled: true,
          fillColor: _getFillColor(),
          border: _getBorder(),
          enabledBorder: _getBorder(),
          focusedBorder: _getFocusedBorder(),
          errorBorder: _getErrorBorder(),
          focusedErrorBorder: _getErrorBorder(),
          disabledBorder: _getDisabledBorder(),
          contentPadding: _getContentPadding(),
          counterText: '',
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility_off : Icons.visibility,
          size: _getIconSize(),
          color: AppColors.grey500,
        ),
        onPressed: () {
          setState(() {
            _isObscured = !_isObscured;
          });
        },
      );
    }
    return widget.suffixIcon;
  }

  Widget _buildHelperText() {
    return Text(
      widget.errorText ?? widget.helperText ?? '',
      style: AppTypography.bodySmall.copyWith(
        color: widget.errorText != null 
            ? AppColors.error600 
            : AppColors.grey600,
      ),
    );
  }

  double _getInputHeight() {
    switch (widget.size) {
      case AppInputFieldSize.small:
        return AppDimensions.inputHeightS;
      case AppInputFieldSize.medium:
        return AppDimensions.inputHeightM;
      case AppInputFieldSize.large:
        return AppDimensions.inputHeightL;
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case AppInputFieldSize.small:
        return AppDimensions.radiusS;
      case AppInputFieldSize.medium:
        return AppDimensions.radiusM;
      case AppInputFieldSize.large:
        return AppDimensions.radiusL;
    }
  }

  EdgeInsetsGeometry _getContentPadding() {
    switch (widget.size) {
      case AppInputFieldSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        );
      case AppInputFieldSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        );
      case AppInputFieldSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingL,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case AppInputFieldSize.small:
        return AppTypography.bodySmall;
      case AppInputFieldSize.medium:
        return AppTypography.bodyMedium;
      case AppInputFieldSize.large:
        return AppTypography.bodyLarge;
    }
  }

  TextStyle _getHintStyle() {
    return _getTextStyle().copyWith(
      color: AppColors.placeholder,
    );
  }

  double _getIconSize() {
    switch (widget.size) {
      case AppInputFieldSize.small:
        return AppDimensions.iconS;
      case AppInputFieldSize.medium:
        return AppDimensions.iconM;
      case AppInputFieldSize.large:
        return AppDimensions.iconL;
    }
  }

  Color _getFillColor() {
    if (!widget.isEnabled) {
      return AppColors.grey100;
    }
    if (widget.errorText != null) {
      return AppColors.error50;
    }
    return AppColors.grey50;
  }

  InputBorder _getBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      borderSide: const BorderSide(
        color: AppColors.grey300,
        width: AppDimensions.borderThin,
      ),
    );
  }

  InputBorder _getFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      borderSide: const BorderSide(
        color: AppColors.primary600,
        width: AppDimensions.borderMedium,
      ),
    );
  }

  InputBorder _getErrorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      borderSide: const BorderSide(
        color: AppColors.error600,
        width: AppDimensions.borderThin,
      ),
    );
  }

  InputBorder _getDisabledBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      borderSide: const BorderSide(
        color: AppColors.grey200,
        width: AppDimensions.borderThin,
      ),
    );
  }
}

// Convenience constructors for common input types
class AppEmailField extends AppInputField {
  const AppEmailField({
    super.key,
    super.label = 'Email',
    super.hintText = 'Enter your email',
    super.controller,
    super.isRequired = false,
    super.onChanged,
    super.validator,
  }) : super(
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        );
}

class AppPasswordField extends AppInputField {
  const AppPasswordField({
    super.key,
    super.label = 'Password',
    super.hintText = 'Enter your password',
    super.controller,
    super.isRequired = false,
    super.onChanged,
    super.validator,
  }) : super(
          isPassword: true,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
        );
}

class AppSearchField extends AppInputField {
  const AppSearchField({
    super.key,
    super.hintText = 'Search...',
    super.controller,
    super.onChanged,
    super.onSubmitted,
    Widget? prefixIcon,
  }) : super(
          prefixIcon: prefixIcon ?? const Icon(Icons.search, color: AppColors.grey500),
          textInputAction: TextInputAction.search,
        );
} 