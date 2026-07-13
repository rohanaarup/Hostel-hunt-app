// ─────────────────────────────────────────────────────────
// Hostel Hunt — Hostel Data Model
// ─────────────────────────────────────────────────────────
//
// SINGLE SOURCE OF TRUTH for hostel data across the entire app.
// Every screen (home, search, detail, future) must use THIS model.
// Do NOT create duplicate Hostel classes anywhere else.
//
// Field names match the Django REST Framework serializer output:
//   - HostelListSerializer  → list endpoint fields
//   - HostelDetailSerializer → detail endpoint fields (__all__ + images + average_rating)

/// Nested image model matching `HostelImageSerializer` output.
class HostelImage {
  final String id;
  final String imageUrl; // relative URL path from backend
  final String caption;

  const HostelImage({
    this.id = '',
    this.imageUrl = '',
    this.caption = '',
  });

  factory HostelImage.fromJson(Map<String, dynamic> json) {
    return HostelImage(
      id: json['id'] as String? ?? '',
      imageUrl: json['remote_url'] as String? ?? 
                json['file_url'] as String? ?? 
                json['file'] as String? ?? '',
      caption: json['file_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'file': imageUrl,
        'file_name': caption,
      };
}

class Hostel {
  // ── Primary fields (from DRF serializer) ──
  final String id;
  final String name;
  final String city;
  final String state;
  final String address;
  final String pincode;
  final String hostelType; // 'boys', 'girls', 'mixed'
  final double pricePerMonth;
  final double securityDeposit;
  final List<String> amenities; // list of strings from backend
  final List<String> occupancyTypes;
  final String? landmark;
  final String? rules;
  final String? checkInPolicy;
  final String? checkOutPolicy;
  final String? googleMapsUrl;
  final bool isAvailable;
  final int availableRooms;
  final int totalRooms;
  final double averageRating;
  final int imageCount; // from list serializer only
  final String description;
  final String contactPhone;
  final String contactEmail;
  final double? latitude;
  final double? longitude;
  final int? owner;
  final String createdAt;
  final String updatedAt;

  // ── Nested data (from detail serializer) ──
  final List<HostelImage> imagesList; // nested HostelImage objects

  // ── Flag to distinguish API-sourced vs local sample data ──
  final bool isLocal;

  // ── Local asset paths (only used by sampleHostels) ──
  final String _localImage;
  final List<String> _localImages;

  const Hostel({
    this.id = '',
    required this.name,
    this.city = '',
    this.state = '',
    this.address = '',
    this.pincode = '',
    this.hostelType = 'mixed',
    this.pricePerMonth = 0,
    this.securityDeposit = 0,
    this.amenities = const [],
    this.occupancyTypes = const [],
    this.landmark,
    this.rules,
    this.checkInPolicy,
    this.checkOutPolicy,
    this.googleMapsUrl,
    this.isAvailable = true,
    this.availableRooms = 0,
    this.totalRooms = 0,
    this.averageRating = 0.0,
    this.imageCount = 0,
    this.description = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.latitude,
    this.longitude,
    this.owner,
    this.createdAt = '',
    this.updatedAt = '',
    this.imagesList = const [],
    this.isLocal = false,
    String localImage = '',
    List<String> localImages = const [],
  })  : _localImage = localImage,
        _localImages = localImages;

  // ═══════════════════════ BACKWARD-COMPAT GETTERS ═══════════════════════
  //
  // These let existing UI code (hostel_detail.dart, premium_hostel_card.dart,
  // search_result_card.dart, etc.) continue to reference the old field names
  // without modification. Internally the model stores the correct backend
  // field names.

  /// Combined location string for display (replaces old `location` field).
  String get location {
    if (city.isEmpty && state.isEmpty) return address;
    if (state.isEmpty) return city;
    return '$city, $state';
  }

  /// Formatted price string for display (replaces old `price` field).
  String get price {
    if (pricePerMonth == 0) return 'Contact for price';
    // Format without decimals if it's a whole number
    final formatted = pricePerMonth == pricePerMonth.roundToDouble()
        ? '₹${pricePerMonth.round()}/mo'
        : '₹${pricePerMonth.toStringAsFixed(0)}/mo';
    return formatted;
  }

  /// Rating alias (replaces old `rating` field).
  double get rating => averageRating;

  /// Primary image for card thumbnails (replaces old `image` field).
  /// Returns local asset path for sample data, network URL for API data.
  String get image {
    if (isLocal && _localImage.isNotEmpty) return _localImage;
    if (imagesList.isNotEmpty) return imagesList.first.imageUrl;
    return '';
  }

  /// Tag chips derived from hostelType (replaces old `tags` field).
  List<String> get tags {
    final result = <String>[];
    switch (hostelType) {
      case 'boys':
        result.add('Boys');
      case 'girls':
        result.add('Girls');
      case 'mixed':
        result.add('Co-ed');
    }
    // Add AC tag if amenities mention it
    if (amenities.any((a) => a.toLowerCase().contains('ac'))) {
      result.add('AC');
    }
    return result;
  }

  /// Facility list derived from amenities (replaces old `facilities` field).
  List<String> get facilities => amenities;

  /// Review count — backend doesn't return this in current serializer.
  int get reviewCount => 0;

  /// Gallery images for the carousel.
  /// Returns local asset paths for sample data, network URLs for API data.
  List<String> get galleryImages {
    if (isLocal && _localImages.isNotEmpty) return _localImages;
    if (imagesList.isNotEmpty) {
      return imagesList.map((img) => img.imageUrl).toList();
    }
    // Fall back to primary image
    final primary = image;
    return primary.isNotEmpty ? [primary] : [];
  }

  /// Owner phone (alias for cleaner access).
  String get ownerPhone => contactPhone;

  // ═══════════════════════ JSON SERIALIZATION ═══════════════════════

  factory Hostel.fromJson(Map<String, dynamic> json) {
    return Hostel(
      id: json['hostel_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      address: json['address'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      hostelType: json['gender_type'] as String? ?? 'mixed',
      pricePerMonth: _parseDouble(json['price_per_month']),
      securityDeposit: _parseDouble(json['security_deposit']),
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      occupancyTypes: (json['occupancy_types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      landmark: json['landmark'] as String?,
      rules: json['rules'] as String?,
      checkInPolicy: json['check_in_policy'] as String?,
      checkOutPolicy: json['check_out_policy'] as String?,
      googleMapsUrl: json['google_maps_url'] as String?,
      isAvailable: json['is_active'] as bool? ?? true,
      availableRooms: (json['available_rooms'] as num?)?.toInt() ?? 0,
      totalRooms: (json['total_rooms'] as num?)?.toInt() ?? 0,
      averageRating: _parseDouble(json['average_rating']),
      imageCount: (json['image_count'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      contactEmail: json['contact_email'] as String? ?? '',
      latitude: json['latitude'] != null ? _parseDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? _parseDouble(json['longitude']) : null,
      owner: (json['owner'] as num?)?.toInt(),
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      imagesList: ((json['media'] ?? json['media_items']) as List<dynamic>?)
              ?.map((e) => HostelImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isLocal: false,
    );
  }

  /// Helper to parse DRF's decimal fields (returned as String like "5000.00").
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
        'hostel_id': id,
        'name': name,
        'city': city,
        'state': state,
        'address': address,
        'pincode': pincode,
        'gender_type': hostelType,
        'price_per_month': pricePerMonth,
        'security_deposit': securityDeposit,
        'amenities': amenities,
        'occupancy_types': occupancyTypes,
        'landmark': landmark,
        'rules': rules,
        'check_in_policy': checkInPolicy,
        'check_out_policy': checkOutPolicy,
        'google_maps_url': googleMapsUrl,
        'is_active': isAvailable,
        'available_rooms': availableRooms,
        'total_rooms': totalRooms,
        'average_rating': averageRating,
        'image_count': imageCount,
        'description': description,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'latitude': latitude,
        'longitude': longitude,
        'owner': owner,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'media_items': imagesList.map((e) => e.toJson()).toList(),
      };

  /// Create a merged copy with detail data overlaid on top of list data.
  Hostel mergeWithDetail(Hostel detail) {
    return Hostel(
      id: detail.id,
      name: detail.name.isNotEmpty ? detail.name : name,
      city: detail.city.isNotEmpty ? detail.city : city,
      state: detail.state.isNotEmpty ? detail.state : state,
      address: detail.address,
      pincode: detail.pincode,
      hostelType: detail.hostelType,
      pricePerMonth: detail.pricePerMonth > 0 ? detail.pricePerMonth : pricePerMonth,
      securityDeposit: detail.securityDeposit,
      amenities: detail.amenities.isNotEmpty ? detail.amenities : amenities,
      isAvailable: detail.isAvailable,
      availableRooms: detail.availableRooms,
      totalRooms: detail.totalRooms,
      averageRating: detail.averageRating > 0 ? detail.averageRating : averageRating,
      imageCount: detail.imageCount > 0 ? detail.imageCount : imageCount,
      description: detail.description,
      contactPhone: detail.contactPhone,
      contactEmail: detail.contactEmail,
      latitude: detail.latitude,
      longitude: detail.longitude,
      owner: detail.owner,
      createdAt: detail.createdAt,
      updatedAt: detail.updatedAt,
      imagesList: detail.imagesList.isNotEmpty ? detail.imagesList : imagesList,
      isLocal: false,
    );
  }


}
