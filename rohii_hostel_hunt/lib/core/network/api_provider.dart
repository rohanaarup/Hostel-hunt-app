import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';

/// ─────────────────────────────────────────────────────────
/// Riverpod DI wrapper for the existing ApiService singleton.
/// ─────────────────────────────────────────────────────────
///
/// This preserves the existing ApiService exactly as-is.
/// Other providers can declare a dependency on apiServiceProvider
/// to get the singleton instance via ref.read(apiServiceProvider).

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
