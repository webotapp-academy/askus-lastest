import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  String? _city;
  String? _state;
  String? _pincode;
  bool _isLoading = false;
  String? _error;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String? get city => _city;
  String? get state => _state;
  String? get pincode => _pincode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _currentPosition != null;
  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;

  Future<void> loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('location_lat');
    final lng = prefs.getDouble('location_lng');
    _currentAddress = prefs.getString('location_address');
    _city = prefs.getString('location_city');
    _state = prefs.getString('location_state');
    _pincode = prefs.getString('location_pincode');
    
    if (lat != null && lng != null) {
      _currentPosition = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
    notifyListeners();
  }

  Future<bool> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permission permanently denied';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _getAddressFromCoordinates();
      await _saveLocation();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _getAddressFromCoordinates() async {
    if (_currentPosition == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        _city = place.locality ?? place.subAdministrativeArea;
        _state = place.administrativeArea;
        _pincode = place.postalCode;
        _currentAddress = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
    } catch (e) {
      _currentAddress = 'Unable to get address';
    }
  }

  Future<void> _saveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentPosition != null) {
      await prefs.setDouble('location_lat', _currentPosition!.latitude);
      await prefs.setDouble('location_lng', _currentPosition!.longitude);
    }
    if (_currentAddress != null) {
      await prefs.setString('location_address', _currentAddress!);
    }
    if (_city != null) await prefs.setString('location_city', _city!);
    if (_state != null) await prefs.setString('location_state', _state!);
    if (_pincode != null) await prefs.setString('location_pincode', _pincode!);
  }

  Future<void> setManualLocation({
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? state,
    String? pincode,
  }) async {
    _currentPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _currentAddress = address;
    _city = city;
    _state = state;
    _pincode = pincode;
    await _saveLocation();
    notifyListeners();
  }
}
