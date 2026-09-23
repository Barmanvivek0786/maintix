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

  // Mappls (MapmyIndia) — primary reverse-geocoder. Mappls has the deepest
  // India-specific address data (house/building level, gali/mohalla,
  // society names) — the same tier of precision Zomato/Swiggy/Flipkart use
  // for their door-step delivery pin, and noticeably better than generic
  // OSM-based providers for Indian addresses.
  static const String _mapplsKey = String.fromEnvironment(
    'MAPPLS_API_KEY',
    defaultValue: 'afrxvvpdutbnfrctntffykqkdtebbqojdsej',
  );

  // LocationIQ — kept as a fallback if Mappls is unreachable/fails or
  // returns no usable result (e.g. outside India).
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

  /// Reverse geocode using the Mappls (MapmyIndia) Advanced Maps API, at
  /// door-step precision — house/building number, street, gali/mohalla
  /// (sub-locality) and locality, exactly like Zomato/Swiggy/Flipkart show
  /// on their delivery-address screens.
  /// Format: "{House no/Building}, {Street}, {Sub-locality/Mohalla}, {Locality}, {City}"
  Future<String?> reverseGeocodeMappls(double lat, double lon) async {
    if (_mapplsKey.isEmpty) return null;

    try {
      final response = await _dio.get(
        'https://apis.mappls.com/advancedmaps/v1/$_mapplsKey/rev_geocode',
        queryParameters: {'lat': lat.toString(), 'lng': lon.toString()},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List?;
        if (results == null || results.isEmpty) return null;
        final r = results.first as Map<String, dynamic>;

        String? str(String key) {
          final v = r[key];
          if (v is String && v.trim().isNotEmpty && v.trim() != 'NA') {
            return v.trim();
          }
          return null;
        }

        // Door-step level: house/building number + POI/building name.
        final houseNumber = str('houseNumber');
        final houseName = str('houseName') ?? str('poi');

        // Street / road.
        final street = str('street');

        // Gali/mohalla level — the finest granularity below street.
        final subSubLocality = str('subSubLocality');
        final subLocality = str('subLocality');

        // Locality / area.
        final locality = str('locality') ?? str('village');

        // City / district.
        final city = str('city') ?? str('district') ?? str('subDistrict');
        final state = str('state');
        final pincode = str('pincode');

        String? streetLine;
        if (houseNumber != null && street != null) {
          streetLine = '$houseNumber, $street';
        } else {
          streetLine = houseName ?? street;
        }

        final parts = <String>[];
        void add(String? v) {
          if (v != null && v.isNotEmpty && !parts.contains(v)) parts.add(v);
        }

        add(streetLine);
        add(subSubLocality);
        add(subLocality);
        add(locality);
        add(city);
        add(state);
        if (pincode != null) add(pincode);

        if (parts.isNotEmpty) return parts.join(', ');

        final formatted = str('formatted_address');
        if (formatted != null) return formatted;
      }
    } catch (e) {
      debugPrint('reverseGeocodeMappls error: $e');
    }
    return null;
  }

  /// Reverse geocode using LocationIQ API, at building/door-step precision
  /// (zoom=18). Used as a fallback when Mappls fails or has no coverage.
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

  /// Reverse geocode with Mappls first (best precision for Indian
  /// addresses), falling back to LocationIQ, then raw coordinates.
  Future<String> reverseGeocode(double lat, double lon) async {
    final mappls = await reverseGeocodeMappls(lat, lon);
    if (mappls != null && mappls.isNotEmpty) return mappls;
    return reverseGeocodeLocationIQ(lat, lon);
  }

  /// Full flow: request permission → get position → reverse geocode
  /// (Mappls, with LocationIQ fallback).
  Future<LocationResult?> fetchCurrentLocation() async {
    try {
      final granted = await requestPermission();
      if (!granted) return null;

      final position = await getCurrentPosition();
      if (position == null) return null;

      final address = await reverseGeocode(
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
