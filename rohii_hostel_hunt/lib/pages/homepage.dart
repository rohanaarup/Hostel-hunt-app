import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rohii_hostel_hunt/models/hostel.dart';
import 'package:rohii_hostel_hunt/pages/search.dart';
import 'package:rohii_hostel_hunt/services/colors.dart';
import 'package:rohii_hostel_hunt/services/location_provider.dart';
import 'package:rohii_hostel_hunt/services/notifiers.dart';
import 'package:rohii_hostel_hunt/widgets/premium_filter_chips.dart';
import 'package:rohii_hostel_hunt/widgets/premium_hostel_card.dart';
import 'package:rohii_hostel_hunt/widgets/premium_bottom_nav.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  final List<String> filters = ["All", "AC", "Non-AC", "Boys", "Girls", "Premium"];
  String selectedFilter = "All";

  // Hostels data — fresh copy from the centralized model
  final List<Hostel> hostels = List<Hostel>.from(Hostel.sampleHostels);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      Navigator.pushNamed(context, '/profile');
    }
    if (index == 2) {
      Navigator.pushNamed(context, '/about');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: AppColors.background(isDark),
          extendBody: true,
          body: SafeArea(
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
      },
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
                  onTap: () => Navigator.pushNamed(context, '/location'),
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
                              Consumer<LocationProvider>(
                                builder: (context, locProvider, _) {
                                  return Text(
                                    locProvider.selectedCity,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.white, size: 18),
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
                  onTap: toggleTheme,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Profile avatar
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.white.withValues(alpha: 0.2),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.white, size: 20),
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
                    child: Image.asset('images/loading.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => const Icon(
                            Icons.home_work_rounded,
                            color: AppColors.white,
                            size: 24)),
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
                    reverseTransitionDuration: const Duration(milliseconds: 250),
                    transitionsBuilder: (context, animation, secondaryAnim, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: isDark ? 0.08 : 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: AppColors.white.withValues(alpha: 0.7), size: 20),
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
                      child: Icon(Icons.tune_rounded,
                          color: AppColors.white.withValues(alpha: 0.8),
                          size: 16),
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
  Widget _buildHostelList(bool isDark) {
    return Expanded(
      child: ListView.builder(
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
      ),
    );
  }
}

