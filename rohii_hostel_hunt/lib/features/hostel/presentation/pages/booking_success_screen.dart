import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/room.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/booking_provider.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';
import 'package:rohii_hostel_hunt/features/auth/presentation/pages/login_page.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/pages/payment_screen.dart';

class BookingSummaryScreen extends ConsumerStatefulWidget {
  final Hostel hostel;
  final Room room;
  final String bedNumber; // raw numeric id, e.g. "3" — never "Bed 3"

  const BookingSummaryScreen({
    super.key,
    required this.hostel,
    required this.room,
    required this.bedNumber,
  });

  @override
  ConsumerState<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  final ApiService _api = ApiService();

  // True while the "Continue to Online Payment" path is driving the shared
  // bookingProvider — keeps its success state from popping the offline
  // WhatsApp success view underneath the online payment screens.
  bool _isOnlineFlow = false;
  String? _onlineError;

  String get _floorLabel => widget.room.floorNumber == 0 ? "Ground Floor" : "Floor ${widget.room.floorNumber}";
  String get _bedLabel => "Bed ${widget.bedNumber}";
  String get _roomLabel => widget.room.roomName.isNotEmpty ? widget.room.roomName : widget.room.roomNumber;

  @override
  void initState() {
    super.initState();
    // Reset state when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).reset();
    });
  }

  void _submitBooking() {
    final userProfile = ref.read(userProvider).valueOrNull;
    ref.read(bookingProvider.notifier).submitBooking(
      hostelId: widget.hostel.id,
      roomId: widget.room.roomId,
      roomName: _roomLabel,
      floorNumber: widget.room.floorNumber.toString(),
      roomNumber: widget.room.roomNumber,
      bedNumber: widget.bedNumber,
      checkInDate: DateTime.now().toIso8601String().split('T')[0],
      studentName: userProfile?.name ?? '',
      studentPhone: userProfile?.phone ?? '',
    );
  }

  Future<void> _startOnlinePayment() async {
    setState(() => _onlineError = null);

    // Booking creation only auto-links `student` when the request is
    // authenticated — an anonymous booking can never be attached to a user
    // afterwards, so login must happen before submitBooking(), not after.
    final loggedIn = await _api.isLoggedIn();
    if (!mounted) return;

    if (!loggedIn) {
      final loggedInNow = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage(popOnSuccess: true)),
      );
      if (!mounted) return;
      if (loggedInNow != true) {
        setState(() => _onlineError = 'Please log in to pay online.');
        return;
      }
    }

    setState(() => _isOnlineFlow = true);

    final userProfile = ref.read(userProvider).valueOrNull;
    await ref.read(bookingProvider.notifier).submitBooking(
      hostelId: widget.hostel.id,
      roomId: widget.room.roomId,
      roomName: _roomLabel,
      floorNumber: widget.room.floorNumber.toString(),
      roomNumber: widget.room.roomNumber,
      bedNumber: widget.bedNumber,
      checkInDate: DateTime.now().toIso8601String().split('T')[0],
      studentName: userProfile?.name ?? '',
      studentPhone: userProfile?.phone ?? '',
      paymentMode: 'online',
    );

    if (!mounted) return;
    final bookingState = ref.read(bookingProvider);

    if (bookingState.status != BookingStatus.success || bookingState.data == null) {
      setState(() {
        _isOnlineFlow = false;
        _onlineError = bookingState.errorMessage ?? 'Failed to create booking. Please try again.';
      });
      return;
    }

    final bookingId = bookingState.data!['id']?.toString();
    if (bookingId == null || bookingId.isEmpty) {
      setState(() {
        _isOnlineFlow = false;
        _onlineError = 'Booking was created but no booking ID was returned.';
      });
      return;
    }

    // Booking is created — reset the shared provider so a later return to
    // this screen (e.g. the student backs out of payment) shows a clean
    // summary view rather than a stuck "success"/"loading" state.
    ref.read(bookingProvider.notifier).reset();

    if (!mounted) return;
    setState(() => _isOnlineFlow = false);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(bookingId: bookingId)),
    );
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.hostel.contactPhone;
    final message = "Hello, I just requested a booking for $_bedLabel in Room $_roomLabel at ${widget.hostel.name} via Hostel Hunt. I'd like to pay offline.";
    final uri = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookingState = ref.watch(bookingProvider);
    final showOfflineSuccess = bookingState.status == BookingStatus.success && !_isOnlineFlow;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
      appBar: AppBar(
        title: const Text("Booking Summary"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: bookingState.status == BookingStatus.loading
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: showOfflineSuccess
              ? _buildSuccessView(isDark)
              : _buildSummaryView(isDark, bookingState),
        ),
      ),
    );
  }

  Widget _buildSummaryView(bool isDark, BookingState state) {
    final isBusy = state.status == BookingStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.ink900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.auburn500.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hostel: ${widget.hostel.name}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.ivory50 : AppColors.ink900,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow("Floor", _floorLabel, isDark),
              const SizedBox(height: 8),
              _buildDetailRow("Room", _roomLabel, isDark),
              const SizedBox(height: 8),
              _buildDetailRow("Bed", _bedLabel, isDark),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (state.status == BookingStatus.error && !_isOnlineFlow) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Text(
              "Booking Failed: ${state.errorMessage}",
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (_onlineError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Text(_onlineError!, style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: isBusy ? null : _submitBooking,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? AppColors.auburn300 : AppColors.auburn500, width: 2),
              foregroundColor: isDark ? AppColors.auburn300 : AppColors.auburn500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: (isBusy && !_isOnlineFlow)
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: isDark ? AppColors.auburn300 : AppColors.auburn500,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Send Info & Pay Offline",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isBusy ? null : _startOnlinePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.auburn300 : AppColors.auburn500,
              foregroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: (isBusy && _isOnlineFlow)
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: isDark ? AppColors.ink900 : AppColors.ivory50,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Continue to Online Payment",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.ivory300 : AppColors.ink700,
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? AppColors.ivory50 : AppColors.ink900,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "Booking Created!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.ivory50 : AppColors.ink900,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Your request for $_bedLabel in Room $_roomLabel ($_floorLabel) has been submitted to the hostel owner.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppColors.ivory300 : AppColors.ink700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _openWhatsApp,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text(
              "Contact Owner on WhatsApp",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Text(
            "Back to Home",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.auburn500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
