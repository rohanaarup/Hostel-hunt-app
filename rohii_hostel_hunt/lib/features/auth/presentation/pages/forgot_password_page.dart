import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'dart:async';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  // ─── Controllers ──────────────────────────────────────────────────────────
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // ─── Focus nodes ──────────────────────────────────────────────────────────
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

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

  // Animation
  late AnimationController _formController;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic));
    _formFade =
        CurvedAnimation(parent: _formController, curve: Curves.easeOut);
    _formController.forward();

    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _otpFocus.addListener(() => setState(() => _otpFocused = _otpFocus.hasFocus));
    _passwordFocus.addListener(() => setState(() => _passwordFocused = _passwordFocus.hasFocus));
    _confirmFocus.addListener(() => setState(() => _confirmFocused = _confirmFocus.hasFocus));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _otpFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _countdownTimer?.cancel();
    _formController.dispose();
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
    final email = _emailController.text.trim().toLowerCase();

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

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
                    color:
                        isDark ? AppColors.auburn300 : AppColors.auburn500),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined,
                      color: isDark
                          ? AppColors.auburn300
                          : AppColors.auburn500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
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
                  fontStyle: FontStyle.italic),
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
              backgroundColor:
                  isDark ? AppColors.auburn300 : AppColors.auburn500,
              foregroundColor:
                  isDark ? AppColors.ink900 : AppColors.ivory50,
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
      final response = await _api.post(
        '/auth/send-otp/',
        {
          'identifier': email,
          'identifier_type': 'email',
          'purpose': 'forgot_password',
        },
      );

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
          content: Text(response.message.isNotEmpty 
              ? response.message 
              : 'OTP sent to your email!'),
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
      debugPrint('OTP send error: $errorMsg');
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
        'purpose': 'forgot_password',
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
              backgroundColor: AppColors.emerald500),
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

  Future<void> _resetPassword() async {
    setState(() => _errorMessage = '');

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 8 ||
        !RegExp(r'[a-zA-Z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      setState(() => _errorMessage =
          'Password must be at least 8 characters with 1 letter and 1 number');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();

      final response = await _api.post('/auth/reset-password/', {
        'identifier': email,
        'identifier_type': 'email',
        'new_password': password,
        'verification_token': _verificationToken,
      });

      setState(() => _isLoading = false);

      if (!response.success) {
        setState(() => _errorMessage = response.message);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Password reset successfully! Please login.'),
          backgroundColor: AppColors.emerald500,
          duration: const Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() {
        _errorMessage = 'Reset failed. Please try again.';
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
    final heroHeight = size.height * 0.40;
    final primaryColor = isDark ? AppColors.auburn300 : AppColors.auburn500;
    final primaryDark = isDark ? AppColors.auburn500 : AppColors.auburn700;
    final formBgTop = isDark ? AppColors.ink900 : AppColors.ivory50;
    final formBgBottom = isDark ? const Color(0xFF151212) : AppColors.ivory100;
    final cardBorder = isDark ? AppColors.ivory700 : AppColors.ivory300;
    final cardBg = isDark ? AppColors.ivory900 : AppColors.ivory100;
    final textColor = isDark ? AppColors.ivory50 : AppColors.ink900;
    final secondaryText = isDark ? AppColors.ivory500 : AppColors.ink700;
    final inputBg = isDark ? AppColors.ivory900 : AppColors.ivory50;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [formBgTop, formBgBottom],
          ),
        ),
        child: Stack(
        children: [
          // ── Hero photo ──
          SizedBox(
            height: heroHeight + 32,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'images/backgrounds/hostel_room.jpg',
                  fit: BoxFit.cover,
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.50)
                      : Colors.black.withValues(alpha: 0.22),
                  colorBlendMode: BlendMode.darken,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.25, 1.0],
                      colors: [
                        Colors.transparent,
                        formBgTop,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ──
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero content
                SizedBox(
                  height: heroHeight,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Image.asset(
                          isDark
                              ? 'images/logos/logo_icon_dark_bg.png'
                              : 'images/logos/hostel_hunt_logo_horizontal.png',
                          width: size.width * 0.52,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Reset Your\nPassword',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ivory50,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your email to receive an OTP',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                AppColors.ivory100.withValues(alpha: 0.85),
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Form card ──
                SlideTransition(
                  position: _formSlide,
                  child: FadeTransition(
                    opacity: _formFade,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [formBgTop, formBgBottom],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Step indicator
                          _StepIndicator(
                            currentStep: _currentStep,
                            primaryColor: primaryColor,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),

                          // Error banner
                          if (_errorMessage.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.error.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.error
                                        .withValues(alpha: 0.4),
                                    width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                          color: AppColors.error,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Step 0: Email ──
                          _ForgotInputField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            isFocused: _emailFocused,
                            hint: 'Email address',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_otpSent,
                            isDark: isDark,
                            inputBg: inputBg,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            textColor: textColor,
                            primaryColor: primaryColor,
                          ),

                          // ── Send OTP button (step 0) ──
                          if (!_otpSent) ...[
                            const SizedBox(height: 28),
                            _ForgotActionButton(
                              label: 'Send OTP',
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _sendOTP,
                              primaryColor: primaryColor,
                              primaryDark: primaryDark,
                              isDark: isDark,
                            ),
                          ],

                          // ── Step 1: OTP ──
                          if (_otpSent && !_otpVerified) ...[
                            const SizedBox(height: 16),
                            _ForgotInputField(
                              controller: _otpController,
                              focusNode: _otpFocus,
                              isFocused: _otpFocused,
                              hint: 'Enter 6-digit OTP',
                              prefixIcon: Icons.schedule_outlined,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              isDark: isDark,
                              inputBg: inputBg,
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              textColor: textColor,
                              primaryColor: primaryColor,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _ForgotActionButton(
                                    label: 'Verify OTP',
                                    isLoading: _isLoading,
                                    onPressed: _isLoading ? null : _verifyOTP,
                                    primaryColor: primaryColor,
                                    primaryDark: primaryDark,
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

                          // ── Step 2: Password ──
                          if (_otpVerified) ...[
                            const SizedBox(height: 16),
                            _ForgotInputField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              isFocused: _passwordFocused,
                              hint: 'Create Password',
                              prefixIcon: Icons.lock_outlined,
                              obscureText: !_passwordVisible,
                              isDark: isDark,
                              inputBg: inputBg,
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              textColor: textColor,
                              primaryColor: primaryColor,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: isDark
                                      ? AppColors.ivory500
                                      : AppColors.ink700,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _passwordVisible = !_passwordVisible),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _ForgotInputField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmFocus,
                              isFocused: _confirmFocused,
                              hint: 'Confirm Password',
                              prefixIcon: Icons.lock_outlined,
                              obscureText: !_confirmPasswordVisible,
                              isDark: isDark,
                              inputBg: inputBg,
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              textColor: textColor,
                              primaryColor: primaryColor,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _confirmPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: isDark
                                      ? AppColors.ivory500
                                      : AppColors.ink700,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _confirmPasswordVisible =
                                        !_confirmPasswordVisible),
                              ),
                            ),
                            const SizedBox(height: 28),
                            _ForgotActionButton(
                              label: 'Reset Password',
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _resetPassword,
                              primaryColor: primaryColor,
                              primaryDark: primaryDark,
                              isDark: isDark,
                            ),
                          ],

                          const SizedBox(height: 28),

                          // Already have account link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Remember your password? ',
                                style: TextStyle(
                                    color: secondaryText, fontSize: 13),
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

                          SizedBox(
                            height:
                                MediaQuery.of(context).padding.bottom + 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step indicator dots
// ─────────────────────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final Color primaryColor;
  final bool isDark;

  const _StepIndicator({
    required this.currentStep,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == currentStep;
        final isDone = i < currentStep;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isDone || isActive
                    ? primaryColor
                    : (isDark ? AppColors.ivory700 : AppColors.ivory300),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            if (i < 2)
              Container(
                width: 20,
                height: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isDone
                    ? primaryColor
                    : (isDark ? AppColors.ivory700 : AppColors.ivory300),
              ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Signup input field with focus glow
// ─────────────────────────────────────────────────────────────────────────────
class _ForgotInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool isDark;
  final Color inputBg;
  final Color cardBg;
  final Color cardBorder;
  final Color textColor;
  final Color primaryColor;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLength;

  const _ForgotInputField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    required this.isDark,
    required this.inputBg,
    required this.cardBg,
    required this.cardBorder,
    required this.textColor,
    required this.primaryColor,
    this.suffixIcon,
    this.enabled = true,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.18),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.ivory500, fontSize: 14),
          prefixIcon: Icon(
            prefixIcon,
            color: isFocused ? primaryColor : AppColors.ivory500,
            size: 20,
          ),
          suffixIcon: suffixIcon,
          counterText: '',
          filled: true,
          fillColor: enabled ? inputBg : cardBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cardBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.8),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cardBorder, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Signup pill action button
// ─────────────────────────────────────────────────────────────────────────────
class _ForgotActionButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color primaryColor;
  final Color primaryDark;
  final bool isDark;

  const _ForgotActionButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.primaryColor,
    required this.primaryDark,
    required this.isDark,
  });

  @override
  State<_ForgotActionButton> createState() => _ForgotActionButtonState();
}

class _ForgotActionButtonState extends State<_ForgotActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        reverseDuration: const Duration(milliseconds: 180),
        lowerBound: 0,
        upperBound: 1);
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _press.forward(),
        onTapUp: isDisabled
            ? null
            : (_) {
                _press.reverse();
                widget.onPressed?.call();
              },
        onTapCancel: () => _press.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : LinearGradient(
                    colors: [widget.primaryColor, widget.primaryDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: isDisabled
                ? (widget.isDark ? AppColors.ivory900 : AppColors.ivory300)
                : null,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color:
                          widget.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: widget.isDark
                        ? AppColors.ink900
                        : AppColors.ivory50,
                  ),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    color: isDisabled
                        ? AppColors.ivory500
                        : (widget.isDark
                            ? AppColors.ink900
                            : AppColors.ivory50),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
