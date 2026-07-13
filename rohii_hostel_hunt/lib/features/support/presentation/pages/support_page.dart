import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';
import 'package:rohii_hostel_hunt/shared/widgets/sub_header.dart';

// ── Support & Help ───────────────────────────────────────────────────────────

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const _faqs = [
    _FAQ('How do I book a hostel?', 'Browse hostels on the home screen, open a hostel detail, and tap "Book Now" to submit a booking request.'),
    _FAQ('Can I cancel my booking?', 'Yes, go to Booking Requests → find your booking → tap Cancel. Cancellation policy varies by hostel.'),
    _FAQ('How is my payment processed?', 'Payments are made directly to the hostel owner. Hostel Hunt facilitates the connection only.'),
    _FAQ('What if the hostel does not match the listing?', 'Use the Report Issue option below or contact our support team immediately.'),
    _FAQ('How do I reset my password?', 'Go to the login screen and tap "Forgot Password" to receive a reset link via email.'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.appBackground(isDark),
        body: Column(
          children: [
            SubHeader(title: 'Support & Help', subtitle: 'We are here to help you', isDark: isDark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Quick actions
                  Row(children: [
                    Expanded(child: _SupportAction(icon: Icons.chat_bubble_outline_rounded, label: 'Live Chat',
                        color: AppColors.auburn500, isDark: isDark, onTap: () => _snack(context, 'Live Chat'))),
                    const SizedBox(width: 10),
                    Expanded(child: _SupportAction(icon: Icons.email_outlined, label: 'Email Us',
                        color: const Color(0xFF1565C0), isDark: isDark, onTap: () => _snack(context, 'Email'))),
                    const SizedBox(width: 10),
                    Expanded(child: _SupportAction(icon: Icons.flag_outlined, label: 'Report',
                        color: AppColors.error, isDark: isDark, onTap: () => _snack(context, 'Report'))),
                  ]),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text('FREQUENTLY ASKED QUESTIONS',
                        style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                  ),
                  ..._faqs.map((f) => _FAQTile(faq: f, isDark: isDark)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.auburn500, AppColors.auburn700],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: AppColors.auburn500.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: Row(children: [
                      const Icon(Icons.support_agent_rounded, color: AppColors.ivory50, size: 28),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Need more help?', style: TextStyle(color: AppColors.ivory50, fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('Contact us at support@hostelhunt.in', style: TextStyle(color: AppColors.ivory50.withValues(alpha: 0.8), fontSize: 12)),
                      ])),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.ivory50, size: 16),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String label) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label — coming soon!', style: const TextStyle(color: AppColors.ivory50, fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.auburn500,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ));
  }
}

class _SupportAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  const _SupportAction({required this.icon, required this.label, required this.color, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _FAQ { final String q, a; const _FAQ(this.q, this.a); }

class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  final bool isDark;
  const _FAQTile({required this.faq, required this.isDark});
  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(widget.isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isDark ? AppColors.ivory700 : AppColors.ivory300, width: 0.8),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _open = !_open); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Expanded(child: Text(widget.faq.q,
                  style: TextStyle(color: AppColors.textHeading(widget.isDark), fontSize: 14, fontWeight: FontWeight.w600))),
              Icon(_open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.auburn500, size: 22),
            ]),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(widget.faq.a,
                style: TextStyle(color: AppColors.textSecondary(widget.isDark), fontSize: 13, height: 1.5)),
          ),
      ]),
    );
  }
}

