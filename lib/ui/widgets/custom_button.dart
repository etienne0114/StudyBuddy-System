// lib/ui/widgets/custom_button.dart

import 'package:flutter/material.dart';
import 'package:study_scheduler/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? color;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final BorderRadius? borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.color,
    this.width,
    this.height,
    this.padding,
    this.textStyle,
    this.borderRadius, required String label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    final buttonTextStyle = textStyle ?? 
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        );
    final buttonBorderRadius = borderRadius ?? BorderRadius.circular(8);
    
    // Button content
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 12),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                buttonTextStyle.color ?? Colors.white,
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              icon,
              color: buttonTextStyle.color,
              size: 20,
            ),
          ),
        Text(
          text,
          style: buttonTextStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
    
    // Button with appropriate size constraints
    Widget sizedButton = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: buttonBorderRadius,
        ),
        disabledBackgroundColor: buttonColor.withOpacity(0.6),
      ),
      child: buttonContent,
    );
    
    // Apply width constraints if requested
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: sizedButton,
      );
    } else if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: sizedButton,
      );
    } else {
      return sizedButton;
    }
  }
}