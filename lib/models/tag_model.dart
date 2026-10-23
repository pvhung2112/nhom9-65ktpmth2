import 'dart:convert';

class DocumentTag {
  final String id;
  final String name;
  final String color;
  final DateTime createdAt;

  DocumentTag({
    required this.id,
    required this.name,
    this.color = '#D81B60',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color,
    'created_at': createdAt.toIso8601String(),
  };

  factory DocumentTag.fromMap(Map<String, dynamic> map) => DocumentTag(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    color: map['color']?.toString() ?? '#D81B60',
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
  );

  String toJson() => jsonEncode(toMap());
  factory DocumentTag.fromJson(String source) => DocumentTag.fromMap(jsonDecode(source));
}
