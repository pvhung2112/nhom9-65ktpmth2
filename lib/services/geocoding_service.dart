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

/// Dịch vụ Tìm kiếm Địa điểm & Tọa độ Bản đồ (OpenStreetMap / Photon Geocoding)
/// Hoàn toàn miễn phí, không yêu cầu thẻ tín dụng hay Google API Key phức tạp
class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  /// Danh mục các địa điểm mẫu chuẩn xác tại Trường Đại học Thủy Lợi (175 Tây Sơn, Đống Đa, Hà Nội)
  static final List<PlaceSearchResult> thuyLoiPresets = [
    PlaceSearchResult(
      name: 'Thư viện K1 - ĐH Thủy Lợi',
      displayName: 'Nhà Thư viện K1, 175 Tây Sơn, Phường Trung Liệt, Quận Đống Đa, Hà Nội',
      latitude: 21.0071,
      longitude: 105.8253,
      building: 'Nhà K1 (Thư viện)',
      street: '175 Tây Sơn',
      city: 'Hà Nội',
    ),
    PlaceSearchResult(
      name: 'Tòa T5 - Khoa CNTT & KTPM (ĐH Thủy Lợi)',
      displayName: 'Tòa nhà T5, Đại học Thủy Lợi, 175 Tây Sơn, Đống Đa, Hà Nội',
      latitude: 21.0075,
      longitude: 105.8246,
      building: 'Tòa T5 (CNTT)',
      street: '175 Tây Sơn',
      city: 'Hà Nội',
    ),
    PlaceSearchResult(
      name: 'Tòa A1 - Khu Giảng đường chính (ĐH Thủy Lợi)',
      displayName: 'Tòa nhà A1, Đại học Thủy Lợi, 175 Tây Sơn, Đống Đa, Hà Nội',
      latitude: 21.0073,
      longitude: 105.8242,
      building: 'Tòa A1',
      street: '175 Tây Sơn',
      city: 'Hà Nội',
    ),
    PlaceSearchResult(
      name: 'Tòa B1 - Kho Giáo trình & Thí nghiệm (ĐH Thủy Lợi)',
      displayName: 'Tòa nhà B1, Đại học Thủy Lợi, 175 Tây Sơn, Đống Đa, Hà Nội',
      latitude: 21.0065,
      longitude: 105.8256,
      building: 'Tòa B1',
      street: '175 Tây Sơn',
      city: 'Hà Nội',
    ),
    PlaceSearchResult(
      name: 'Cổng chính ĐH Thủy Lợi (175 Tây Sơn)',
      displayName: 'Trường Đại học Thủy Lợi, 175 Phố Tây Sơn, Kim Liên, Đống Đa, Hà Nội',
      latitude: 21.00699,
      longitude: 105.82510,
      building: 'Cổng chính',
      street: '175 Tây Sơn',
      city: 'Hà Nội',
    ),
  ];

  /// Tìm kiếm địa điểm trực tuyến qua OpenStreetMap Photon API
  Future<List<PlaceSearchResult>> searchLocation(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    // Kiểm tra nhanh trong danh sách Đại học Thủy Lợi trước
    final lower = clean.toLowerCase();
    final localMatches = thuyLoiPresets.where((p) =>
      p.name.toLowerCase().contains(lower) ||
      p.displayName.toLowerCase().contains(lower) ||
      p.building.toLowerCase().contains(lower)
    ).toList();

    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(clean)}&limit=5',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 4));
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
            final house = props['housenumber']?.toString() ?? '';

            final parts = [
              if (name.isNotEmpty) name,
              if (house.isNotEmpty) 'số $house',
              if (street.isNotEmpty) street,
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

        if (results.isNotEmpty) {
          return results;
        }
      }
    } catch (e) {
      debugPrint('Geocoding search error: $e');
    }

    return localMatches.isNotEmpty ? localMatches : thuyLoiPresets;
  }
}
