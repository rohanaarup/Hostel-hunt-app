import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';
import 'package:rohii_hostel_hunt/features/dashboard/providers/dashboard_provider.dart';
import 'package:rohii_hostel_hunt/features/dashboard/models/dashboard_stats_model.dart';
import 'package:rohii_hostel_hunt/features/dashboard/widgets/dashboard_skeleton_widget.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F0A0A) : const Color(0xFFF5F0EE),
            body: SafeArea(
              child: Column(
                children: [
                  _AppBar(isDark: isDark),
                  Expanded(child: _Body(isDark: isDark)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final bool isDark;
  const _AppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F0A0A) : const Color(0xFFF5F0EE);
    final textColor = isDark ? AppColors.ivory50 : AppColors.ink900;
    final mutedColor = isDark ? AppColors.ivory500 : AppColors.ink700;
    final iconBg = isDark ? const Color(0xFF1C1212) : Colors.white;
    final iconBorder = isDark ? const Color(0xFF2E1E1E) : const Color(0xFFE8DDD9);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _CircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            isDark: isDark,
            iconBg: iconBg,
            iconBorder: iconBorder,
            iconColor: textColor,
            onTap: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analytics',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
                Text('Your hostel journey',
                    style: TextStyle(color: mutedColor, fontSize: 12)),
              ],
            ),
          ),
          Consumer(
            builder: (context, ref, _) => _CircleBtn(
              icon: Icons.refresh_rounded,
              isDark: isDark,
              iconBg: iconBg,
              iconBorder: iconBorder,
              iconColor: textColor,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(dashboardProvider.notifier).refresh();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final Color iconBg, iconBorder, iconColor;
  final VoidCallback onTap;
  const _CircleBtn({
    required this.icon,
    required this.isDark,
    required this.iconBg,
    required this.iconBorder,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          shape: BoxShape.circle,
          border: Border.all(color: iconBorder, width: 1),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final bool isDark;
  const _Body({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardProvider);

    return statsAsync.when(
      loading: () => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: DashboardSkeletonWidget(isDark: isDark),
        ),
      ),
      error: (err, _) => _ErrorView(
        isDark: isDark,
        message: err.toString(),
        onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
      ),
      data: (stats) => RefreshIndicator(
        color: AppColors.auburn500,
        backgroundColor: isDark ? const Color(0xFF1C1212) : Colors.white,
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          children: [
            // ── 1. Period selector + big summary ─────────────────────
            _SummaryHeader(stats: stats, isDark: isDark),
            const SizedBox(height: 20),

            // ── 2. Bubble chart (booking breakdown) ─────────────────
            if (stats.bookingStats.total > 0) ...[
              _SectionLabel(label: 'Booking Breakdown', isDark: isDark),
              const SizedBox(height: 10),
              _BubbleChart(stats: stats.bookingStats, isDark: isDark),
              const SizedBox(height: 20),

              // ── 3. Horizontal bar chart ─────────────────────────
              _SectionLabel(label: 'Status Distribution', isDark: isDark),
              const SizedBox(height: 10),
              _HorizontalBarChart(stats: stats.bookingStats, isDark: isDark),
              const SizedBox(height: 20),
            ] else ...[
              _EmptyState(isDark: isDark),
              const SizedBox(height: 20),
            ],

            // ── 4. Active booking spotlight ───────────────────────
            if (stats.activeBooking != null) ...[
              _SectionLabel(label: 'Active Booking', isDark: isDark),
              const SizedBox(height: 10),
              _ActiveBookingCard(booking: stats.activeBooking!, isDark: isDark),
              const SizedBox(height: 20),
            ],

            // ── 5. Area sparkline (activity over time) ────────────
            if (stats.recentActivity.isNotEmpty) ...[
              _SectionLabel(label: 'Recent Activity', isDark: isDark),
              const SizedBox(height: 10),
              _SparklineCard(items: stats.recentActivity, isDark: isDark),
              const SizedBox(height: 20),

              // ── 6. Ranked activity list ──────────────────────
              _RankedActivityList(items: stats.recentActivity, isDark: isDark),
              const SizedBox(height: 20),
            ],

            // ── 7. Quick actions ─────────────────────────────────
            _QuickActions(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Header  (like the "$54.62K" card in the reference)
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final DashboardStats stats;
  final bool isDark;
  const _SummaryHeader({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1C1212) : Colors.white;
    final border = isDark ? const Color(0xFF2E1E1E) : const Color(0xFFECE4E0);
    final textColor = isDark ? AppColors.ivory50 : AppColors.ink900;
    final mutedColor = isDark ? AppColors.ivory500 : AppColors.ink700;
    final accent = isDark ? AppColors.auburn300 : AppColors.auburn500;
    final total = stats.bookingStats.total;
    final active = stats.bookingStats.confirmed + stats.bookingStats.pending;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Total Bookings',
                style: TextStyle(color: mutedColor, fontSize: 12, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (active > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.emerald500, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('$active Active',
                        style: const TextStyle(color: AppColors.emerald500, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$total',
                style: TextStyle(
                    color: textColor, fontSize: 52, fontWeight: FontWeight.w800, height: 1, letterSpacing: -2)),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('bookings',
                  style: TextStyle(color: mutedColor, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 16),
          // Mini stat row
          Row(children: [
            _MiniStat(label: 'Saved', value: stats.wishlistCount, color: accent, icon: Icons.favorite_rounded),
            const SizedBox(width: 12),
            _MiniStat(label: 'Pending', value: stats.bookingStats.pending, color: AppColors.warning, icon: Icons.schedule_rounded),
            const SizedBox(width: 12),
            _MiniStat(label: 'Paid', value: stats.bookingStats.paid, color: AppColors.emerald500, icon: Icons.verified_rounded),
          ]),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('$value', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, height: 1)),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 10)),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
          color: isDark ? AppColors.ivory100 : AppColors.ink900,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bubble Chart  (reference: circular bubble breakdown)
// ─────────────────────────────────────────────────────────────────────────────

class _BubbleChart extends StatefulWidget {
  final BookingStats stats;
  final bool isDark;
  const _BubbleChart({required this.stats, required this.isDark});

  @override
  State<_BubbleChart> createState() => _BubbleChartState();
}

class _BubbleChartState extends State<_BubbleChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF1C1212) : Colors.white;
    final border = isDark ? const Color(0xFF2E1E1E) : const Color(0xFFECE4E0);

    final segments = [
      _BubbleSeg('Pending', s.pending, AppColors.auburn300),
      _BubbleSeg('Confirmed', s.confirmed, AppColors.emerald500),
      _BubbleSeg('Paid', s.paid, const Color(0xFF5FA394)),
      _BubbleSeg('Cancelled', s.cancelled, AppColors.error),
      _BubbleSeg('Rejected', s.rejected, const Color(0xFF8C7060)),
    ].where((e) => e.count > 0).toList();

    if (segments.isEmpty) return const SizedBox.shrink();

    final maxCount = segments.map((e) => e.count).reduce(math.max);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => Column(
          children: [
            SizedBox(
              height: 180,
              child: _BubbleCanvas(segments: segments, maxCount: maxCount, scale: _anim.value, isDark: isDark),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: segments.map((seg) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: seg.color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${seg.label} ${seg.count}',
                      style: TextStyle(
                        color: isDark ? AppColors.ivory300 : AppColors.ink700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleSeg {
  final String label;
  final int count;
  final Color color;
  const _BubbleSeg(this.label, this.count, this.color);
}

class _BubbleCanvas extends StatelessWidget {
  final List<_BubbleSeg> segments;
  final int maxCount;
  final double scale;
  final bool isDark;
  const _BubbleCanvas({required this.segments, required this.maxCount, required this.scale, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(segments: segments, maxCount: maxCount, scale: scale, isDark: isDark),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final List<_BubbleSeg> segments;
  final int maxCount;
  final double scale;
  final bool isDark;

  const _BubblePainter({required this.segments, required this.maxCount, required this.scale, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty || maxCount == 0) return;

    final maxRadius = math.min(size.width, size.height) * 0.35;
    final n = segments.length;

    // Lay bubbles out in a loose row with the biggest one centered
    final sorted = [...segments]..sort((a, b) => b.count.compareTo(a.count));
    final total = segments.fold(0, (s, e) => s + e.count);

    // positions: spread across width
    final positions = <Offset>[];
    for (int i = 0; i < sorted.length; i++) {
      final x = (size.width / (n + 1)) * (i + 1);
      // Alternate y slightly for visual interest
      final y = size.height * 0.5 + (i.isOdd ? -12.0 : 12.0);
      positions.add(Offset(x, y));
    }

    for (int i = 0; i < sorted.length; i++) {
      final seg = sorted[i];
      final r = maxRadius * math.sqrt(seg.count / maxCount) * scale;
      final center = positions[i];
      final paint = Paint()..color = seg.color.withValues(alpha: 0.85);
      final shadowPaint = Paint()
        ..color = seg.color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(center, r + 4, shadowPaint);
      canvas.drawCircle(center, r, paint);

      // Label inside if big enough
      if (r > 28) {
        final pct = total > 0 ? '${(seg.count / total * 100).round()}%' : '';
        final tp = TextPainter(
          text: TextSpan(
            text: '$pct\n${seg.label}',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, height: 1.3),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: r * 2);
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.scale != scale;
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal Bar Chart (reference: "Today sales by categories" style)
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalBarChart extends StatefulWidget {
  final BookingStats stats;
  final bool isDark;
  const _HorizontalBarChart({required this.stats, required this.isDark});

  @override
  State<_HorizontalBarChart> createState() => _HorizontalBarChartState();
}

class _HorizontalBarChartState extends State<_HorizontalBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF1C1212) : Colors.white;
    final border = isDark ? const Color(0xFF2E1E1E) : const Color(0xFFECE4E0);
    final textColor = isDark ? AppColors.ivory50 : AppColors.ink900;
    final mutedColor = isDark ? AppColors.ivory500 : AppColors.ink700;

    final rows = [
      _BarRow('Pending', s.pending, AppColors.auburn300),
      _BarRow('Confirmed', s.confirmed, AppColors.emerald500),
      _BarRow('Paid', s.paid, const Color(0xFF5FA394)),
      _BarRow('Cancelled', s.cancelled, AppColors.error),
      _BarRow('Rejected', s.rejected, const Color(0xFF8C7060)),
    ].where((r) => r.count > 0).toList();

    if (rows.isEmpty) return const SizedBox.shrink();
    final maxVal = rows.map((r) => r.count).reduce(math.max);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => Column(
          children: rows.map((row) {
            final frac = maxVal > 0 ? row.count / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(row.label,
                        style: TextStyle(color: mutedColor, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A1A1A) : const Color(0xFFF2ECEA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: (frac * _anim.value).clamp(0.0, 1.0),
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: row.color,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: row.color.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 28,
                    child: Text('${row.count}',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BarRow {
  final String label;
  final int count;
  final Color color;
  const _BarRow(this.label, this.count, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// Area Sparkline Card (reference: orange area chart)
// ─────────────────────────────────────────────────────────────────────────────

class _SparklineCard extends StatelessWidget {
  final List<RecentBookingItem> items;
  final bool isDark;
  const _SparklineCard({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.auburn300 : AppColors.auburn500;

    // Build y-values: index timeline (oldest=left, newest=right)
    // Y = booking "weight": paid=3, confirmed=2, pending=1, cancelled/rejected=0
    final reversed = items.reversed.toList();
    final spots = List.generate(reversed.length, (i) {
      final s = reversed[i].status;
      double y = s == 'paid' ? 3 : s == 'confirmed' ? 2 : s == 'pending' ? 1 : 0.5;
      return FlSpot(i.toDouble(), y);
    });

    return Container(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Activity Trend',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('+${items.length} bookings',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Recent booking activity', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.white,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeWidth: 1.5,
                        strokeColor: accent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 3.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ranked Activity List (reference: numbered rows with data)
// ─────────────────────────────────────────────────────────────────────────────

class _RankedActivityList extends StatelessWidget {
  final List<RecentBookingItem> items;
  final bool isDark;
  const _RankedActivityList({required this.items, required this.isDark});

  Color _statusColor(String s) => switch (s) {
        'confirmed' => AppColors.emerald500,
        'paid' => const Color(0xFF5FA394),
        'pending' => AppColors.auburn300,
        'cancelled' || 'rejected' => AppColors.error,
        _ => AppColors.ivory500,
      };

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1C1212) : Colors.white;
    final border = isDark ? const Color(0xFF2E1E1E) : const Color(0xFFECE4E0);
    final textColor = isDark ? AppColors.ivory50 : AppColors.ink900;
    final mutedColor = isDark ? AppColors.ivory500 : AppColors.ink700;
    final divider = isDark ? const Color(0xFF2E1E1E) : const Color(0xFFF0E8E4);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final b = items[i];
          final color = _statusColor(b.status);
          final isLast = i == items.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // Rank number
                    SizedBox(
                      width: 26,
                      child: Text('${i + 1 < 10 ? '0' : ''}${i + 1}',
                          style: TextStyle(color: mutedColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),
                    // Status pill circle
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_statusIcon(b.status), size: 16, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.hostelName ?? 'Hostel Booking',
                              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (b.hostelCity != null)
                            Text(b.hostelCity!, style: TextStyle(color: mutedColor, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      if (b.amount != null)
                        Text('₹${b.amount}',
                            style: TextStyle(
                              color: isDark ? AppColors.auburn300 : AppColors.auburn500,
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(b.status,
                            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: divider, indent: 20, endIndent: 20),
            ],
          );
        }),
      ),
    );
  }

  IconData _statusIcon(String s) => switch (s) {
        'confirmed' => Icons.check_circle_rounded,
        'paid' => Icons.verified_rounded,
        'pending' => Icons.schedule_rounded,
        'cancelled' => Icons.cancel_rounded,
        _ => Icons.block_rounded,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Active Booking Card (dark gradient spotlight)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveBookingCard extends StatelessWidget {
  final ActiveBooking booking;
  final bool isDark;
  const _ActiveBookingCard({required this.booking, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = booking.status == 'paid' ? AppColors.emerald500 : AppColors.emerald500;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1A0E), Color(0xFF1A0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.auburn700.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.auburn300.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.hotel_rounded, color: AppColors.auburn300, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Active Booking', style: TextStyle(color: AppColors.ivory500, fontSize: 11)),
                Text(booking.hostelName ?? 'Your Hostel',
                    style: const TextStyle(color: AppColors.ivory50, fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(booking.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Divider(color: AppColors.ivory700.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 16),
          Row(children: [
            if (booking.hostelCity != null)
              _InfoChip(Icons.location_on_rounded, booking.hostelCity!),
            if (booking.roomNumber != null) ...[
              const SizedBox(width: 12),
              _InfoChip(Icons.door_front_door_rounded, 'Room ${booking.roomNumber}'),
            ],
            if (booking.bedNumber != null) ...[
              const SizedBox(width: 12),
              _InfoChip(Icons.single_bed_rounded, 'Bed ${booking.bedNumber}'),
            ],
          ]),
          if (booking.checkInDate != null || booking.amount != null) ...[
            const SizedBox(height: 14),
            Row(children: [
              if (booking.checkInDate != null)
                Expanded(child: _StatCol('Check-in', _fmt(booking.checkInDate) ?? '')),
              if (booking.checkOutDate != null)
                Expanded(child: _StatCol('Check-out', _fmt(booking.checkOutDate) ?? 'Open')),
              if (booking.amount != null)
                Expanded(child: _StatCol('Amount', '₹${booking.amount}', color: AppColors.auburn300)),
            ]),
          ],
        ],
      ),
    );
  }

  String? _fmt(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]}';
    } catch (_) { return iso; }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AppColors.ivory500),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: AppColors.ivory300, fontSize: 12)),
  ]);
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatCol(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: AppColors.ivory500, fontSize: 10)),
    const SizedBox(height: 2),
    Text(value, style: TextStyle(color: color ?? AppColors.ivory100, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final bool isDark;
  const _QuickActions({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1C1212) : Colors.white;
    final border = isDark ? const Color(0xFF2E1E1E) : const Color(0xFFECE4E0);
    final accent = isDark ? AppColors.auburn300 : AppColors.auburn500;

    return Row(children: [
      Expanded(child: _ActionTile(icon: Icons.favorite_rounded, label: 'Wishlist', accent: accent, cardBg: cardBg, border: border, onTap: () => context.push('/profile/saved'))),
      const SizedBox(width: 14),
      Expanded(child: _ActionTile(icon: Icons.book_online_rounded, label: 'My Bookings', accent: accent, cardBg: cardBg, border: border, onTap: () => context.push('/profile/bookings'))),
    ]);
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent, cardBg, border;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.accent, required this.cardBg, required this.border, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.lightImpact(); onTap(); },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatefulWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _float = Tween<double>(begin: -6, end: 6).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? const Color(0xFF1C1212) : Colors.white;
    final border = widget.isDark ? const Color(0xFF2E1E1E) : const Color(0xFFECE4E0);
    final textColor = widget.isDark ? AppColors.ivory50 : AppColors.ink900;
    final mutedColor = widget.isDark ? AppColors.ivory500 : AppColors.ink700;
    final accent = widget.isDark ? AppColors.auburn300 : AppColors.auburn500;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _float,
          builder: (context, child) => Transform.translate(offset: Offset(0, _float.value), child: child),
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
              ),
            ),
            child: Icon(Icons.bar_chart_rounded, color: accent.withValues(alpha: 0.7), size: 40),
          ),
        ),
        const SizedBox(height: 20),
        Text('No Bookings Yet', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Make your first booking to see analytics here.', textAlign: TextAlign.center, style: TextStyle(color: mutedColor, fontSize: 13, height: 1.5)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.push('/search'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent, foregroundColor: AppColors.ivory50,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          icon: const Icon(Icons.explore_rounded, size: 16),
          label: const Text('Explore Hostels', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final bool isDark;
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.isDark, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.ivory50 : AppColors.ink900;
    final mutedColor = isDark ? AppColors.ivory500 : AppColors.ink700;
    final accent = isDark ? AppColors.auburn300 : AppColors.auburn500;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: mutedColor.withValues(alpha: 0.5)),
          const SizedBox(height: 20),
          Text('Could not load dashboard', style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message.replaceFirst('Exception: ', ''), textAlign: TextAlign.center, style: TextStyle(color: mutedColor, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent, foregroundColor: AppColors.ivory50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ]),
      ),
    );
  }
}
