// dashboard_stats_model.dart
// Matches the JSON shape from GET /api/v1/dashboard/student/stats/

class ActiveBooking {
  final String id;
  final String? hostelName;
  final String? hostelCity;
  final String? roomName;
  final String? roomNumber;
  final String? bedNumber;
  final String status;
  final String? checkInDate;
  final String? checkOutDate;
  final String? amount;
  final String createdAt;

  const ActiveBooking({
    required this.id,
    this.hostelName,
    this.hostelCity,
    this.roomName,
    this.roomNumber,
    this.bedNumber,
    required this.status,
    this.checkInDate,
    this.checkOutDate,
    this.amount,
    required this.createdAt,
  });

  factory ActiveBooking.fromJson(Map<String, dynamic> json) {
    return ActiveBooking(
      id: json['id'] as String,
      hostelName: json['hostel_name'] as String?,
      hostelCity: json['hostel_city'] as String?,
      roomName: json['room_name'] as String?,
      roomNumber: json['room_number'] as String?,
      bedNumber: json['bed_number'] as String?,
      status: json['status'] as String,
      checkInDate: json['check_in_date'] as String?,
      checkOutDate: json['check_out_date'] as String?,
      amount: json['amount'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

class RecentBookingItem {
  final String id;
  final String? hostelName;
  final String? hostelCity;
  final String status;
  final String? amount;
  final String? checkInDate;
  final String createdAt;

  const RecentBookingItem({
    required this.id,
    this.hostelName,
    this.hostelCity,
    required this.status,
    this.amount,
    this.checkInDate,
    required this.createdAt,
  });

  factory RecentBookingItem.fromJson(Map<String, dynamic> json) {
    return RecentBookingItem(
      id: json['id'] as String,
      hostelName: json['hostel_name'] as String?,
      hostelCity: json['hostel_city'] as String?,
      status: json['status'] as String,
      amount: json['amount'] as String?,
      checkInDate: json['check_in_date'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

class BookingStats {
  final int total;
  final int pending;
  final int confirmed;
  final int paid;
  final int cancelled;
  final int rejected;

  const BookingStats({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.paid,
    required this.cancelled,
    required this.rejected,
  });

  factory BookingStats.fromJson(Map<String, dynamic> json) {
    return BookingStats(
      total: (json['total'] as int?) ?? 0,
      pending: (json['pending'] as int?) ?? 0,
      confirmed: (json['confirmed'] as int?) ?? 0,
      paid: (json['paid'] as int?) ?? 0,
      cancelled: (json['cancelled'] as int?) ?? 0,
      rejected: (json['rejected'] as int?) ?? 0,
    );
  }

  /// Active (non-terminal) count used for the donut chart.
  int get active => pending + confirmed;
}

class DashboardStats {
  final int wishlistCount;
  final BookingStats bookingStats;
  final ActiveBooking? activeBooking;
  final List<RecentBookingItem> recentActivity;

  const DashboardStats({
    required this.wishlistCount,
    required this.bookingStats,
    this.activeBooking,
    required this.recentActivity,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final rawActive = json['active_booking'];
    return DashboardStats(
      wishlistCount: (json['wishlist_count'] as int?) ?? 0,
      bookingStats: BookingStats.fromJson(
        json['booking_stats'] as Map<String, dynamic>? ?? {},
      ),
      activeBooking: rawActive != null
          ? ActiveBooking.fromJson(rawActive as Map<String, dynamic>)
          : null,
      recentActivity: (json['recent_activity'] as List<dynamic>? ?? [])
          .map((e) => RecentBookingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
