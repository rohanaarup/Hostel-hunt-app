import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/theme/theme_provider.dart';
import 'package:rohii_hostel_hunt/core/theme/colors.dart';

import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';

// ─── Centralized route names ──────────────────────────────────────────────────
class _R {
  static const edit = '/profile/edit';
  static const saved = '/profile/saved';
  static const recent = '/profile/recent';
  static const bookings = '/profile/bookings';
  static const prefs = '/profile/preferences';
  static const payments = '/profile/payments';
  static const support = '/profile/support';
  static const settings = '/profile/settings';
}

// ─── Main Profile page ────────────────────────────────────────────────────────
class Profile extends ConsumerWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background(isDark),
        extendBodyBehindAppBar: true,
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

class _ProfileState extends ConsumerState<_ProfileContent> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _ac.forward();
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  void _go(String route) {
    HapticFeedback.lightImpact();
    context.push(route);
  }

  void _logout(bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Log Out', style: TextStyle(color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to log out of your account?',
            style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary(isDark)),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final userAsync = ref.watch(userProvider);
    final user = userAsync.valueOrNull;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(isDark: isDark, onEdit: () => _go(_R.edit), user: user)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 22),
                  _Label('My Activity', isDark),
                  const SizedBox(height: 10),
                  _Card(isDark: isDark, tiles: [
                    _Tile(icon: Icons.favorite_rounded, bg: const Color(0xFFFCE4EC), fg: const Color(0xFFE91E63), title: 'Saved Hostels', sub: '3 hostels saved', route: _R.saved),
                    _Tile(icon: Icons.history_rounded, bg: const Color(0xFFEDE7F6), fg: const Color(0xFF7C4DFF), title: 'Recently Viewed', sub: '12 hostels viewed', route: _R.recent),
                    _Tile(icon: Icons.assignment_rounded, bg: AppColors.orangeSoft, fg: AppColors.orange, title: 'Booking Requests', sub: '1 pending request', route: _R.bookings, isLast: true),
                  ]),
                  const SizedBox(height: 22),
                  _Label('Preferences & Payments', isDark),
                  const SizedBox(height: 10),
                  _Card(isDark: isDark, tiles: [
                    _Tile(icon: Icons.tune_rounded, bg: const Color(0xFFE0F2F1), fg: const Color(0xFF00897B), title: 'Preferences', sub: 'AC, Boys, Near metro...', route: _R.prefs),
                    _Tile(icon: Icons.account_balance_wallet_rounded, bg: const Color(0xFFE3F2FD), fg: const Color(0xFF1565C0), title: 'Payments & Rentals', sub: 'Manage transactions', route: _R.payments, isLast: true),
                  ]),
                  const SizedBox(height: 22),
                  _Label('Support & App', isDark),
                  const SizedBox(height: 10),
                  _Card(isDark: isDark, tiles: [
                    _Tile(icon: Icons.help_outline_rounded, bg: const Color(0xFFE1F5FE), fg: const Color(0xFF0288D1), title: 'Support & Help', sub: 'FAQs, contact us', route: _R.support),
                    _Tile(icon: Icons.settings_rounded, bg: AppColors.chip, fg: AppColors.textMuted, title: 'Settings', sub: 'Theme, notifications & more', route: _R.settings, isLast: true),
                  ]),
                  const SizedBox(height: 22),
                  _LogoutRow(isDark: isDark, onTap: () => _logout(isDark)),
                  const SizedBox(height: 16),
                  Center(child: Text('Hostel Hunt v1.0.0 · Aarupa Matrix',
                    style: TextStyle(color: AppColors.textTertiary(isDark), fontSize: 11, letterSpacing: 0.3))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom Header (replaces AppBar) ─────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isDark;
  final VoidCallback onEdit;
  final UserProfile? user;
  const _Header({required this.isDark, required this.onEdit, this.user});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.cardDark, AppColors.surfaceDark2]
              : [AppColors.headerStart, AppColors.headerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.shadow.withValues(alpha: 0.25)
                : AppColors.orange.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: top + 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _PillButton(
                  isDark: isDark,
                  onTap: () => Navigator.maybePop(context),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 17,
                      color: AppColors.textPrimary(isDark)),
                ),
                const Spacer(),
                Text('Profile',
                    style: TextStyle(
                      color: AppColors.textPrimary(isDark),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    )),
                const Spacer(),
                _PillButton(
                  isDark: isDark,
                  onTap: onEdit,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: AppColors.orange),
                      const SizedBox(width: 5),
                      Text('Edit',
                          style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            child: _HeroCard(isDark: isDark, onEdit: onEdit, user: user),
          ),
        ],
      ),
    );
  }
}

