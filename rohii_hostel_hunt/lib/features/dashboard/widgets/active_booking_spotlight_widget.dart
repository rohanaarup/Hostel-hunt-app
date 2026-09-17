import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/features/dashboard/models/dashboard_stats_model.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// ActiveBookingSpotlightWidget
/// Dark card spotlighting the user's most recent confirmed/paid booking.
/// Mirrors the Ref-2 "Mark Johnson" dark balance card pattern.
class ActiveBookingSpotlightWidget extends StatelessWidget {
  final ActiveBooking booking;
  final bool isDark;

  const ActiveBookingSpotlightWidget({
    super.key,
    required this.booking,
    required this.isDark,
  });

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed':
        return AppColors.emerald500;
      case 'paid':
        return AppColors.emerald300;
      default:
        return AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (booking.status) {
      case 'confirmed':
        return '● Confirmed';
      case 'paid':
        return '● Paid';
      default:
        return '● ${booking.status}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always rendered with dark-card palette (spotlight style)
    const bgStart = AppColors.ivory900;
    const bgEnd = Color(0xFF3B2A2A); // deep auburn-tinted dark

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [bgStart, bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.auburn700.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.auburn300.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: AppColors.auburn300,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Booking',
                      style: TextStyle(
                        color: AppColors.ivory500,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      booking.hostelName ?? 'Unknown Hostel',
                      style: const TextStyle(
                        color: AppColors.ivory50,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── City + Room info row ─────────────────────────────
          Row(
            children: [
              if (booking.hostelCity != null)
                _InfoTile(
                  icon: Icons.location_on_rounded,
                  label: booking.hostelCity!,
                  color: AppColors.ivory300,
                ),
              if (booking.roomName != null || booking.roomNumber != null) ...[
                const SizedBox(width: 16),
                _InfoTile(
                  icon: Icons.door_front_door_rounded,
                  label: [booking.roomName, booking.roomNumber]
                      .where((s) => s != null)
                      .join(' • '),
                  color: AppColors.ivory300,
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // ── Divider ─────────────────────────────────────────
          Divider(
            color: AppColors.ivory700.withValues(alpha: 0.5),
            thickness: 1,
          ),
          const SizedBox(height: 16),

          // ── Date + amount row ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Check-in',
                  value: _formatDate(booking.checkInDate) ?? '—',
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Check-out',
                  value: _formatDate(booking.checkOutDate) ?? 'Open',
                ),
              ),
              if (booking.amount != null)
                Expanded(
                  child: _StatColumn(
                    label: 'Amount',
                    value: '₹${booking.amount}',
                    valueColor: AppColors.auburn300,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String? _formatDate(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoTile(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatColumn(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ivory500,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.ivory100,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
