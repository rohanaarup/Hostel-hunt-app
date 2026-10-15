import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';
import 'package:rohii_hostel_hunt/features/auth/presentation/pages/login_page.dart';
import 'package:rohii_hostel_hunt/features/booking/domain/booking_request.dart';
import 'package:rohii_hostel_hunt/features/booking/presentation/providers/my_bookings_provider.dart';
import 'package:rohii_hostel_hunt/features/home/presentation/widgets/hostel_list_states.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

// ── Booking Requests ─────────────────────────────────────────────────────────

/// The signed-in student's bookings, from the server, one page at a time.
class BookingRequestsPage extends ConsumerStatefulWidget {
  const BookingRequestsPage({super.key});

  @override
  ConsumerState<BookingRequestsPage> createState() => _BookingRequestsPageState();
}

class _BookingRequestsPageState extends ConsumerState<BookingRequestsPage> {
  Future<void> _login() async {
    await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginPage(popOnSuccess: true)));
    if (!mounted) return;
    ref.invalidate(myBookingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(myBookingsProvider);
    final paging = ref.watch(myBookingsPagingProvider);
    final user = ref.watch(userProvider);
    final loggedOut = !user.isLoading && !user.hasError && user.valueOrNull == null;
    final count = bookings.valueOrNull?.length ?? 0;

    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.appBackground(isDark),
        body: Column(
          children: [
            _SubHeader(
              title: 'Booking Requests',
              subtitle: loggedOut
                  ? 'Log in to see them'
                  : '$count${paging.hasMore ? '+' : ''} booking request${count == 1 && !paging.hasMore ? '' : 's'}',
              isDark: isDark,
            ),
            Expanded(child: _body(isDark, bookings, paging, loggedOut)),
          ],
        ),
      ),
    );
  }

  Widget _body(bool isDark, AsyncValue<List<BookingRequest>> bookings, HostelPaging paging, bool loggedOut) {
    if (loggedOut) {
      return _Message(
        icon: Icons.assignment_outlined,
        title: 'Log in to see your booking requests',
        message: 'Your requests are kept with your account.',
        isDark: isDark,
        action: FilledButton(onPressed: _login, child: const Text('Log in')),
      );
    }
    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => HostelListErrorState(
        message: userMessageOf(error),
        isDark: isDark,
        onRetry: () => ref.read(myBookingsProvider.notifier).refresh(),
      ),
      data: (list) {
        if (list.isEmpty) {
          return _Message(
            icon: Icons.assignment_outlined,
            title: 'No booking requests yet',
            message: 'When you book a bed, your request and its status show up here.',
            isDark: isDark,
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(myBookingsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: list.length + 1,
            itemBuilder: (context, i) {
              if (i == list.length) {
                // Built only when the end of the list comes into view: time for the next page.
                final canLoadMore = paging.hasMore && !paging.loadingMore && paging.loadMoreError == null;
                if (canLoadMore) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) ref.read(myBookingsProvider.notifier).loadMore();
                  });
                }
                return HostelListFooter(
                  loading: paging.hasMore && paging.loadMoreError == null,
                  error: paging.loadMoreError,
                  isDark: isDark,
                  onRetry: () => ref.read(myBookingsProvider.notifier).loadMore(),
                );
              }
              return _BookingCard(booking: list[i], isDark: isDark);
            },
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool isDark;
  final Widget? action;
  const _Message({required this.icon, required this.title, required this.message, required this.isDark, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.auburn500.withValues(alpha: 0.6)),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 14, height: 1.5)),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingRequest booking;
  final bool isDark;
  const _BookingCard({required this.booking, required this.isDark});

  Color get _statusColor {
    switch (booking.status) {
      case BookingRequestStatus.pending:
        return AppColors.warning;
      case BookingRequestStatus.confirmed:
      case BookingRequestStatus.paid:
        return AppColors.success;
      case BookingRequestStatus.cancelled:
      case BookingRequestStatus.rejected:
        return AppColors.error;
      case BookingRequestStatus.unknown:
        return AppColors.textSecondary(isDark);
    }
  }

  IconData get _statusIcon {
    switch (booking.status) {
      case BookingRequestStatus.pending:
        return Icons.schedule_rounded;
      case BookingRequestStatus.confirmed:
      case BookingRequestStatus.paid:
        return Icons.check_circle_rounded;
      case BookingRequestStatus.cancelled:
      case BookingRequestStatus.rejected:
        return Icons.cancel_rounded;
      case BookingRequestStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitted = booking.submittedOn;
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
                Text(booking.statusLabel,
                    style: TextStyle(color: _statusColor, fontSize: 13, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (submitted.isNotEmpty)
                  Text('Submitted: $submitted',
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (booking.roomLabel.isNotEmpty)
                      _InfoChip(label: booking.roomLabel, icon: Icons.bed_rounded, isDark: isDark),
                    if (booking.amountLabel.isNotEmpty)
                      _InfoChip(label: booking.amountLabel, icon: Icons.currency_rupee_rounded, isDark: isDark, isOrange: true),
                    if (booking.paymentMode == 'online' || booking.paymentMode == 'offline')
                      _InfoChip(
                        label: booking.paymentMode == 'online' ? 'Online payment' : 'Pay at hostel',
                        icon: Icons.payments_rounded,
                        isDark: isDark,
                      ),
                  ],
                ),
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

