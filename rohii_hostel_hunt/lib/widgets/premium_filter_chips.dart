import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rohii_hostel_hunt/services/colors.dart';

/// Premium animated filter chips with:
///  • AnimatedContainer — smooth bg color, shadow/glow, border transitions
///  • AnimatedScale — bounce on press (0.92×) + scale-up on select (1.05×)
///  • AnimatedDefaultTextStyle — color & weight transitions
///  • Double-shadow glow using AppColors.orangeGlow when selected
///  • HapticFeedback for tactile response
///  • Duration: 250ms per spec
///
/// Fully reusable — accepts any list of filter strings.
class PremiumFilterChips extends StatefulWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final bool isDark;

  const PremiumFilterChips({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.isDark,
  });

  @override
  State<PremiumFilterChips> createState() => _PremiumFilterChipsState();
}

class _PremiumFilterChipsState extends State<PremiumFilterChips> {
  String? _pressedFilter;

  void _onTapDown(String filter) {
    setState(() => _pressedFilter = filter);
  }

  void _onTapUp(String filter) {
    setState(() => _pressedFilter = null);
    HapticFeedback.lightImpact();
    widget.onFilterSelected(filter);
  }

  void _onTapCancel() {
    setState(() => _pressedFilter = null);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        physics: const BouncingScrollPhysics(),
        itemCount: widget.filters.length,
        itemBuilder: (context, index) {
          final filter = widget.filters[index];
          final isSelected = widget.selectedFilter == filter;
          final isPressed = _pressedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTapDown: (_) => _onTapDown(filter),
              onTapUp: (_) => _onTapUp(filter),
              onTapCancel: () => _onTapCancel(),
              child: AnimatedScale(
                scale: isPressed ? 0.92 : (isSelected ? 1.05 : 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    // Selected = orange gradient, else neutral chip bg
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppColors.orange, AppColors.orangeDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : AppColors.chipBg(widget.isDark),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: widget.isDark
                                ? AppColors.chipDark
                                : AppColors.border,
                            width: 1,
                          ),
                    // Double-shadow glow when selected for premium halo
                    boxShadow: isSelected
                        ? [
                            // Primary glow — warm orange halo
                            const BoxShadow(
                              color: AppColors.orangeGlow,
                              blurRadius: 18,
                              spreadRadius: 2,
                              offset: Offset(0, 4),
                            ),
                            // Secondary inner glow — tighter ring
                            BoxShadow(
                              color:
                                  AppColors.orange.withValues(alpha: 0.2),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : const [],
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary(widget.isDark),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12.5,
                      letterSpacing: 0.3,
                    ),
                    child: Text(filter),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
