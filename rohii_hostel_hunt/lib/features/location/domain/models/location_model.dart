/// Data model for a saved address in Hostel Hunt.
///
/// Used by [LocationProvider] and the Location Selection screen.
/// Fields are future-ready for backend API integration.
class SavedAddress {
  final String id;
  final String title; // e.g. "Home", "Work", "Other"
  final String fullAddress;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  const SavedAddress({
    required this.id,
    required this.title,
    required this.fullAddress,
    this.phone,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  SavedAddress copyWith({
    String? id,
    String? title,
    String? fullAddress,
    String? phone,
    double? latitude,
    double? longitude,
    double? distanceKm,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      title: title ?? this.title,
      fullAddress: fullAddress ?? this.fullAddress,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  /// Mock data for development — replace with API call later.
  static List<SavedAddress> mockAddresses() {
    return const [
      SavedAddress(
        id: '1',
        title: 'Home',
        fullAddress:
            'testify road, Maisammaguda, Bhadurpalle, Hyderabad',
        phone: '+91-8639687990',
        distanceKm: 9.5,
      ),
      SavedAddress(
        id: '2',
        title: 'Home',
        fullAddress:
            'Vengmamba Boys Hostel, Vengamamba Boys Hostel, Maisammaguda, Dulapally, Hyderabad',
        phone: '+91-9182748841',
        distanceKm: 9.6,
      ),
      SavedAddress(
        id: '3',
        title: 'Home',
        fullAddress: 'no idea, Bahadurpally, Hyderabad',
        phone: '+91-8639687990',
        distanceKm: 8.3,
      ),
    ];
  }
}
