import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlaceSearchResult {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final String building;
  final String street;
  final String city;

  PlaceSearchResult({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.building = '',
    this.street = '',
    this.city = '',
  });

  String get googleMapsUrl => 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}

/// Dịch vụ Tìm kiếm Địa điểm & Tọa độ Bản đồ Động (OpenStreetMap / Photon Geocoding)
/// Hoàn toàn động theo bất kỳ từ khóa nào người dùng nhập, 0% fix cứng dữ liệu
class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  /// Tìm kiếm địa điểm trực tuyến theo từ khóa người dùng nhập (không fix cứng)
  Future<List<PlaceSearchResult>> searchLocation(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=' + Uri.encodeComponent(clean) + '&limit=6',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        final List<PlaceSearchResult> results = [];
        for (var f in features) {
          final props = f['properties'] as Map<String, dynamic>? ?? {};
          final geom = f['geometry'] as Map<String, dynamic>? ?? {};
          final coords = geom['coordinates'] as List<dynamic>? ?? [];

          if (coords.length >= 2) {
            final lon = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();
            final name = props['name']?.toString() ?? props['street']?.toString() ?? clean;
            final street = props['street']?.toString() ?? '';
            final city = props['city']?.toString() ?? props['state']?.toString() ?? '';
            final district = props['district']?.toString() ?? '';
            final house = props['housenumber']?.toString() ?? '';

            final parts = [
              if (name.isNotEmpty) name,
              if (house.isNotEmpty) 'số ' + house,
              if (street.isNotEmpty && street != name) street,
              if (district.isNotEmpty) district,
              if (city.isNotEmpty) city,
            ];

            results.add(PlaceSearchResult(
              name: name,
              displayName: parts.join(', '),
              latitude: lat,
              longitude: lon,
              building: name,
              street: street,
              city: city,
            ));
          }
        }
        return results;
      }
    } catch (e) {
      debugPrint('Geocoding search error: $e');
    }

    return [];
  }
}
