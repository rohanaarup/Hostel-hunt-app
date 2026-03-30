import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rohii_hostel_hunt/models/hostel.dart';
import 'package:rohii_hostel_hunt/services/colors.dart';
import 'package:rohii_hostel_hunt/utils/hostel_navigation.dart';

/// Premium hostel card — immersive full-image design.
///
/// Visual features:
/// - Full-bleed image with strong bottom gradient
/// - Orange-accented CTA button
/// - Glassmorphic info panel with strong contrast
/// - Floating orange rating badge
/// - Frosted tag chips
/// - Staggered entry animation + press scale
class PremiumHostelCard extends StatefulWidget {
  final Hostel hostel;
  final bool isDark;
  final int index;

  const PremiumHostelCard({
    super.key,
    required this.hostel,
    required this.isDark,
    this.index = 0,
  });

  @override
  State<PremiumHostelCard> createState() => _PremiumHostelCardState();
}

class _PremiumHostelCardState extends State<PremiumHostelCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _cartBounce = false;

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _onCartTap() {
    HapticFeedback.mediumImpact();
    setState(() => _cartBounce = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _cartBounce = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${widget.hostel.name} added to cart!',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hostel = widget.hostel;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.lightImpact();
            navigateToHostelDetails(context, widget.hostel);
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Container(
              height: 280,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDark
                        ? AppColors.shadow.withValues(alpha: 0.35)
                        : AppColors.shadow.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                    spreadRadius: -4,
                  ),
                  // Subtle orange glow for premium look
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Full-bleed image ──
                    _buildImage(hostel),

                    // ── STRONG gradient overlay for readability ──
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.35, 0.65, 1.0],
                          colors: [
                            Color(0x00000000),        // transparent top
                            Color(0x10000000),        // very slight mid
                            Color(0x70000000),        // readable lower
                            Color(0xCC000000),        // strong bottom (80%)
                          ],
                        ),
                      ),
                    ),

                    // ── Floating rating badge — top right ──
                    _buildRatingBadge(hostel),

                    // ── Tag chips — top left ──
                    _buildTagChips(hostel),

                    // ── Bottom info panel ──
                    _buildInfoPanel(hostel),

                    // ── Orange CTA button — bottom right ──
                    _buildCartButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Hostel hostel) {
    return Image.asset(
      hostel.image,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.orange.withValues(alpha: 0.25),
              AppColors.orangeDark.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apartment_rounded,
                  size: 48, color: AppColors.orange.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(hostel.name,
                  style: TextStyle(
                    color: AppColors.orange.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(Hostel hostel) {
    return Positioned(
      top: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.orange, AppColors.orangeDark],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.white, size: 14),
            const SizedBox(width: 3),
            Text(
              hostel.rating.toString(),
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChips(Hostel hostel) {
    return Positioned(
      top: 14,
      left: 14,
      child: Row(
        children: hostel.tags
            .map((tag) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x50000000),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.18),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  /// Glassmorphic bottom info panel
  Widget _buildInfoPanel(Hostel hostel) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 65, 16),
            decoration: BoxDecoration(
              color: const Color(0x40000000),
              border: Border(
                top: BorderSide(
                  color: AppColors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hostel name — bold, clear
                Text(
                  hostel.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 12,
                        color: AppColors.orangeLight),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        hostel.location,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Price — highlighted with orange accent
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hostel.price,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orangeLight,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Orange CTA button (not white!)
  /// Arrow CTA button — isolated from card's onTap via its own
  /// GestureDetector. The `behavior: HitTestBehavior.opaque` prevents
  /// the tap from propagating to the parent card's GestureDetector.
  Widget _buildCartButton() {
    return Positioned(
      bottom: 14,
      right: 14,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Stop propagation — this tap only fires the arrow action,
          // not the full-card navigation.
          _onCartTap();
        },
        child: AnimatedScale(
          scale: _cartBounce ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.elasticOut,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.orange, AppColors.orangeDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
