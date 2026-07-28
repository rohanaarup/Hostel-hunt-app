import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

class AuthGradientButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isDark;
  final IconData? suffixIcon; // Defaults to send/paper-plane if not provided

  const AuthGradientButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.isDark,
    this.suffixIcon,
  });

  @override
  State<AuthGradientButton> createState() => _AuthGradientButtonState();
}

class _AuthGradientButtonState extends State<AuthGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0,
      upperBound: 1,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _pressController.forward(),
        onTapUp: isDisabled
            ? null
            : (_) {
                _pressController.reverse();
                widget.onPressed?.call();
              },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : const LinearGradient(
                    colors: [AppColors.auburn500, AppColors.auburn700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isDisabled
                ? (widget.isDark ? AppColors.ivory900 : AppColors.ivory300)
                : null,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: (widget.isDark ? AppColors.auburn900 : AppColors.auburn700)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // Empty space on left to balance the icon on the right, keeping text centered
                const SizedBox(width: 44), 
                Expanded(
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
                // Circular white icon badge on the right end
                if (!widget.isLoading)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.suffixIcon ?? Icons.send_rounded,
                      color: AppColors.auburn500,
                      size: 20,
                    ),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
