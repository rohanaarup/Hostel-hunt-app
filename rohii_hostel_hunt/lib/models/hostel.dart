// ─────────────────────────────────────────────────────────
// Hostel Hunt — Hostel Data Model
// ─────────────────────────────────────────────────────────
//
// SINGLE SOURCE OF TRUTH for hostel data across the entire app.
// Every screen (home, search, detail, future) must use THIS model.
// Do NOT create duplicate Hostel classes anywhere else.

class Hostel {
  final String name;
  final String location;
  final String price;
  final double rating;
  final String image;
  final List<String> tags;

  // ── Detail page fields (optional for backward compat) ──
  final List<String> images;       // Gallery carousel
  final List<String> facilities;   // Facility bullet list
  final int reviewCount;           // e.g. 9000
  final String description;        // Short hostel bio
  final String ownerPhone;         // Contact number

  const Hostel({
    required this.name,
    required this.location,
    required this.price,
    required this.rating,
    required this.image,
    required this.tags,
    this.images = const [],
    this.facilities = const [],
    this.reviewCount = 0,
    this.description = '',
    this.ownerPhone = '',
  });

  /// Returns the gallery images. Falls back to [image] if gallery is empty.
  List<String> get galleryImages =>
      images.isNotEmpty ? images : [image];

  // ── JSON serialization stubs (for future API integration) ──

  factory Hostel.fromJson(Map<String, dynamic> json) {
    return Hostel(
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      price: json['price'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      facilities: (json['facilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      ownerPhone: json['ownerPhone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'location': location,
        'price': price,
        'rating': rating,
        'image': image,
        'tags': tags,
        'images': images,
        'facilities': facilities,
        'reviewCount': reviewCount,
        'description': description,
        'ownerPhone': ownerPhone,
      };

  // ── Sample data (future: fetched from API) ──
  // NOTE: Using `static final` (not `static const`) intentionally.
  // `const` instances retain their type identity across hot reloads,
  // which causes "type 'Hostel' is not a subtype of type 'Hostel'"
  // errors when the model file is moved or refactored.

  static final List<Hostel> sampleHostels = [
    Hostel(
      name: "Sri Lakshmi Hostels",
      location: "Kukatpally, Hyderabad",
      price: "₹6,500/mo",
      rating: 4.5,
      image: "images/loading.png",
      tags: ["AC", "Boys"],
      images: ["images/loading.png", "images/bm.png", "images/hostel_kphb.png"],
      facilities: [
        "24 hours hot water",
        "Weekly twice food — non-veg",
        "Thursday — noodles",
        "Friday — fried rice",
        "500m from metro station",
        "Free Wi-Fi",
        "CCTV surveillance",
      ],
      reviewCount: 9200,
      description: "A premium boys hostel in the heart of Kukatpally with modern amenities and home-cooked meals.",
      ownerPhone: "+91 98765 43210",
    ),
    Hostel(
      name: "Green View Residency",
      location: "Gachibowli, Hyderabad",
      price: "₹8,000/mo",
      rating: 4.8,
      image: "images/bm.png",
      tags: ["Premium", "Girls"],
      images: ["images/bm.png", "images/loading.png", "images/hostel_kphb.png"],
      facilities: [
        "Fully furnished rooms",
        "24/7 security",
        "In-house laundry",
        "Gym access",
        "200m from IT Park",
        "Power backup",
        "Daily housekeeping",
      ],
      reviewCount: 12400,
      description: "Premium girls-only residency near IT corridor with world-class facilities.",
      ownerPhone: "+91 87654 32109",
    ),
    Hostel(
      name: "Student Hive",
      location: "Madhapur, Hyderabad",
      price: "₹5,500/mo",
      rating: 4.2,
      image: "images/loading.png",
      tags: ["Non-AC", "Boys"],
      images: ["images/loading.png", "images/bm.png"],
      facilities: [
        "Breakfast included",
        "Study room",
        "Common TV lounge",
        "300m from bus stop",
        "Parking available",
      ],
      reviewCount: 5600,
      description: "Affordable student-friendly hostel with a vibrant community atmosphere.",
      ownerPhone: "+91 76543 21098",
    ),
    Hostel(
      name: "Ritz Grand Hostel",
      location: "Kukatpally, Hyderabad",
      price: "₹4,567/mo",
      rating: 4.8,
      image: "images/hostel_kphb.png",
      tags: ["AC", "Girls"],
      images: ["images/hostel_kphb.png", "images/loading.png", "images/bm.png"],
      facilities: [
        "24 hours hot water",
        "AC rooms with Wi-Fi",
        "Weekly room cleaning",
        "Attached washroom",
        "Near JNTU campus",
        "Rooftop garden",
      ],
      reviewCount: 8900,
      description: "Budget-friendly AC hostel for girls near JNTU with cozy, clean rooms.",
      ownerPhone: "+91 65432 10987",
    ),
  ];
}
