import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/booking_provider.dart';

class BookingSummaryScreen extends ConsumerStatefulWidget {
  final Hostel hostel;
  final String floor;
  final String room;
  final String bedLabel;

  const BookingSummaryScreen({
    super.key,
    required this.hostel,
    required this.floor,
    required this.room,
    required this.bedLabel,
  });

  @override
  ConsumerState<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  @override
  void initState() {
    super.initState();
    // Reset state when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).reset();
    });
  }

  void _submitBooking() {
    // Room ID is hardcoded for mock bed selection until API provides room models in the UI
    final dummyRoomId = "00000000-0000-0000-0000-000000000000";

    ref.read(bookingProvider.notifier).submitBooking(
      hostelId: widget.hostel.id,
      roomId: dummyRoomId,
      roomName: "Room ${widget.room}",
      floorNumber: widget.floor,
      roomNumber: widget.room,
      bedNumber: widget.bedLabel,
      checkInDate: DateTime.now().toIso8601String().split('T')[0],
    );
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.hostel.contactPhone;
    final message = "Hello, I just requested a booking for ${widget.bedLabel} in Room ${widget.room} at ${widget.hostel.name} via Hostel Hunt. I'd like to pay offline.";
    final uri = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookingState = ref.watch(bookingProvider);

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
          child: bookingState.status == BookingStatus.success
              ? _buildSuccessView(isDark)
              : _buildSummaryView(isDark, bookingState),
        ),
      ),
    );
  }

  Widget _buildSummaryView(bool isDark, BookingState state) {
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
              _buildDetailRow("Floor", widget.floor, isDark),
              const SizedBox(height: 8),
              _buildDetailRow("Room", widget.room, isDark),
              const SizedBox(height: 8),
              _buildDetailRow("Bed", widget.bedLabel, isDark),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (state.status == BookingStatus.error) ...[
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
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: state.status == BookingStatus.loading ? null : _submitBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.auburn500,
              foregroundColor: AppColors.ivory50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: state.status == BookingStatus.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.ivory50,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Send Info & Pay Offline",
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
          "Your request for ${widget.bedLabel} in Room ${widget.room} (${widget.floor}) has been submitted to the hostel owner.",
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
