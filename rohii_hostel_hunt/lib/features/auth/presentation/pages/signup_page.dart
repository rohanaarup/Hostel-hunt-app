import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'dart:async';
import 'package:rohii_hostel_hunt/shared/widgets/auth/auth_logo_lockup.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/auth_hero_row.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/auth_input_field.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/auth_gradient_button.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/decorative_auth_footer.dart';
import 'package:rohii_hostel_hunt/core/observability/debug_log.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  // ─── Controllers ──────────────────────────────────────────────────────────
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // ─── Focus nodes ──────────────────────────────────────────────────────────
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _otpFocused = false;
  bool _passwordFocused = false;
  bool _confirmFocused = false;

  // ─── State (ALL ORIGINAL LOGIC PRESERVED) ─────────────────────────────────
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _canResendOTP = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String _verificationToken = '';

  // Single controller drives all 3 entrance layers via Interval curves.
  // Total duration: 850ms
  // Layer 1 (image):    0.00 → 0.55
  // Layer 2 (headline): 0.12 → 0.67  (≈100ms delay)
  // Layer 3 (sheet):    0.22 → 0.80  (≈185ms delay)
  late AnimationController _entranceController;

  late Animation<double> _imageFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _sheetFade;
  late Animation<Offset> _sheetSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _imageFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.12, 0.67, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.12, 0.67, curve: Curves.easeOutCubic),
          ),
        );
    _sheetFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.22, 0.80, curve: Curves.easeOut),
    );
    _sheetSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.22, 0.80, curve: Curves.easeOutCubic),
          ),
        );

    _entranceController.forward();

    _nameFocus.addListener(
      () => setState(() => _nameFocused = _nameFocus.hasFocus),
    );
    _emailFocus.addListener(
      () => setState(() => _emailFocused = _emailFocus.hasFocus),
    );
    _otpFocus.addListener(
      () => setState(() => _otpFocused = _otpFocus.hasFocus),
    );
    _passwordFocus.addListener(
      () => setState(() => _passwordFocused = _passwordFocus.hasFocus),
    );
    _confirmFocus.addListener(
      () => setState(() => _confirmFocused = _confirmFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _otpFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _countdownTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  // ─── ORIGINAL BUSINESS LOGIC — UNCHANGED ──────────────────────────────────

  void _startResendCountdown() {
    setState(() {
      _canResendOTP = false;
      _resendCountdown = 60;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResendOTP = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOTP() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    if (fullName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your full name';
        _isLoading = false;
      });
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please confirm your email address:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.ivory700 : AppColors.auburn50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.auburn300 : AppColors.auburn500,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: isDark ? AppColors.auburn300 : AppColors.auburn500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '⚠️ Make sure this is correct! OTP will be sent to this email.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Edit Email'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.auburn300
                  : AppColors.auburn500,
              foregroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
            ),
            child: const Text('Confirm & Send OTP'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _api.post('/auth/send-otp/', {
        'identifier': email,
        'identifier_type': 'email',
        'purpose': 'signup',
      });

      if (!response.success) {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      _startResendCountdown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'OTP sent to your email!',
          ),
          backgroundColor: AppColors.emerald500,
        ),
      );
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('SocketException') ||
          errorMsg.contains('HandshakeException')) {
        setState(() {
          _errorMessage =
              'Cannot connect to server. Check if backend is running.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'OTP send failed. Please try again.';
          _isLoading = false;
        });
      }
      debugLog('OTP send failed');
    }
  }

  Future<void> _verifyOTP() async {
    setState(() => _errorMessage = '');
    final otp = _otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final response = await _api.post('/auth/verify-otp/', {
        'identifier': email,
        'identifier_type': 'email',
        'otp': otp,
        'purpose': 'signup',
      });

      if (response.success) {
        final token = response.data?['verification_token'] as String?;
        _verificationToken = token ?? '';
        setState(() {
          _otpVerified = true;
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppColors.emerald500,
          ),
        );
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    setState(() => _errorMessage = '');

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 8 ||
        !RegExp(r'[a-zA-Z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      setState(
        () => _errorMessage =
            'Password must be at least 8 characters with 1 letter and 1 number',
      );
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();

      final response = await _api.post('/auth/register/', {
        'identifier': email,
        'identifier_type': 'email',
        'display_name': fullName,
        'password': password,
        'verification_token': _verificationToken,
        'signup_source': 'mobile_app',
      });

      setState(() => _isLoading = false);

      if (!response.success) {
        setState(() => _errorMessage = response.message);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created successfully! Please login.'),
          backgroundColor: AppColors.emerald500,
          duration: const Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign up failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  // ─── Step label helper ────────────────────────────────────────────────────

  int get _currentStep => _otpVerified ? 2 : (_otpSent ? 1 : 0);

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bgColor = isDark ? const Color(0xFF151212) : AppColors.ivory50;
    final primaryColor = AppColors.auburn500;
    final secondaryText = isDark ? AppColors.ivory500 : AppColors.ink700;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DecorativeAuthFooter(isDark: isDark),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _sheetFade,
              child: SlideTransition(
                position: _sheetSlide,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      AuthLogoLockup(isDark: isDark),

                      const SizedBox(height: 32),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: AuthHeroRow(
                          headline: 'Discover Your\nPerfect ',
                          accentWord: 'Stay',
                          subtext: 'Create your account to\nget started',
                          imagePath: 'images/backgrounds/hostel_room.jpg',
                          isDark: isDark,
                        ),
                      ),

                      const SizedBox(height: 32),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.ink900.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink900.withValues(alpha: 0.05),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Progress dots (3 steps)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (index) {
                                final isActive = index == _currentStep;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: isActive ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? primaryColor
                                        : (isDark
                                              ? AppColors.ivory700
                                              : AppColors.ivory300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 24),

                            if (_errorMessage.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.error.withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.error,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage,
                                        style: TextStyle(
                                          color: AppColors.error,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Step 0: Name + Email
                            if (!_otpSent || (_otpSent && !_otpVerified)) ...[
                              AuthInputField(
                                controller: _fullNameController,
                                focusNode: _nameFocus,
                                isFocused: _nameFocused,
                                hint: 'Full Name',
                                prefixIcon: Icons.person_outline,
                                enabled: !_otpSent,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),
                              AuthInputField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                isFocused: _emailFocused,
                                hint: 'Email address',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_otpSent,
                                isDark: isDark,
                              ),
                            ],

                            if (!_otpSent) ...[
                              const SizedBox(height: 24),
                              AuthGradientButton(
                                label: 'Send OTP',
                                isLoading: _isLoading,
                                onPressed: _isLoading ? null : _sendOTP,
                                isDark: isDark,
                              ),
                            ],

                            // Step 1: OTP
                            if (_otpSent && !_otpVerified) ...[
                              const SizedBox(height: 16),
                              AuthInputField(
                                controller: _otpController,
                                focusNode: _otpFocus,
                                isFocused: _otpFocused,
                                hint: 'Enter 6-digit OTP',
                                prefixIcon: Icons.schedule_outlined,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: AuthGradientButton(
                                      label: 'Verify OTP',
                                      isLoading: _isLoading,
                                      onPressed: _isLoading ? null : _verifyOTP,
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton(
                                    onPressed: _canResendOTP && !_isLoading
                                        ? _sendOTP
                                        : null,
                                    child: Text(
                                      _canResendOTP
                                          ? 'Resend'
                                          : 'Resend ($_resendCountdown)',
                                      style: TextStyle(
                                        color: _canResendOTP
                                            ? primaryColor
                                            : AppColors.ivory500,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Step 2: Password
                            if (_otpVerified) ...[
                              AuthInputField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                isFocused: _passwordFocused,
                                hint: 'Create Password',
                                prefixIcon: Icons.lock_outlined,
                                obscureText: !_passwordVisible,
                                isDark: isDark,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: secondaryText,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _passwordVisible = !_passwordVisible,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AuthInputField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmFocus,
                                isFocused: _confirmFocused,
                                hint: 'Confirm Password',
                                prefixIcon: Icons.lock_outlined,
                                obscureText: !_confirmPasswordVisible,
                                isDark: isDark,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _confirmPasswordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: secondaryText,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _confirmPasswordVisible =
                                        !_confirmPasswordVisible,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              AuthGradientButton(
                                label: 'Create Account',
                                isLoading: _isLoading,
                                onPressed: _isLoading ? null : _signUp,
                                isDark: isDark,
                              ),
                            ],

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/login'),
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
