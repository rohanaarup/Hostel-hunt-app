import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';
import 'package:rohii_hostel_hunt/shared/widgets/sub_header.dart';

// ── Payments & Rentals ───────────────────────────────────────────────────────

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  static const _txns = [
    _Txn(title: 'Rent — May 2026', hostel: 'Sri Lakshmi Hostels', date: 'May 1, 2026', amount: '₹6,500', status: _TxnStatus.paid),
    _Txn(title: 'Security Deposit', hostel: 'Sri Lakshmi Hostels', date: 'Jan 12, 2026', amount: '₹13,000', status: _TxnStatus.paid),
    _Txn(title: 'Rent — Apr 2026', hostel: 'Sri Lakshmi Hostels', date: 'Apr 1, 2026', amount: '₹6,500', status: _TxnStatus.paid),
    _Txn(title: 'Rent — Jun 2026', hostel: 'Sri Lakshmi Hostels', date: 'Due Jun 1, 2026', amount: '₹6,500', status: _TxnStatus.due),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.appBackground(isDark),
        body: Column(
          children: [
            SubHeader(title: 'Payments & Rentals', subtitle: '${_txns.length} transactions', isDark: isDark),
            // Summary card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.auburn500, AppColors.auburn700],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.auburn500.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Active Rental', style: TextStyle(color: AppColors.ivory50, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    const Text('Sri Lakshmi Hostels', style: TextStyle(color: AppColors.ivory50, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('₹6,500/mo', style: TextStyle(color: AppColors.ivory50.withValues(alpha: 0.85), fontSize: 13)),
                  ]),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.ivory50.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Active', style: TextStyle(color: AppColors.ivory50, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Row(children: [
                Text('Transaction History', style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                physics: const BouncingScrollPhysics(),
                itemCount: _txns.length,
                itemBuilder: (context, i) => _TxnCard(txn: _txns[i], isDark: isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TxnStatus { paid, due }

class _Txn {
  final String title, hostel, date, amount;
  final _TxnStatus status;
  const _Txn({required this.title, required this.hostel, required this.date, required this.amount, required this.status});
}

class _TxnCard extends StatelessWidget {
  final _Txn txn;
  final bool isDark;
  const _TxnCard({required this.txn, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPaid = txn.status == _TxnStatus.paid;
    final statusColor = isPaid ? AppColors.success : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.ivory700 : AppColors.ivory300, width: 0.8),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(isPaid ? Icons.check_circle_outline_rounded : Icons.schedule_rounded, color: statusColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(txn.title, style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 14, fontWeight: FontWeight.w600)),
          Text(txn.hostel, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12)),
          Text(txn.date, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(txn.amount, style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(isPaid ? 'Paid' : 'Due', style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }
}

