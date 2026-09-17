import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// StatCardWidget
/// Replicates the "Balance / Spend" big-number card pattern from the reference.
/// Features: bold 36pt number, muted small label above, rounded-full status pill,
/// 24px radius, 20-24px padding, soft drop shadow.
class StatCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? pillLabel;
  final Color? pillColor;
  final bool isDark;

  const StatCardWidget({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.pillLabel,
    this.pillColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = AppColors.cardBg(isDark);
    final textPrimary = AppColors.textHeading(isDark);
    final textMuted = AppColors.textSecondary(isDark);
    final accent = isDark ? AppColors.auburn300 : AppColors.auburn500;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.cardBorder(isDark),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: isDark ? 0.18 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: icon + pill ──────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
              if (pillLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (pillColor ?? AppColors.success)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pillLabel!,
                    style: TextStyle(
                      color: pillColor ?? AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Muted label ───────────────────────────────────────
          Text(
            label,
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          // ── Big number ────────────────────────────────────────
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
