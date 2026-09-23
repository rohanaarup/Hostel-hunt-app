import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/widgets/payment_method_card.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/pages/payment_confirming_screen.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/pages/payment_success_screen.dart';

/// Real payment-method screen: calls the backend to create a Razorpay order
/// for [bookingId], then lets the student pay via a UPI app or card.
class PaymentScreen extends StatefulWidget {
  final String bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _api = ApiService();
  late final Razorpay _razorpay;

  bool _loadingOrder = true;
  bool _actionInProgress = false;
  String? _orderError;

  String? _paymentId;
  String _amount = '';

  String _selectedMethod = 'gpay';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onCardSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onCardError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _createOrder();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  String _errorFrom(RawApiResponse res, String fallback) {
    final body = res.body;
    if (body is Map && body['error'] is String) return body['error'] as String;
    return res.message.isNotEmpty ? res.message : fallback;
  }

  Future<void> _createOrder() async {
    setState(() {
      _loadingOrder = true;
      _orderError = null;
    });

    final res = await _api.authPostRaw('/payments/create-order/', {
      'booking_id': widget.bookingId,
    });

    if (!mounted) return;

    if ((res.statusCode == 200 || res.statusCode == 201) && res.body is Map) {
      final body = res.body as Map;
      setState(() {
        _paymentId = body['payment_id'] as String?;
        _amount = body['amount']?.toString() ?? '';
        _loadingOrder = false;
      });
    } else {
      setState(() {
        _orderError = _errorFrom(res, 'Failed to start payment. Please try again.');
        _loadingOrder = false;
      });
    }
  }

  Future<void> _payWithUpi(String app) async {
    if (_paymentId == null || _actionInProgress) return;
    setState(() => _actionInProgress = true);

    final res = await _api.authPostRaw('/payments/initiate-upi-intent/', {
      'payment_id': _paymentId,
      'app': app,
    });

    if (!mounted) return;
    setState(() => _actionInProgress = false);

    if (res.statusCode == 200 && res.body is Map) {
      final intentUrl = (res.body as Map)['intent_url'] as String?;
      if (intentUrl == null) {
        _showSnack('No payment link returned. Please try again.');
        return;
      }

      final uri = Uri.parse(intentUrl);
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        _showSnack(
          'No ${_appLabel(app)} app found on this device. Try a different UPI app, or pay by card.',
        );
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;

      // Flutter must navigate to the confirming screen right after launching
      // the intent — it cannot know the outcome until the poll resolves it.
      final retry = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentConfirmingScreen(paymentId: _paymentId!),
        ),
      );
      if (retry == true) {
        await _createOrder();
      }
    } else {
      _showSnack(_errorFrom(res, 'Failed to start UPI payment. Please try again.'));
    }
  }

  Future<void> _payWithCard() async {
    if (_paymentId == null || _actionInProgress) return;
    setState(() => _actionInProgress = true);

    final res = await _api.authPostRaw('/payments/initiate-card-checkout/', {
      'payment_id': _paymentId,
    });

    if (!mounted) return;
    setState(() => _actionInProgress = false);

    if (res.statusCode == 200 && res.body is Map) {
      final config = (res.body as Map)['checkout_config'];
      if (config is Map) {
        _razorpay.open(Map<String, dynamic>.from(config));
      } else {
        _showSnack('Invalid payment configuration returned. Please try again.');
      }
    } else {
      _showSnack(_errorFrom(res, 'Failed to start card payment. Please try again.'));
    }
  }

  void _onCardSuccess(PaymentSuccessResponse response) async {
    if (_paymentId == null) return;

    final res = await _api.authPostRaw('/payments/verify/', {
      'payment_id': _paymentId,
      'razorpay_payment_id': response.paymentId,
      'razorpay_signature': response.signature,
    });

    if (!mounted) return;

    final body = res.body;
    final verified = res.statusCode == 200 && body is Map && body['success'] == true;
    if (verified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
      );
    } else {
      _showSnack(_errorFrom(res, 'Payment verification failed. Please try again.'));
    }
  }

  void _onCardError(PaymentFailureResponse response) {
    _showSnack('Card payment ${response.message ?? "failed"}. You can try again.');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _showSnack('Selected external wallet: ${response.walletName}');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _appLabel(String app) {
    switch (app) {
      case 'gpay':
        return 'Google Pay';
      case 'phonepe':
        return 'PhonePe';
      case 'paytm':
        return 'Paytm';
      default:
        return app;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _loadingOrder
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : _orderError != null
                ? _buildOrderError(isDark)
                : _buildMethodPicker(isDark),
      ),
    );
  }

  Widget _buildOrderError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _orderError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.ivory50 : AppColors.ink900),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _createOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.auburn300 : AppColors.auburn500,
                  foregroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Retry"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodPicker(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Amount to pay: ₹$_amount",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.ivory50 : AppColors.ink900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select Payment Method",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.ivory50 : AppColors.ink900,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                PaymentMethodCard(
                  value: 'gpay',
                  title: 'Google Pay',
                  iconUrl: 'https://cdn-icons-png.flaticon.com/512/6124/6124998.png',
                  fallbackIcon: Icons.g_mobiledata,
                  fallbackColor: Colors.blue,
                  groupValue: _selectedMethod,
                  onChanged: (val) => setState(() => _selectedMethod = val),
                ),
                const SizedBox(height: 12),
                PaymentMethodCard(
                  value: 'phonepe',
                  title: 'PhonePe',
                  iconUrl: 'https://uxwing.com/wp-content/themes/uxwing/download/brands-and-social-media/phonepe-logo-icon.png',
                  fallbackIcon: Icons.mobile_friendly,
                  fallbackColor: Colors.purple,
                  groupValue: _selectedMethod,
                  onChanged: (val) => setState(() => _selectedMethod = val),
                ),
                const SizedBox(height: 12),
                PaymentMethodCard(
                  value: 'paytm',
                  title: 'Paytm',
                  iconUrl: 'https://cdn.iconscout.com/icon/free/png-256/paytm-226448.png',
                  fallbackIcon: Icons.payment,
                  fallbackColor: Colors.lightBlue,
                  groupValue: _selectedMethod,
                  onChanged: (val) => setState(() => _selectedMethod = val),
                ),
                const SizedBox(height: 12),
                PaymentMethodCard(
                  value: 'card',
                  title: 'Credit / Debit Card',
                  iconUrl: 'https://cdn-icons-png.flaticon.com/512/633/633611.png',
                  fallbackIcon: Icons.credit_card,
                  fallbackColor: Colors.orange,
                  groupValue: _selectedMethod,
                  onChanged: (val) => setState(() => _selectedMethod = val),
                  isCard: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _actionInProgress
                  ? null
                  : () => _selectedMethod == 'card' ? _payWithCard() : _payWithUpi(_selectedMethod),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.auburn300 : AppColors.auburn500,
                foregroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _actionInProgress
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Pay Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
