import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/hostel_provider.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';
import 'package:rohii_hostel_hunt/core/utils/hostel_navigation.dart';

class SavedHostelsPage extends ConsumerStatefulWidget {
  const SavedHostelsPage({super.key});
  @override
  ConsumerState<SavedHostelsPage> createState() => _SavedHostelsPageState();
}

class _SavedHostelsPageState extends ConsumerState<SavedHostelsPage> {
  List<Hostel>? _saved;

  void _remove(Hostel h) {
    HapticFeedback.mediumImpact();
    setState(() => _saved?.remove(h));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${h.name} removed from saved',
          style: const TextStyle(color: AppColors.ivory50, fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.ink700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_saved == null) {
      final hostels = ref.watch(hostelListProvider).valueOrNull ?? [];
      _saved = List.from(hostels.take(2));
    }

    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.appBackground(isDark),
        body: Column(
          children: [
            _ProfileSubHeader(title: 'Saved Hostels', isDark: isDark,
                subtitle: '${_saved!.length} hostel${_saved!.length == 1 ? '' : 's'} saved'),
            Expanded(
              child: _saved!.isEmpty
                  ? _EmptyState(icon: Icons.favorite_border_rounded,
                      color: const Color(0xFFE91E63),
                      title: 'No Saved Hostels',
                      message: 'Tap the heart icon on any hostel to save it here for later.',
                      isDark: isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _saved!.length,
                      itemBuilder: (context, i) => _SavedCard(
                        hostel: _saved![i], isDark: isDark,
                        onRemove: () => _remove(_saved![i]),
                        onTap: () => navigateToHostelDetails(context, _saved![i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
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
                child: Image.asset(h.image, width: 110, height: 110, fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      width: 110, height: 110,
                      color: AppColors.auburn500.withValues(alpha: 0.1),
                      child: Icon(Icons.apartment_rounded, color: AppColors.auburn500, size: 36),
                    )),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...h.tags.take(2).map((t) => Container(
                            margin: const EdgeInsets.only(right: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.auburn500.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.auburn500)),
                          )),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(h.name, style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.location_on_rounded, size: 12, color: AppColors.auburn500),
                        const SizedBox(width: 3),
                        Flexible(child: Text(h.location, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(h.price, style: const TextStyle(color: AppColors.auburn500, fontSize: 14, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Row(children: [
                            const Icon(Icons.star_rounded, color: AppColors.auburn500, size: 14),
                            const SizedBox(width: 2),
                            Text('${h.rating}', style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 12, fontWeight: FontWeight.w700)),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Remove button
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
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
class RecentActivityPage extends ConsumerStatefulWidget {
  const RecentActivityPage({super.key});
  @override
  ConsumerState<RecentActivityPage> createState() => _RecentActivityPageState();
}

class _RecentActivityPageState extends ConsumerState<RecentActivityPage> {
  List<_RecentItem>? _history;

  void _clearAll(bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear History?', style: TextStyle(color: AppColors.textHeading(isDark), fontWeight: FontWeight.w700)),
        content: Text('Remove all recently viewed hostels?',
            style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(isDark)))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); setState(() => _history?.clear()); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.ivory50,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_history == null) {
      final hostels = ref.watch(hostelListProvider).valueOrNull ?? [];
      _history = hostels.length >= 4
          ? [
              _RecentItem(hostel: hostels[0], viewedAt: 'Today, 10:32 AM'),
              _RecentItem(hostel: hostels[2], viewedAt: 'Today, 9:15 AM'),
              _RecentItem(hostel: hostels[1], viewedAt: 'Yesterday, 6:48 PM'),
              _RecentItem(hostel: hostels[3], viewedAt: 'Yesterday, 2:10 PM'),
            ]
          : hostels.map((h) => _RecentItem(hostel: h, viewedAt: 'Recently')).toList();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.appBackground(isDark),
        body: Column(
          children: [
            _ProfileSubHeader(
              title: 'Recently Viewed', isDark: isDark,
              subtitle: '${_history!.length} hostel${_history!.length == 1 ? '' : 's'} viewed',
              action: _history!.isEmpty ? null : TextButton(
                onPressed: () => _clearAll(isDark),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
            Expanded(
              child: _history!.isEmpty
                  ? _EmptyState(icon: Icons.history_rounded, color: const Color(0xFF7C4DFF),
                      title: 'No Recent Activity', message: 'Hostels you browse will appear here.', isDark: isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _history!.length,
                      itemBuilder: (context, i) {
                        final item = _history![i];
                        return _RecentCard(
                          item: item, isDark: isDark,
                          onTap: () => navigateToHostelDetails(context, item.hostel),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentItem {
  final Hostel hostel;
  final String viewedAt;
  const _RecentItem({required this.hostel, required this.viewedAt});
}

class _RecentCard extends StatelessWidget {
  final _RecentItem item;
  final bool isDark;
  final VoidCallback onTap;
  const _RecentCard({required this.item, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = item.hostel;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppColors.ivory700 : AppColors.ivory300, width: 0.8),
          boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: isDark ? 0.18 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(h.image, width: 68, height: 68, fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Container(
                    width: 68, height: 68,
                    color: AppColors.auburn500.withValues(alpha: 0.1),
                    child: const Icon(Icons.apartment_rounded, color: AppColors.auburn500),
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name, style: TextStyle(color: AppColors.textHeading(isDark), fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(h.location, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(children: [
                    Text(h.price, style: const TextStyle(color: AppColors.auburn500, fontSize: 13, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Icon(Icons.access_time_rounded, size: 11, color: AppColors.textSecondary(isDark)),
                    const SizedBox(width: 3),
                    Text(item.viewedAt, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 10)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary(isDark)),
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
  final Widget? action;
  const _ProfileSubHeader({required this.title, required this.subtitle, required this.isDark, this.action});

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
          if (action != null) action!,
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
  const _EmptyState({required this.icon, required this.color, required this.title, required this.message, required this.isDark});

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
          ],
        ),
      ),
    );
  }
}

