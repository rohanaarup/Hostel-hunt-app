import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/core/theme/colors.dart';
import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';

// Shared placeholder scaffold used by every profile sub-page.
class _SubPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String message;

  const _SubPage({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.background(isDark),
        appBar: AppBar(
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.orange, AppColors.orangeDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
          ),
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: iconColor.withValues(alpha: 0.2)),
                      ),
                      child: Icon(icon, size: 48, color: iconColor),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: TextStyle(
                          color: AppColors.textSecondary(isDark),
                          fontSize: 14,
                          height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        side: const BorderSide(
                            color: AppColors.orange, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                      ),
                      child: const Text('Go Back',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const _SubPage(
        title: 'Edit Profile',
        icon: Icons.edit_rounded,
        iconColor: AppColors.orange,
        message:
            'Update your name, photo, phone number and other personal details.',
      );
}

class SavedHostelsPage extends StatelessWidget {
  const SavedHostelsPage({super.key});
  @override
  Widget build(BuildContext context) => const _SubPage(
        title: 'Saved Hostels',
        icon: Icons.favorite_rounded,
        iconColor: Color(0xFFE91E63),
        message:
            'Your wishlisted hostels appear here. Start saving hostels you love!',
      );
}

class RecentActivityPage extends StatelessWidget {
  const RecentActivityPage({super.key});
  @override
  Widget build(BuildContext context) => const _SubPage(
        title: 'Recently Viewed',
        icon: Icons.history_rounded,
        iconColor: Color(0xFF7C4DFF),
        message:
            'Hostels you have recently browsed will show up here for quick access.',
      );
}

class BookingRequestsPage extends StatelessWidget {
  const BookingRequestsPage({super.key});
  @override
  Widget build(BuildContext context) => const _SubPage(
        title: 'Booking Requests',
        icon: Icons.assignment_rounded,
        iconColor: AppColors.orange,
        message:
            'Track pending, confirmed, and past booking requests from one place.',
      );
}

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});
  @override
  Widget build(BuildContext context) => const _SubPage(
        title: 'Preferences',
        icon: Icons.tune_rounded,
        iconColor: Color(0xFF00897B),
        message:
            'Set your hostel preferences — AC, gender type, location filters and more.',
      );
}

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});
  @override
  Widget build(BuildContext context) => const _SubPage(
        title: 'Payments & Rentals',
        icon: Icons.account_balance_wallet_rounded,
        iconColor: Color(0xFF1565C0),
        message:
            'View rental history, payment receipts and upcoming dues.',
      );
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});
  @override
  Widget build(BuildContext context) => const _SubPage(
        title: 'Support & Help',
        icon: Icons.help_outline_rounded,
        iconColor: Color(0xFF0288D1),
        message:
            'Browse FAQs, raise a support ticket or contact the Hostel Hunt team.',
      );
}

// Settings page — functional theme toggle
class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.background(isDark),
        appBar: AppBar(
          title: const Text('Settings',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.orange, AppColors.orangeDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
          ),
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            physics: const BouncingScrollPhysics(),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg(isDark),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.chipDark : AppColors.border,
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow
                          .withValues(alpha: isDark ? 0.18 : 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: AppColors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App Theme',
                              style: TextStyle(
                                color: AppColors.textPrimary(isDark),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              isDark ? 'Dark Mode' : 'Light Mode',
                              style: TextStyle(
                                  color: AppColors.textSecondary(isDark),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDark,
                        activeTrackColor: AppColors.orange,
                        onChanged: (_) => toggleTheme(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'More settings coming soon.',
                  style: TextStyle(
                      color: AppColors.textTertiary(isDark), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
