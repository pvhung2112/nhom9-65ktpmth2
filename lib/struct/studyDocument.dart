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

  // Thuộc tính phân quyền RLS & Đám mây Supabase
  final String ownerId;
  final String ownerEmail;
  final String ownerName;
  final String sharedPermission; // 'owner' | 'edit' | 'view'
  final List<String> permissions; // Mảng danh sách quyền hạn cụ thể ['view', 'edit', 'delete', 'share']
  final String sharedByEmail;

  // Tính năng TH2: Định vị vật lý & Quản lý mượn/trả
  final String physicalLocation;
  final double latitude;
  final double longitude;
  final String shelfLocation;
  final String borrowStatus; // 'available' | 'borrowed' | 'reserved'
  final String currentBorrowerName;
  final DateTime? borrowDueDate;

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
    this.ownerId = '',
    this.ownerEmail = '',
    this.ownerName = '',
    this.sharedPermission = 'owner',
    this.permissions = const [],
    this.sharedByEmail = '',
    this.physicalLocation = 'Thư viện Trung tâm - Tòa H1',
    this.latitude = 10.8700,
    this.longitude = 106.8030,
    this.shelfLocation = 'Kệ A3 - Ngăn 02',
    this.borrowStatus = 'available',
    this.currentBorrowerName = '',
    this.borrowDueDate,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isOwner => sharedPermission == 'owner';
  bool get canView => isOwner || permissions.contains('view') || sharedPermission == 'all' || true;
  bool get canEdit => isOwner || permissions.contains('edit') || sharedPermission == 'edit' || sharedPermission == 'all' || sharedPermission.contains('edit');
  bool get canDelete => isOwner || permissions.contains('delete') || sharedPermission == 'delete' || sharedPermission == 'all' || sharedPermission.contains('delete');
  bool get canShare => isOwner || permissions.contains('share') || sharedPermission == 'share' || sharedPermission == 'all' || sharedPermission.contains('share');

  String get permissionsSummary {
    if (isOwner) return 'Toàn quyền (Chủ sở hữu)';
    final List<String> list = [];
    if (canView) list.add('Xem');
    if (canEdit) list.add('Sửa');
    if (canDelete) list.add('Xóa');
    if (canShare) list.add('Chia sẻ');
    return list.isNotEmpty ? list.join(' & ') : 'Chỉ xem';
  }

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
    String? ownerId,
    String? ownerEmail,
    String? ownerName,
    String? sharedPermission,
    List<String>? permissions,
    String? sharedByEmail,
    String? physicalLocation,
    double? latitude,
    double? longitude,
    String? shelfLocation,
    String? borrowStatus,
    String? currentBorrowerName,
    DateTime? borrowDueDate,
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
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerName: ownerName ?? this.ownerName,
      sharedPermission: sharedPermission ?? this.sharedPermission,
      permissions: permissions ?? this.permissions,
      sharedByEmail: sharedByEmail ?? this.sharedByEmail,
      physicalLocation: physicalLocation ?? this.physicalLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      shelfLocation: shelfLocation ?? this.shelfLocation,
      borrowStatus: borrowStatus ?? this.borrowStatus,
      currentBorrowerName: currentBorrowerName ?? this.currentBorrowerName,
      borrowDueDate: borrowDueDate ?? this.borrowDueDate,
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
      'owner_id': ownerId,
      'owner_email': ownerEmail,
      'owner_name': ownerName,
      'shared_permission': sharedPermission,
      'permissions': jsonEncode(permissions),
      'shared_by_email': sharedByEmail,
      'physical_location': physicalLocation,
      'latitude': latitude,
      'longitude': longitude,
      'shelf_location': shelfLocation,
      'borrow_status': borrowStatus,
      'current_borrower_name': currentBorrowerName,
      'borrow_due_date': borrowDueDate?.toIso8601String(),
    };
  }

  factory StudyDocument.fromMap(Map<String, dynamic> map) {
        List<String> parsedTags = [];
    if (map['tags'] != null) {
      try {
        if (map['tags'] is List) {
          parsedTags = (map['tags'] as List).map((e) => e.toString()).toList();
        } else {
          final dec = jsonDecode(map['tags']);
          if (dec is List) {
            parsedTags = dec.map((e) => e.toString()).toList();
          }
        }
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
      ownerId: (map['owner_id'] ?? '') as String,
      ownerEmail: (map['owner_email'] ?? '') as String,
      ownerName: (map['owner_name'] ?? '') as String,
      sharedPermission: (map['shared_permission'] ?? 'owner') as String,
      permissions: map['permissions'] != null ? (map['permissions'] is List ? List<String>.from(map['permissions']) : (jsonDecode(map['permissions']) is List ? List<String>.from(jsonDecode(map['permissions'])) : [])) : [],
      sharedByEmail: (map['shared_by_email'] ?? '') as String,
      physicalLocation: (map['physical_location'] ?? 'Thư viện Trung tâm - Tòa H1') as String,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 10.8700,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 106.8030,
      shelfLocation: (map['shelf_location'] ?? 'Kệ A3 - Ngăn 02') as String,
      borrowStatus: (map['borrow_status'] ?? 'available') as String,
      currentBorrowerName: (map['current_borrower_name'] ?? '') as String,
      borrowDueDate: map['borrow_due_date'] != null ? DateTime.tryParse(map['borrow_due_date'].toString()) : null,
    );
  }
}
