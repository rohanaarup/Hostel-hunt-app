import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/features/dashboard/data/dashboard_repository.dart';
import 'package:rohii_hostel_hunt/features/dashboard/models/dashboard_stats_model.dart';

// ── Repository provider ───────────────────────────────────────────────────────
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return DashboardRepository(api);
});

// ── AsyncNotifier ─────────────────────────────────────────────────────────────
class DashboardNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    final repo = ref.read(dashboardRepositoryProvider);
    return repo.fetchDashboardStats();
  }

  /// Called by RefreshIndicator to reload the dashboard data.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardStats>(
  DashboardNotifier.new,
);
