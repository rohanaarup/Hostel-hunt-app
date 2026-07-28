import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool isDark;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLength;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    required this.isDark,
    this.suffixIcon,
    this.enabled = true,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.ivory700 : AppColors.ivory300;
    final textColor = isDark ? AppColors.ivory50 : AppColors.ink900;
    final primaryColor = AppColors.auburn500;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100), // pill shape
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.12),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        maxLength: maxLength,
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.ivory500 : AppColors.ink700,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.auburn500,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                prefixIcon,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.transparent,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderColor, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(
              color: borderColor.withValues(alpha: 0.5), 
              width: 1.2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}
