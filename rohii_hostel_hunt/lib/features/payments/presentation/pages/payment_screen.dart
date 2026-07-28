import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/features/payments/presentation/widgets/payment_method_card.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'google_pay';

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      value: 'google_pay',
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
                  onPressed: () {
                    // Process Payment
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.auburn300 : AppColors.auburn500,
                    foregroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Next ->",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
