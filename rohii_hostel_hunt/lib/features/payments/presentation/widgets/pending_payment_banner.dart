import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/features/payments/data/pending_payment_store.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/pages/payment_confirming_screen.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/pages/payment_screen.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// Shown on the home screen while a payment started on this phone has not been confirmed: the app was
/// closed (or killed by the phone) while the student was in the UPI app. One tap asks the server what
/// became of it, so nobody has to wonder whether they paid.
class PendingPaymentBanner extends ConsumerWidget {
  const PendingPaymentBanner({super.key});

  Future<void> _check(BuildContext context, WidgetRef ref, PendingPayment pending) async {
    final navigator = Navigator.of(context);
    final startAgain = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => PaymentConfirmingScreen(paymentId: pending.paymentId)),
    );
    // `true` means the server said the payment failed: a fresh payment for the booking is safe.
    if (startAgain == true) {
      navigator.push(MaterialPageRoute(builder: (_) => PaymentScreen(bookingId: pending.bookingId)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingPaymentProvider);
    if (pending == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_bottom_rounded, size: 18, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A payment is waiting to be confirmed.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark)),
            ),
          ),
          TextButton(onPressed: () => _check(context, ref, pending), child: const Text('Check')),
        ],
      ),
    );
  }
}
