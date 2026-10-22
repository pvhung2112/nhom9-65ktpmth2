import 'dart:convert';

class SupabaseDocument {
  final String id;
  final String title;
  final String description;
  final String courseCode;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String ownerId;
  final String ownerEmail;
  final String ownerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupabaseDocument({
    required this.id,
    required this.title,
    this.description = '',
    this.courseCode = 'SE301',
    required this.fileUrl,
    required this.fileName,
    this.fileSize = 0,
    required this.ownerId,
    required this.ownerEmail,
    required this.ownerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  SupabaseDocument copyWith({
    String? title,
    String? description,
    String? courseCode,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    DateTime? updatedAt,
  }) {
    return SupabaseDocument(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseCode: courseCode ?? this.courseCode,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      ownerId: ownerId,
      ownerEmail: ownerEmail,
      ownerName: ownerName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'course_code': courseCode,
    'file_url': fileUrl,
    'file_name': fileName,
    'file_size': fileSize,
    'owner_id': ownerId,
    'owner_email': ownerEmail,
    'owner_name': ownerName,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory SupabaseDocument.fromMap(Map<String, dynamic> map) => SupabaseDocument(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    courseCode: map['course_code'] ?? 'SE301',
    fileUrl: map['file_url'] ?? '',
    fileName: map['file_name'] ?? '',
    fileSize: map['file_size'] is int ? map['file_size'] : int.tryParse(map['file_size'].toString()) ?? 0,
    ownerId: map['owner_id'] ?? '',
    ownerEmail: map['owner_email'] ?? '',
    ownerName: map['owner_name'] ?? '',
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
  );

  String toJson() => jsonEncode(toMap());
  factory SupabaseDocument.fromJson(String source) => SupabaseDocument.fromMap(jsonDecode(source));
}
