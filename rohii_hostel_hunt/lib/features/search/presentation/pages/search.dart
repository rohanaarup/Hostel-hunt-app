import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/theme/colors.dart';
import 'package:rohii_hostel_hunt/core/theme/theme_provider.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/providers/search_riverpod_provider.dart';
import 'package:rohii_hostel_hunt/features/search/presentation/widgets/search_result_card.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — Search Page
/// ─────────────────────────────────────────────────────────
///
/// Full-screen search experience with:
///  • Auto-focused search input
///  • Recent searches (chips)
///  • Popular suggestion grid
///  • Real-time debounced results
///  • Empty-state illustration
///  • Smooth animated transitions between states
///  • Light/dark theme support

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Auto-focus the search input after the page builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // ── Search header ──
              _buildSearchHeader(isDark),

              // ── Content area ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _buildContent(searchState, isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════ SEARCH HEADER ═══════════════════════

  Widget _buildSearchHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary(isDark),
              size: 24,
            ),
            splashRadius: 22,
          ),

          // Search input field
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.chipBg(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AppColors.orange.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiary(isDark),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (value) {
                        ref.read(searchProvider.notifier).onQueryChanged(value);
                        setState(() {}); // rebuild for clear button
                      },
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search hostels, areas...',
                        hintStyle: TextStyle(
                          color: AppColors.textTertiary(isDark),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.search,
                    ),
                  ),

                  // Clear / mic button
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        ref.read(searchProvider.notifier).clearSearch();
                        setState(() {});
                        _focusNode.requestFocus();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary(isDark),
                          size: 18,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.mic_none_rounded,
                        color: AppColors.orange.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════ CONTENT SWITCHER ═══════════════════════

  Widget _buildContent(SearchStateData searchState, bool isDark) {
    switch (searchState.status) {
      case SearchStatus.idle:
        return _buildIdleState(searchState, isDark);
      case SearchStatus.searching:
        return _buildSearchingState(isDark);
      case SearchStatus.results:
        return _buildResultsState(searchState, isDark);
      case SearchStatus.empty:
        return _buildEmptyState(isDark);
      case SearchStatus.error:
        return _buildErrorState(searchState, isDark);
    }
  }

  // ═══════════════════════ IDLE STATE ═══════════════════════

  Widget _buildIdleState(SearchStateData searchState, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('idle'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Recent searches ──
          if (searchState.recentSearches.isNotEmpty) ...[
            _buildSectionHeader(
              'YOUR RECENT SEARCHES',
              isDark,
              trailing: GestureDetector(
                onTap: () => ref.read(searchProvider.notifier).clearRecentSearches(),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: searchState.recentSearches.map((term) {
                return _buildRecentChip(term, isDark, () {
                  _controller.text = term;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: term.length),
                  );
                  ref.read(searchProvider.notifier).searchForTerm(term);
                  setState(() {});
                });
              }).toList(),
            ),
            const SizedBox(height: 28),
          ],

          // ── Popular searches ──
          _buildSectionHeader('POPULAR SEARCHES', isDark),
          const SizedBox(height: 14),
          _buildPopularGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textSecondary(isDark),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildRecentChip(String term, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.chipBg(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.white.withValues(alpha: 0.08)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 14,
              color: AppColors.textTertiary(isDark),
            ),
            const SizedBox(width: 6),
            Text(
              term,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularGrid(bool isDark) {
    final popularIcons = [
      Icons.ac_unit_rounded,
      Icons.female_rounded,
      Icons.male_rounded,
      Icons.workspace_premium_rounded,
      Icons.location_city_rounded,
      Icons.apartment_rounded,
      Icons.villa_rounded,
      Icons.savings_rounded,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: popularSearches.length,
      itemBuilder: (context, index) {
        final term = popularSearches[index];
        final icon = popularIcons[index % popularIcons.length];

        return GestureDetector(
          onTap: () {
            _controller.text = term;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: term.length),
            );
            ref.read(searchProvider.notifier).searchForTerm(term);
            setState(() {});
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.06)
                    : AppColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    term,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════ SEARCHING STATE ═══════════════════════

  Widget _buildSearchingState(bool isDark) {
    return Center(
      key: const ValueKey('searching'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.orange.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════ RESULTS STATE ═══════════════════════

  Widget _buildResultsState(SearchStateData searchState, bool isDark) {
    return ListView.builder(
      key: const ValueKey('results'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: searchState.results.length + 1, // +1 for header
      itemBuilder: (context, index) {
        // Results count header
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              '${searchState.results.length} hostel${searchState.results.length == 1 ? '' : 's'} found',
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final hostel = searchState.results[index - 1];
        return SearchResultCard(
          hostel: hostel,
          isDark: isDark,
          query: searchState.query,
          onTap: () {
            // Navigate to hostel detail — for now show a detailed snackbar
            // Future: Navigator.push(context, MaterialPageRoute(
            //   builder: (_) => HostelDetailPage(hostel: hostel),
            // ));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.apartment_rounded,
                        color: AppColors.white, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${hostel.name} — ${hostel.price}',
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════ EMPTY STATE ═══════════════════════

  Widget _buildEmptyState(bool isDark) {
    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration circle
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 44,
                color: AppColors.orange.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No hostels found',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different keyword\nor check the spelling',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════ ERROR STATE ═══════════════════════

  Widget _buildErrorState(SearchStateData searchState, bool isDark) {
    return Center(
      key: const ValueKey('error'),
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
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              searchState.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                ref.read(searchProvider.notifier).onQueryChanged(_controller.text);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
