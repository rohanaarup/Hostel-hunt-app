import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/utils/call.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _errorMessage = '');

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Invalid email format');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _api.post(
        '/auth/login/',
        {
          'identifier': email,
          'identifier_type': 'email',
          'password': password,
        },
      );

      if (!response.success) {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
        return;
      }

      // Save JWT tokens and user info
      final tokens = response.data?['tokens'] as Map<String, dynamic>?;
      final user = response.data?['user'] as Map<String, dynamic>?;
      if (tokens != null) {
        await _api.saveTokens(
          tokens['access'] as String,
          tokens['refresh'] as String,
        );
        debugPrint('[LOGIN] Tokens saved — access: ${tokens['access']?.toString().substring(0, 20)}...');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user?['owner_id']?.toString() ?? user?['id']?.toString() ?? '');
        await prefs.setString('user_email', user?['email'] as String? ?? '');
        
        // Refresh the profile data now that the user is logged in
        ref.read(userProvider.notifier).refresh();
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login successful!'),
          backgroundColor: AppColors.emerald500,
          duration: const Duration(seconds: 1),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
        _isLoading = false;
      });
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
                  height: 480,
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
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05,
                          ),

                          Text(
                            "L O G I N",
                            style: AppCall.headlineTextFieldStyle().copyWith(
                              color: headerColor,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 40),

                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
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

                          TextField(
                            controller: _emailController,
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
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextField(
                            controller: _passwordController,
                            obscureText: !_passwordVisible,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: "Password",
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

                          const SizedBox(height: 40),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: isDark ? AppColors.ink900 : AppColors.ivory50,
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
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
                                    "Login",
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "don't have an account??",
                                style: TextStyle(color: isDark ? AppColors.ivory300 : AppColors.ink700),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.push('/signup');
                                },
                                child: Text(
                                  " Sign Up",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
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
