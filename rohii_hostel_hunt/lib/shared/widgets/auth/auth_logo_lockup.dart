import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

class AuthLogoLockup extends StatelessWidget {
  final bool isDark;

  const AuthLogoLockup({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Square icon badge with rounded corners & auburn gradient
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.auburn500, AppColors.auburn700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.auburn500.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Image.asset(
              'images/logos/transparent_icon.png', // The transparent logo we copied
              color: Colors.white,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Wordmark and tagline
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hostel Hunt',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.ivory50 : AppColors.ink900,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'FIND YOUR SPACE. FEEL AT HOME.',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.ivory300 : AppColors.ink700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
