// ─────────────────────────────────────────────────────────
// Hostel Hunt — Premium Hostel Detail Page (FIXED)
// ─────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/pages/bed_selection_screen.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/theme/theme_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';

class HostelDetailPage extends ConsumerStatefulWidget {
  final Hostel hostel;

  const HostelDetailPage({super.key, required this.hostel});

  @override
  ConsumerState<HostelDetailPage> createState() => _HostelDetailPageState();
}

class _HostelDetailPageState extends ConsumerState<HostelDetailPage>
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

  // ── Detail API state ──
  late Hostel _hostel;
  // ignore: unused_field
  bool _isDetailLoading = false;
  // ignore: unused_field
  bool _hasDetailError = false;
  // ignore: unused_field
  String _detailErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _hostel = widget.hostel;
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

    // Fetch full detail from API if this is an API-sourced hostel
    if (!_hostel.isLocal && _hostel.id.isNotEmpty) {
      _fetchDetail();
    }
  }

  /// Fetch full hostel detail from GET /api/hostels/{id}/
  Future<void> _fetchDetail() async {
    setState(() {
      _isDetailLoading = true;
      _hasDetailError = false;
    });

    try {
      final response = await ApiService().getRaw('/hostels/${_hostel.id}/');

      if (!mounted) return;

      if (!response.success) {
        setState(() {
          _hasDetailError = true;
          _detailErrorMessage = response.message;
          _isDetailLoading = false;
        });
        return;
      }

      final body = response.body;
      if (body is Map<String, dynamic>) {
        setState(() {
          _hostel = _hostel.mergeWithDetail(Hostel.fromJson(body));
          _isDetailLoading = false;
        });
      } else {
        setState(() {
          _hasDetailError = true;
          _detailErrorMessage = 'Unexpected response format.';
          _isDetailLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasDetailError = true;
        _detailErrorMessage = 'Failed to load details.';
        _isDetailLoading = false;
      });
    }
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
                color: AppColors.ivory50, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$feature coming soon!',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ivory50,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.auburn500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMediaSheet(bool isPhoto) {
    final isDark = ref.read(themeProvider);
    final surfaceColor = isDark ? AppColors.ivory900 : AppColors.ivory100;
    final textColor = AppColors.textHeading(isDark);
    final mutedColor = AppColors.textSecondary(isDark);

    final title = isPhoto ? 'Photo Gallery' : 'Video Tour';
    final images = _hostel.galleryImages;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: mutedColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: mutedColor.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Expanded(
              child: images.isEmpty
                  ? Center(
                      child: Text(
                        isPhoto 
                          ? "No photos available." 
                          : "No videos available.",
                        style: TextStyle(color: mutedColor),
                      ),
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: isPhoto ? images.length : 1,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isDark ? AppColors.ivory900 : AppColors.ivory300,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildImageWidget(
                                  images[isPhoto ? index : 0],
                                  fit: BoxFit.cover,
                                ),
                                if (!isPhoto)
                                  Container(
                                    color: Colors.black45,
                                    child: const Center(
                                      child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSheet() {
    final isDark = ref.read(themeProvider);
    final surfaceColor = isDark ? AppColors.ivory900 : AppColors.ivory100;
    final textColor = AppColors.textHeading(isDark);
    final mutedColor = AppColors.textSecondary(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: mutedColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Contact Owner",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: mutedColor.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.phone_rounded, color: AppColors.auburn500),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _hostel.contactPhone.isNotEmpty ? _hostel.contactPhone : 'Not available',
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  color: mutedColor,
                  onPressed: _hostel.contactPhone.isNotEmpty ? () {
                    Clipboard.setData(ClipboardData(text: _hostel.contactPhone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Phone number copied!")),
                    );
                  } : null,
                ),
                IconButton(
                  icon: const Icon(Icons.call_rounded, size: 20),
                  color: AppColors.auburn500,
                  onPressed: _hostel.contactPhone.isNotEmpty
                      ? () => launchUrl(Uri.parse('tel:${_hostel.contactPhone.replaceAll(' ', '')}'))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.email_rounded, color: AppColors.auburn500),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _hostel.contactEmail.isNotEmpty ? _hostel.contactEmail : 'Not available',
                    style: TextStyle(fontSize: 14, color: textColor),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  color: mutedColor,
                  onPressed: _hostel.contactEmail.isNotEmpty ? () {
                    Clipboard.setData(ClipboardData(text: _hostel.contactEmail));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Email copied!")),
                    );
                  } : null,
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  color: AppColors.auburn500,
                  onPressed: _hostel.contactEmail.isNotEmpty
                      ? () => launchUrl(Uri.parse('mailto:${_hostel.contactEmail}'))
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Book Now handler ──
  void _onBookNow() {
    HapticFeedback.mediumImpact();

    setState(() => _bookBounce = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _bookBounce = false);
    });

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => BedSelectionScreen(hostel: _hostel),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.appBackground(isDark),
      body: Stack(
        children: [
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
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildBottomBar(isDark),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TOP BAR
  // ══════════════════════════════════════════════════════════

  Widget _buildTopBar(bool isDark) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            _PremiumIconButton(
              icon: Icons.arrow_back_rounded,
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.apartment_rounded, size: 20, color: AppColors.auburn500),
                const SizedBox(height: 2),
                Text(
                  "HOSTEL HUNT",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: AppColors.textHeading(isDark),
                  ),
                ),
              ],
            ),
            const Spacer(),
            _PremiumIconButton(
              icon: Icons.share_rounded,
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                Share.share(
                  'Check out ${_hostel.name} on Hostel Hunt!\n'
                  'Located at ${_hostel.location}\n'
                  'Starting from ${_hostel.price}\n\n'
                  'Find your perfect PG on Hostel Hunt 🏠',
                  subject: 'Check out ${_hostel.name} on Hostel Hunt',
                );
              },
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
    final images = _hostel.galleryImages;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark ? AppColors.ivory900 : AppColors.ivory300,
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
                  return _buildImageWidget(
                    images[index],
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.apartment_rounded,
                    fallbackSize: 64,
                    fallbackBgColor: isDark ? AppColors.ivory900 : AppColors.ivory300,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
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
                      ? AppColors.auburn500
                      : (isDark
                          ? AppColors.ivory50.withValues(alpha: 0.2)
                          : AppColors.ivory300),
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
    final hostel = _hostel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
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
          ...hostel.tags.take(2).map((tag) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.auburn500.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.auburn500,
                  ),
                ),
              )),
          const Spacer(),
          const Icon(Icons.star_rounded, color: AppColors.auburn500, size: 18),
          const SizedBox(width: 3),
          Text(
            '${hostel.rating}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeading(isDark),
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
    final hostel = _hostel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              hostel.name,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.15,
                color: AppColors.textHeading(isDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.auburn500.withValues(alpha: isDark ? 0.2 : 0.12),
                  AppColors.auburn700.withValues(alpha: isDark ? 0.12 : 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              hostel.price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.auburn500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  ACTION BUTTONS
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
              onTap: () => _showMediaSheet(true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionPill(
              icon: Icons.videocam_rounded,
              label: 'Videos',
              isDark: isDark,
              onTap: () => _showMediaSheet(false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionPill(
              icon: Icons.call_rounded,
              label: 'Contact',
              isDark: isDark,
              isPrimary: true,
              onTap: _showContactSheet,
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
    final facilities = _hostel.facilities;
    if (facilities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.auburn500,
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
                  color: AppColors.textHeading(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
  //  CONTACT SECTION
  // ══════════════════════════════════════════════════════════

  Widget _buildContactSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: GestureDetector(
        onTap: _showContactSheet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.auburn500, AppColors.auburn700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.auburn500.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.call_rounded, color: AppColors.ivory50, size: 20),
              SizedBox(width: 10),
              Text(
                'Contact Owner Now',
                style: TextStyle(
                  color: AppColors.ivory50,
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
  //  STICKY BOTTOM BAR — FIXED (single onTap, clean navigation)
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
                  ? AppColors.ivory900.withValues(alpha: 0.85)
                  : AppColors.ivory100.withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.ivory50.withValues(alpha: 0.06)
                      : AppColors.ivory300,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // ── Book Now button (FIXED — single onTap only) ──
                Expanded(
                  child: GestureDetector(
                    onTap: _onBookNow, // ← clean single reference, no duplication
                    child: AnimatedScale(
                      scale: _bookBounce ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.auburn500, AppColors.auburn700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.auburn500.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month_rounded,
                                color: AppColors.ivory50, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'BOOK NOW',
                              style: TextStyle(
                                color: AppColors.ivory50,
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

                // ── Save / Wishlist button ──
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
                          ? AppColors.auburn500.withValues(alpha: 0.12)
                          : (isDark ? AppColors.ivory900 : AppColors.ivory300),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isSaved
                            ? AppColors.auburn500.withValues(alpha: 0.4)
                            : (isDark
                                ? AppColors.ivory50.withValues(alpha: 0.08)
                                : AppColors.ivory300),
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
                            ? AppColors.auburn500
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

  // ═══════════════════════ IMAGE HELPER ═══════════════════════

  /// Builds an image widget that handles both local asset paths and network URLs.
  Widget _buildImageWidget(
    String imagePath, {
    BoxFit fit = BoxFit.cover,
    IconData fallbackIcon = Icons.image_not_supported_rounded,
    double fallbackSize = 32,
    Color? fallbackBgColor,
  }) {
    final fallback = Container(
      color: fallbackBgColor,
      child: Center(
        child: Icon(
          fallbackIcon,
          size: fallbackSize,
          color: AppColors.auburn500.withValues(alpha: 0.4),
        ),
      ),
    );

    // Local asset path (starts with 'images/' or doesn't start with 'http'/'/')
    if (_hostel.isLocal || (!imagePath.startsWith('http') && !imagePath.startsWith('/'))) {
      return Image.asset(
        imagePath,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    // Network URL — prepend base URL if it's a relative path
    String url = imagePath;
    if (!imagePath.startsWith('http')) {
      // Strip '/api' from base URL to get the media root
      final baseUrl = ApiService.baseUrl;
      final mediaBase = baseUrl.replaceAll(RegExp(r'/api(?:/v1)?'), '');
      url = '$mediaBase$imagePath';
    }

    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.auburn500.withValues(alpha: 0.6),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

// ══════════════════════════════════════════════════════════
//  REUSABLE SUB-WIDGETS
// ══════════════════════════════════════════════════════════

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
                ? AppColors.ivory50.withValues(alpha: 0.08)
                : AppColors.ivory300,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.ivory50.withValues(alpha: 0.06)
                  : AppColors.ivory300,
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: AppColors.textHeading(widget.isDark),
            size: 20,
          ),
        ),
      ),
    );
  }
}

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
                    colors: [AppColors.auburn500, AppColors.auburn700],
                  )
                : null,
            color: isFilled
                ? null
                : (widget.isDark
                    ? AppColors.ivory50.withValues(alpha: 0.06)
                    : AppColors.ivory300),
            borderRadius: BorderRadius.circular(14),
            border: isFilled
                ? null
                : Border.all(
                    color: widget.isDark
                        ? AppColors.ivory50.withValues(alpha: 0.1)
                        : AppColors.ivory300,
                    width: 1,
                  ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: AppColors.auburn500.withValues(alpha: 0.3),
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
                    ? AppColors.ivory50
                    : (widget.isDark
                        ? AppColors.ivory50.withValues(alpha: 0.7)
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
                        ? AppColors.ivory50
                        : AppColors.textHeading(widget.isDark),
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

class _FacilityItem extends StatelessWidget {
  final String facility;
  final bool isDark;
  final int index;

  const _FacilityItem({
    required this.facility,
    required this.isDark,
    required this.index,
  });

  IconData get _icon {
    final lower = facility.toLowerCase();
    if (lower.contains('water')) return Icons.water_drop_rounded;
    if (lower.contains('food') || lower.contains('noodle') || lower.contains('rice')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('metro') || lower.contains('bus')) {
      return Icons.directions_transit_rounded;
    }
    if (lower.contains('wi-fi') || lower.contains('wifi')) return Icons.wifi_rounded;
    if (lower.contains('cctv') || lower.contains('security') || lower.contains('24/7')) {
      return Icons.security_rounded;
    }
    if (lower.contains('gym')) return Icons.fitness_center_rounded;
    if (lower.contains('laundry')) return Icons.local_laundry_service_rounded;
    if (lower.contains('parking')) return Icons.local_parking_rounded;
    if (lower.contains('furnished')) return Icons.chair_rounded;
    if (lower.contains('power') || lower.contains('backup')) return Icons.bolt_rounded;
    if (lower.contains('clean') || lower.contains('housekeep')) {
      return Icons.cleaning_services_rounded;
    }
    if (lower.contains('study') || lower.contains('campus')) return Icons.school_rounded;
    if (lower.contains('garden') || lower.contains('rooftop')) return Icons.park_rounded;
    if (lower.contains('washroom') || lower.contains('bathroom')) {
      return Icons.bathtub_rounded;
    }
    if (lower.contains('breakfast')) return Icons.free_breakfast_rounded;
    if (lower.contains('tv') || lower.contains('lounge')) return Icons.tv_rounded;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.ivory900 : AppColors.ivory100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.ivory50.withValues(alpha: 0.05)
                : AppColors.ivory300.withValues(alpha: 0.6),
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
                color: AppColors.auburn500.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, size: 18, color: AppColors.auburn500),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                facility,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHeading(isDark),
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

