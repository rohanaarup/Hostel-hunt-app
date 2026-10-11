import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_error.dart';
import 'package:rohii_hostel_hunt/core/network/api_provider.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/room.dart';

final roomsProvider = FutureProvider.family<Map<int, List<Room>>, String>((ref, hostelId) async {
  final api = ref.read(apiServiceProvider);
  final allRooms = <dynamic>[];

  // DRF paginates this endpoint (10 rooms/page) - a hostel with more rooms
  // than one page must not silently lose floors, so keep asking for the next
  // page until the server says there is none.
  const maxPages = 100;
  for (var page = 1; page <= maxPages; page++) {
    final response = await api.getRaw(
      '/hostels/$hostelId/rooms/',
      queryParams: page > 1 ? {'page': '$page'} : null,
    );
    if (!response.success) throw response.toException();

    final body = response.body;
    if (body is Map<String, dynamic> && body.containsKey('results')) {
      allRooms.addAll(body['results'] as List<dynamic>);
      if (body['next'] == null) break;
    } else if (body is List) {
      allRooms.addAll(body);
      break;
    } else {
      throw ApiException(ApiError.unreadable(response.statusCode));
    }
  }

  final rooms = allRooms.map((json) => Room.fromJson(json)).toList();

  // Group rooms by floorNumber
  final Map<int, List<Room>> groupedRooms = {};
  for (var room in rooms) {
    if (!groupedRooms.containsKey(room.floorNumber)) {
      groupedRooms[room.floorNumber] = [];
    }
    groupedRooms[room.floorNumber]!.add(room);
  }

  // Sort keys and inner lists for consistency
  final sortedGroupedRooms = Map.fromEntries(
    groupedRooms.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key))
  );
  for (var floor in sortedGroupedRooms.keys) {
    sortedGroupedRooms[floor]!.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));
  }

  return sortedGroupedRooms;
});
