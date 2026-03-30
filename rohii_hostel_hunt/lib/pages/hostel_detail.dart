// ─────────────────────────────────────────────────────────
// Hostel Hunt — Premium Hostel Detail Page
// ─────────────────────────────────────────────────────────
//
// Layout inspired by premium e-commerce UIs:
// • Full-width image carousel with dot indicators
// • Bold name + price row
// • Rating badge
// • Action pills (Photos, Videos, Contact Owner)
// • Facilities list with staggered fade-in
// • Sticky bottom bar (Book Now + Save)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rohii_hostel_hunt/models/hostel.dart';
import 'package:rohii_hostel_hunt/services/colors.dart';
import 'package:rohii_hostel_hunt/services/notifiers.dart';

class HostelDetailPage extends StatefulWidget {
  final Hostel hostel;

  const HostelDetailPage({super.key, required this.hostel});

  @override
  State<HostelDetailPage> createState() => _HostelDetailPageState();
}

class _HostelDetailPageState extends State<HostelDetailPage>
    with TickerProviderStateMixin {
  // ── Carousel ──
  late final PageController _pageController;
  int _currentPage = 0;

  // ── Animations ──
  late final AnimationController _entryController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  // ── State ──
  bool _isSaved = false;
  bool _bookBounce = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    _entryController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ── Helpers ──

  String _formatReviewCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return k == k.roundToDouble()
          ? '${k.round()}K'
          : '${k.toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _showPlaceholder(String feature) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.construction_rounded,
                color: AppColors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$feature coming soon!',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: AppColors.background(isDark),
          body: Stack(
            children: [
              // ── Scrollable content ──
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(isDark),
                            _buildImageCarousel(isDark),
                            _buildRatingRow(isDark),
                            _buildNamePriceRow(isDark),
                            _buildActionButtons(isDark),
                            _buildFacilitiesSection(isDark),
                            _buildContactSection(isDark),
                            // Space for sticky bottom bar
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Sticky bottom bar ──
              _buildBottomBar(isDark),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TOP BAR — Back + Brand + Share
  // ══════════════════════════════════════════════════════════

  Widget _buildTopBar(bool isDark) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            // Back button
            _PremiumIconButton(
              icon: Icons.arrow_back_rounded,
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),

            const Spacer(),

            // Brand
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.apartment_rounded,
                  size: 20,
                  color: AppColors.orange,
                ),
                const SizedBox(height: 2),
                Text(
                  "HOSTEL HUNT",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Share button
            _PremiumIconButton(
              icon: Icons.share_rounded,
              isDark: isDark,
              onTap: () => _showPlaceholder('Share'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  IMAGE CAROUSEL
  // ══════════════════════════════════════════════════════════

  Widget _buildImageCarousel(bool isDark) {
    final images = widget.hostel.galleryImages;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          // Carousel container
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark ? AppColors.cardDark : AppColors.chip,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.shadow.withValues(alpha: 0.4)
                      : AppColors.shadow.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  return Image.asset(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark ? AppColors.cardDark : AppColors.chip,
                      child: Center(
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 64,
                          color: AppColors.orange.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? AppColors.orange
                      : (isDark
                          ? AppColors.white.withValues(alpha: 0.2)
                          : AppColors.border),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  RATING ROW
  // ══════════════════════════════════════════════════════════

  Widget _buildRatingRow(bool isDark) {
    final hostel = widget.hostel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          // Location tag
          Text(
            hostel.location.split(',').first.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(width: 8),
          // Tags
          ...hostel.tags.take(2).map((tag) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              )),
          const Spacer(),
          // Star
          const Icon(Icons.star_rounded, color: AppColors.orange, size: 18),
          const SizedBox(width: 3),
          Text(
            '${hostel.rating}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${_formatReviewCount(hostel.reviewCount)} reviews)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  NAME + PRICE ROW
  // ══════════════════════════════════════════════════════════

  Widget _buildNamePriceRow(bool isDark) {
    final hostel = widget.hostel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Expanded(
            child: Text(
              hostel.name,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.15,
                color: AppColors.textPrimary(isDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.orange.withValues(alpha: isDark ? 0.2 : 0.12),
                  AppColors.orangeDark.withValues(alpha: isDark ? 0.12 : 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              hostel.price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  ACTION BUTTONS — Photos / Videos / Contact Owner
  // ══════════════════════════════════════════════════════════

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionPill(
              icon: Icons.photo_library_rounded,
              label: 'Photos',
              isDark: isDark,
              onTap: () => _showPlaceholder('Photo gallery'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionPill(
              icon: Icons.videocam_rounded,
              label: 'Videos',
              isDark: isDark,
              onTap: () => _showPlaceholder('Video tour'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionPill(
              icon: Icons.call_rounded,
              label: 'Contact',
              isDark: isDark,
              isPrimary: true,
              onTap: () => _showPlaceholder('Contact owner'),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  FACILITIES SECTION
  // ══════════════════════════════════════════════════════════

  Widget _buildFacilitiesSection(bool isDark) {
    final facilities = widget.hostel.facilities;
    if (facilities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'FACILITIES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Facility items with staggered animation
          ...List.generate(facilities.length, (index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 80)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _FacilityItem(
                facility: facilities[index],
                isDark: isDark,
                index: index,
              ),
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  CONTACT OWNER CTA
  // ══════════════════════════════════════════════════════════

  Widget _buildContactSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: GestureDetector(
        onTap: () => _showPlaceholder('Contact owner'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.orange, AppColors.orangeDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.call_rounded, color: AppColors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Contact Owner Now',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STICKY BOTTOM BAR — Book Now + Save
  // ══════════════════════════════════════════════════════════

  Widget _buildBottomBar(bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.85)
                  : AppColors.card.withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.06)
                      : AppColors.border,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Book Now button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _bookBounce = true);
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted) setState(() => _bookBounce = false);
                      });
                      _showPlaceholder('Booking');
                    },
                    child: AnimatedScale(
                      scale: _bookBounce ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.orange, AppColors.orangeDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month_rounded,
                                color: AppColors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'BOOK NOW',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Save / Wishlist button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _isSaved = !_isSaved);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _isSaved
                          ? AppColors.orange.withValues(alpha: 0.12)
                          : (isDark ? AppColors.cardDark : AppColors.chip),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isSaved
                            ? AppColors.orange.withValues(alpha: 0.4)
                            : (isDark
                                ? AppColors.white.withValues(alpha: 0.08)
                                : AppColors.border),
                        width: 1.5,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        _isSaved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(_isSaved),
                        color: _isSaved
                            ? AppColors.orange
                            : AppColors.textSecondary(isDark),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  REUSABLE SUB-WIDGETS (private to this file)
// ══════════════════════════════════════════════════════════

/// Frosted icon button used in the top bar.
class _PremiumIconButton extends StatefulWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _PremiumIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_PremiumIconButton> createState() => _PremiumIconButtonState();
}

class _PremiumIconButtonState extends State<_PremiumIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.white.withValues(alpha: 0.08)
                : AppColors.chip,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.white.withValues(alpha: 0.06)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: AppColors.textPrimary(widget.isDark),
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Action pill button (Photos / Videos / Contact).
class _ActionPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.isDark,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  State<_ActionPill> createState() => _ActionPillState();
}

class _ActionPillState extends State<_ActionPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isFilled = widget.isPrimary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: isFilled
                ? const LinearGradient(
                    colors: [AppColors.orange, AppColors.orangeDark],
                  )
                : null,
            color: isFilled
                ? null
                : (widget.isDark
                    ? AppColors.white.withValues(alpha: 0.06)
                    : AppColors.chip),
            borderRadius: BorderRadius.circular(14),
            border: isFilled
                ? null
                : Border.all(
                    color: widget.isDark
                        ? AppColors.white.withValues(alpha: 0.1)
                        : AppColors.border,
                    width: 1,
                  ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: isFilled
                    ? AppColors.white
                    : (widget.isDark
                        ? AppColors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary(widget.isDark)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isFilled
                        ? AppColors.white
                        : AppColors.textPrimary(widget.isDark),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual facility row item.
class _FacilityItem extends StatelessWidget {
  final String facility;
  final bool isDark;
  final int index;

  const _FacilityItem({
    required this.facility,
    required this.isDark,
    required this.index,
  });

  // Map keywords to appropriate icons
  IconData get _icon {
    final lower = facility.toLowerCase();
    if (lower.contains('water')) { return Icons.water_drop_rounded; }
    if (lower.contains('food') || lower.contains('noodle') || lower.contains('rice')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('metro') || lower.contains('bus')) {
      return Icons.directions_transit_rounded;
    }
    if (lower.contains('wi-fi') || lower.contains('wifi')) {
      return Icons.wifi_rounded;
    }
    if (lower.contains('cctv') || lower.contains('security') || lower.contains('24/7')) {
      return Icons.security_rounded;
    }
    if (lower.contains('gym')) { return Icons.fitness_center_rounded; }
    if (lower.contains('laundry')) { return Icons.local_laundry_service_rounded; }
    if (lower.contains('parking')) { return Icons.local_parking_rounded; }
    if (lower.contains('furnished')) { return Icons.chair_rounded; }
    if (lower.contains('power') || lower.contains('backup')) {
      return Icons.bolt_rounded;
    }
    if (lower.contains('clean') || lower.contains('housekeep')) {
      return Icons.cleaning_services_rounded;
    }
    if (lower.contains('study') || lower.contains('campus')) {
      return Icons.school_rounded;
    }
    if (lower.contains('garden') || lower.contains('rooftop')) {
      return Icons.park_rounded;
    }
    if (lower.contains('washroom') || lower.contains('bathroom')) {
      return Icons.bathtub_rounded;
    }
    if (lower.contains('breakfast')) { return Icons.free_breakfast_rounded; }
    if (lower.contains('tv') || lower.contains('lounge')) {
      return Icons.tv_rounded;
    }
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.white.withValues(alpha: 0.05)
                : AppColors.border.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.shadow.withValues(alpha: 0.15)
                  : AppColors.shadow.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _icon,
                size: 18,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                facility,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(isDark),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
