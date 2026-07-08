import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/core/theme/colors.dart';
import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';
import 'package:rohii_hostel_hunt/shared/widgets/sub_header.dart';

// ── Settings Page ─────────────────────────────────────────────────────────────

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});
  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool _bookingNotifs = true;
  bool _promoNotifs = false;
  bool _locationAccess = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.background(isDark),
        body: Column(
          children: [
            SubHeader(title: 'Settings', subtitle: 'App preferences & permissions', isDark: isDark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                physics: const BouncingScrollPhysics(),
                children: [
                  _SettingsGroup(label: 'Appearance', isDark: isDark, tiles: [
                    _ToggleTile(icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        iconColor: AppColors.orange, iconBg: AppColors.orangeSoft,
                        title: 'App Theme', subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                        value: isDark, isDark: isDark, onChanged: (_) => toggleTheme()),
                  ]),
                  const SizedBox(height: 16),
                  _SettingsGroup(label: 'Notifications', isDark: isDark, tiles: [
                    _ToggleTile(icon: Icons.notifications_outlined, iconColor: const Color(0xFF7C4DFF),
                        iconBg: const Color(0xFFEDE7F6), title: 'Booking Updates',
                        subtitle: 'Alerts on booking status changes', value: _bookingNotifs, isDark: isDark,
                        onChanged: (v) => setState(() => _bookingNotifs = v)),
                    _ToggleTile(icon: Icons.local_offer_outlined, iconColor: const Color(0xFFE91E63),
                        iconBg: const Color(0xFFFCE4EC), title: 'Promotions & Offers',
                        subtitle: 'Deals and special listings', value: _promoNotifs, isDark: isDark,
                        onChanged: (v) => setState(() => _promoNotifs = v), isLast: true),
                  ]),
                  const SizedBox(height: 16),
                  _SettingsGroup(label: 'Permissions', isDark: isDark, tiles: [
                    _ToggleTile(icon: Icons.location_on_outlined, iconColor: const Color(0xFF00897B),
                        iconBg: const Color(0xFFE0F2F1), title: 'Location Access',
                        subtitle: 'Used for nearby hostel search', value: _locationAccess, isDark: isDark,
                        onChanged: (v) => setState(() => _locationAccess = v), isLast: true),
                  ]),
                  const SizedBox(height: 16),
                  _SettingsGroup(label: 'Account', isDark: isDark, tiles: [
                    _NavTile(icon: Icons.privacy_tip_outlined, iconColor: const Color(0xFF1565C0),
                        iconBg: const Color(0xFFE3F2FD), title: 'Privacy Policy',
                        isDark: isDark, onTap: () {}),
                    _NavTile(icon: Icons.description_outlined, iconColor: AppColors.textMuted,
                        iconBg: AppColors.chip, title: 'Terms of Service',
                        isDark: isDark, onTap: () {}, isLast: true),
                  ]),
                  const SizedBox(height: 20),
                  Center(child: Text('Hostel Hunt v1.0.0 · Aarupa Matrix',
                      style: TextStyle(color: AppColors.textTertiary(isDark), fontSize: 11))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String label;
  final bool isDark;
  final List<Widget> tiles;
  const _SettingsGroup({required this.label, required this.isDark, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(label.toUpperCase(),
            style: TextStyle(color: AppColors.textTertiary(isDark), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.chipDark : AppColors.border, width: 0.8),
          boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: tiles),
      ),
    ]);
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final bool value, isDark, isLast;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.iconColor, required this.iconBg,
      required this.title, required this.subtitle, required this.value,
      required this.isDark, required this.onChanged, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(width: 42, height: 42,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 14, fontWeight: FontWeight.w600)),
            Text(subtitle, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12)),
          ])),
          Switch(value: value, activeTrackColor: AppColors.orange, onChanged: onChanged),
        ]),
      ),
      if (!isLast)
        Padding(padding: const EdgeInsets.only(left: 72),
            child: Divider(height: 1, thickness: 0.6, color: isDark ? AppColors.chipDark : AppColors.border)),
    ]);
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title;
  final bool isDark, isLast;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.iconColor, required this.iconBg,
      required this.title, required this.isDark, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 14, fontWeight: FontWeight.w600))),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary(isDark)),
          ]),
        ),
      ),
      if (!isLast)
        Padding(padding: const EdgeInsets.only(left: 72),
            child: Divider(height: 1, thickness: 0.6, color: isDark ? AppColors.chipDark : AppColors.border)),
    ]);
  }
}
