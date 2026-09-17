import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/features/dashboard/models/dashboard_stats_model.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// RecentActivityListWidget
/// Ranked timeline list of up to 5 recent bookings.
/// Includes a status filter chip at the top.
class RecentActivityListWidget extends StatefulWidget {
  final List<RecentBookingItem> items;
  final bool isDark;

  const RecentActivityListWidget({
    super.key,
    required this.items,
    required this.isDark,
  });

  @override
  State<RecentActivityListWidget> createState() =>
      _RecentActivityListWidgetState();
}

class _RecentActivityListWidgetState extends State<RecentActivityListWidget> {
  String _selectedFilter = 'All';
  static const _filters = ['All', 'Pending', 'Confirmed', 'Paid', 'Cancelled'];

  List<RecentBookingItem> get _filtered {
    if (_selectedFilter == 'All') return widget.items;
    return widget.items
        .where((b) =>
            b.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.emerald500;
      case 'paid':
        return AppColors.emerald300;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary(widget.isDark);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'paid':
        return Icons.verified_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'rejected':
        return Icons.block_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = AppColors.textHeading(isDark);
    final textMuted = AppColors.textSecondary(isDark);
    final cardBg = AppColors.cardBg(isDark);
    final accent = isDark ? AppColors.auburn300 : AppColors.auburn500;
    final filtered = _filtered;

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
          // ── Header + filter chip row ──────────────────────────
          Row(
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Filter dropdown chip
              _FilterChip(
                value: _selectedFilter,
                options: _filters,
                isDark: isDark,
                onChanged: (v) => setState(() => _selectedFilter = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── List rows ─────────────────────────────────────────
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No $_selectedFilter bookings yet',
                  style: TextStyle(color: textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ...List.generate(filtered.length, (i) {
              final b = filtered[i];
              final color = _statusColor(b.status);
              final isLast = i == filtered.length - 1;
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Index number
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1 < 10 ? '0' : ''}${i + 1}',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Status icon circle
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_statusIcon(b.status),
                            size: 14, color: color),
                      ),
                      const SizedBox(width: 12),
                      // Hostel name + date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.hostelName ?? 'Hostel',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (b.hostelCity != null)
                              Text(
                                b.hostelCity!,
                                style: TextStyle(
                                    color: textMuted, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      // Amount + date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (b.amount != null)
                            Text(
                              '₹${b.amount}',
                              style: TextStyle(
                                color: accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          Text(
                            _formatDate(b.createdAt),
                            style:
                                TextStyle(color: textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 46, top: 10, bottom: 10),
                      child: Divider(
                        color: AppColors.divider(isDark),
                        height: 1,
                        thickness: 1,
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

/// Compact filter chip dropdown.
class _FilterChip extends StatelessWidget {
  final String value;
  final List<String> options;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _FilterChip({
    required this.value,
    required this.options,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final rect = context.findRenderObject() as RenderBox?;
        if (rect == null) return;
        final offset = rect.localToGlobal(Offset.zero);
        final selected = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
              offset.dx, offset.dy + rect.size.height + 4, 0, 0),
          color: AppColors.cardBg(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          items: options
              .map((o) => PopupMenuItem(
                    value: o,
                    child: Text(
                      o,
                      style: TextStyle(
                        color: AppColors.textHeading(isDark),
                        fontSize: 13,
                        fontWeight: o == value
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ))
              .toList(),
        );
        if (selected != null) onChanged(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.chipInactiveBg(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.cardBorder(isDark), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Status: $value',
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.textSecondary(isDark)),
          ],
        ),
      ),
    );
  }
}
