import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rohii_hostel_hunt/features/location/domain/models/location_model.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — Location Provider (Riverpod)
/// ─────────────────────────────────────────────────────────
///
/// 1:1 translation of the ChangeNotifier-based LocationProvider
/// into a Riverpod Notifier with an immutable state class.
///
/// All existing methods are preserved:
///   • selectAddress / setCity
///   • detectCurrentLocation (GPS)
///   • deleteAddress / addAddress

// ── Immutable state class ──
class LocationState {
  final String selectedCity;
  final SavedAddress? selectedAddress;
  final String currentLocationText;
  final bool isDetectingLocation;
  final String? locationError;
  final List<SavedAddress> savedAddresses;

  const LocationState({
    this.selectedCity = 'Hyderabad',
    this.selectedAddress,
    this.currentLocationText = '',
    this.isDetectingLocation = false,
    this.locationError,
    this.savedAddresses = const [],
  });

  LocationState copyWith({
    String? selectedCity,
    SavedAddress? selectedAddress,
    bool clearSelectedAddress = false,
    String? currentLocationText,
    bool? isDetectingLocation,
    String? locationError,
    bool clearLocationError = false,
    List<SavedAddress>? savedAddresses,
  }) {
    return LocationState(
      selectedCity: selectedCity ?? this.selectedCity,
      selectedAddress: clearSelectedAddress ? null : (selectedAddress ?? this.selectedAddress),
      currentLocationText: currentLocationText ?? this.currentLocationText,
      isDetectingLocation: isDetectingLocation ?? this.isDetectingLocation,
      locationError: clearLocationError ? null : (locationError ?? this.locationError),
      savedAddresses: savedAddresses ?? this.savedAddresses,
    );
  }
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    return LocationState(
      savedAddresses: SavedAddress.mockAddresses(),
    );
  }

  /// Select an address and update city — same as LocationProvider.selectAddress
  void selectAddress(SavedAddress address) {
    final parts = address.fullAddress.split(',');
    final city = parts.length >= 2
        ? parts[parts.length - 1].trim()
        : parts.last.trim();
    state = state.copyWith(
      selectedAddress: address,
      selectedCity: city,
    );
  }

  /// Set city directly — same as LocationProvider.setCity
  void setCity(String city) {
    state = state.copyWith(selectedCity: city);
  }

  /// Detect current GPS location — same as LocationProvider.detectCurrentLocation
  Future<void> detectCurrentLocation() async {
    debugPrint('[LocationNotifier] detectCurrentLocation() called');
    state = state.copyWith(
      isDetectingLocation: true,
      clearLocationError: true,
    );

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[LocationNotifier] Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        state = state.copyWith(
          locationError: 'Location services are disabled',
          isDetectingLocation: false,
        );
        return;
      }

      // Check / request permission
      var permission = await Geolocator.checkPermission();
      debugPrint('[LocationNotifier] Current permission: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[LocationNotifier] Requested permission, got: $permission');
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            locationError: 'Location permission denied',
            isDetectingLocation: false,
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationNotifier] Permission permanently denied');
        state = state.copyWith(
          locationError: 'Location permission permanently denied. Please enable in Settings.',
          isDetectingLocation: false,
        );
        return;
      }

      // Get position
      debugPrint('[LocationNotifier] Fetching GPS position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      debugPrint('[LocationNotifier] Got position: ${position.latitude}, ${position.longitude}');

      // Reverse geocode
      debugPrint('[LocationNotifier] Reverse geocoding...');
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      debugPrint('[LocationNotifier] Got ${placemarks.length} placemarks');

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        debugPrint('[LocationNotifier] Placemark: subLocality=${p.subLocality}, '
            'locality=${p.locality}, subAdmin=${p.subAdministrativeArea}, '
            'admin=${p.administrativeArea}');

        final locationText = [
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        final city = p.locality ?? p.subAdministrativeArea ?? 'Unknown';
        debugPrint('[LocationNotifier] Resolved: city=$city, text=$locationText');

        state = state.copyWith(
          currentLocationText: locationText,
          selectedCity: city,
          isDetectingLocation: false,
        );
      } else {
        state = state.copyWith(
          currentLocationText: 'Lat: ${position.latitude.toStringAsFixed(4)}, '
              'Lng: ${position.longitude.toStringAsFixed(4)}',
          isDetectingLocation: false,
        );
        debugPrint('[LocationNotifier] No placemarks, using coords');
      }
    } catch (e, stack) {
      debugPrint('[LocationNotifier] ERROR: $e');
      debugPrint('[LocationNotifier] Stack: $stack');
      state = state.copyWith(
        locationError: 'Could not detect location. Tap to retry.',
        isDetectingLocation: false,
      );
    }
  }

  /// Delete a saved address — same as LocationProvider.deleteAddress
  void deleteAddress(String id) {
    state = state.copyWith(
      savedAddresses: state.savedAddresses.where((a) => a.id != id).toList(),
    );
  }

  /// Add a saved address — same as LocationProvider.addAddress
  void addAddress(SavedAddress address) {
    state = state.copyWith(
      savedAddresses: [...state.savedAddresses, address],
    );
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);
