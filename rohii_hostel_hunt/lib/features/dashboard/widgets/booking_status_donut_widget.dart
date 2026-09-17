import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rohii_hostel_hunt/features/dashboard/models/dashboard_stats_model.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// BookingStatusDonutWidget
/// Renders a donut chart with booking status breakdown + legend list.
/// IMPORTANT: The parent (DashboardScreen) must NOT render this if total == 0.
class BookingStatusDonutWidget extends StatefulWidget {
  final BookingStats stats;
  final bool isDark;

  const BookingStatusDonutWidget({
    super.key,
    required this.stats,
    required this.isDark,
  });

  @override
  State<BookingStatusDonutWidget> createState() =>
      _BookingStatusDonutWidgetState();
}

class _BookingStatusDonutWidgetState extends State<BookingStatusDonutWidget> {
  int _touchedIndex = -1;

  // Segment colours derived from HH's semantic palette
  static const _pending = Color(0xFFB8843A);   // AppColors.warning
  static const _confirmed = Color(0xFF0A6A5A); // AppColors.emerald500
  static const _paid = Color(0xFF5FA394);      // AppColors.emerald300
  static const _cancelled = Color(0xFF8C2F2F); // AppColors.error
  static const _rejected = Color(0xFF6B5D4F);  // AppColors.ivory700

  List<PieChartSectionData> _buildSections(BookingStats s) {
    final total = s.total;
    final entries = [
      _Entry('Pending', s.pending, _pending),
      _Entry('Confirmed', s.confirmed, _confirmed),
      _Entry('Paid', s.paid, _paid),
      _Entry('Cancelled', s.cancelled, _cancelled),
      _Entry('Rejected', s.rejected, _rejected),
    ].where((e) => e.count > 0).toList();

    return List.generate(entries.length, (i) {
      final e = entries[i];
      final isTouched = i == _touchedIndex;
      final pct = total > 0 ? (e.count / total * 100).toStringAsFixed(0) : '0';
      return PieChartSectionData(
        value: e.count.toDouble(),
        color: e.color,
        radius: isTouched ? 64 : 54,
        title: isTouched ? '$pct%' : '',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        borderSide: isTouched
            ? BorderSide(color: e.color.withValues(alpha: 0.6), width: 2)
            : BorderSide.none,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final isDark = widget.isDark;
    final textPrimary = AppColors.textHeading(isDark);
    final textMuted = AppColors.textSecondary(isDark);
    final cardBg = AppColors.cardBg(isDark);

    final allEntries = [
      _Entry('Pending', s.pending, _pending),
      _Entry('Confirmed', s.confirmed, _confirmed),
      _Entry('Paid', s.paid, _paid),
      _Entry('Cancelled', s.cancelled, _cancelled),
      _Entry('Rejected', s.rejected, _rejected),
    ].where((e) => e.count > 0).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder(isDark), width: 1),
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
          // ── Title ─────────────────────────────────────────────
          Text(
            'Booking Status',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${s.total} total bookings',
            style: TextStyle(color: textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // ── Donut + center label ───────────────────────────────
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: _buildSections(s),
                    centerSpaceRadius: 52,
                    sectionsSpace: 2,
                  ),
                ),
                // Center total
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.total.toString(),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Total',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Legend ────────────────────────────────────────────
          ...allEntries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: e.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    e.label,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: e.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      e.count.toString(),
                      style: TextStyle(
                        color: e.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
}

class _Entry {
  final String label;
  final int count;
  final Color color;
  const _Entry(this.label, this.count, this.color);
}