// Small floating pill button used in header
class _PillButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  final Widget child;
  const _PillButton({required this.isDark, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? AppColors.chipDark : AppColors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.white.withValues(alpha: 0.08) : AppColors.border,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─── Profile Hero Card ────────────────────────────────────────────────────────
// Left ~40% = tall image box, Right ~60% = user info
class _HeroCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onEdit;
  final UserProfile? user;
  const _HeroCard({required this.isDark, required this.onEdit, this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.chipDark : AppColors.border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left: image section ────────────────────────────────────────
            Expanded(
              flex: 4,
              child: GestureDetector(
                onTap: onEdit,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 160),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.orange, AppColors.orangeDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Subtle top highlight
                        Positioned(
                          top: 0, left: 0, right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.white.withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.white.withValues(alpha: 0.3),
                                    width: 1.5),
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: AppColors.white, size: 38),
                            ),
                            const SizedBox(height: 10),
                            Text('Change\nPhoto',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.white.withValues(alpha: 0.65),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Right: user info ───────────────────────────────────────────
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.name ?? 'Loading...',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    if (user?.isVerified ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 11, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text('Verified',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    _IR(Icons.email_outlined, user?.email ?? '', isDark),
                    const SizedBox(height: 5),
                    _IR(Icons.phone_outlined, user?.phone ?? '', isDark),
                    const SizedBox(height: 5),
                    _IR(Icons.calendar_today_outlined, user?.joinedAt ?? '', isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mini info row inside hero card
class _IR extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _IR(this.icon, this.text, this.isDark);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.orange.withValues(alpha: 0.75)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text,
              style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label(this.text, this.isDark);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppColors.textTertiary(isDark),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ─── Tile data model ──────────────────────────────────────────────────────────
class _Tile {
  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String sub;
  final String route;
  final bool isLast;
  const _Tile({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.title,
    required this.sub,
    required this.route,
    this.isLast = false,
  });
}

// ─── Section card ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final bool isDark;
  final List<_Tile> tiles;
  const _Card({required this.isDark, required this.tiles});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? AppColors.chipDark : AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: tiles.map((t) => _TileRow(tile: t, isDark: isDark)).toList(),
      ),
    );
  }
}

// ─── Individual tile row with press animation ─────────────────────────────────
class _TileRow extends StatefulWidget {
  final _Tile tile;
  final bool isDark;
  const _TileRow({required this.tile, required this.isDark});
  @override
  State<_TileRow> createState() => _TileRowState();
}

class _TileRowState extends State<_TileRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tile;
    final isDark = widget.isDark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) {
            setState(() => _down = false);
            HapticFeedback.lightImpact();
            context.push(t.route);
          },
          onTapCancel: () => setState(() => _down = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _down
                  ? AppColors.orange.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: t.isLast
                  ? const BorderRadius.vertical(bottom: Radius.circular(20))
                  : BorderRadius.zero,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: t.bg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(t.icon, color: t.fg, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title,
                          style: TextStyle(
                            color: AppColors.textPrimary(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          )),
                      const SizedBox(height: 2),
                      Text(t.sub,
                          style: TextStyle(
                              color: AppColors.textSecondary(isDark),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textTertiary(isDark)),
              ],
            ),
          ),
        ),
        if (!t.isLast)
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Divider(
              height: 1,
              thickness: 0.6,
              color: isDark ? AppColors.chipDark : AppColors.border,
            ),
          ),
      ],
    );
  }
}

// ─── Logout tile ──────────────────────────────────────────────────────────────
class _LogoutRow extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _LogoutRow({required this.isDark, required this.onTap});
  @override
  State<_LogoutRow> createState() => _LogoutRowState();
}

class _LogoutRowState extends State<_LogoutRow> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _down
              ? AppColors.error.withValues(alpha: 0.12)
              : AppColors.error.withValues(alpha: widget.isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Log Out',
                  style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.error.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
