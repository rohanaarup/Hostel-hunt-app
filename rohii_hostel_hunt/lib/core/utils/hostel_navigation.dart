// ─────────────────────────────────────────────────────────
// Hostel Hunt — Central Navigation Utility
// ─────────────────────────────────────────────────────────
//
// Single source of truth for hostel-related navigation.
// All screens (home, search, filters, future) must use this
// instead of inline Navigator calls, ensuring consistent
// transitions and type safety across the entire app.

import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/pages/hostel_detail.dart';

/// Navigates to the hostel detail screen with a premium
/// right-to-left slide + fade transition.
///
/// Usage from any screen:
/// ```dart
/// navigateToHostelDetails(context, hostel);
/// ```
void navigateToHostelDetails(BuildContext context, Hostel hostel) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          HostelDetailPage(hostel: hostel),
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Combined slide + fade for premium feel
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0), // Enter from right
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.6,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    ),
  );
}
