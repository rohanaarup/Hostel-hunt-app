import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';
import 'package:rohii_hostel_hunt/core/utils/hostel_navigation.dart';
import 'package:rohii_hostel_hunt/features/auth/presentation/pages/login_page.dart';
import 'package:rohii_hostel_hunt/features/home/presentation/widgets/hostel_list_states.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/widgets/hostel_cover_image.dart';
import 'package:rohii_hostel_hunt/features/profile/presentation/providers/user_provider.dart';
import 'package:rohii_hostel_hunt/features/wishlist/presentation/providers/saved_provider.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

// ── Saved Hostels ─────────────────────────────────────────────────────────────
/// The hostels this person has saved: the real list from the server, one page at a time.
class SavedHostelsPage extends ConsumerStatefulWidget {
  const SavedHostelsPage({super.key});
  @override
  ConsumerState<SavedHostelsPage> createState() => _SavedHostelsPageState();
}

class _SavedHostelsPageState extends ConsumerState<SavedHostelsPage> {
  void _say(String text, {Color? color, SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text, style: const TextStyle(color: AppColors.ivory50, fontWeight: FontWeight.w500)),
        backgroundColor: color ?? AppColors.ink700,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 3),
      ));
  }

  Future<void> _remove(Hostel hostel) async {
    HapticFeedback.mediumImpact();
    final outcome = await ref.read(savedListProvider.notifier).remove(hostel);
    if (outcome.result == SaveResult.removed) {
      _say(
        '${hostel.name} removed from saved',
        action: SnackBarAction(label: 'Undo', textColor: AppColors.ivory50, onPressed: () => _undo(hostel)),
      );
    } else if (outcome.result == SaveResult.failed) {
      _say(outcome.error?.message ?? 'Could not remove it. Please try again.', color: AppColors.error);
    }
  }

  Future<void> _undo(Hostel hostel) async {
    final outcome = await ref.read(savedIdsProvider.notifier).toggle(hostel.id, wantSaved: true, refreshList: false);
    if (outcome.result == SaveResult.failed) {
      _say(outcome.error?.message ?? 'Could not save it again. Please try again.', color: AppColors.error);
      return;
    }
    await ref.read(savedListProvider.notifier).refresh();
  }

  Future<void> _login() async {
    await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginPage(popOnSuccess: true)));
    // LoginPage reloads the profile and the saved hostels when it succeeds.
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(savedListProvider);
    final paging = ref.watch(savedPagingProvider);
    final user = ref.watch(userProvider);
    final loggedOut = !user.isLoading && !user.hasError && user.valueOrNull == null;
    final count = ref.watch(savedIdsProvider).valueOrNull?.length ?? list.valueOrNull?.length ?? 0;

    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.appBackground(isDark),
        body: Column(
          children: [
            _ProfileSubHeader(
              title: 'Saved Hostels',
              isDark: isDark,
              subtitle: loggedOut ? 'Log in to see them' : '$count hostel${count == 1 ? '' : 's'} saved',
            ),
            Expanded(child: _body(isDark, list, paging, loggedOut)),
          ],
        ),
      ),
    );
  }

  Widget _body(bool isDark, AsyncValue<List<Hostel>> list, HostelPaging paging, bool loggedOut) {
    if (loggedOut) {
      return _EmptyState(
        icon: Icons.favorite_border_rounded,
        color: const Color(0xFFE91E63),
        title: 'Log in to see your saved hostels',
        message: 'Saved hostels are kept with your account, so you can find them again on any phone.',
        isDark: isDark,
        action: FilledButton(onPressed: _login, child: const Text('Log in')),
      );
    }
    return list.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => HostelListErrorState(
        message: userMessageOf(error),
        isDark: isDark,
        onRetry: () => ref.read(savedListProvider.notifier).refresh(),
      ),
      data: (hostels) {
        if (hostels.isEmpty) {
          return _EmptyState(
            icon: Icons.favorite_border_rounded,
            color: const Color(0xFFE91E63),
            title: 'No Saved Hostels',
            message: 'Tap the heart icon on any hostel to save it here for later.',
            isDark: isDark,
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(savedListProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: hostels.length + 1,
            itemBuilder: (context, i) {
              if (i == hostels.length) {
                // Built only when the end of the list comes into view: time for the next page.
                final canLoadMore = paging.hasMore && !paging.loadingMore && paging.loadMoreError == null;
                if (canLoadMore) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) ref.read(savedListProvider.notifier).loadMore();
                  });
                }
                return HostelListFooter(
                  loading: paging.hasMore && paging.loadMoreError == null,
                  error: paging.loadMoreError,
                  isDark: isDark,
                  onRetry: () => ref.read(savedListProvider.notifier).loadMore(),
                );
              }
              final hostel = hostels[i];
              return _SavedCard(
                hostel: hostel,
                isDark: isDark,
                onRemove: () => _remove(hostel),
                onTap: () => navigateToHostelDetails(context, hostel),
              );
            },
          ),
        );
      },
    );
  }
}

class _SavedCard extends StatefulWidget {
  final Hostel hostel;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  const _SavedCard({required this.hostel, required this.isDark, required this.onRemove, required this.onTap});

  @override
  State<_SavedCard> createState() => _SavedCardState();
}

class _SavedCardState extends State<_SavedCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.hostel;
    final isDark = widget.isDark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBg(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.ivory700 : AppColors.ivory300, width: 0.8),
            boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 16, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              // Hostel image
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                child: HostelCoverImage(source: h.image, width: 110, height: 110),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name, style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.location_on_rounded, size: 12, color: AppColors.auburn500),
                        const SizedBox(width: 3),
                        Flexible(child: Text(h.location, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 8),
                      Text(h.price, style: const TextStyle(color: AppColors.auburn500, fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              // Remove button
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  key: const Key('saved-remove'),
                  onTap: widget.onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Color(0xFFE91E63), size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recently Viewed ───────────────────────────────────────────────────────────
/// Not built yet. It used to show made-up hostels with made-up times; now it says so honestly.
class RecentActivityPage extends StatelessWidget {
  const RecentActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.appBackground(isDark),
        body: Column(
          children: [
            _ProfileSubHeader(title: 'Recently Viewed', isDark: isDark, subtitle: 'Coming soon'),
            Expanded(
              child: _EmptyState(
                icon: Icons.history_rounded,
                color: const Color(0xFF7C4DFF),
                title: 'Coming soon',
                message: "We'll keep track of the hostels you look at here in a future update.",
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-page header ────────────────────────────────────────────────────
class _ProfileSubHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  const _ProfileSubHeader({required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: isDark ? 0.22 : 0.07), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          GestureDetector(
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
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state widget ────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final bool isDark;
  final Widget? action;
  const _EmptyState({required this.icon, required this.color, required this.title, required this.message, required this.isDark, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 22),
            Text(title, style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(message, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 14, height: 1.5), textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

