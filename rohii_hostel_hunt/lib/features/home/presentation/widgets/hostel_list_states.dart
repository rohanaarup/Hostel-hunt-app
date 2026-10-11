import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// Shown when the selected area has no hostels. Inside a locality it offers to widen to the whole city.
class HostelListEmptyState extends StatelessWidget {
  final String city;
  final String? locality;
  final bool isDark;
  final VoidCallback onShowAll;

  const HostelListEmptyState({
    super.key,
    required this.city,
    required this.locality,
    required this.isDark,
    required this.onShowAll,
  });

  bool get _hasLocality => locality != null && locality!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.auburn500.withValues(alpha: 0.12),
                    AppColors.auburn300.withValues(alpha: 0.06),
                  ],
                ),
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 44,
                color: AppColors.auburn500.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _hasLocality ? 'No hostels in $locality' : 'No hostels available',
              style: TextStyle(
                color: AppColors.textHeading(isDark),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasLocality ? 'No listings match this area yet' : 'Check back later for new listings',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 14),
            ),
            if (_hasLocality) ...[
              const SizedBox(height: 20),
              _GradientButton(label: 'Show all in $city', onTap: onShowAll),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown when the list could not be loaded: the reason, and a Retry button.
class HostelListErrorState extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback onRetry;

  const HostelListErrorState({
    super.key,
    required this.message,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load hostels',
              style: TextStyle(
                color: AppColors.textHeading(isDark),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            _GradientButton(label: 'Retry', icon: Icons.refresh_rounded, onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

/// The small footer under the list while more hostels load, or when loading more failed.
class HostelListFooter extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool isDark;
  final VoidCallback onRetry;

  const HostelListFooter({
    super.key,
    required this.loading,
    required this.error,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Could not load more. Tap to retry'),
          ),
        ),
      );
    }
    if (!loading) return const SizedBox(height: 8);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.auburn500, AppColors.auburn700]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.auburn500.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.ivory50, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(color: AppColors.ivory50, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
