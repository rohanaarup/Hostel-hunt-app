import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/features/dashboard/models/dashboard_stats_model.dart';

class DashboardRepository {
  final ApiService _api;

  DashboardRepository(this._api);

  /// Fetches aggregated stats for the authenticated student.
  /// Endpoint: GET /dashboard/student/stats/
  Future<DashboardStats> fetchDashboardStats() async {
    final response = await _api.authGetRaw('/dashboard/student/stats/');

    if (!response.success) {
      throw response.toException();
    }

    final body = response.body;
    if (body is! Map<String, dynamic>) {
      throw ApiException(ApiError.unreadable(response.statusCode));
    }

    return DashboardStats.fromJson(body);
  }
}
