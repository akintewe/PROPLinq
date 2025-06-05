import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_dimensions.dart';

enum AppButtonType {
  primary,
  secondary,
  tertiary,
  ghost,
  danger,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final bool fullWidth;
  final bool isDisabled;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _getButtonHeight(),
      child: ElevatedButton(
        onPressed: (isDisabled || isLoading) ? null : onPressed,
        style: _getButtonStyle(),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: AppDimensions.spacing8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _getBackgroundColor(),
      foregroundColor: _getTextColor(),
      elevation: _getElevation(),
      shadowColor: _getShadowColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        side: _getBorderSide(),
      ),
      padding: _getPadding(),
      textStyle: _getTextStyle(),
    );
  }

  double _getButtonHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppDimensions.buttonHeightS;
      case AppButtonSize.medium:
        return AppDimensions.buttonHeightM;
      case AppButtonSize.large:
        return AppDimensions.buttonHeightL;
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case AppButtonSize.small:
        return AppDimensions.radiusS;
      case AppButtonSize.medium:
        return AppDimensions.radiusM;
      case AppButtonSize.large:
        return AppDimensions.radiusL;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingM,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingXL,
          vertical: AppDimensions.paddingL,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.labelMedium;
      case AppButtonSize.medium:
        return AppTypography.labelLarge;
      case AppButtonSize.large:
        return AppTypography.labelLarge.copyWith(fontSize: 16);
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppDimensions.iconS;
      case AppButtonSize.medium:
        return AppDimensions.iconM;
      case AppButtonSize.large:
        return AppDimensions.iconL;
    }
  }

  Color _getBackgroundColor() {
    if (isDisabled) return AppColors.disabled;

    switch (type) {
      case AppButtonType.primary:
        return AppColors.primary600;
      case AppButtonType.secondary:
        return AppColors.secondary600;
      case AppButtonType.tertiary:
        return AppColors.tertiary600;
      case AppButtonType.ghost:
        return Colors.transparent;
      case AppButtonType.danger:
        return AppColors.error600;
    }
  }

  Color _getTextColor() {
    if (isDisabled) return AppColors.grey600;

    switch (type) {
      case AppButtonType.primary:
        return AppColors.onPrimary;
      case AppButtonType.secondary:
        return AppColors.onSecondary;
      case AppButtonType.tertiary:
        return AppColors.onTertiary;
      case AppButtonType.ghost:
        return AppColors.primary600;
      case AppButtonType.danger:
        return AppColors.onError;
    }
  }

  BorderSide _getBorderSide() {
    switch (type) {
      case AppButtonType.ghost:
        return const BorderSide(
          color: AppColors.primary600,
          width: AppDimensions.borderThin,
        );
      default:
        return BorderSide.none;
    }
  }

  double _getElevation() {
    switch (type) {
      case AppButtonType.primary:
      case AppButtonType.secondary:
      case AppButtonType.tertiary:
      case AppButtonType.danger:
        return AppDimensions.elevationLow;
      case AppButtonType.ghost:
        return AppDimensions.elevationNone;
    }
  }

  Color? _getShadowColor() {
    switch (type) {
      case AppButtonType.primary:
        return AppColors.primary600.withOpacity(0.3);
      case AppButtonType.secondary:
        return AppColors.secondary600.withOpacity(0.3);
      case AppButtonType.tertiary:
        return AppColors.tertiary600.withOpacity(0.3);
      case AppButtonType.danger:
        return AppColors.error600.withOpacity(0.3);
      case AppButtonType.ghost:
        return null;
    }
  }
}

// Convenience constructors for common button types
class AppPrimaryButton extends AppButton {
  const AppPrimaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.icon,
    super.fullWidth = false,
    super.isDisabled = false,
  }) : super(type: AppButtonType.primary);
}

class AppSecondaryButton extends AppButton {
  const AppSecondaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.icon,
    super.fullWidth = false,
    super.isDisabled = false,
  }) : super(type: AppButtonType.secondary);
}

class AppGhostButton extends AppButton {
  const AppGhostButton({
    super.key,
    required super.text,
    super.onPressed,
    super.size = AppButtonSize.medium,
    super.isLoading = false,
    super.icon,
    super.fullWidth = false,
    super.isDisabled = false,
  }) : super(type: AppButtonType.ghost);
} 