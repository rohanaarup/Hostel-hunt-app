import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/pages/payment_success_screen.dart';

enum _PollState { waiting, failed, timedOut }

/// Shown right after a UPI intent is launched. Polls the backend's payment
/// status endpoint since Flutter cannot know synchronously whether the
/// student actually completed the payment in their UPI app.
class PaymentConfirmingScreen extends StatefulWidget {
  final String paymentId;

  const PaymentConfirmingScreen({super.key, required this.paymentId});

  @override
  State<PaymentConfirmingScreen> createState() => _PaymentConfirmingScreenState();
}

class _PaymentConfirmingScreenState extends State<PaymentConfirmingScreen> {
  final ApiService _api = ApiService();
  Timer? _timer;
  _PollState _state = _PollState.waiting;
  int _attempts = 0;

  // ~30 attempts * 2.5s ≈ 75s before giving up — UPI confirmation can be
  // genuinely slow and isn't always a failure.
  static const int _maxAttempts = 30;
  static const Duration _interval = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(_interval, (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (!mounted || _state != _PollState.waiting) return;
    _attempts++;

    final res = await _api.authGetRaw('/payments/status/${widget.paymentId}/');
    if (!mounted || _state != _PollState.waiting) return;

    if (res.statusCode == 200 && res.body is Map) {
      final status = (res.body as Map)['status'] as String?;
      if (status == 'SUCCESS') {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
        );
        return;
      }
      if (status == 'FAILED') {
        _timer?.cancel();
        setState(() => _state = _PollState.failed);
        return;
      }
    }

    if (_attempts >= _maxAttempts) {
      _timer?.cancel();
      setState(() => _state = _PollState.timedOut);
    }
  }

  /// Returning `true` tells the payment-method screen to create a fresh
  /// order — this payment is terminal (FAILED) or too stale to retry as-is.
  void _retry() {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _state != _PollState.waiting,
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
            child: Padding(
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
    switch (_state) {
      case _PollState.waiting:
        return [
          const CircularProgressIndicator(color: Colors.orange),
          const SizedBox(height: 24),
          Text(
            "Waiting for your payment to confirm...",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: isDark ? AppColors.ivory50 : AppColors.ink900),
          ),
          const SizedBox(height: 8),
          Text(
            "Please complete the payment in your UPI app if you haven't already.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.ivory300 : AppColors.ink700),
          ),
        ];
      case _PollState.failed:
        return [
          Icon(Icons.cancel_rounded, color: AppColors.error, size: 64),
          const SizedBox(height: 24),
          Text(
            "Payment Failed",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.ivory50 : AppColors.ink900),
          ),
          const SizedBox(height: 8),
          Text(
            "Your payment could not be completed. You can try again.",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? AppColors.ivory300 : AppColors.ink700),
          ),
          const SizedBox(height: 24),
          _retryButton(isDark),
        ];
      case _PollState.timedOut:
        return [
          const Icon(Icons.hourglass_bottom_rounded, color: Colors.orange, size: 64),
          const SizedBox(height: 24),
          Text(
            "Still Waiting",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.ivory50 : AppColors.ink900),
          ),
          const SizedBox(height: 8),
          Text(
            "This is taking longer than expected. Your payment may still confirm shortly — check back later, or try again.",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? AppColors.ivory300 : AppColors.ink700),
          ),
          const SizedBox(height: 24),
          _retryButton(isDark),
        ];
    }
  }

  Widget _retryButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _retry,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.auburn300 : AppColors.auburn500,
          foregroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text("Try Again", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
