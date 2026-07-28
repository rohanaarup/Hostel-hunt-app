import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/auth_logo_lockup.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/auth_hero_row.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/auth_gradient_button.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/decorative_auth_footer.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bgColor = isDark ? const Color(0xFF151212) : AppColors.ivory50;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Footer Decoration
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DecorativeAuthFooter(isDark: isDark),
          ),

          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Logo Lockup at Top
                    AuthLogoLockup(isDark: isDark),

                    const SizedBox(height: 32),

                    // Split Hero Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: AuthHeroRow(
                        headline: 'Discover\nYour Perfect\n',
                        accentWord: 'Stay',
                        subtext:
                            'Comfortable stays for\nstudents & professionals',
                        imagePath: 'images/backgrounds/city_sunset.jpg',
                        isDark: isDark,
                      ),
                    ),

                    const Spacer(),

                    // Form Sheet Area
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.ink900.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink900.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthGradientButton(
                            label: 'Get Started',
                            isLoading: false,
                            onPressed: () => context.push('/signup'),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => context.push('/login'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: AppColors.auburn500.withValues(
                                  alpha: 0.7,
                                ),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.auburn500,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
