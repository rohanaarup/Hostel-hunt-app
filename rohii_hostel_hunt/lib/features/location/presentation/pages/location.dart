import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/features/location/presentation/providers/location_riverpod_provider.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';
import 'package:rohii_hostel_hunt/core/theme/theme_provider.dart';

// ═══════════════════════════════════════════════════════════════
// LocationScreen — BookMyShow-inspired city + locality selector
// ═══════════════════════════════════════════════════════════════
//
// Layout:
//  1. AppBar — back arrow + "Select Location"
//  2. Search bar — filters cities & localities in real-time
//  3. Auto Detect row
//  4. Popular Cities grid (4-column)
//  5. Areas section — shows after city tap, fetches from API

const List<_CityMeta> _popularCities = [
  _CityMeta('Mumbai', Icons.location_city_rounded),
  _CityMeta('Delhi-NCR', Icons.account_balance_rounded),
  _CityMeta('Bengaluru', Icons.corporate_fare_rounded),
  _CityMeta('Hyderabad', Icons.domain_rounded),
  _CityMeta('Chandigarh', Icons.holiday_village_rounded),
  _CityMeta('Ahmedabad', Icons.museum_rounded),
  _CityMeta('Pune', Icons.apartment_rounded),
  _CityMeta('Chennai', Icons.temple_hindu_rounded),
  _CityMeta('Kolkata', Icons.fort_rounded),
  _CityMeta('Kochi', Icons.sailing_rounded),
];

