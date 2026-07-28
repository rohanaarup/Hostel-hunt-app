class Room {
  final String roomId;
  final String hostelId;
  final int floorNumber;
  final String roomNumber;
  final String roomName;
  final String sharingType;
  final int capacity;
  final int bedCount;
  final double pricePerMonth;
  final int availableBeds;
  final bool hasAttachedBathroom;
  final bool isAc;
  final String description;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const Room({
    required this.roomId,
    required this.hostelId,
    required this.floorNumber,
    required this.roomNumber,
    required this.roomName,
    required this.sharingType,
    required this.capacity,
    required this.bedCount,
    required this.pricePerMonth,
    required this.availableBeds,
    required this.hasAttachedBathroom,
    required this.isAc,
    this.description = '',
    this.isActive = true,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['room_id'] as String? ?? '',
      hostelId: json['hostel_id'] as String? ?? '',
      floorNumber: (json['floor_number'] as num?)?.toInt() ?? 1,
      roomNumber: json['room_number'] as String? ?? '',
      roomName: json['room_name'] as String? ?? '',
      sharingType: json['sharing_type'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 1,
      bedCount: (json['bed_count'] as num?)?.toInt() ?? 1,
      pricePerMonth: _parseDouble(json['price_per_month']),
      availableBeds: (json['available_beds'] as num?)?.toInt() ?? 0,
      hasAttachedBathroom: json['has_attached_bathroom'] as bool? ?? false,
      isAc: json['is_ac'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
