// lib/features/prayer_times/services/location_search_service.dart
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class CityLocation {
  final String cityName;
  final String countryName;
  final double latitude;
  final double longitude;

  const CityLocation({
    required this.cityName,
    required this.countryName,
    required this.latitude,
    required this.longitude,
  });

  String get displayName => countryName.isNotEmpty ? '$cityName, $countryName' : cityName;

  Map<String, dynamic> toMap() => {
        'cityName': cityName,
        'countryName': countryName,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory CityLocation.fromMap(Map<String, dynamic> map) => CityLocation(
        cityName: map['cityName'] as String? ?? 'Lahore',
        countryName: map['countryName'] as String? ?? 'Pakistan',
        latitude: (map['latitude'] as num?)?.toDouble() ?? 31.5204,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 74.3587,
      );
}

class LocationSearchService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: {'User-Agent': 'AlQuranApp/1.0.2'},
    ),
  );

  /// Default fallback location (Lahore, Pakistan)
  static const CityLocation defaultLocation = CityLocation(
    cityName: 'Lahore',
    countryName: 'Pakistan',
    latitude: 31.5204,
    longitude: 74.3587,
  );

  /// Pre-bundled list of major worldwide cities for instant zero-latency selection
  static const List<CityLocation> popularCities = [
    // Pakistan
    CityLocation(cityName: 'Lahore', countryName: 'Pakistan', latitude: 31.5204, longitude: 74.3587),
    CityLocation(cityName: 'Karachi', countryName: 'Pakistan', latitude: 24.8607, longitude: 67.0011),
    CityLocation(cityName: 'Islamabad', countryName: 'Pakistan', latitude: 33.6844, longitude: 73.0479),
    CityLocation(cityName: 'Rawalpindi', countryName: 'Pakistan', latitude: 33.5651, longitude: 73.0169),
    CityLocation(cityName: 'Faisalabad', countryName: 'Pakistan', latitude: 31.4504, longitude: 73.1350),
    CityLocation(cityName: 'Multan', countryName: 'Pakistan', latitude: 30.1575, longitude: 71.5249),
    CityLocation(cityName: 'Peshawar', countryName: 'Pakistan', latitude: 34.0151, longitude: 71.5249),
    CityLocation(cityName: 'Quetta', countryName: 'Pakistan', latitude: 30.1798, longitude: 66.9750),

    // Saudi Arabia & Middle East
    CityLocation(cityName: 'Makkah', countryName: 'Saudi Arabia', latitude: 21.4225, longitude: 39.8262),
    CityLocation(cityName: 'Madinah', countryName: 'Saudi Arabia', latitude: 24.5247, longitude: 39.5692),
    CityLocation(cityName: 'Riyadh', countryName: 'Saudi Arabia', latitude: 24.7136, longitude: 46.6753),
    CityLocation(cityName: 'Jeddah', countryName: 'Saudi Arabia', latitude: 21.4858, longitude: 39.1925),
    CityLocation(cityName: 'Dubai', countryName: 'UAE', latitude: 25.2048, longitude: 55.2708),
    CityLocation(cityName: 'Abu Dhabi', countryName: 'UAE', latitude: 24.4539, longitude: 54.3773),
    CityLocation(cityName: 'Doha', countryName: 'Qatar', latitude: 25.2854, longitude: 51.5310),
    CityLocation(cityName: 'Kuwait City', countryName: 'Kuwait', latitude: 29.3759, longitude: 47.9774),
    CityLocation(cityName: 'Manama', countryName: 'Bahrain', latitude: 26.2285, longitude: 50.5860),
    CityLocation(cityName: 'Muscat', countryName: 'Oman', latitude: 23.5880, longitude: 58.3829),
    CityLocation(cityName: 'Cairo', countryName: 'Egypt', latitude: 30.0444, longitude: 31.2357),
    CityLocation(cityName: 'Istanbul', countryName: 'Turkey', latitude: 41.0082, longitude: 28.9784),
    CityLocation(cityName: 'Ankara', countryName: 'Turkey', latitude: 39.9334, longitude: 32.8597),
    CityLocation(cityName: 'Amman', countryName: 'Jordan', latitude: 31.9454, longitude: 35.9284),
    CityLocation(cityName: 'Jerusalem (Al-Quds)', countryName: 'Palestine', latitude: 31.7683, longitude: 35.2137),

    // Asia & South East Asia
    CityLocation(cityName: 'Dhaka', countryName: 'Bangladesh', latitude: 23.8103, longitude: 90.4125),
    CityLocation(cityName: 'Chittagong', countryName: 'Bangladesh', latitude: 22.3569, longitude: 91.7832),
    CityLocation(cityName: 'New Delhi', countryName: 'India', latitude: 28.6139, longitude: 77.2090),
    CityLocation(cityName: 'Mumbai', countryName: 'India', latitude: 19.0760, longitude: 72.8777),
    CityLocation(cityName: 'Hyderabad', countryName: 'India', latitude: 17.3850, longitude: 78.4867),
    CityLocation(cityName: 'Kuala Lumpur', countryName: 'Malaysia', latitude: 3.1390, longitude: 101.6869),
    CityLocation(cityName: 'Jakarta', countryName: 'Indonesia', latitude: -6.2088, longitude: 106.8456),
    CityLocation(cityName: 'Bandung', countryName: 'Indonesia', latitude: -6.9175, longitude: 107.6191),
    CityLocation(cityName: 'Singapore', countryName: 'Singapore', latitude: 1.3521, longitude: 103.8198),
    CityLocation(cityName: 'Tokyo', countryName: 'Japan', latitude: 35.6762, longitude: 139.6503),

    // Europe
    CityLocation(cityName: 'London', countryName: 'United Kingdom', latitude: 51.5074, longitude: -0.1278),
    CityLocation(cityName: 'Birmingham', countryName: 'United Kingdom', latitude: 52.4862, longitude: -1.8904),
    CityLocation(cityName: 'Manchester', countryName: 'United Kingdom', latitude: 53.4808, longitude: -2.2426),
    CityLocation(cityName: 'Paris', countryName: 'France', latitude: 48.8566, longitude: 2.3522),
    CityLocation(cityName: 'Berlin', countryName: 'Germany', latitude: 52.5200, longitude: 13.4050),
    CityLocation(cityName: 'Frankfurt', countryName: 'Germany', latitude: 50.1109, longitude: 8.6821),
    CityLocation(cityName: 'Amsterdam', countryName: 'Netherlands', latitude: 52.3676, longitude: 4.9041),

    // North America & Others
    CityLocation(cityName: 'New York', countryName: 'United States', latitude: 40.7128, longitude: -74.0060),
    CityLocation(cityName: 'Chicago', countryName: 'United States', latitude: 41.8781, longitude: -87.6298),
    CityLocation(cityName: 'Houston', countryName: 'United States', latitude: 29.7604, longitude: -95.3698),
    CityLocation(cityName: 'Toronto', countryName: 'Canada', latitude: 43.6532, longitude: -79.3832),
    CityLocation(cityName: 'Sydney', countryName: 'Australia', latitude: -33.8688, longitude: 151.2093),
    CityLocation(cityName: 'Melbourne', countryName: 'Australia', latitude: -37.8136, longitude: 144.9631),
    CityLocation(cityName: 'Cape Town', countryName: 'South Africa', latitude: -33.9249, longitude: 18.4241),
  ];

  /// Searches worldwide locations via OpenStreetMap Nominatim API with instant offline fallback
  static Future<List<CityLocation>> searchLocations(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return popularCities;

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 15,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        final results = <CityLocation>[];
        for (final item in response.data as List) {
          final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
          final address = item['address'] as Map<String, dynamic>?;

          final city = address?['city'] ??
              address?['town'] ??
              address?['village'] ??
              address?['county'] ??
              item['name'] ??
              'Unknown';
          final country = address?['country'] ?? '';

          if (lat != 0.0 && lon != 0.0) {
            results.add(CityLocation(
              cityName: city.toString(),
              countryName: country.toString(),
              latitude: lat,
              longitude: lon,
            ));
          }
        }

        if (results.isNotEmpty) return results;
      }
    } catch (_) {
      // Offline fallback: filter popular cities
    }

    return popularCities.where((c) {
      return c.cityName.toLowerCase().contains(cleanQuery) ||
          c.countryName.toLowerCase().contains(cleanQuery);
    }).toList();
  }

  /// Obtains current GPS location
  static Future<CityLocation?> getCurrentGpsLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    Position? pos;

    // Get CURRENT live location via network/cell towers (medium = fast 1-2s, accurate enough for prayer times)
    // NOTE: Do NOT use getLastKnownPosition() — it returns stale old coords from days/weeks ago
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // Uses cell towers + WiFi — fast & current
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      // Fallback — try with no time limit
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        );
      } catch (_) {
        return null;
      }
    }

    // Format coordinates as a short display label (always shown as subtitle)
    final latStr = pos.latitude.toStringAsFixed(5);
    final lonStr = pos.longitude.toStringAsFixed(5);
    final coordLabel = '$latStr°N, $lonStr°E';

    // Try reverse geocoding via OpenStreetMap Nominatim
    String cityName = coordLabel; // fallback = exact coordinates
    String countryName = 'Pakistan';

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': pos.latitude,
          'lon': pos.longitude,
          'format': 'json',
          'addressdetails': 1,
          'zoom': 14, // town/village level — NOT district/county
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        final address = response.data['address'] as Map<String, dynamic>?;
        // Priority: hamlet > village > town > suburb > city
        // (hamlet/village are most precise for rural areas like Pindmuneem)
        final resolved = (address?['hamlet'] ??
                address?['village'] ??
                address?['town'] ??
                address?['suburb'] ??
                address?['city_district'] ??
                address?['city'] ??
                address?['municipality'] ??
                '')
            .toString()
            .trim();

        // Use resolved name if found, otherwise keep exact coordinates as name
        if (resolved.isNotEmpty) {
          cityName = resolved;
        }
        countryName = address?['country']?.toString() ?? 'Pakistan';
      }
    } catch (_) {}

    return CityLocation(
      cityName: cityName,
      countryName: countryName,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }
}
