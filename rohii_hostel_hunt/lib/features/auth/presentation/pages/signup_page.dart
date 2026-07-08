import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/core/theme/colors.dart';
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
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.orange),
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
            const Text(
              '⚠️ Make sure this is correct! OTP will be sent to this email.',
              style: TextStyle(fontSize: 12, color: Colors.red, fontStyle: FontStyle.italic),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
        '/otp/send/',
        {'email': email, 'display_name': fullName},
      );

      if (!response.success) {
        setState(() { _errorMessage = response.message; _isLoading = false; });
        return;
      }

      setState(() { _otpSent = true; _isLoading = false; });
      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your email!'), backgroundColor: Colors.green),
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
      final response = await _api.post('/otp/verify/', {'email': email, 'otp': otp});

      if (response.success) {
        setState(() { _otpVerified = true; _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.green),
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
        'email': email,
        'display_name': fullName,
        'password': password,
        'password_confirm': confirmPassword,
        'signup_source': 'app',
      });

      setState(() => _isLoading = false);

      if (!response.success) {
        setState(() => _errorMessage = response.message);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please login.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() { _errorMessage = 'Sign up failed. Please try again.'; _isLoading = false; });
    }
  }
//backend part end


//design part start------------------------------------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(209, 142, 142, 142),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),

                const Spacer(),

                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 550,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 67, 67, 67),
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "S I G N  U P",
                            style: AppCall.headlineTextFieldStyle(),
                          ),
                          const SizedBox(height: 20),

                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(color: Colors.red),
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
                              style: const TextStyle(color: Color.fromARGB(255, 18, 17, 17)),
                              decoration: InputDecoration(
                                hintText: "Full Name",
                                hintStyle: const TextStyle(
                                  color: Color.fromARGB(179, 24, 24, 24),
                                ),
                                prefixIconColor: Colors.deepOrange,
                                prefixIcon: const Icon(Icons.person),
                                border: UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 5, 5, 5)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.deepOrange,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                disabledBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 18, 17, 17)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextField(
                              controller: _emailController,
                              enabled: !_otpSent,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Email",
                                hintStyle: const TextStyle(
                                  color: Color.fromARGB(179, 201, 197, 197),
                                ),
                                prefixIconColor: Colors.deepOrange,
                                prefixIcon: const Icon(Icons.email),
                                border: UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.deepOrange,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                disabledBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),

                          if (!_otpSent)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _sendOTP,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: AppColors.textDark,
                                  backgroundColor: Colors.orange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
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
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Enter OTP",
                                  hintStyle: const TextStyle(
                                    color: Color.fromARGB(179, 201, 197, 197),
                                  ),
                                  prefixIconColor: Colors.deepOrange,
                                  prefixIcon: const Icon(Icons.lock_clock),
                                  counterText: '',
                                  border: UnderlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.deepOrange,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
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
                                        foregroundColor: AppColors.textDark,
                                        backgroundColor: Colors.orange,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
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
                                            ? Colors.orange
                                            : Colors.grey,
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
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Create Password",
                                  hintStyle: const TextStyle(
                                    color: Color.fromARGB(179, 201, 197, 197),
                                  ),
                                  prefixIconColor: Colors.deepOrange,
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                  ),
                                  border: UnderlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.deepOrange,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),

                          if (_otpVerified)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextField(
                                controller: _confirmPasswordController,
                                obscureText: !_confirmPasswordVisible,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Confirm Password",
                                  hintStyle: const TextStyle(
                                    color: Color.fromARGB(179, 201, 197, 197),
                                  ),
                                  prefixIconColor: Colors.deepOrange,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _confirmPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _confirmPasswordVisible = !_confirmPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: UnderlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.deepOrange,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),

                          if (_otpVerified)
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: AppColors.textDark,
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
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
