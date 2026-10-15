import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';

import 'package:rohii_hostel_hunt/features/hostel/domain/models/room.dart';

/// How long one rooms request may take before it counts as failed. Tests shorten it.
final roomsRequestTimeoutProvider = Provider<Duration>((ref) => const Duration(seconds: 20));

/// Rooms grouped by floor, floors and the rooms on each floor in order.
Map<int, List<Room>> groupRoomsByFloor(List<Room> rooms) {
  final grouped = <int, List<Room>>{};
  for (final room in rooms) {
    grouped.putIfAbsent(room.floorNumber, () => []).add(room);
  }
  final sorted = Map.fromEntries(grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  for (final floor in sorted.keys) {
    sorted[floor]!.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));
  }
  return sorted;
}

/// The rooms of a hostel, fetched from GET /hostels/{id}/rooms/. Only needed when the hostel on
/// screen has no rooms of its own yet (the detail reply already carries them: see
/// [hostelDetailProvider]). It is dropped when the screen closes, so a failure is never remembered;
/// each request has a time limit; and once the first page says how many rooms there are, the other
/// pages are requested together instead of one after another.
final roomsProvider = FutureProvider.autoDispose.family<Map<int, List<Room>>, String>((ref, hostelId) async {
  final api = ref.read(apiServiceProvider);
  final timeout = ref.watch(roomsRequestTimeoutProvider);

  Future<Map<String, dynamic>> fetchPage(int page) async {
    final response = await api
        .getRaw('/hostels/$hostelId/rooms/', queryParams: page > 1 ? {'page': '$page'} : null)
        .timeout(timeout, onTimeout: () => throw const ApiException(ApiError.timeout));
    if (!response.success) throw response.toException();
    final body = response.body;
    if (body is Map<String, dynamic>) return body;
    if (body is List) return {'results': body, 'next': null};
    throw ApiException(ApiError.unreadable(response.statusCode));
  }

  List<dynamic> resultsOf(Map<String, dynamic> page) => (page['results'] as List<dynamic>?) ?? const [];

  final first = await fetchPage(1);
  final all = [...resultsOf(first)];

  if (first['next'] != null) {
    final count = (first['count'] as num?)?.toInt();
    final perPage = all.length;
    if (count != null && perPage > 0) {
      final lastPage = ((count + perPage - 1) ~/ perPage).clamp(2, 100);
      final rest = await Future.wait([for (var p = 2; p <= lastPage; p++) fetchPage(p)]);
      for (final page in rest) {
        all.addAll(resultsOf(page));
      }
    } else {
      // The server did not say how many: follow `next` one page at a time.
      var page = 2;
      Map<String, dynamic> current = first;
      while (current['next'] != null && page <= 100) {
        current = await fetchPage(page++);
        all.addAll(resultsOf(current));
      }
    }
  }

  return groupRoomsByFloor(all.whereType<Map<String, dynamic>>().map(Room.fromJson).toList());
});
