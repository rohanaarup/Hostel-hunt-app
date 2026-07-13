import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/utils/call.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'dart:async';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
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
  String _verificationToken = ''; // received from /otp/verify/ response

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

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
      setState(() { _errorMessage = 'Please enter your full name'; _isLoading = false; });
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() { _errorMessage = 'Please enter a valid email address'; _isLoading = false; });
      return;
    }

    // Confirm email dialog (UI unchanged)
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
                border: Border.all(color: isDark ? AppColors.auburn300 : AppColors.auburn500),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: isDark ? AppColors.auburn300 : AppColors.auburn500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '⚠️ Make sure this is correct! OTP will be sent to this email.',
              style: TextStyle(fontSize: 12, color: AppColors.error, fontStyle: FontStyle.italic),
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
              backgroundColor: isDark ? AppColors.auburn300 : AppColors.auburn500,
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
      final response = await _api.post(
        '/auth/send-otp/',
        {
          'identifier': email,
          'identifier_type': 'email',
          'purpose': 'signup',
        },
      );

      if (!response.success) {
        setState(() { _errorMessage = response.message; _isLoading = false; });
        return;
      }

      setState(() { _otpSent = true; _isLoading = false; });
      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('OTP sent to your email!'), backgroundColor: AppColors.emerald500),
      );
    } catch (e) {
      // Show more detailed error for debugging
      final errorMsg = e.toString();
      if (errorMsg.contains('SocketException') || errorMsg.contains('HandshakeException')) {
        setState(() { _errorMessage = 'Cannot connect to server. Check if backend is running.'; _isLoading = false; });
      } else {
        setState(() { _errorMessage = 'OTP send failed. Please try again.'; _isLoading = false; });
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
        'purpose': 'signup',
      });

      if (response.success) {
        // Store the verification_token from backend
        final token = response.data?['verification_token'] as String?;
        _verificationToken = token ?? '';
        setState(() { _otpVerified = true; _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: AppColors.emerald500),
        );
      } else {
        setState(() { _errorMessage = response.message; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _errorMessage = 'Verification failed. Please try again.'; _isLoading = false; });
    }
  }

  Future<void> _signUp() async {
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
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();

      final response = await _api.post('/auth/register/', {
        'identifier': email,
        'identifier_type': 'email',
        'display_name': fullName,
        'password': password,
        'verification_token': _verificationToken,
      });

      setState(() => _isLoading = false);

      if (!response.success) {
        setState(() => _errorMessage = response.message);
        return;
      }

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
      setState(() { _errorMessage = 'Sign up failed. Please try again.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.auburn300 : AppColors.auburn500;
    final scaffoldBg = isDark ? AppColors.ink900 : AppColors.ivory50;
    final cardBg = isDark ? AppColors.ivory900 : AppColors.ivory50;
    final cardBorder = isDark ? AppColors.ivory700 : AppColors.ivory300;
    final inputBg = isDark ? AppColors.ink900 : AppColors.ivory100;
    final inputBorder = isDark ? AppColors.ivory700 : AppColors.ivory300;
    final textColor = isDark ? AppColors.ivory50 : AppColors.ink900;
    final hintColor = AppColors.ivory500;
    final headerColor = isDark ? AppColors.ember500 : AppColors.ember700;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Layer 1: Decorative background blobs
            Positioned(
              top: -60,
              left: -60,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.ember300.withValues(alpha: 0.12) : AppColors.ember500.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -80,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.ember300.withValues(alpha: 0.12) : AppColors.ember500.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 550,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: cardBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink900.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "S I G N  U P",
                            style: AppCall.headlineTextFieldStyle().copyWith(
                              color: headerColor,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.error),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: AppColors.error),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextField(
                              controller: _fullNameController,
                              enabled: !_otpSent,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                hintText: "Full Name",
                                hintStyle: TextStyle(
                                  color: hintColor,
                                ),
                                prefixIconColor: primaryColor,
                                prefixIcon: const Icon(Icons.person),
                                filled: true,
                                fillColor: inputBg,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: inputBorder),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: isDark ? AppColors.ivory700 : AppColors.ivory300),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextField(
                              controller: _emailController,
                              enabled: !_otpSent,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                hintText: "Email",
                                hintStyle: TextStyle(
                                  color: hintColor,
                                ),
                                prefixIconColor: primaryColor,
                                prefixIcon: const Icon(Icons.email),
                                filled: true,
                                fillColor: inputBg,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: inputBorder),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: isDark ? AppColors.ivory700 : AppColors.ivory300),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                            ),
                          ),

                          if (!_otpSent)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _sendOTP,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  shadowColor: AppColors.auburn700.withValues(alpha: 0.2),
                                  elevation: 8,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: isDark ? AppColors.ink900 : AppColors.ivory50,
                                        ),
                                      )
                                    : const Text(
                                        "Send OTP",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),

                          if (_otpSent && !_otpVerified)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  hintText: "Enter OTP",
                                  hintStyle: TextStyle(
                                    color: hintColor,
                                  ),
                                  prefixIconColor: primaryColor,
                                  prefixIcon: const Icon(Icons.lock_clock),
                                  counterText: '',
                                  filled: true,
                                  fillColor: inputBg,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: inputBorder),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                ),
                              ),
                            ),

                          if (_otpSent && !_otpVerified)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _verifyOTP,
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
                                        backgroundColor: primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: isDark ? AppColors.ink900 : AppColors.ivory50,
                                              ),
                                            )
                                          : const Text(
                                              "Verify OTP",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  TextButton(
                                    onPressed: _canResendOTP && !_isLoading ? _sendOTP : null,
                                    child: Text(
                                      _canResendOTP
                                          ? "Resend"
                                          : "Resend ($_resendCountdown)",
                                      style: TextStyle(
                                        color: _canResendOTP
                                            ? primaryColor
                                            : AppColors.ivory500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (_otpVerified)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: !_passwordVisible,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  hintText: "Create Password",
                                  hintStyle: TextStyle(
                                    color: hintColor,
                                  ),
                                  prefixIconColor: primaryColor,
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: hintColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: inputBg,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: inputBorder),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                ),
                              ),
                            ),

                          if (_otpVerified)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: _confirmPasswordController,
                                obscureText: !_confirmPasswordVisible,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  hintText: "Confirm Password",
                                  hintStyle: TextStyle(
                                    color: hintColor,
                                  ),
                                  prefixIconColor: primaryColor,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _confirmPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: hintColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _confirmPasswordVisible = !_confirmPasswordVisible;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: inputBg,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: inputBorder),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),

                          if (_otpVerified)
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: isDark ? AppColors.ink900 : AppColors.ivory50,
                                      ),
                                    )
                                  : const Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
