import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rohii_hostel_hunt/features/location/domain/models/location_model.dart';
import 'package:rohii_hostel_hunt/core/observability/debug_log.dart';
import 'package:rohii_hostel_hunt/core/observability/error_reporter.dart';

/// ─────────────────────────────────────────────────────────
/// Hostel Hunt — Location Provider (Riverpod)
/// ─────────────────────────────────────────────────────────
///
/// Holds:
///   • selectedCity     — e.g. "Hyderabad"
///   • selectedLocality — e.g. "Kondapur" (null = show all in city)
///
/// Persists to SharedPreferences so selection survives app restart.

// ── Immutable state class ──
class LocationState {
  final String selectedCity;
  final String? selectedLocality;
  final SavedAddress? selectedAddress;
  final String currentLocationText;
  final bool isDetectingLocation;
  final String? locationError;
  final List<SavedAddress> savedAddresses;

  const LocationState({
    this.selectedCity = '',
    this.selectedLocality,
    this.selectedAddress,
    this.currentLocationText = '',
    this.isDetectingLocation = false,
    this.locationError,
    this.savedAddresses = const [],
  });

  LocationState copyWith({
    String? selectedCity,
    String? selectedLocality,
    bool clearLocality = false,
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
      selectedLocality: clearLocality ? null : (selectedLocality ?? this.selectedLocality),
      selectedAddress: clearSelectedAddress ? null : (selectedAddress ?? this.selectedAddress),
      currentLocationText: currentLocationText ?? this.currentLocationText,
      isDetectingLocation: isDetectingLocation ?? this.isDetectingLocation,
      locationError: clearLocationError ? null : (locationError ?? this.locationError),
      savedAddresses: savedAddresses ?? this.savedAddresses,
    );
  }

  /// Display label shown in the home header location button.
  String get displayLabel {
    if (selectedLocality != null && selectedLocality!.isNotEmpty) {
      return selectedLocality!;
    }
    if (selectedCity.isNotEmpty) return selectedCity;
    return 'Select City';
  }
}

class LocationNotifier extends Notifier<LocationState> {
  static const _cityKey = 'selected_city';
  static const _localityKey = 'selected_locality';

  @override
  LocationState build() {
    _loadPersistedLocation();
    return const LocationState();
  }

  Future<void> _loadPersistedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString(_cityKey) ?? '';
      final locality = prefs.getString(_localityKey);
      if (city.isNotEmpty) {
        state = state.copyWith(
          selectedCity: city,
          selectedLocality: locality,
        );
      }
    } catch (e, st) {
      errorReporter.report(e, st, hint: 'location: load saved city');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cityKey, state.selectedCity);
      if (state.selectedLocality != null) {
        await prefs.setString(_localityKey, state.selectedLocality!);
      } else {
        await prefs.remove(_localityKey);
      }
    } catch (e, st) {
      errorReporter.report(e, st, hint: 'location: save city');
    }
  }

  /// Select city only — clears locality so we show all hostels in city.
  void setCity(String city) {
    state = state.copyWith(selectedCity: city, clearLocality: true);
    _persist();
  }

  /// Select city + locality (from locality row tap).
  void setCityAndLocality(String city, String locality) {
    state = state.copyWith(selectedCity: city, selectedLocality: locality);
    _persist();
  }

  /// Clear only locality — keep city.
  void clearLocality() {
    state = state.copyWith(clearLocality: true);
    _persist();
  }

  /// Clear both city and locality.
  void clearAll() {
    state = const LocationState();
    _persist();
  }

  /// Select an address and update city — kept for backward compat.
  void selectAddress(SavedAddress address) {
    final parts = address.fullAddress.split(',');
    final city = parts.length >= 2
        ? parts[parts.length - 1].trim()
        : parts.last.trim();
    state = state.copyWith(
      selectedAddress: address,
      selectedCity: city,
      clearLocality: true,
    );
    _persist();
  }

  /// Detect current GPS location and auto-set city.
  Future<void> detectCurrentLocation() async {
    debugLog('[LocationNotifier] detectCurrentLocation() called');
    state = state.copyWith(
      isDetectingLocation: true,
      clearLocationError: true,
    );

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          locationError: 'Location services are disabled',
          isDetectingLocation: false,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            locationError: 'Location permission denied',
            isDetectingLocation: false,
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          locationError: 'Location permission permanently denied. Please enable in Settings.',
          isDetectingLocation: false,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final locationText = [
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        final city = p.locality ?? p.subAdministrativeArea ?? '';
        state = state.copyWith(
          currentLocationText: locationText,
          selectedCity: city,
          clearLocality: true,
          isDetectingLocation: false,
        );
        _persist();
      } else {
        state = state.copyWith(
          currentLocationText: 'Lat: ${position.latitude.toStringAsFixed(4)}, '
              'Lng: ${position.longitude.toStringAsFixed(4)}',
          isDetectingLocation: false,
        );
      }
    } catch (e) {
      debugLog('[LocationNotifier] ERROR: ${e.runtimeType}');
      state = state.copyWith(
        locationError: 'Could not detect location. Tap to retry.',
        isDetectingLocation: false,
      );
    }
  }

  /// Add a saved address.
  void addAddress(SavedAddress address) {
    state = state.copyWith(
      savedAddresses: [...state.savedAddresses, address],
    );
  }

  /// Delete a saved address.
  void deleteAddress(String id) {
    state = state.copyWith(
      savedAddresses: state.savedAddresses.where((a) => a.id != id).toList(),
    );
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);
