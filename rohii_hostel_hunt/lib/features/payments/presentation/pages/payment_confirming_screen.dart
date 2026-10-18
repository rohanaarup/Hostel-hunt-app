import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/features/payments/data/payment_status_poller.dart';
import 'package:rohii_hostel_hunt/features/payments/data/pending_payment_store.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/pages/payment_success_screen.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

enum _ScreenState { waiting, checking, failed, undecided }

/// Shown after the student leaves for a UPI app or the card sheet, and again when the app is reopened
/// with a payment still unconfirmed. The server is the only judge: this screen asks it, one question
/// at a time, and shows what it says.
///
/// The screen pops `true` only when the server has said the payment FAILED (a new payment is then
/// safe to start); `false` / null means "leave it, the payment may still confirm".
class PaymentConfirmingScreen extends ConsumerStatefulWidget {
  final String paymentId;

  /// Optional hook for tests: a poller with a fake clock and a fake server.
  final PaymentStatusPoller? poller;

  const PaymentConfirmingScreen({super.key, required this.paymentId, this.poller});

  @override
  ConsumerState<PaymentConfirmingScreen> createState() => _PaymentConfirmingScreenState();
}

class _PaymentConfirmingScreenState extends ConsumerState<PaymentConfirmingScreen> {
  late final PaymentStatusPoller _poller = widget.poller ?? PaymentStatusPoller(check: _fetchStatus);
  _ScreenState _state = _ScreenState.waiting;
  bool _stillPendingNote = false;

  @override
  void initState() {
    super.initState();
    _waitForServer();
  }

  Future<String?> _fetchStatus(String paymentId) async {
    final res = await ref.read(apiServiceProvider).authGetRaw('/payments/status/$paymentId/');
    if (res.statusCode == 200 && res.body is Map) {
      return (res.body as Map)['status'] as String?;
    }
    return null;
  }

  Future<void> _waitForServer() async {
    setState(() => _state = _ScreenState.waiting);
    final outcome = await _poller.run(widget.paymentId, isCancelled: () => !mounted);
    if (!mounted) return;
    await _show(outcome);
  }

  Future<void> _show(PaymentOutcome outcome) async {
    switch (outcome) {
      case PaymentOutcome.success:
        await ref.read(pendingPaymentProvider.notifier).clear();
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()));
      case PaymentOutcome.failed:
        await ref.read(pendingPaymentProvider.notifier).clear();
        if (!mounted) return;
        setState(() => _state = _ScreenState.failed);
      case PaymentOutcome.undecided:
        setState(() => _state = _ScreenState.undecided);
    }
  }

  /// "Try Again" never starts a new payment on its own: it first asks the server what became of this
  /// one. A payment that turned out SUCCESS goes to the success screen; one that is FAILED lets the
  /// payment screen create a new order; one still undecided stays here, so the student is never
  /// charged twice for the same booking.
  Future<void> _tryAgain() async {
    setState(() {
      _state = _ScreenState.checking;
      _stillPendingNote = false;
    });
    final outcome = await _poller.checkOnce(widget.paymentId);
    if (!mounted) return;
    if (outcome == PaymentOutcome.failed) {
      await ref.read(pendingPaymentProvider.notifier).clear();
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }
    if (outcome == PaymentOutcome.undecided) {
      setState(() {
        _state = _ScreenState.undecided;
        _stillPendingNote = true;
      });
      return;
    }
    await _show(outcome);
  }

  /// Leave without deciding anything: the payment stays remembered and the home screen offers to
  /// check it again.
  void _checkLater() => Navigator.pop(context, false);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busy = _state == _ScreenState.waiting || _state == _ScreenState.checking;

    return PopScope(
      canPop: !busy,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
        appBar: AppBar(
          title: const Text("Confirming Payment"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildContent(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(bool isDark) {
    final titleColor = isDark ? AppColors.ivory50 : AppColors.ink900;
    final bodyColor = isDark ? AppColors.ivory300 : AppColors.ink700;
    switch (_state) {
      case _ScreenState.waiting:
      case _ScreenState.checking:
        return [
          const CircularProgressIndicator(color: Colors.orange),
          const SizedBox(height: 24),
          Text(
            _state == _ScreenState.checking ? "Checking your payment..." : "Waiting for your payment to confirm...",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: titleColor),
          ),
          const SizedBox(height: 8),
          Text(
            "Please complete the payment in your UPI app if you haven't already.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: bodyColor),
          ),
        ];
      case _ScreenState.failed:
        return [
          Icon(Icons.cancel_rounded, color: AppColors.error, size: 64),
          const SizedBox(height: 24),
          Text("Payment Failed", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 8),
          Text(
            "Your payment could not be completed. You can try again.",
            textAlign: TextAlign.center,
            style: TextStyle(color: bodyColor),
          ),
          const SizedBox(height: 24),
          _primaryButton(isDark, "Try Again", _tryAgain),
        ];
      case _ScreenState.undecided:
        return [
          const Icon(Icons.hourglass_bottom_rounded, color: Colors.orange, size: 64),
          const SizedBox(height: 24),
          Text("Still Waiting", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 8),
          Text(
            _stillPendingNote
                ? "The server has not confirmed this payment yet. Please do not pay again: if money was taken it will show up here shortly."
                : "This is taking longer than expected. Your payment may still confirm shortly. If money was taken, do not pay again.",
            textAlign: TextAlign.center,
            style: TextStyle(color: bodyColor),
          ),
          const SizedBox(height: 24),
          _primaryButton(isDark, "Check Again", _tryAgain),
          const SizedBox(height: 12),
          TextButton(onPressed: _checkLater, child: const Text("Check later")),
        ];
    }
  }

  Widget _primaryButton(bool isDark, String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.auburn300 : AppColors.auburn500,
          foregroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
