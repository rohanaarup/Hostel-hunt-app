import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/pages/search.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/providers/location_riverpod_provider.dart';
import 'package:rohii_hostel_hunt/core/theme/theme_provider.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/widgets/premium_filter_chips.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/widgets/premium_hostel_card.dart';
import 'package:rohii_hostel_hunt/features/home/presentation/widgets/hostel_list_states.dart';
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
      backgroundColor: AppColors.appBackground(isDark),
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
                ref.read(hostelListProvider.notifier).applyFilter(filter);
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
    final textColor = isDark ? AppColors.ivory50 : AppColors.ink900;
    final headerBg = isDark ? AppColors.ivory900 : AppColors.ivory100;
    final headerIconBg = isDark ? AppColors.ivory50.withValues(alpha: 0.1) : AppColors.ink900.withValues(alpha: 0.06);
    final borderColor = isDark ? AppColors.ivory700 : AppColors.ivory300;
    final searchBarBg = isDark ? AppColors.ivory700 : AppColors.ivory50;
    final searchBarBorderColor = isDark ? AppColors.ivory500 : AppColors.ivory300;
    final secondaryTextColor = isDark ? AppColors.ivory300 : AppColors.ink700;
    final primaryColor = isDark ? AppColors.auburn300 : AppColors.auburn500;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1.5),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.ink900.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          children: [
            // ── Background Image ──
            Positioned.fill(
              child: Image.asset(
                'images/backgrounds/homepage_styling_bg.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            // ── Gradient Overlay ──
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            AppColors.ink900.withValues(alpha: 0.4),
                            AppColors.ink900.withValues(alpha: 0.8),
                            AppColors.ink900,
                          ]
                        : [
                            AppColors.ivory50.withValues(alpha: 0.4),
                            AppColors.ivory50.withValues(alpha: 0.8),
                            AppColors.ivory50,
                          ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),
            // ── Content ──
            Padding(
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
                          color: headerIconBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: primaryColor,
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
                              color: secondaryTextColor,
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
                                    locState.displayLabel,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: textColor,
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
                      color: headerIconBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Dashboard shortcut
                GestureDetector(
                  onTap: () => context.push('/dashboard'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 0.8),
                    ),
                    child: Icon(
                      Icons.dashboard_rounded,
                      color: primaryColor,
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
                      border: Border.all(color: primaryColor, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: headerIconBg,
                      child: Icon(
                        Icons.person_outlined,
                        color: primaryColor,
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
                    color: headerIconBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      isDark
                          ? 'images/logos/logo_icon_dark_bg.png'
                          : 'images/logos/logo_icon_white_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Icon(
                        Icons.home_work_rounded,
                        color: primaryColor,
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
                      "FIND YOUR SPACE",
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Hostel Hunt",
                      style: TextStyle(
                        color: textColor,
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
                  color: searchBarBg.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(

                    color: searchBarBorderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: secondaryTextColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Search hostels, areas...",
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: headerIconBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: primaryColor,
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
          ],
        ),
      ),
    );
  }

  /// ── HOSTEL LIST ──────────────────────────────────────────
  /// Now uses Riverpod AsyncValue instead of GetX Obx.
  Widget _buildHostelList(bool isDark) {
    final hostelListAsync = ref.watch(hostelListProvider);
    final paging = ref.watch(hostelPagingProvider);

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
                    AppColors.auburn500.withValues(alpha: 0.8),
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
        error: (error, _) => HostelListErrorState(
          message: error.toString().replaceFirst('Exception: ', ''),
          isDark: isDark,
          onRetry: () => ref.read(hostelListProvider.notifier).refresh(),
        ),

        // ── Data state ──
        data: (hostels) {
          // ── Empty state ──
          if (hostels.isEmpty) {
            final locState = ref.read(locationProvider);
            return HostelListEmptyState(
              city: locState.selectedCity,
              locality: locState.selectedLocality,
              isDark: isDark,
              onShowAll: () => ref.read(locationProvider.notifier).clearLocality(),
            );
          }

          // ── Success state — live hostel list, one page at a time ──
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
            physics: const BouncingScrollPhysics(),
            itemCount: hostels.length + 1,
            itemBuilder: (context, index) {
              if (index == hostels.length) {
                // The footer is only built once the user scrolls close to the end of the list:
                // that is the moment to ask for the next page.
                final canLoadMore = paging.hasMore && !paging.loadingMore && paging.loadMoreError == null;
                if (canLoadMore) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) ref.read(hostelListProvider.notifier).loadMore();
                  });
                }
                return HostelListFooter(
                  loading: paging.hasMore && paging.loadMoreError == null,
                  error: paging.loadMoreError,
                  isDark: isDark,
                  onRetry: () => ref.read(hostelListProvider.notifier).loadMore(),
                );
              }
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
