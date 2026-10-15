import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rohii_hostel_hunt/features/auth/presentation/pages/login_page.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/wishlist/presentation/providers/saved_provider.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// What every heart does when tapped: save or un-save with the heart changing at once, ask for a
/// login when nobody is signed in, and say plainly when the server refused (the heart goes back).
Future<void> onHeartTapped(BuildContext context, WidgetRef ref, Hostel hostel) async {
  HapticFeedback.mediumImpact();
  var outcome = await ref.read(savedIdsProvider.notifier).toggle(hostel.id);
  if (!context.mounted) return;

  if (outcome.result == SaveResult.needsLogin) {
    final wantsLogin = await _askToLogin(context);
    if (wantsLogin != true || !context.mounted) return;
    final loggedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage(popOnSuccess: true)),
    );
    if (loggedIn != true || !context.mounted) return;
    // They came here to save this hostel: save it, whatever the heart said before they logged in.
    outcome = await ref.read(savedIdsProvider.notifier).toggle(hostel.id, wantSaved: true);
    if (!context.mounted) return;
  }

  switch (outcome.result) {
    case SaveResult.saved:
      _message(
        context,
        '${hostel.name} saved',
        color: AppColors.success,
        action: SnackBarAction(
          label: 'View',
          textColor: AppColors.ivory50,
          onPressed: () => context.push('/profile/saved'),
        ),
      );
    case SaveResult.removed:
      _message(context, 'Removed from saved');
    case SaveResult.failed:
      _message(
        context,
        outcome.error?.message ?? 'Could not update your saved hostels. Please try again.',
        color: AppColors.error,
        action: SnackBarAction(
          label: 'Retry',
          textColor: AppColors.ivory50,
          onPressed: () => onHeartTapped(context, ref, hostel),
        ),
      );
    case SaveResult.needsLogin:
    case SaveResult.ignored:
      break;
  }
}

Future<bool?> _askToLogin(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log in to save hostels'),
      content: const Text('Saved hostels are kept with your account, so you can find them again on any phone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log in')),
      ],
    ),
  );
}

void _message(BuildContext context, String text, {Color? color, SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        action: action,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
}
