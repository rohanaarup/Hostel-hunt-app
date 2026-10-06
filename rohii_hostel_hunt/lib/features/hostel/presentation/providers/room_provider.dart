import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rohii_hostel_hunt/features/hostel/domain/models/room.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';

final roomsProvider = FutureProvider.family<Map<int, List<Room>>, String>((ref, hostelId) async {
  final allRooms = <dynamic>[];
  String? nextUrl = '${ApiService.baseUrl}/hostels/$hostelId/rooms/';

  // DRF paginates this endpoint (10 rooms/page) — a hostel with more rooms
  // than one page must not silently lose floors, so follow `next` until
  // every page has been collected.
  while (nextUrl != null) {
    final response = await http.get(Uri.parse(nextUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to load rooms');
    }

    final body = json.decode(response.body);

    if (body is Map<String, dynamic> && body.containsKey('results')) {
      allRooms.addAll(body['results'] as List<dynamic>);
      nextUrl = body['next'] as String?;
    } else if (body is List) {
      allRooms.addAll(body);
      nextUrl = null;
    } else {
      throw Exception('Unexpected response format.');
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
