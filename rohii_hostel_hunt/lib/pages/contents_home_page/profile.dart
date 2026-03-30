import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/services/colors.dart';
import 'package:rohii_hostel_hunt/services/notifiers.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ValueListenableBuilder<bool>(
          valueListenable: themeNotifier,
          builder: (context, currentTheme, child) {
            return AlertDialog(
              backgroundColor: currentTheme ? AppColors.cardDark : AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                '⚙ Settings',
                style: TextStyle(
                  color: AppColors.textPrimary(currentTheme),
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          currentTheme ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: AppColors.orange,
                        ),
                      ),
                      title: Text(
                        'Theme',
                        style: TextStyle(
                          color: AppColors.textPrimary(currentTheme),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        currentTheme ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                          color: AppColors.textSecondary(currentTheme),
                          fontSize: 12,
                        ),
                      ),
                      trailing: Switch(
                        value: currentTheme,
                        activeTrackColor: AppColors.orange,
                        onChanged: (bool value) => toggleTheme(),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.orange,
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: AppColors.background(isDark),
          appBar: AppBar(
            title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.w700)),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.orange, AppColors.orangeDark],
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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // ── Profile card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.cardDark, AppColors.surfaceDark2]
                            : [AppColors.headerStart, AppColors.headerEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.orange, AppColors.orangeLight],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.cardBg(isDark),
                            child: Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'User Profile',
                          style: TextStyle(
                            color: AppColors.textPrimary(isDark),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your account',
                          style: TextStyle(
                            color: AppColors.textSecondary(isDark),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Options card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(isDark),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? AppColors.chipDark
                            : AppColors.border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Options',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(isDark),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Settings row
                        InkWell(
                          onTap: _showSettingsDialog,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.orange.withValues(alpha: 0.08),
                                  AppColors.orangeLight.withValues(alpha: 0.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.orange.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.orange, AppColors.orangeDark],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.settings_rounded,
                                    color: AppColors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Settings',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary(isDark),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Theme, notifications & more',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary(isDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppColors.orange,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
