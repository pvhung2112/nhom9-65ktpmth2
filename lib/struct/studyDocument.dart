import 'dart:convert';

enum DocumentType {
  lecture,
  exercise,
  reference,
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.lecture:
        return 'Bài giảng';
      case DocumentType.exercise:
        return 'Bài tập';
      case DocumentType.reference:
        return 'Tài liệu tham khảo';
    }
  }

  String get keyName => name;

  static DocumentType fromString(String? value) {
    if (value == null) return DocumentType.lecture;
    return DocumentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DocumentType.lecture,
    );
  }
}

enum DocumentStatus {
  todo,
  inProgress,
  completed,
}

extension DocumentStatusExtension on DocumentStatus {
  String get displayName {
    switch (this) {
      case DocumentStatus.todo:
        return 'Cần học';
      case DocumentStatus.inProgress:
        return 'Đang học';
      case DocumentStatus.completed:
        return 'Đã hoàn thành';
    }
  }

  static DocumentStatus fromString(String? value) {
    if (value == null) return DocumentStatus.todo;
    return DocumentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DocumentStatus.todo,
    );
  }
}

class StudyDocument {
  final String id;
  final String title;
  final String courseId;
  final DocumentType type;
  final DocumentStatus status;
  final String description;
  final String fileUrl;
  final List<String> tags;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isSynced;

  StudyDocument({
    required this.id,
    required this.title,
    required this.courseId,
    required this.type,
    this.status = DocumentStatus.todo,
    this.description = '',
    this.fileUrl = '',
    this.tags = const [],
    this.deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  StudyDocument copyWith({
    String? id,
    String? title,
    String? courseId,
    DocumentType? type,
    DocumentStatus? status,
    String? description,
    String? fileUrl,
    List<String>? tags,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isSynced,
  }) {
    return StudyDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      courseId: courseId ?? this.courseId,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      tags: tags ?? this.tags,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'course_id': courseId,
      'type': type.name,
      'status': status.name,
      'description': description,
      'file_url': fileUrl,
      'tags': jsonEncode(tags),
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_pinned': isPinned ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory StudyDocument.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null) {
      try {
        parsedTags = List<String>.from(jsonDecode(map['tags']));
      } catch (_) {
        parsedTags = [];
      }
    }

    return StudyDocument(
      id: map['id'] as String,
      title: map['title'] as String,
      courseId: (map['course_id'] ?? map['courseId'] ?? '') as String,
      type: DocumentTypeExtension.fromString(map['type'] as String?),
      status: DocumentStatusExtension.fromString(map['status'] as String?),
      description: (map['description'] ?? '') as String,
      fileUrl: (map['file_url'] ?? map['fileUrl'] ?? '') as String,
      tags: parsedTags,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
      isPinned: (map['is_pinned'] ?? map['isPinned'] ?? 0) == 1,
      isSynced: (map['is_synced'] ?? map['isSynced'] ?? 0) == 1,
    );
  }
}
