import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/core/network/api_service.dart';

enum BookingStatus { idle, loading, success, error }

class BookingState {
  final BookingStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  BookingState({
    this.status = BookingStatus.idle,
    this.errorMessage,
    this.data,
  });

  BookingState copyWith({
    BookingStatus? status,
    String? errorMessage,
    Map<String, dynamic>? data,
  }) {
    return BookingState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      data: data ?? this.data,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final ApiService _apiService;

  BookingNotifier(this._apiService) : super(BookingState());

  Future<void> submitBooking({
    required String hostelId,
    required String roomId,
    required String roomName,
    required String floorNumber,
    required String roomNumber,
    required String bedNumber,
    required String checkInDate,
  }) async {
    state = state.copyWith(status: BookingStatus.loading, errorMessage: null);

    try {
      final payload = {
        'hostel': hostelId,
        'room': roomId,
        'room_name': roomName,
        'floor_number': floorNumber,
        'room_number': roomNumber,
        'bed_number': bedNumber,
        'check_in_date': checkInDate,
      };

      final response = await _apiService.authPostRaw('/bookings/', payload);
      
      if (response.success && (response.statusCode == 201 || response.statusCode == 200)) {
        state = state.copyWith(
          status: BookingStatus.success, 
          data: response.body is Map ? response.body as Map<String, dynamic> : null
        );
      } else {
        state = state.copyWith(
          status: BookingStatus.error, 
          errorMessage: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: BookingStatus.error, 
        errorMessage: e.toString(),
      );
    }
  }
  
  void reset() {
    state = BookingState();
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier(ApiService());
});
