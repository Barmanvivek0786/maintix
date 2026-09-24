import 'dart:convert';

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

  /// User id for which the live location was already auto-refreshed in this
  /// app session (used by GpsEnforcementWrapper so a stale, coarse address
  /// saved in the DB is replaced by a fresh Mappls address once per login).
  String? lastAutoRefreshUserId;

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

  // ───────────────────────── Mappls ─────────────────────────

  Map<String, dynamic>? _asMap(dynamic data) {
    try {
      if (data is Map) return Map<String, dynamic>.from(data);
      if (data is String && data.trim().isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  String _snippet(dynamic data) {
    final s = data?.toString() ?? '';
    return s.length > 200 ? s.substring(0, 200) : s;
  }

  /// Calls Mappls reverse-geocode and returns the first result object.
  ///
  /// Mappls has two auth styles and a key only works with one of them:
  ///  1. Current API  : search.mappls.com/search/address/rev-geocode?access_token=KEY
  ///  2. Legacy REST  : apis.mappls.com/advancedmaps/v1/KEY/rev_geocode
  /// We try both, so the address is fetched whichever key type is configured.
  /// HTTP status + body snippet are logged (debugPrint) on failure so the
  /// real reason (401 invalid key / 403 not enabled / quota) is visible.
  Future<Map<String, dynamic>?> _fetchMapplsResult(
    double lat,
    double lon,
  ) async {
    if (_mapplsKey.isEmpty) return null;

    final options = Options(
      headers: {'Accept': 'application/json'},
      // Do not throw on 4xx so we can log the real error body.
      validateStatus: (s) => s != null && s < 500,
    );

    final attempts = <String, Future<Response<dynamic>> Function()>{
      'access_token': () => _dio.get(
        'https://search.mappls.com/search/address/rev-geocode',
        queryParameters: {
          'lat': lat.toString(),
          'lng': lon.toString(),
          'access_token': _mapplsKey,
        },
        options: options,
      ),
      'legacy-key': () => _dio.get(
        'https://apis.mappls.com/advancedmaps/v1/$_mapplsKey/rev_geocode',
        queryParameters: {'lat': lat.toString(), 'lng': lon.toString()},
        options: options,
      ),
    };

    for (final entry in attempts.entries) {
      try {
        final response = await entry.value();
        final map = _asMap(response.data);
        if (response.statusCode == 200 && map != null) {
          final results = map['results'];
          if (results is List && results.isNotEmpty && results.first is Map) {
            return Map<String, dynamic>.from(results.first as Map);
          }
        }
        debugPrint(
          'Mappls (${entry.key}) HTTP ${response.statusCode}: '
          '${_snippet(response.data)}',
        );
      } catch (e) {
        debugPrint('Mappls (${entry.key}) error: $e');
      }
    }
    return null;
  }

  /// Reverse geocode using Mappls (MapmyIndia), at door-step precision —
  /// house/building number, street, gali/mohalla (sub-locality) and locality,
  /// like Zomato/Swiggy/Blinkit delivery-address screens.
  /// Format: "{House no/Building}, {Street}, {Gali}, {Mohalla}, {Locality}, {City}, {State}, {Pincode}"
  Future<String?> reverseGeocodeMappls(double lat, double lon) async {
    final r = await _fetchMapplsResult(lat, lon);
    if (r == null) return null;

    String? str(String key) {
      final v = r[key];
      if (v is String) {
        final t = v.trim();
        if (t.isNotEmpty && t.toUpperCase() != 'NA') return t;
      }
      return null;
    }

    // "Satna District" -> "Satna"
    String? cleanDistrict(String? v) {
      if (v == null) return null;
      return v.replaceAll(RegExp(r'\s+District$', caseSensitive: false), '');
    }

    // Door-step level: house/building number + POI/building name.
    final houseNumber = str('houseNumber');
    final houseName = str('houseName') ?? str('poi');

    // Street / road — skip Mappls' placeholder for unnamed roads.
    var street = str('street');
    if (street != null && street.toLowerCase().startsWith('unnamed road')) {
      street = null;
    }

    // Gali/mohalla level — the finest granularity below street.
    final subSubLocality = str('subSubLocality');
    final subLocality = str('subLocality');

    // Locality / area.
    final locality = str('locality') ?? str('village');

    // City / district.
    final city =
        str('city') ??
        cleanDistrict(str('district')) ??
        cleanDistrict(str('subDistrict'));
    final state = str('state');
    final pincode = str('pincode');

    String? streetLine;
    if (houseNumber != null && street != null) {
      streetLine = '$houseNumber, $street';
    } else {
      streetLine = houseNumber ?? houseName ?? street;
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
    add(pincode);

    if (parts.isNotEmpty) return parts.join(', ');

    return str('formatted_address');
  }

  // ───────────────────────── LocationIQ (fallback) ─────────────────────────

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
          final locality =
              str('neighbourhood') ??
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

  int _detailCount(String address) =>
      address.split(',').where((s) => s.trim().isNotEmpty).length;

  /// Reverse geocode with Mappls first (best precision for Indian
  /// addresses). If Mappls fails, or only returns a coarse address
  /// (just city/state), LocationIQ is also tried and the more detailed of
  /// the two is used. Raw coordinates are the last resort.
  Future<String> reverseGeocode(double lat, double lon) async {
    final mappls = await reverseGeocodeMappls(lat, lon);
    // 4+ parts => street/gali/locality-level detail is present.
    if (mappls != null && mappls.isNotEmpty && _detailCount(mappls) >= 4) {
      return mappls;
    }

    final fallback = await reverseGeocodeLocationIQ(lat, lon);
    if (mappls != null &&
        mappls.isNotEmpty &&
        _detailCount(mappls) >= _detailCount(fallback)) {
      return mappls;
    }
    return fallback;
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
