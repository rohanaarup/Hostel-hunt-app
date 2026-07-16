import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// Splash Screen — auto-navigates to /landing after 1.8 s.
/// Background: city_sunset.jpg (dramatic orange skyline) with radial
/// gradient overlay. Logo pulses gently while waiting.
class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Make status bar transparent so image bleeds through
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Gentle pulse on logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Fade-in on mount
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Auto-navigate after 1.8 s
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/landing');
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink900 : const Color(0xFF1A0A00),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Full-bleed background photo ──
          Image.asset(
            'images/backgrounds/city_sunset.jpg',
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
            color: isDark
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.28),
            colorBlendMode: BlendMode.darken,
          ),

          // ── Layer 2: Radial vignette overlay ──
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: isDark ? 0.75 : 0.60),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),

          // ── Layer 3: Bottom fade-up for legibility ──
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.35,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: isDark ? 0.85 : 0.70),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 4: Content ──
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Animated logo
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + _pulseController.value * 0.04;
                      final glowOpacity = 0.25 + _pulseController.value * 0.30;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.auburn300
                                    .withValues(alpha: glowOpacity),
                                blurRadius: 48,
                                spreadRadius: 12,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      isDark
                          ? 'images/logos/logo_icon_dark_bg.png'
                          : 'images/logos/logo_stacked_white_bg.png',
                      width: size.width * 0.42,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Tagline
                  Text(
                    'FIND YOUR SPACE. FEEL AT HOME.',
                    style: TextStyle(
                      color: AppColors.ivory50.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Subtle loading indicator
                  SizedBox(
                    width: 32,
                    height: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        backgroundColor:
                            AppColors.ivory50.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.auburn300.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
