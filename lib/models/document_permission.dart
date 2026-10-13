import 'dart:convert';

enum PermissionType {
  view,
  edit;

  static PermissionType fromString(String val) {
    if (val.toLowerCase() == 'edit') return PermissionType.edit;
    return PermissionType.view;
  }
}

class DocumentPermission {
  final String id;
  final String documentId;
  final String userId;
  final String userEmail;
  final String userName;
  final PermissionType permissionType;
  final String grantedBy;
  final DateTime createdAt;

  DocumentPermission({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.permissionType,
    required this.grantedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'document_id': documentId,
    'user_id': userId,
    'user_email': userEmail,
    'user_name': userName,
    'permission_type': permissionType.name,
    'granted_by': grantedBy,
    'created_at': createdAt.toIso8601String(),
  };

  factory DocumentPermission.fromMap(Map<String, dynamic> map) => DocumentPermission(
    id: map['id'] ?? '',
    documentId: map['document_id'] ?? '',
    userId: map['user_id'] ?? '',
    userEmail: map['user_email'] ?? '',
    userName: map['user_name'] ?? '',
    permissionType: PermissionType.fromString(map['permission_type'] ?? 'view'),
    grantedBy: map['granted_by'] ?? '',
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
  );

  String toJson() => jsonEncode(toMap());
  factory DocumentPermission.fromJson(String source) => DocumentPermission.fromMap(jsonDecode(source));
}
