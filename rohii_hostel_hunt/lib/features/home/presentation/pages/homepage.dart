import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/pages/search.dart';
import 'package:rohii_hostel_hunt/core/theme/colors.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/providers/location_riverpod_provider.dart';
import 'package:rohii_hostel_hunt/core/theme/theme_provider.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/widgets/premium_filter_chips.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/widgets/premium_hostel_card.dart';
import 'package:rohii_hostel_hunt/shared/widgets/premium_bottom_nav.dart';

class Homepage extends ConsumerStatefulWidget {
  const Homepage({super.key});

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage> {
  int _selectedIndex = 0;
  final List<String> filters = [
    "All",
    "AC",
    "Non-AC",
    "Boys",
    "Girls",
    "Premium",
  ];
  String selectedFilter = "All";

  void _onItemTapped(int index) {
    // index 0 = Home (stays on this page — no push needed)
    if (index == 0) {
      setState(() => _selectedIndex = 0);
      return;
    }

    // For tabs that push a new screen, briefly highlight the tapped tab
    // then reset to Home (0) so the indicator returns correctly on pop.
    setState(() => _selectedIndex = index);

    if (index == 1) {
      context.push('/search')
          .then((_) => setState(() => _selectedIndex = 0));
    }
    if (index == 2) {
      // Reuse the existing SavedHostelsPage from the Profile module.
      context.push('/profile/saved')
          .then((_) => setState(() => _selectedIndex = 0));
    }
    if (index == 3) {
      context.push('/profile')
          .then((_) => setState(() => _selectedIndex = 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      extendBody: true,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 4),
            PremiumFilterChips(
              filters: filters,
              selectedFilter: selectedFilter,
              onFilterSelected: (filter) {
                setState(() {
                  selectedFilter = filter;
                });
              },
              isDark: isDark,
            ),
            _buildHostelList(isDark),
          ],
        ),
      ),
      bottomNavigationBar: PremiumBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        isDark: isDark,
      ),
    );
  }

  /// ── PREMIUM HEADER ──────────────────────────────────────────
  /// Bold orange gradient, modern layout, integrated search bar
  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1030), const Color(0xFF0F0F1A)]
              : [AppColors.orange, AppColors.orangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.shadow.withValues(alpha: 0.4)
                : AppColors.orange.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top row: location + actions ──
            Row(
              children: [
                // Location — tappable, navigates to location screen
                GestureDetector(
                  onTap: () => context.push('/location'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "YOUR LOCATION",
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Consumer(
                                builder: (context, ref, _) {
                                  final locState = ref.watch(locationProvider);
                                  return Text(
                                    locState.selectedCity,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Theme toggle
                GestureDetector(
                  onTap: () => ref.read(themeProvider.notifier).toggle(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Profile avatar
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.white.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Brand title ──
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'images/loading.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => const Icon(
                        Icons.home_work_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AARUPA MATRIX",
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.65),
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      "Hostel Hunt",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Search bar — tappable, opens search page ──
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, anim1, anim2) => const SearchPage(),
                    transitionDuration: const Duration(milliseconds: 300),
                    reverseTransitionDuration: const Duration(
                      milliseconds: 250,
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnim, child) {
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: child,
                          );
                        },
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(
                    alpha: isDark ? 0.08 : 0.18,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: AppColors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Search hostels, areas...",
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.55),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: AppColors.white.withValues(alpha: 0.8),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ── HOSTEL LIST ──────────────────────────────────────────
  /// Now uses Riverpod AsyncValue instead of GetX Obx.
  Widget _buildHostelList(bool isDark) {
    final hostelListAsync = ref.watch(hostelListProvider);

    return Expanded(
      child: hostelListAsync.when(
        // ── Loading state ──
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.orange.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading hostels...',
                style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // ── Error state ──
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 36,
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load hostels',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => ref.read(hostelListProvider.notifier).refresh(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.orange, AppColors.orangeDark],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: AppColors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Retry',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Data state ──
        data: (hostels) {
          // ── Empty state ──
          if (hostels.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.orange.withValues(alpha: 0.12),
                            AppColors.orangeLight.withValues(alpha: 0.06),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 44,
                        color: AppColors.orange.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No hostels available',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new listings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Success state — render live hostel list ──
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
            physics: const BouncingScrollPhysics(),
            itemCount: hostels.length,
            itemBuilder: (context, index) {
              return PremiumHostelCard(
                hostel: hostels[index],
                isDark: isDark,
                index: index,
              );
            },
          );
        },
      ),
    );
  }
}
