import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rohii_hostel_hunt/core/theme/theme_provider.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';

// ─── Centralized route names ──────────────────────────────────────────────────
class _R {
  static const settings = '/profile/settings';
  static const search = '/search';
}

// ─── Main Profile page ────────────────────────────────────────────────────────
class Profile extends ConsumerWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
        body: _ProfileContent(isDark: isDark),
      ),
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  final bool isDark;
  const _ProfileContent({required this.isDark});
  @override
  ConsumerState<_ProfileContent> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<_ProfileContent> {
  bool _isUploadingPhoto = false;

  // ── Logout ──────────────────────────────────────────────────────────────────
  void _logout() {
    final isDark = widget.isDark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.ivory900 : AppColors.ivory50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Log Out',
            style: TextStyle(
                color: isDark ? AppColors.ivory50 : AppColors.ink900,
                fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to log out of your account?',
            style: TextStyle(
                color: isDark ? AppColors.ivory300 : AppColors.ink700,
                fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? AppColors.ivory300 : AppColors.ink700),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.ivory50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Photo upload ─────────────────────────────────────────────────────────────
  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    final notifier = ref.read(userProvider.notifier);
    final mimeType = picked.mimeType ?? 'image/jpeg';
    final bytes = await picked.readAsBytes();
    final error = await notifier.uploadPhoto(bytes, picked.name, mimeType);
    if (mounted) {
      setState(() => _isUploadingPhoto = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile photo updated!'),
            backgroundColor: AppColors.emerald500,
          ),
        );
      }
    }
  }

  // ── Edit profile bottom sheet ────────────────────────────────────────────────
  void _showEditProfileSheet(UserProfile? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        isDark: widget.isDark,
        user: user,
        onSave: (fields) async {
          final notifier = ref.read(userProvider.notifier);
          final error = await notifier.updateProfile(fields);
          if (mounted) {
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Update failed: $error'),
                    backgroundColor: AppColors.error),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: const Text('Profile updated!'),
                    backgroundColor: AppColors.emerald500),
              );
            }
          }
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final userAsync = ref.watch(userProvider);
    final user = userAsync.valueOrNull;

    final bannerHeight = MediaQuery.of(context).size.height * 0.24;
    const avatarSize = 100.0;

    Color getStatusColor(String status) {
      status = status.toLowerCase();
      if (status == 'confirmed') return AppColors.emerald300;
      if (status == 'pending') return AppColors.warning;
      return AppColors.ivory300;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Layer 1 & 2: Banner + Avatar ──────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Spacer to give Stack enough height for hit-testing the overlapping avatar
              SizedBox(
                height: bannerHeight + (avatarSize / 2),
                width: double.infinity,
              ),
              
              // Banner
              Container(
                height: bannerHeight,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.auburn300 : AppColors.auburn500,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _FloatingCircleBtn(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                        ),
                        _FloatingCircleBtn(
                          icon: Icons.settings_rounded,
                          onTap: () => context.push(_R.settings),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Avatar with overlaid action icons
              Positioned(
                bottom: 0,
                child: Stack(
                  children: [
                    // Avatar circle
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.ivory700 : AppColors.ivory100,
                        border: Border.all(
                          color:
                              isDark ? AppColors.ink900 : AppColors.ivory50,
                          width: 4,
                        ),
                      ),
                      child: ClipOval(
                        child: _isUploadingPhoto
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.auburn500,
                                  strokeWidth: 2,
                                ),
                              )
                            : user?.profilePhotoUrl != null
                                ? Image.network(
                                    user!.profilePhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person_rounded,
                                      size: 48,
                                      color: isDark
                                          ? AppColors.ivory300
                                          : AppColors.ivory500,
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    size: 48,
                                    color: isDark
                                        ? AppColors.ivory300
                                        : AppColors.ivory500,
                                  ),
                      ),
                    ),

                    // Pen icon (bottom-left) — opens edit form
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: GestureDetector(
                        onTap: () => _showEditProfileSheet(user),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                isDark ? AppColors.ivory900 : AppColors.ink900,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isDark
                                    ? AppColors.ink900
                                    : AppColors.ivory50,
                                width: 2),
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: AppColors.ivory50,
                          ),
                        ),
                      ),
                    ),

                    // + icon (bottom-right) — opens image picker
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.auburn500,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isDark
                                    ? AppColors.ink900
                                    : AppColors.ivory50,
                                width: 2),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppColors.ivory50,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Gap for text
          const SizedBox(height: 12),

          Text(
            userAsync.hasError 
                ? 'Error loading profile' 
                : (user?.name ?? 'Loading...'),
            style: TextStyle(
              color: isDark ? AppColors.ivory50 : AppColors.ink900,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userAsync.hasError 
                ? userAsync.error.toString() 
                : (user?.email ?? ''),
            style: TextStyle(
              color: isDark ? AppColors.ivory300 : AppColors.ink700,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (user?.gender != null || user?.dateOfBirth != null) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (user?.gender != null)
                  _genderLabel(user!.gender!),
                if (user?.dateOfBirth != null)
                  _formatDob(user!.dateOfBirth!),
              ].join('  ·  '),
              style: TextStyle(
                color: isDark ? AppColors.ivory500 : AppColors.ink700,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 30),

          // ── Layer 3: Stat card grid ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _StatCard(
                  isDark: isDark,
                  icon: Icons.bookmark_added_rounded,
                  iconColor: AppColors.auburn500,
                  value: user?.bookingsCount.toString() ?? '0',
                  label: 'Bookings Made',
                ),
                _StatCard(
                  isDark: isDark,
                  icon: Icons.favorite_rounded,
                  iconColor: AppColors.auburn500,
                  value: user?.savedHostelsCount.toString() ?? '0',
                  label: 'Saved Hostels',
                ),
                _StatCard(
                  isDark: isDark,
                  icon: Icons.rate_review_rounded,
                  iconColor: AppColors.emerald500,
                  value: '0',
                  label: 'Reviews',
                ),
                _StatCard(
                  isDark: isDark,
                  icon: Icons.verified_user_rounded,
                  iconColor: AppColors.emerald500,
                  value: '${user?.profileCompletePercent ?? 0}%',
                  label: 'Profile Complete',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Layer 4: Recent Booking Activity ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Booking Activity',
                  style: TextStyle(
                    color: isDark ? AppColors.ivory50 : AppColors.ink900,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (user == null || user.recentBookings.isEmpty)
                  _EmptyBookingsState(isDark: isDark)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: user.recentBookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final booking =
                          user.recentBookings[index] as Map<String, dynamic>;
                      final hostelName =
                          booking['hostel_name'] as String? ?? 'Hostel Booking';
                      final bookingDate =
                          (booking['created_at'] as String? ?? 'Recent')
                              .split('T')[0];
                      final status =
                          booking['status'] as String? ?? 'pending';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.ivory900
                              : AppColors.ivory100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.ivory700
                                : AppColors.ivory300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.ivory700
                                    : AppColors.ivory300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.hotel_rounded,
                                color: isDark
                                    ? AppColors.ivory50
                                    : AppColors.ink900,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hostelName,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.ivory50
                                          : AppColors.ink900,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Booked on $bookingDate',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.ivory300
                                          : AppColors.ink700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: getStatusColor(status)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: getStatusColor(status)
                                        .withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: getStatusColor(status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 32),

                // ── Logout Button ─────────────────────────────────────────
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error
                          .withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _genderLabel(String g) {
    const map = {
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      'prefer_not_to_say': 'Prefer not to say',
    };
    return map[g] ?? g;
  }

  static String _formatDob(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day} ${_month(d.month)} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  static String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}

// ─── Edit Profile Bottom Sheet ────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final bool isDark;
  final UserProfile? user;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _EditProfileSheet({
    required this.isDark,
    required this.user,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _dobCtrl;
  String? _selectedGender;
  DateTime? _selectedDob;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _mobileCtrl = TextEditingController(text: u?.phone ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _selectedGender = u?.gender;
    if (u?.dateOfBirth != null) {
      try {
        _selectedDob = DateTime.parse(u!.dateOfBirth!);
        _dobCtrl = TextEditingController(
            text: _formatDate(_selectedDob!));
      } catch (_) {
        _dobCtrl = TextEditingController();
      }
    } else {
      _dobCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 10),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.auburn500,
            onPrimary: AppColors.ivory50,
            surface: widget.isDark ? AppColors.ivory900 : AppColors.ivory50,
            onSurface: widget.isDark ? AppColors.ivory50 : AppColors.ink900,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobCtrl.text = _formatDate(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final fields = <String, dynamic>{};
    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (name.isNotEmpty && name != widget.user?.name) {
      fields['display_name'] = name;
    }
    if (mobile.isNotEmpty && mobile != widget.user?.phone) {
      fields['phone_number'] = mobile;
    }
    if (email.isNotEmpty && email != widget.user?.email) {
      fields['email'] = email;
    }
    if (_selectedGender != null && _selectedGender != widget.user?.gender) {
      fields['gender'] = _selectedGender;
    }
    if (_selectedDob != null) {
      final isoDate =
          '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}';
      if (isoDate != widget.user?.dateOfBirth) {
        fields['date_of_birth'] = isoDate;
      }
    }

    if (fields.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    await widget.onSave(fields);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.ivory900 : AppColors.ivory50;
    final textColor = isDark ? AppColors.ivory50 : AppColors.ink900;
    final hintColor = isDark ? AppColors.ivory500 : AppColors.ink700;
    final borderColor = isDark ? AppColors.ivory700 : AppColors.ivory300;
    final fillColor = isDark ? AppColors.ivory900 : AppColors.ivory100;

    InputDecoration _field(String label, IconData icon) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: hintColor, fontSize: 13),
          prefixIcon: Icon(icon, color: hintColor, size: 20),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.auburn500, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        );

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  style: TextStyle(color: textColor),
                  decoration: _field('Full Name', Icons.person_outline_rounded),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Mobile
                TextFormField(
                  controller: _mobileCtrl,
                  style: TextStyle(color: textColor),
                  decoration: _field('Mobile Number', Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // optional
                    if (v.trim().length < 10) {
                      return 'Enter a valid 10-digit number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  style: TextStyle(color: textColor),
                  decoration: _field('Email Address', Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // optional
                    final emailRe =
                        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRe.hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date of Birth
                TextFormField(
                  controller: _dobCtrl,
                  style: TextStyle(color: textColor),
                  decoration: _field('Date of Birth', Icons.cake_outlined)
                      .copyWith(
                    suffixIcon: Icon(Icons.calendar_today_rounded,
                        color: hintColor, size: 18),
                  ),
                  readOnly: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),

                // Gender dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  dropdownColor: bg,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: _field('Gender', Icons.wc_rounded),
                  items: const [
                    DropdownMenuItem(
                        value: 'male', child: Text('Male')),
                    DropdownMenuItem(
                        value: 'female', child: Text('Female')),
                    DropdownMenuItem(
                        value: 'other', child: Text('Other')),
                    DropdownMenuItem(
                        value: 'prefer_not_to_say',
                        child: Text('Prefer not to say')),
                  ],
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                const SizedBox(height: 28),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.auburn500,
                      foregroundColor: AppColors.ivory50,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.ivory50,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Floating circle button ───────────────────────────────────────────────────
class _FloatingCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingCircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.ivory50,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.ink900, size: 22),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.ivory900 : AppColors.ivory100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.ivory700 : AppColors.ivory300,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isDark ? AppColors.ivory50 : AppColors.ink900,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? AppColors.ivory300 : AppColors.ink700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty Bookings State ─────────────────────────────────────────────────────
class _EmptyBookingsState extends StatelessWidget {
  final bool isDark;
  const _EmptyBookingsState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.ivory900 : AppColors.ivory100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.ivory700 : AppColors.ivory300,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.bed_rounded,
              size: 48,
              color: isDark ? AppColors.ivory500 : AppColors.ivory500),
          const SizedBox(height: 16),
          Text(
            'No bookings yet',
            style: TextStyle(
              color: isDark ? AppColors.ivory300 : AppColors.ink700,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(_R.search),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? AppColors.auburn300 : AppColors.auburn500,
              foregroundColor:
                  isDark ? AppColors.ink900 : AppColors.ivory50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Find a Hostel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
