import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  static const String _locationIqKey = String.fromEnvironment(
    'LOCATIONIQ_API_KEY',
    defaultValue: 'pk.9021ca0351eccb4c4a9ae57085c14964',
  );

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Check if location services (hardware GPS) are enabled on device.
  Future<bool> isLocationServiceEnabled() async {
    if (kIsWeb) return true;
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission and return whether granted.
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        return requested != LocationPermission.denied &&
            requested != LocationPermission.deniedForever;
      }
      return permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  /// Check if permission is already granted (without prompting).
  Future<bool> isPermissionGranted() async {
    if (kIsWeb) return true;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Open device location settings.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Get current GPS position. Uses `LocationAccuracy.best` (GPS-chip-grade,
  /// same tier apps like Zomato/Swiggy use for the door-step pin) and a
  /// slightly longer time budget so the fix has a chance to settle indoors.
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (e) {
      debugPrint('getCurrentPosition error: $e');
      // Fall back to the last known fix rather than nothing — still far more
      // precise than a city-level address.
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Reverse geocode using LocationIQ API, at building/door-step precision
  /// (zoom=18) — the same level of detail apps like Zomato/Swiggy show.
  /// Format: "{House no/Building}, {Road}, {Area}, {City}"
  Future<String> reverseGeocodeLocationIQ(double lat, double lon) async {
    if (_locationIqKey.isEmpty) {
      return '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
    }

    try {
      final response = await _dio.get(
        'https://us1.locationiq.com/v1/reverse',
        queryParameters: {
          'key': _locationIqKey,
          'lat': lat.toString(),
          'lon': lon.toString(),
          'format': 'json',
          'addressdetails': 1,
          // zoom=18 = building level (max detail LocationIQ/Nominatim support),
          // vs the previous default (~city level).
          'zoom': 18,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          String? str(String key) {
            final v = address[key];
            if (v is String && v.trim().isNotEmpty) return v.trim();
            return null;
          }

          // Door-step level: house/building number + name.
          final houseNumber = str('house_number');
          final building = str('building') ?? str('house_name');

          // Street level.
          final road =
              str('road') ?? str('pedestrian') ?? str('footway') ?? str('path');

          // Immediate locality (colony/mohalla level — more precise than city).
          final locality = str('neighbourhood') ??
              str('suburb') ??
              str('quarter') ??
              str('residential');

          // City / town.
          final city =
              str('city') ?? str('town') ?? str('village') ?? str('county');

          final state = str('state');

          // Build the door-step line, e.g. "12, MG Road" or just "MG Road".
          String? streetLine;
          if (houseNumber != null && road != null) {
            streetLine = '$houseNumber, $road';
          } else {
            streetLine = building ?? road;
          }

          final parts = <String>[];
          void add(String? v) {
            if (v != null && v.isNotEmpty && !parts.contains(v)) parts.add(v);
          }

          add(streetLine);
          add(locality);
          add(city);
          add(state);

          if (parts.isNotEmpty) return parts.join(', ');
        }

        // Fallback to display_name trimmed (more segments than before, to
        // keep street-level detail if the structured address was sparse).
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          final segments = displayName
              .split(',')
              .take(4)
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          return segments.join(', ');
        }
      }
    } catch (e) {
      debugPrint('reverseGeocodeLocationIQ error: $e');
    }
    return '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
  }

  /// Full flow: request permission → get position → reverse geocode via LocationIQ.
  Future<LocationResult?> fetchCurrentLocation() async {
    try {
      final granted = await requestPermission();
      if (!granted) return null;

      final position = await getCurrentPosition();
      if (position == null) return null;

      final address = await reverseGeocodeLocationIQ(
        position.latitude,
        position.longitude,
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      debugPrint('fetchCurrentLocation error: $e');
      return null;
    }
  }
}
