import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';

// ── Booking Requests ─────────────────────────────────────────────────────────

enum _BookingStatus { pending, approved, rejected }

class _Booking {
  final String hostelName;
  final String location;
  final String price;
  final String roomType;
  final String submittedOn;
  final _BookingStatus status;
  const _Booking({
    required this.hostelName, required this.location, required this.price,
    required this.roomType, required this.submittedOn, required this.status,
  });
}

const _kBookings = [
  _Booking(hostelName: 'Sri Lakshmi Hostels', location: 'Kukatpally, Hyderabad',
      price: '₹6,500/mo', roomType: '3-Sharing AC Room', submittedOn: 'May 10, 2026', status: _BookingStatus.pending),
  _Booking(hostelName: 'Green View Residency', location: 'Gachibowli, Hyderabad',
      price: '₹8,000/mo', roomType: '2-Sharing Premium', submittedOn: 'Apr 28, 2026', status: _BookingStatus.approved),
  _Booking(hostelName: 'Student Hive', location: 'Madhapur, Hyderabad',
      price: '₹5,500/mo', roomType: '4-Sharing Non-AC', submittedOn: 'Apr 15, 2026', status: _BookingStatus.rejected),
];

class BookingRequestsPage extends StatelessWidget {
  const BookingRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.appBackground(isDark),
        body: Column(
          children: [
            _SubHeader(title: 'Booking Requests', subtitle: '${_kBookings.length} requests total', isDark: isDark),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                physics: const BouncingScrollPhysics(),
                itemCount: _kBookings.length,
                itemBuilder: (context, i) => _BookingCard(booking: _kBookings[i], isDark: isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final _Booking booking;
  final bool isDark;
  const _BookingCard({required this.booking, required this.isDark});

  Color get _statusColor {
    switch (booking.status) {
      case _BookingStatus.pending: return AppColors.warning;
      case _BookingStatus.approved: return AppColors.success;
      case _BookingStatus.rejected: return AppColors.error;
    }
  }

  String get _statusLabel {
    switch (booking.status) {
      case _BookingStatus.pending: return 'Pending';
      case _BookingStatus.approved: return 'Approved';
      case _BookingStatus.rejected: return 'Rejected';
    }
  }

  IconData get _statusIcon {
    switch (booking.status) {
      case _BookingStatus.pending: return Icons.schedule_rounded;
      case _BookingStatus.approved: return Icons.check_circle_rounded;
      case _BookingStatus.rejected: return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor.withValues(alpha: 0.2), width: 0.8),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar at top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, size: 16, color: _statusColor),
                const SizedBox(width: 6),
                Text(_statusLabel,
                    style: TextStyle(color: _statusColor, fontSize: 13, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('Submitted: ${booking.submittedOn}',
                    style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.hostelName,
                    style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.location_on_rounded, size: 13, color: AppColors.auburn500),
                  const SizedBox(width: 3),
                  Flexible(child: Text(booking.location, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 13))),
                ]),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(label: booking.roomType, icon: Icons.bed_rounded, isDark: isDark),
                    const SizedBox(width: 8),
                    _InfoChip(label: booking.price, icon: Icons.currency_rupee_rounded, isDark: isDark, isOrange: true),
                  ],
                ),
                if (booking.status == _BookingStatus.pending) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => HapticFeedback.lightImpact(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => HapticFeedback.lightImpact(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.auburn500, foregroundColor: AppColors.ivory50,
                          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final bool isOrange;
  const _InfoChip({required this.label, required this.icon, required this.isDark, this.isOrange = false});

  @override
  Widget build(BuildContext context) {
    final color = isOrange ? AppColors.auburn500 : AppColors.textSecondary(isDark);
    final bg = isOrange ? AppColors.auburn500.withValues(alpha: 0.1) : AppColors.chipInactiveBg(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Shared sub-page header ────────────────────────────────────────────────────
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
          colors: isDark ? [AppColors.ivory900, AppColors.ivory900] : [AppColors.ivory100, AppColors.ivory50],
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
                color: isDark ? AppColors.ivory700 : AppColors.ivory50.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.ivory50.withValues(alpha: 0.08) : AppColors.ivory300, width: 0.8),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textHeading(isDark)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            Text(subtitle, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12)),
          ])),
        ],
      ),
    );
  }
}

