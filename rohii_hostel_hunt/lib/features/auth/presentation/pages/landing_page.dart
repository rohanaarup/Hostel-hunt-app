import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// Landing / Onboarding screen.
/// Shows the city_sunset.jpg hero image in the top half,
/// bold headline, and two pill CTA buttons.
/// Navigates to /signup (Get Started) or /login (Sign In).
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final heroHeight = size.height * 0.52;

    final formBgTop = isDark ? AppColors.ink900 : AppColors.ivory50;
    final formBgBottom = isDark ? const Color(0xFF151212) : AppColors.ivory100;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [formBgTop, formBgBottom],
          ),
        ),
        child: Stack(
        children: [
          // ── Hero image section (top 52%) ──
          SizedBox(
            height: heroHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'images/backgrounds/city_sunset.jpg',
                  fit: BoxFit.cover,
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.20),
                  colorBlendMode: BlendMode.darken,
                ),
                // Gradient: transparent top → bg color bottom (for smooth merge)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.55, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.40),
                        isDark
                            ? AppColors.ink900
                            : AppColors.ivory50,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Full scroll content ──
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                // Spacer to push headline into lower part of hero
                SizedBox(height: heroHeight * 0.38),

                // ── Logo ──
                Center(
                  child: Image.asset(
                    isDark
                        ? 'images/logos/logo_icon_dark_bg.png'
                        : 'images/logos/logo_icon_white_bg.png',
                    width: size.width * 0.22,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Headline ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Find Your\nPerfect Stay',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ivory50,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 10),

                // ── Subtext ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Discover verified hostels & PGs near you.\nReal listings. Real reviews.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.ivory100.withValues(alpha: 0.90),
                      height: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Bottom card area ──
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [formBgTop, formBgBottom],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Get Started — Primary pill
                          _PillButton(
                            label: 'Get Started',
                            isDark: isDark,
                            onPressed: () => context.push('/signup'),
                            isPrimary: true,
                          ),

                          const SizedBox(height: 16),

                          // Sign In — Outlined pill
                          _PillButton(
                            label: 'Sign In',
                            isDark: isDark,
                            onPressed: () => context.push('/login'),
                            isPrimary: false,
                          ),

                          const Spacer(),

                          // Fine print
                          Text(
                            'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.ivory500
                                  : AppColors.ivory700,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),
),
);

  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill Button — shared widget (primary gradient or outlined)
// ─────────────────────────────────────────────────────────────────────────────

class _PillButton extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _PillButton({
    required this.label,
    required this.isDark,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.isDark ? AppColors.auburn300 : AppColors.auburn500;
    final primaryDark =
        widget.isDark ? AppColors.auburn500 : AppColors.auburn700;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _pressController.reverse(),
        child: widget.isPrimary
            ? Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isDark ? AppColors.ink900 : AppColors.ivory50,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              )
            : Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.70),
                    width: 1.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
      ),
    );
  }
}