class _CityMeta {
  final String name;
  final IconData icon;
  const _CityMeta(this.name, this.icon);
}

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // The city selected in the grid (drives the Areas section)
  String? _pendingCity;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filter popular cities by search query ──
  List<_CityMeta> get _filteredCities {
    if (_query.isEmpty) return _popularCities;
    return _popularCities
        .where((c) => c.name.toLowerCase().contains(_query))
        .toList();
  }

  void _onCityTap(String city) {
    HapticFeedback.selectionClick();
    setState(() => _pendingCity = city);
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
  }

  void _onLocalityTap(String locality) {
    HapticFeedback.lightImpact();
    ref.read(locationProvider.notifier).setCityAndLocality(
      _pendingCity ?? ref.read(locationProvider).selectedCity,
      locality,
    );
    Navigator.pop(context);
  }

  void _onCityOnlyConfirm(String city) {
    HapticFeedback.lightImpact();
    ref.read(locationProvider.notifier).setCity(city);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final locState = ref.watch(locationProvider);
    final currentSelected = locState.selectedCity;

    return Scaffold(
      backgroundColor: AppColors.appBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.appBackground(isDark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppColors.textHeading(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Location',
          style: TextStyle(
            color: AppColors.textHeading(isDark),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            // ── 1. Search bar ──
            _SearchBar(
              isDark: isDark,
              controller: _searchCtrl,
            ),
            const SizedBox(height: 16),

            // ── 2. Auto Detect ──
            _AutoDetectRow(
              isDark: isDark,
              locState: locState,
              onTap: () async {
                HapticFeedback.lightImpact();
                await ref
                    .read(locationProvider.notifier)
                    .detectCurrentLocation();
                if (!mounted) return;
                final updated = ref.read(locationProvider);
                if (updated.selectedCity.isNotEmpty && updated.locationError == null) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 24),

            // ── 3. Popular Cities ──
            _SectionHeader(
              isDark: isDark,
              label: 'POPULAR CITIES',
            ),
            const SizedBox(height: 12),

            if (_filteredCities.isEmpty)
              _EmptySearch(isDark: isDark, query: _query)
            else
              _CitiesGrid(
                cities: _filteredCities,
                isDark: isDark,
                selectedCity: currentSelected,
                onTap: _onCityTap,
              ),

            const SizedBox(height: 24),

            // ── 4. Areas in selected city ──
            if (_pendingCity != null) ...[
              _AreasSection(
                isDark: isDark,
                city: _pendingCity!,
                query: _query,
                onLocalityTap: _onLocalityTap,
                onCityOnlyTap: () => _onCityOnlyConfirm(_pendingCity!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  final bool isDark;
  final TextEditingController controller;

  const _SearchBar({required this.isDark, required this.controller});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.chipInactiveBg(widget.isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? AppColors.auburn500.withValues(alpha: 0.7)
              : AppColors.cardBorder(widget.isDark),
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.auburn500.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            color: _focused
                ? AppColors.auburn500
                : AppColors.textSecondary(widget.isDark),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              focusNode: _focus,
              controller: widget.controller,
              style: TextStyle(
                color: AppColors.textHeading(widget.isDark),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search for your city or area...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary(widget.isDark),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: widget.controller.clear,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textSecondary(widget.isDark),
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// AUTO DETECT ROW
// ─────────────────────────────────────────────────────────────────

class _AutoDetectRow extends StatelessWidget {
  final bool isDark;
  final LocationState locState;
  final VoidCallback onTap;

  const _AutoDetectRow({
    required this.isDark,
    required this.locState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: locState.isDetectingLocation ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              locState.isDetectingLocation
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.auburn500),
                      ),
                    )
                  : Icon(
                      Icons.my_location_rounded,
                      color: AppColors.auburn500,
                      size: 22,
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto Detect My Location',
                      style: TextStyle(
                        color: AppColors.auburn500,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (locState.locationError != null)
                      Text(
                        locState.locationError!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      )
                    else if (locState.isDetectingLocation)
                      Text(
                        'Detecting your location...',
                        style: TextStyle(
                          color: AppColors.textSecondary(isDark),
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        'Using GPS to find your city',
                        style: TextStyle(
                          color: AppColors.textSecondary(isDark),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary(isDark),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final bool isDark;
  final String label;

  const _SectionHeader({required this.isDark, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textSecondary(isDark),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CITIES GRID
// ─────────────────────────────────────────────────────────────────

class _CitiesGrid extends StatelessWidget {
  final List<_CityMeta> cities;
  final bool isDark;
  final String selectedCity;
  final void Function(String) onTap;

  const _CitiesGrid({
    required this.cities,
    required this.isDark,
    required this.selectedCity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: cities.length,
      itemBuilder: (context, i) {
        final city = cities[i];
        final isSelected =
            selectedCity.toLowerCase() == city.name.toLowerCase();
        return _CityTile(
          city: city,
          isDark: isDark,
          isSelected: isSelected,
          onTap: () => onTap(city.name),
        );
      },
    );
  }
}

class _CityTile extends StatelessWidget {
  final _CityMeta city;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  const _CityTile({
    required this.city,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? AppColors.auburn300 : AppColors.auburn500;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.6)
                : AppColors.cardBorder(isDark),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  city.icon,
                  size: 28,
                  color: isSelected
                      ? primaryColor
                      : AppColors.textSecondary(isDark),
                ),
                if (isSelected)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2ECC71), // green dot
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              city.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected
                    ? primaryColor
                    : AppColors.textHeading(isDark),
                fontSize: 10.5,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EMPTY SEARCH STATE
// ─────────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  final bool isDark;
  final String query;

  const _EmptySearch({required this.isDark, required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.textSecondary(isDark)),
            const SizedBox(height: 12),
            Text(
              'No cities found for "$query"',
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
}

// ─────────────────────────────────────────────────────────────────
// AREAS SECTION — fetches from /hostels/localities/?city=...
// ─────────────────────────────────────────────────────────────────

class _AreasSection extends ConsumerWidget {
  final bool isDark;
  final String city;
  final String query;
  final void Function(String) onLocalityTap;
  final VoidCallback onCityOnlyTap;

  const _AreasSection({
    required this.isDark,
    required this.city,
    required this.query,
    required this.onLocalityTap,
    required this.onCityOnlyTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localitiesAsync = ref.watch(localitiesProvider(city));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header row
        Row(
          children: [
            Expanded(
              child: Text(
                '${city.toUpperCase()} AREAS',
                style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            // "All in city" button
            GestureDetector(
              onTap: onCityOnlyTap,
              child: Text(
                'All in $city →',
                style: TextStyle(
                  color: AppColors.auburn500,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Content
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder(isDark)),
          ),
          child: localitiesAsync.when(
            loading: () => _buildSkeletonList(isDark),
            error: (e, _) => _buildErrorState(isDark, e.toString()),
            data: (localities) {
              // Filter by search query
              final filtered = query.isEmpty
                  ? localities
                  : localities
                      .where((l) =>
                          l.locality.toLowerCase().contains(query))
                      .toList();

              if (filtered.isEmpty) {
                return _buildEmptyState(isDark, city);
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider(isDark),
                ),
                itemBuilder: (context, i) {
                  final item = filtered[i];
                  return _LocalityRow(
                    isDark: isDark,
                    locality: item.locality,
                    count: item.count,
                    onTap: () => onLocalityTap(item.locality),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonList(bool isDark) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: _ShimmerBox(
                  isDark: isDark,
                  width: double.infinity,
                  height: 14,
                ),
              ),
              const SizedBox(width: 12),
              _ShimmerBox(isDark: isDark, width: 60, height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded,
                color: AppColors.textSecondary(isDark), size: 36),
            const SizedBox(height: 8),
            Text(
              'Could not load areas',
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String city) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.location_off_rounded,
              color: AppColors.auburn500.withValues(alpha: 0.5),
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'No hostels listed in $city yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textHeading(isDark),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to list your hostel',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// LOCALITY ROW
// ─────────────────────────────────────────────────────────────────

class _LocalityRow extends StatelessWidget {
  final bool isDark;
  final String locality;
  final int count;
  final VoidCallback onTap;

  const _LocalityRow({
    required this.isDark,
    required this.locality,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  locality,
                  style: TextStyle(
                    color: AppColors.textHeading(isDark),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count ${count == 1 ? 'hostel' : 'hostels'}',
                style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary(isDark),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SHIMMER BOX (skeleton loading)
// ─────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final bool isDark;
  final double width;
  final double height;

  const _ShimmerBox({
    required this.isDark,
    required this.width,
    required this.height,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.cardBorder(widget.isDark)
              .withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
