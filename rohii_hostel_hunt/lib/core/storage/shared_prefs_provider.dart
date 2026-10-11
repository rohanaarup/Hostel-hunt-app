import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's SharedPreferences, loaded once in main() before the first screen builds.
///
/// Providers that need saved settings at their very first build (the selected city and locality)
/// read them from here synchronously, so nothing starts with an empty value and then changes a
/// moment later. Null only in tests that do not override it; those providers fall back to loading
/// the preferences asynchronously.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);
