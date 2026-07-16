import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _passwordVisible = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;

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
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic));
    _formFade =
        CurvedAnimation(parent: _formController, curve: Curves.easeOut);
    _formController.forward();

    _emailFocus.addListener(() {
      setState(() => _emailFocused = _emailFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _formController.dispose();
    super.dispose();
  }

  // ─── API logic preserved exactly ────────────────────────────────────────────

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

      final tokens = response.data?['tokens'] as Map<String, dynamic>?;
      final user = response.data?['user'] as Map<String, dynamic>?;
      if (tokens != null) {
        await _api.saveTokens(
          tokens['access'] as String,
          tokens['refresh'] as String,
        );
        debugPrint(
            '[LOGIN] Tokens saved — access: ${tokens['access']?.toString().substring(0, 20)}...');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'user_id',
            user?['owner_id']?.toString() ??
                user?['id']?.toString() ??
                '');
        await prefs.setString(
            'user_email', user?['email'] as String? ?? '');

        ref.read(userProvider.notifier).refresh();
      }

      setState(() => _isLoading = false);
      if (!mounted) return;
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
    final cardBg = isDark ? AppColors.ivory900 : AppColors.ivory100;
    final cardBorder = isDark ? AppColors.ivory700 : AppColors.ivory300;
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
                  'images/backgrounds/hostel_lounge.jpg',
                  fit: BoxFit.cover,
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: 0.30),
                  colorBlendMode: BlendMode.darken,
                ),
                // Gradient to form bg color at bottom edge
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.3, 1.0],
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
                // Space inside the hero — logo + headline
                SizedBox(
                  height: heroHeight,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Logo
                        Image.asset(
                          isDark
                              ? 'images/logos/logo_icon_dark_bg.png'
                              : 'images/logos/hostel_hunt_logo_horizontal.png',
                          width: size.width * 0.52,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        // Headline
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ivory50,
                            height: 1.1,
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
                          'Sign in to continue hunting',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.ivory100.withValues(alpha: 0.85),
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
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Error banner ──
                          if (_errorMessage.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color:
                                        AppColors.error.withValues(alpha: 0.4),
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
                            const SizedBox(height: 20),
                          ],

                          // ── Email field ──
                          _InputField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            isFocused: _emailFocused,
                            hint: 'Email address',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            isDark: isDark,
                            inputBg: inputBg,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            textColor: textColor,
                            primaryColor: primaryColor,
                          ),

                          const SizedBox(height: 16),

                          // ── Password field ──
                          _InputField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            isFocused: _passwordFocused,
                            hint: 'Password',
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
                                color: secondaryText,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _passwordVisible = !_passwordVisible),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Forgot Password link ──
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Login pill button ──
                          _ActionButton(
                            label: 'Login',
                            isLoading: _isLoading,
                            onPressed: _isLoading ? null : _login,
                            primaryColor: primaryColor,
                            primaryDark: primaryDark,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 28),

                          // ── Sign Up link ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                    color: secondaryText, fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/signup'),
                                child: Text(
                                  'Sign Up',
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
// Shared: Focused input field with glow shadow
// ─────────────────────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
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

  const _InputField({
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
        keyboardType: keyboardType,
        obscureText: obscureText,
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
          filled: true,
          fillColor: inputBg,
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
// Shared: Full-width pill action button with loading state
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color primaryColor;
  final Color primaryDark;
  final bool isDark;

  const _ActionButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.primaryColor,
    required this.primaryDark,
    required this.isDark,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        reverseDuration: const Duration(milliseconds: 180),
        lowerBound: 0,
        upperBound: 1);
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _pressController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _pressController.forward(),
        onTapUp: isDisabled
            ? null
            : (_) {
                _pressController.reverse();
                widget.onPressed?.call();
              },
        onTapCancel: () => _pressController.reverse(),
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
                      color: widget.primaryColor.withValues(alpha: 0.38),
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
