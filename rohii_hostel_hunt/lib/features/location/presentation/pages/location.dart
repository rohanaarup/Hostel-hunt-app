import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/theme/colors.dart';
import 'package:rohii_hostel_hunt/features/location/domain/models/location_model.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/providers/location_riverpod_provider.dart';
import 'package:rohii_hostel_hunt/core/theme/theme_provider.dart';

// ═══════════════════════════════════════════════════════════════
// LocationScreen — Premium location selection (Zomato-inspired)
// ═══════════════════════════════════════════════════════════════
//
// Sections:
//  1. AppBar — back arrow + "Select a location"
//  2. Search bar — focus glow, debounce-ready
//  3. Use current location — GPS with shimmer
//  4. Add Address — placeholder for future
//  5. Import saved addresses — placeholder
//  6. Saved addresses — animated card list
//
// State: reads from LocationProvider (registered in main.dart)
// Navigation: homepage taps location → pushNamed('/location')
// ═══════════════════════════════════════════════════════════════

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen>
    with TickerProviderStateMixin {
  // ── Search ──
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;

  // ── Stagger animation for sections ──
  late final AnimationController _staggerController;
  static const int _sectionCount = 5;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChanged);

    // Stagger: 800ms total, each section offset by 15%
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnims = List.generate(_sectionCount, (i) {
      final start = i * 0.15;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(_sectionCount, (i) {
      final start = i * 0.15;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _staggerController.forward();

    // Auto-detect location when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(locationProvider.notifier).detectCurrentLocation();
      }
    });
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  /// Wraps a section in fade + slide animation
  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(position: _slideAnims[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final locState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      // ── APP BAR ──
      appBar: AppBar(
        backgroundColor: AppColors.background(isDark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select a location',
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      // ── BODY — fully scrollable ──
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1 ── Search bar
              _animated(0, _SearchBar(
                isDark: isDark,
                focusNode: _searchFocusNode,
                controller: _searchController,
                isFocused: _isSearchFocused,
              )),
              const SizedBox(height: 20),

              // 2 ── Current location
              _animated(1, _CurrentLocationCard(
                isDark: isDark,
                locState: locState,
                onTap: () => _handleCurrentLocation(locState),
              )),
              const SizedBox(height: 8),

              // 3 ── Add address
              _animated(2, _ActionRow(
                isDark: isDark,
                icon: Icons.add_rounded,
                label: 'Add Address',
                onTap: () => _showComingSoon('Add Address'),
              )),
              const SizedBox(height: 8),

              // 4 ── Import saved addresses
              _animated(3, _ActionRow(
                isDark: isDark,
                icon: Icons.download_rounded,
                label: 'Import saved addresses',
                onTap: () => _showComingSoon('Import'),
              )),
              const SizedBox(height: 28),

              // 5 ── Saved addresses
              _animated(4, _SavedAddressesSection(
                isDark: isDark,
                addresses: locState.savedAddresses,
                onSelect: (addr) {
                  ref.read(locationProvider.notifier).selectAddress(addr);
                  Navigator.pop(context);
                },
                onDelete: (id) => ref.read(locationProvider.notifier).deleteAddress(id),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Handlers ──

  void _handleCurrentLocation(LocationState locState) {
    HapticFeedback.lightImpact();
    if (locState.isDetectingLocation) return;

    if (locState.currentLocationText.isNotEmpty &&
        locState.locationError == null) {
      // Use the detected location
      ref.read(locationProvider.notifier).setCity(
        locState.currentLocationText.split(',').last.trim(),
      );
      Navigator.pop(context);
    } else {
      // Retry
      ref.read(locationProvider.notifier).detectCurrentLocation();
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Sub-widgets — private, modular, reusable within this file
// ═══════════════════════════════════════════════════════════════

// ─────────────────── SEARCH BAR ───────────────────

class _SearchBar extends StatelessWidget {
  final bool isDark;
  final FocusNode focusNode;
  final TextEditingController controller;
  final bool isFocused;

  const _SearchBar({
    required this.isDark,
    required this.focusNode,
    required this.controller,
    required this.isFocused,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.chipBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused
              ? AppColors.orange.withValues(alpha: 0.7)
              : AppColors.border.withValues(alpha: isDark ? 0.15 : 0.8),
          width: isFocused ? 1.5 : 1.0,
        ),
        boxShadow: isFocused
            ? [BoxShadow(
                color: AppColors.orangeGlow,
                blurRadius: 12,
                offset: const Offset(0, 2),
              )]
            : [],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isFocused ? AppColors.orange : AppColors.textTertiary(isDark),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search for area, street name…',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary(isDark),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── CURRENT LOCATION CARD ───────────────────

class _CurrentLocationCard extends StatelessWidget {
  final bool isDark;
  final LocationState locState;
  final VoidCallback onTap;

  const _CurrentLocationCard({
    required this.isDark,
    required this.locState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg(isDark),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.06)
                  : AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              // GPS icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Text content
              Expanded(child: _buildContent()),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary(isDark),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Use current location',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),

        // State: loading
        if (locState.isDetectingLocation)
          _ShimmerBar(isDark: isDark)

        // State: error
        else if (locState.locationError != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  locState.locationError!,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.refresh_rounded, color: AppColors.orange, size: 16),
            ],
          )

        // State: resolved
        else if (locState.currentLocationText.isNotEmpty)
          Text(
            locState.currentLocationText,
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 12.5,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )

        // State: idle
        else
          Text(
            'Tap to detect your location',
            style: TextStyle(
              color: AppColors.textTertiary(isDark),
              fontSize: 12.5,
            ),
          ),
      ],
    );
  }
}

// ─────────────────── ACTION ROW ───────────────────

class _ActionRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg(isDark),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.06)
                  : AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.orange, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary(isDark),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── SAVED ADDRESSES SECTION ───────────────────

class _SavedAddressesSection extends StatelessWidget {
  final bool isDark;
  final List<SavedAddress> addresses;
  final void Function(SavedAddress) onSelect;
  final void Function(String id) onDelete;

  const _SavedAddressesSection({
    required this.isDark,
    required this.addresses,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          'SAVED ADDRESSES',
          style: TextStyle(
            color: AppColors.textTertiary(isDark),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 14),

        // Empty state
        if (addresses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.location_off_rounded,
                      color: AppColors.textTertiary(isDark), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No saved addresses yet',
                    style: TextStyle(
                      color: AppColors.textTertiary(isDark),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )

        // Address cards — staggered with TweenAnimationBuilder
        else
          ...List.generate(addresses.length, (i) {
            final addr = addresses[i];
            return TweenAnimationBuilder<double>(
              key: ValueKey(addr.id),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (i * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return Opacity(
                  opacity: val,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - val)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AddressCard(
                  address: addr,
                  isDark: isDark,
                  onTap: () => onSelect(addr),
                  onDelete: () => onDelete(addr.id),
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ─────────────────── ADDRESS CARD ───────────────────

class _AddressCard extends StatelessWidget {
  final SavedAddress address;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg(isDark),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.06)
                  : AppColors.border.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: isDark ? 0.12 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + distance
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.orange
                          .withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForTitle(address.title),
                      color: AppColors.orange,
                      size: 22,
                    ),
                  ),
                  if (address.distanceKm != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${address.distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: AppColors.textTertiary(isDark),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.title,
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.fullAddress,
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (address.phone != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Phone number: ${address.phone}',
                        style: TextStyle(
                          color: AppColors.textTertiary(isDark),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Actions row
                    Row(
                      children: [
                        _CircleButton(
                          icon: Icons.more_horiz_rounded,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        _CircleButton(
                          icon: Icons.share_rounded,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        const Spacer(),
                        _CircleButton(
                          icon: Icons.delete_outline_rounded,
                          isDark: isDark,
                          color: AppColors.error,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'work':
        return Icons.work_outline_rounded;
      case 'other':
        return Icons.location_on_outlined;
      default:
        return Icons.home_outlined;
    }
  }
}

// ─────────────────── CIRCLE BUTTON ───────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final Color? color;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textTertiary(isDark);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 16, color: c),
      ),
    );
  }
}

// ─────────────────── SHIMMER BAR ───────────────────
/// Lightweight shimmer placeholder for loading states.

class _ShimmerBar extends StatefulWidget {
  final bool isDark;
  const _ShimmerBar({required this.isDark});

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(200),
            const SizedBox(height: 6),
            _bar(140),
          ],
        );
      },
    );
  }

  Widget _bar(double width) {
    final base = widget.isDark ? AppColors.chipDark : AppColors.chip;
    final highlight = widget.isDark
        ? AppColors.white.withValues(alpha: 0.08)
        : AppColors.white.withValues(alpha: 0.6);

    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          colors: [base, highlight, base],
          stops: [
            (_ctrl.value - 0.3).clamp(0.0, 1.0),
            _ctrl.value,
            (_ctrl.value + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}
