import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/auth_logo_lockup.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/auth_hero_row.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/auth_input_field.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/auth_gradient_button.dart';
import 'package:rohii_hostel_hunt/shared/widgets/auth/decorative_auth_footer.dart';

class LoginPage extends ConsumerStatefulWidget {
  /// When true, a successful login pops this page (returning `true` to the
  /// caller) instead of navigating to '/home'. Used when login is triggered
  /// mid-flow (e.g. from the booking screen) so the caller's state — and
  /// nav stack — survives the login detour.
  final bool popOnSuccess;

  const LoginPage({super.key, this.popOnSuccess = false});

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

  // Single controller drives all 3 entrance layers via Interval curves.
  // Total duration: 850ms
  // Layer 1 (image):    0.00 → 0.55  (≈ 467ms)
  // Layer 2 (headline): 0.12 → 0.67  (≈ 100ms delay)
  // Layer 3 (sheet):    0.22 → 0.77  (≈ 185ms delay from start)
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
    _sheetSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.22, 0.80, curve: Curves.easeOutCubic),
          ),
        );

    _entranceController.forward();

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
    _entranceController.dispose();
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
      final response = await _api.post('/auth/login/', {
        'identifier': email,
        'identifier_type': 'email',
        'password': password,
      });

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
          '[LOGIN] Tokens saved — access: ${tokens['access']?.toString().substring(0, 20)}...',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'user_id',
          user?['owner_id']?.toString() ?? user?['id']?.toString() ?? '',
        );
        await prefs.setString('user_email', user?['email'] as String? ?? '');

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
      if (!mounted) return;
      if (widget.popOnSuccess) {
        Navigator.of(context).pop(true);
      } else {
        context.go('/home');
      }
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
                          headline: 'Welcome\n',
                          accentWord: 'Back',
                          subtext: 'Sign in to continue\nhunting',
                          imagePath: 'images/backgrounds/hostel_lounge.jpg',
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
                              const SizedBox(height: 20),
                            ],

                            AuthInputField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              isFocused: _emailFocused,
                              hint: 'Email address',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              isDark: isDark,
                            ),

                            const SizedBox(height: 16),

                            AuthInputField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              isFocused: _passwordFocused,
                              hint: 'Password',
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

                            const SizedBox(height: 12),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    context.push('/forgot-password'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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

                            AuthGradientButton(
                              label: 'Login',
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _login,
                              isDark: isDark,
                            ),

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 13,
                                  ),
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
