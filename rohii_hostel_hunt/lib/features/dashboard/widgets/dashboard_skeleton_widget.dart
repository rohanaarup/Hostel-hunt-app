import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// DashboardSkeletonWidget
/// Shimmer-shaped skeleton shown while the dashboard data is loading.
/// Mimics the exact layout of the final populated state.
class DashboardSkeletonWidget extends StatefulWidget {
  final bool isDark;
  const DashboardSkeletonWidget({super.key, required this.isDark});

  @override
  State<DashboardSkeletonWidget> createState() =>
      _DashboardSkeletonWidgetState();
}

class _DashboardSkeletonWidgetState extends State<DashboardSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = CurvedAnimation(parent: _shimmer, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Two stat cards side by side ──────────────────────
            Row(
              children: [
                Expanded(child: _ShimmerCard(height: 130, isDark: widget.isDark, anim: _anim)),
                const SizedBox(width: 14),
                Expanded(child: _ShimmerCard(height: 130, isDark: widget.isDark, anim: _anim)),
              ],
            ),
            const SizedBox(height: 16),
            // ── Spotlight card ───────────────────────────────────
            _ShimmerCard(height: 180, isDark: widget.isDark, anim: _anim),
            const SizedBox(height: 16),
            // ── Donut card ───────────────────────────────────────
            _ShimmerCard(height: 320, isDark: widget.isDark, anim: _anim),
            const SizedBox(height: 16),
            // ── Quick actions row ────────────────────────────────
            Row(
              children: [
                Expanded(child: _ShimmerCard(height: 52, isDark: widget.isDark, anim: _anim)),
                const SizedBox(width: 14),
                Expanded(child: _ShimmerCard(height: 52, isDark: widget.isDark, anim: _anim)),
              ],
            ),
            const SizedBox(height: 16),
            // ── Activity list card ───────────────────────────────
            _ShimmerCard(height: 280, isDark: widget.isDark, anim: _anim),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double height;
  final bool isDark;
  final Animation<double> anim;

  const _ShimmerCard(
      {required this.height, required this.isDark, required this.anim});

  @override
  Widget build(BuildContext context) {
    final base = isDark
        ? AppColors.ivory900
        : AppColors.ivory100;
    final highlight = isDark
        ? AppColors.ivory700.withValues(alpha: 0.5)
        : AppColors.ivory300;

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * anim.value, 0),
            end: Alignment(1 + 2 * anim.value, 0),
            colors: [base, highlight, base],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
