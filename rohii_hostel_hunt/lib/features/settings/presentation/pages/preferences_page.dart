import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rohii_hostel_hunt/core/theme/colors.dart';
import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';

// ── Preferences Page ─────────────────────────────────────────────────────────
class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});
  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  RangeValues _budget = const RangeValues(3000, 10000);
  String _gender = 'Boys';
  String _roomType = '2-Sharing';
  final Set<String> _amenities = {'Wi-Fi', 'Hot Water', 'CCTV'};
  String _food = 'Veg';
  final List<String> _locations = ['Kukatpally'];

  static const _genders = ['Boys', 'Girls', 'Any'];
  static const _roomTypes = ['Single', '2-Sharing', '3-Sharing', '4-Sharing'];
  static const _allAmenities = ['Wi-Fi', 'Hot Water', 'AC', 'CCTV', 'Laundry', 'Gym', 'Parking', 'Study Room'];
  static const _foodPref = ['Veg', 'Non-Veg', 'Both', 'No Preference'];
  static const _cities = ['Kukatpally', 'Gachibowli', 'Madhapur', 'Hitech City', 'Ameerpet', 'Begumpet'];

  void _save(bool isDark) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Preferences saved!',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.background(isDark),
        body: Column(
          children: [
            _SubHeader(title: 'Preferences', subtitle: 'Personalize your hostel search', isDark: isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: Column(
                  children: [
                    // Budget range
                    _PrefCard(
                      isDark: isDark, title: 'Budget Range',
                      icon: Icons.currency_rupee_rounded, iconColor: AppColors.orange,
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹${_budget.start.round()}', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 15)),
                            Text('₹${_budget.end.round()}', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.orange,
                            inactiveTrackColor: AppColors.orange.withValues(alpha: 0.2),
                            thumbColor: AppColors.orange,
                            overlayColor: AppColors.orange.withValues(alpha: 0.15),
                            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
                          ),
                          child: RangeSlider(
                            values: _budget,
                            min: 1000, max: 20000, divisions: 38,
                            onChanged: (v) => setState(() => _budget = v),
                          ),
                        ),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('₹1,000', style: TextStyle(color: AppColors.textTertiary(isDark), fontSize: 11)),
                          Text('₹20,000', style: TextStyle(color: AppColors.textTertiary(isDark), fontSize: 11)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    // Gender
                    _PrefCard(
                      isDark: isDark, title: 'Gender Preference',
                      icon: Icons.people_outline_rounded, iconColor: const Color(0xFF7C4DFF),
                      child: _ChipGroup(
                        options: _genders, selected: {_gender}, isDark: isDark,
                        onTap: (v) => setState(() => _gender = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Room type
                    _PrefCard(
                      isDark: isDark, title: 'Room Type',
                      icon: Icons.bed_rounded, iconColor: const Color(0xFF00897B),
                      child: _ChipGroup(
                        options: _roomTypes, selected: {_roomType}, isDark: isDark,
                        onTap: (v) => setState(() => _roomType = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Amenities
                    _PrefCard(
                      isDark: isDark, title: 'Amenities',
                      icon: Icons.star_outline_rounded, iconColor: const Color(0xFFE91E63),
                      child: _ChipGroup(
                        options: _allAmenities, selected: _amenities, isDark: isDark,
                        onTap: (v) => setState(() => _amenities.contains(v) ? _amenities.remove(v) : _amenities.add(v)),
                        multiSelect: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Food
                    _PrefCard(
                      isDark: isDark, title: 'Food Preference',
                      icon: Icons.restaurant_outlined, iconColor: const Color(0xFF1565C0),
                      child: _ChipGroup(
                        options: _foodPref, selected: {_food}, isDark: isDark,
                        onTap: (v) => setState(() => _food = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Preferred locations
                    _PrefCard(
                      isDark: isDark, title: 'Preferred Locations',
                      icon: Icons.location_on_outlined, iconColor: const Color(0xFF0288D1),
                      child: _ChipGroup(
                        options: _cities, selected: Set.from(_locations), isDark: isDark,
                        onTap: (v) => setState(() => _locations.contains(v) ? _locations.remove(v) : _locations.add(v)),
                        multiSelect: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg(isDark),
            border: Border(top: BorderSide(color: isDark ? AppColors.chipDark : AppColors.border, width: 0.8)),
          ),
          child: ElevatedButton(
            onPressed: () => _save(isDark),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange, foregroundColor: AppColors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}

class _PrefCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _PrefCard({required this.isDark, required this.title, required this.icon, required this.iconColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.chipDark : AppColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: isDark ? 0.16 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final bool isDark;
  final ValueChanged<String> onTap;
  final bool multiSelect;
  const _ChipGroup({required this.options, required this.selected, required this.isDark, required this.onTap, this.multiSelect = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onTap(opt); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.orange : AppColors.chipBg(isDark),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.orange : (isDark ? AppColors.chipDark : AppColors.border),
              ),
            ),
            child: Text(opt,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textSecondary(isDark),
                  fontSize: 13, fontWeight: FontWeight.w600,
                )),
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared sub header (same as in other files) ────────────────────────────────
class _SubHeader extends StatelessWidget {
  final String title, subtitle;
  final bool isDark;
  const _SubHeader({required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [AppColors.cardDark, AppColors.surfaceDark2] : [AppColors.headerStart, AppColors.headerEnd],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: isDark ? 0.22 : 0.07), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.chipDark : AppColors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.white.withValues(alpha: 0.08) : AppColors.border, width: 0.8),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary(isDark)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            Text(subtitle, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12)),
          ])),
        ],
      ),
    );
  }
}
