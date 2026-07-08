import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rohii_hostel_hunt/features/location/domain/models/location_model.dart';

/// Global location state for Hostel Hunt.
///
/// Manages:
///  • Selected city name (shown on homepage header)
///  • Currently selected address
///  • Saved addresses list (mock, future: API)
///  • GPS-based current location detection
class LocationProvider extends ChangeNotifier {
  // ── Selected location (shown on homepage) ──
  String _selectedCity = 'Hyderabad';
  String get selectedCity => _selectedCity;

  SavedAddress? _selectedAddress;
  SavedAddress? get selectedAddress => _selectedAddress;

  // ── Current GPS location ──
  String _currentLocationText = '';
  String get currentLocationText => _currentLocationText;

  bool _isDetectingLocation = false;
  bool get isDetectingLocation => _isDetectingLocation;

  String? _locationError;
  String? get locationError => _locationError;

  // ── Saved addresses ──
  List<SavedAddress> _savedAddresses = [];
  List<SavedAddress> get savedAddresses => _savedAddresses;

  LocationProvider() {
    _savedAddresses = SavedAddress.mockAddresses();
  }

  // ── Select an address and update city ──
  void selectAddress(SavedAddress address) {
    _selectedAddress = address;
    // Extract city from the full address (last segment before country)
    final parts = address.fullAddress.split(',');
    _selectedCity = parts.length >= 2
        ? parts[parts.length - 1].trim()
        : parts.last.trim();
    notifyListeners();
  }

  // ── Set city directly (e.g. from current location) ──
  void setCity(String city) {
    _selectedCity = city;
    notifyListeners();
  }

  // ── Detect current GPS location ──
  Future<void> detectCurrentLocation() async {
    debugPrint('[LocationProvider] detectCurrentLocation() called');
    _isDetectingLocation = true;
    _locationError = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[LocationProvider] Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        _locationError = 'Location services are disabled';
        _isDetectingLocation = false;
        notifyListeners();
        return;
      }

      // Check / request permission
      var permission = await Geolocator.checkPermission();
      debugPrint('[LocationProvider] Current permission: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[LocationProvider] Requested permission, got: $permission');
        if (permission == LocationPermission.denied) {
          _locationError = 'Location permission denied';
          _isDetectingLocation = false;
          notifyListeners();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _locationError = 'Location permission permanently denied. Please enable in Settings.';
        debugPrint('[LocationProvider] Permission permanently denied');
        _isDetectingLocation = false;
        notifyListeners();
        return;
      }

      // Get position
      debugPrint('[LocationProvider] Fetching GPS position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      debugPrint('[LocationProvider] Got position: ${position.latitude}, ${position.longitude}');

      // Reverse geocode
      debugPrint('[LocationProvider] Reverse geocoding...');
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      debugPrint('[LocationProvider] Got ${placemarks.length} placemarks');

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        debugPrint('[LocationProvider] Placemark: subLocality=${p.subLocality}, '
            'locality=${p.locality}, subAdmin=${p.subAdministrativeArea}, '
            'admin=${p.administrativeArea}');

        _currentLocationText = [
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        _selectedCity = p.locality ?? p.subAdministrativeArea ?? 'Unknown';
        debugPrint('[LocationProvider] Resolved: city=$_selectedCity, text=$_currentLocationText');
      } else {
        _currentLocationText = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
            'Lng: ${position.longitude.toStringAsFixed(4)}';
        debugPrint('[LocationProvider] No placemarks, using coords');
      }
    } catch (e, stack) {
      _locationError = 'Could not detect location. Tap to retry.';
      debugPrint('[LocationProvider] ERROR: $e');
      debugPrint('[LocationProvider] Stack: $stack');
    }

    _isDetectingLocation = false;
    notifyListeners();
  }

  // ── Delete a saved address ──
  void deleteAddress(String id) {
    _savedAddresses.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // ── Add a saved address (future: API call) ──
  void addAddress(SavedAddress address) {
    _savedAddresses.add(address);
    notifyListeners();
  }
}
