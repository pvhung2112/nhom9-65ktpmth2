import 'dart:convert';

class StorageLocationItem {
  final String id;
  final String name;
  final String building;
  final String floor;
  final String room;
  final String cabinet;
  final String shelf;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  StorageLocationItem({
    required this.id,
    required this.name,
    this.building = 'Tòa A',
    this.floor = 'Tầng 3',
    this.room = 'Phòng A305',
    this.cabinet = 'Tủ số 2',
    this.shelf = 'Ngăn số 3',
    this.latitude = 10.8708,
    this.longitude = 106.8025,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

    String get fullAddress {
    final list = [building, floor, room].where((s) => s.trim().isNotEmpty).toList();
    final cs = [cabinet, shelf].where((s) => s.trim().isNotEmpty).join(' - ');
    if (cs.isNotEmpty) list.add('($cs)');
    return list.isNotEmpty ? list.join(', ') : name;
  }

  String get shelfDetail {
    final list = [floor, room].where((s) => s.trim().isNotEmpty).toList();
    final cs = [cabinet, shelf].where((s) => s.trim().isNotEmpty).join(' - ');
    if (cs.isNotEmpty) list.add(cs);
    return list.isNotEmpty ? list.join(', ') : '';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'building': building,
    'floor': floor,
    'room': room,
    'cabinet': cabinet,
    'shelf': shelf,
    'latitude': latitude,
    'longitude': longitude,
    'created_at': createdAt.toIso8601String(),
  };

  factory StorageLocationItem.fromMap(Map<String, dynamic> map) => StorageLocationItem(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    building: map['building']?.toString() ?? 'Tòa A',
    floor: map['floor']?.toString() ?? 'Tầng 3',
    room: map['room']?.toString() ?? 'Phòng A305',
    cabinet: map['cabinet']?.toString() ?? 'Tủ số 2',
    shelf: map['shelf']?.toString() ?? 'Ngăn số 3',
    latitude: (map['latitude'] as num?)?.toDouble() ?? 10.8708,
    longitude: (map['longitude'] as num?)?.toDouble() ?? 106.8025,
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
  );

  String toJson() => jsonEncode(toMap());
  factory StorageLocationItem.fromJson(String source) => StorageLocationItem.fromMap(jsonDecode(source));
}
