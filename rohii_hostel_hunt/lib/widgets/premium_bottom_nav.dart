import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:rohii_hostel_hunt/services/colors.dart';

/// Floating pill-style bottom navigation with:
///  • Spring-physics bounce on tap
///  • Animated orange dot indicator below active icon
///  • Smooth icon swap via AnimatedSwitcher
///  • Expanding label via AnimatedSize
///  • Glassmorphic background with orange glow
class PremiumBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final bool isDark;

  const PremiumBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withValues(alpha: 0.95)
            : AppColors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.orange.withValues(alpha: 0.12),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.shadow.withValues(alpha: 0.4)
                : AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          // subtle orange glow
          BoxShadow(
            color: AppColors.orange.withValues(alpha: isDark ? 0.05 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            isSelected: selectedIndex == 0,
            onTap: () => onItemTapped(0),
            isDark: isDark,
          ),
          _NavItem(
            icon: Icons.search_rounded,
            activeIcon: Icons.search_rounded,
            label: 'Search',
            isSelected: selectedIndex == 1,
            onTap: () => onItemTapped(1),
            isDark: isDark,
          ),
          _NavItem(
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart_rounded,
            label: 'Cart',
            isSelected: selectedIndex == 2,
            onTap: () => onItemTapped(2),
            isDark: isDark,
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            isSelected: selectedIndex == 3,
            onTap: () => onItemTapped(3),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// ── NAV ITEM with spring bounce + dot indicator ──────────────
class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      // Will be driven by spring simulation, duration is fallback
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.0)
        .animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _triggerBounce() {
    // Spring simulation: mass=1, stiffness=600, damping=15
    const spring = SpringDescription(mass: 1, stiffness: 600, damping: 15);
    final sim = SpringSimulation(spring, 0.0, 1.0, 0.0);

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);

    _bounceController.reset();
    // Use the spring's time to determine duration
    _bounceController.duration =
        Duration(milliseconds: (sim.x(1.0).abs() * 500).clamp(300, 600).toInt());
    _bounceController.forward();
  }

  void _handleTap() {
    _triggerBounce();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _bounceController,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSelected ? 16 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.orange.withValues(alpha: 0.15),
                      AppColors.orangeLight.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            color: widget.isSelected ? null : const Color(0x00000000),
            borderRadius: BorderRadius.circular(20),
            border: widget.isSelected
                ? Border.all(
                    color: AppColors.orange.withValues(alpha: 0.2),
                    width: 0.5,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with animated switch
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      widget.isSelected ? widget.activeIcon : widget.icon,
                      key: ValueKey(widget.isSelected),
                      size: 22,
                      color: widget.isSelected
                          ? AppColors.orange
                          : AppColors.textTertiary(widget.isDark),
                    ),
                  ),
                  // Expanding label
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: widget.isSelected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              widget.label,
                              style: const TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.2,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // ── Animated dot indicator ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: widget.isSelected ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.orange
                      : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: widget.isSelected
                      ? [
                          const BoxShadow(
                            color: AppColors.orangeGlow,
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : const [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
