import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/core/cache/last_good_cache.dart';
import 'package:rohii_hostel_hunt/core/network/api_activity.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// Shown over every screen while a request has been waiting for more than a few seconds: a sleeping
/// Render server takes 30 to 60 seconds to wake up and a silent spinner looks like a frozen app.
class ServerWakingBanner extends StatelessWidget {
  const ServerWakingBanner({super.key});

  static const String message = 'Waking the server, this can take a minute';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ApiActivity.slow,
      builder: (context, slow, _) {
        if (!slow) return const SizedBox.shrink();
        return IgnorePointer(
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.ink900.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A line above a list that is NOT fresh: the network failed and the saved copy is on screen.
class SavedCopyBanner extends StatelessWidget {
  const SavedCopyBanner({super.key, required this.savedAt, required this.onRetry, this.what = 'hostels'});

  final DateTime savedAt;
  final VoidCallback onRetry;
  final String what;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.auburn500.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.textSecondary(isDark)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No connection. Showing $what saved ${savedAgo(savedAt, DateTime.now())}.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
