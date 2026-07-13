import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl = TextEditingController(text: 'Rohii Aarup');
  final _emailCtrl = TextEditingController(text: 'rohii.aarup@example.com');
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(bool isDark) async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Profile updated successfully!',
          style: TextStyle(color: AppColors.ivory50, fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.appBackground(isDark),
        body: Column(
          children: [
            // ── Header ──
            _buildHeader(isDark),
            // ── Form ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Avatar picker
                    _AvatarPicker(isDark: isDark),
                    const SizedBox(height: 28),
                    // Personal info card
                    _SectionCard(
                      isDark: isDark,
                      label: 'Personal Information',
                      children: [
                        _Field(ctrl: _nameCtrl, label: 'Full Name', icon: Icons.person_outline_rounded, isDark: isDark),
                        _Field(ctrl: _emailCtrl, label: 'Email Address', icon: Icons.email_outlined, isDark: isDark, type: TextInputType.emailAddress),
                        _Field(ctrl: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_outlined, isDark: isDark, type: TextInputType.phone, isLast: true),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      isDark: isDark,
                      label: 'About You',
                      children: [
                        _Field(
                          ctrl: TextEditingController(text: 'Student at JNTU Hyderabad'),
                          label: 'Occupation',
                          icon: Icons.work_outline_rounded,
                          isDark: isDark,
                        ),
                        _Field(
                          ctrl: TextEditingController(text: 'Hyderabad, Telangana'),
                          label: 'City',
                          icon: Icons.location_city_outlined,
                          isDark: isDark,
                          isLast: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // ── Floating Save Button ──
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg(isDark),
            border: Border(top: BorderSide(color: isDark ? AppColors.ivory700 : AppColors.ivory300, width: 0.8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary(isDark),
                    side: BorderSide(color: isDark ? AppColors.ivory700 : AppColors.ivory300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _save(isDark),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.auburn500,
                    foregroundColor: AppColors.ivory50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ivory50))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.ivory900, AppColors.ivory900]
              : [AppColors.ivory100, AppColors.ivory50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          _BackBtn(isDark: isDark),
          const SizedBox(width: 16),
          Text('Edit Profile',
              style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final bool isDark;
  const _AvatarPicker({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.auburn500, AppColors.auburn300],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.cardBg(isDark),
              child: Icon(Icons.person_rounded, size: 50, color: AppColors.auburn500),
            ),
          ),
          Positioned(
            bottom: 4, right: 4,
            child: GestureDetector(
              onTap: () => HapticFeedback.lightImpact(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.auburn500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.ivory50, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final List<Widget> children;
  const _SectionCard({required this.isDark, required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(label.toUpperCase(),
              style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 1.1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.ivory700 : AppColors.ivory300, width: 0.8),
            boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool isDark;
  final TextInputType type;
  final bool isLast;

  const _Field({
    required this.ctrl, required this.label, required this.icon, required this.isDark,
    this.type = TextInputType.text, this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.auburn500.withValues(alpha: 0.8)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 11,
                            fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: ctrl,
                      keyboardType: type,
                      style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, size: 14, color: AppColors.textSecondary(isDark)),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Divider(height: 1, thickness: 0.6, color: isDark ? AppColors.ivory700 : AppColors.ivory300),
          ),
      ],
    );
  }
}

class _BackBtn extends StatelessWidget {
  final bool isDark;
  const _BackBtn({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.ivory700 : AppColors.ivory50.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.ivory50.withValues(alpha: 0.08) : AppColors.ivory300, width: 0.8),
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textHeading(isDark)),
      ),
    );
  }
}

