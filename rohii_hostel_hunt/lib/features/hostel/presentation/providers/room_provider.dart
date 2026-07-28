import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rohii_hostel_hunt/features/hostel/domain/models/room.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';

final roomsProvider = FutureProvider.family<Map<int, List<Room>>, String>((ref, hostelId) async {
  final url = Uri.parse('${ApiService.baseUrl}/hostels/$hostelId/rooms/');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    final rooms = data.map((json) => Room.fromJson(json)).toList();

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
  } else {
    throw Exception('Failed to load rooms');
  }
});
