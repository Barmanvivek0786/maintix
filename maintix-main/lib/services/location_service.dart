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
    defaultValue: '',
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

  /// Get current GPS position.
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('getCurrentPosition error: $e');
      return null;
    }
  }

  /// Reverse geocode using LocationIQ API.
  /// Format: "{Area}, {City}, {State}"
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
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          // Area: road / neighbourhood / suburb
          final area =
              address['road'] as String? ??
              address['neighbourhood'] as String? ??
              address['suburb'] as String? ??
              address['quarter'] as String? ??
              address['pedestrian'] as String?;

          // City: city / town / village / county
          final city =
              address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String? ??
              address['county'] as String?;

          // State
          final state = address['state'] as String?;

          final parts = <String>[];
          if (area != null && area.isNotEmpty) parts.add(area);
          if (city != null && city.isNotEmpty) parts.add(city);
          if (state != null && state.isNotEmpty) parts.add(state);

          if (parts.isNotEmpty) return parts.join(', ');
        }

        // Fallback to display_name trimmed
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          final segments = displayName
              .split(',')
              .take(3)
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
