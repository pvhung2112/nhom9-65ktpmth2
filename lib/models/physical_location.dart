import 'dart:convert';

class PhysicalLocation {
  final String locationName; // Tên phòng, thư viện, hoặc phòng học
  final String campusName;   // Khuôn viên
  final String shelfNumber;  // Số kệ hoặc ngăn sách
  final double latitude;     // Tọa độ Vĩ độ GPS
  final double longitude;    // Tọa độ Kinh độ GPS
  final String floor;        // Tầng

  const PhysicalLocation({
    this.locationName = 'Thư viện Trung tâm - Tòa H1',
    this.campusName = 'Khuôn viên Đại học',
    this.shelfNumber = 'Kệ A3 - Ngăn 02',
    this.latitude = 10.8700,
    this.longitude = 106.8030,
    this.floor = 'Tầng 2',
  });

  String get googleMapsUrl => 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  String get fullAddress => '$locationName ($floor, $shelfNumber) - $campusName';

  Map<String, dynamic> toMap() => {
    'location_name': locationName,
    'campus_name': campusName,
    'shelf_number': shelfNumber,
    'latitude': latitude,
    'longitude': longitude,
    'floor': floor,
  };

  factory PhysicalLocation.fromMap(Map<String, dynamic> map) => PhysicalLocation(
    locationName: map['location_name']?.toString() ?? 'Thư viện Trung tâm - Tòa H1',
    campusName: map['campus_name']?.toString() ?? 'Khuôn viên Đại học',
    shelfNumber: map['shelf_number']?.toString() ?? 'Kệ A3 - Ngăn 02',
    latitude: (map['latitude'] as num?)?.toDouble() ?? 10.8700,
    longitude: (map['longitude'] as num?)?.toDouble() ?? 106.8030,
    floor: map['floor']?.toString() ?? 'Tầng 2',
  );

  String toJson() => jsonEncode(toMap());
  factory PhysicalLocation.fromJson(String source) => PhysicalLocation.fromMap(jsonDecode(source));

  static const List<PhysicalLocation> presetLocations = [
    PhysicalLocation(
      locationName: 'Tòa A - Phòng A305',
      campusName: 'Khuôn viên Giảng đường A',
      shelfNumber: 'Tủ số 2 - Ngăn số 3',
      latitude: 10.8708,
      longitude: 106.8025,
      floor: 'Tầng 3',
    ),
    PhysicalLocation(
      locationName: 'Thư viện Trung tâm - Tòa H1',
      campusName: 'Khu Thư viện & Học liệu',
      shelfNumber: 'Kệ A3 - Ngăn số 2',
      latitude: 10.8700,
      longitude: 106.8030,
      floor: 'Tầng 2',
    ),
    PhysicalLocation(
      locationName: 'Tòa B - Phòng Lab 302',
      campusName: 'Khu Công nghệ Thực hành',
      shelfNumber: 'Tủ số 1 - Ngăn số 2',
      latitude: 10.8712,
      longitude: 106.8045,
      floor: 'Tầng 3',
    ),
    PhysicalLocation(
      locationName: 'Tòa C - Kho Lưu trữ',
      campusName: 'Tòa Nhà Hành chính C',
      shelfNumber: 'Tủ hồ sơ 04 - Ngăn số 1',
      latitude: 10.8695,
      longitude: 106.8018,
      floor: 'Tầng 1',
    ),
  ];
}
