import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — Theme Provider (Riverpod)
/// ─────────────────────────────────────────────────────────
///
/// Replaces the global `ValueNotifier<bool> themeNotifier` from
/// lib/services/notifiers.dart.
///
/// Usage:
///   final isDark = ref.watch(themeProvider);
///   ref.read(themeProvider.notifier).toggle();

import 'package:rohii_hostel_hunt/core/theme/notifiers.dart';

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Sync with legacy ValueNotifier
    void listener() {
      state = themeNotifier.value;
    }
    themeNotifier.addListener(listener);
    ref.onDispose(() => themeNotifier.removeListener(listener));
    return themeNotifier.value;
  }

  void toggle() {
    // Updating the legacy notifier will trigger our listener above
    themeNotifier.value = !themeNotifier.value;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, bool>(ThemeNotifier.new);
