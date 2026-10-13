import 'dart:convert';

enum PermissionType {
  view,
  edit,
  delete,
  share,
  all;

  static PermissionType fromString(String val) {
    final v = val.toLowerCase().trim();
    if (v.contains('all')) return PermissionType.all;
    if (v.contains('share')) return PermissionType.share;
    if (v.contains('delete')) return PermissionType.delete;
    if (v.contains('edit')) return PermissionType.edit;
    return PermissionType.view;
  }
}

class DocumentPermission {
  final String id;
  final String documentId;
  final String userId;
  final String userEmail;
  final String userName;
  final List<String> permissions; // Mảng danh sách quyền: ['view', 'edit', 'delete', 'share']
  final PermissionType permissionType;
  final String grantedBy;
  final DateTime createdAt;

  DocumentPermission({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    List<String>? permissions,
    PermissionType? permissionType,
    required this.grantedBy,
    DateTime? createdAt,
  })  : permissions = permissions ?? (permissionType != null ? _fromEnum(permissionType) : ['view']),
        permissionType = permissionType ?? (permissions != null ? _toEnum(permissions) : PermissionType.view),
        createdAt = createdAt ?? DateTime.now();

  static List<String> _fromEnum(PermissionType t) {
    switch (t) {
      case PermissionType.all:
        return ['view', 'edit', 'delete', 'share'];
      case PermissionType.edit:
        return ['view', 'edit'];
      case PermissionType.delete:
        return ['view', 'delete'];
      case PermissionType.share:
        return ['view', 'share'];
      case PermissionType.view:
        return ['view'];
    }
  }

  static PermissionType _toEnum(List<String> list) {
    if (list.contains('all') || (list.contains('edit') && list.contains('delete') && list.contains('share'))) {
      return PermissionType.all;
    }
    if (list.contains('share') && !list.contains('edit') && !list.contains('delete')) {
      return PermissionType.share;
    }
    if (list.contains('delete') && !list.contains('edit')) {
      return PermissionType.delete;
    }
    if (list.contains('edit')) {
      return PermissionType.edit;
    }
    return PermissionType.view;
  }

  static List<String> parsePermissions(dynamic raw) {
    if (raw == null) return ['view'];
    List<String> rawList = [];

    if (raw is List) {
      rawList = raw.map((e) => e.toString().toLowerCase().trim()).where((e) => e.isNotEmpty).toList();
    } else {
      final s = raw.toString().trim();
      if (s.isEmpty) return ['view'];

      // Chuỗi JSON: '["view","edit","share"]'
      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            rawList = decoded.map((e) => e.toString().toLowerCase().trim()).where((e) => e.isNotEmpty).toList();
          }
        } catch (_) {}
      }

      // Định dạng mảng Postgres: '{"view","edit","share"}'
      if (rawList.isEmpty && s.startsWith('{') && s.endsWith('}')) {
        final inner = s.substring(1, s.length - 1);
        rawList = inner.split(',').map((e) => e.replaceAll('"', '').toLowerCase().trim()).where((e) => e.isNotEmpty).toList();
      }

      // Dạng phân cách bởi dấu phẩy: 'view,edit,share'
      if (rawList.isEmpty && s.contains(',')) {
        rawList = s.split(',').map((e) => e.toLowerCase().trim()).where((e) => e.isNotEmpty).toList();
      }

      if (rawList.isEmpty) {
        rawList = [s.toLowerCase()];
      }
    }

    // Chuẩn hóa từ khóa tiếng Việt hoặc tiếng Anh sang mã quyền chuẩn
    final mapped = <String>{'view'}; // Mặc định luôn có quyền xem
    for (var item in rawList) {
      final k = item.toLowerCase().trim();
      if (k == 'all' || k == 'toàn quyền' || k == 'toan quyen') {
        mapped.addAll(['view', 'edit', 'delete', 'share']);
      } else if (k == 'edit' || k == 'sửa' || k == 'sua') {
        mapped.add('edit');
      } else if (k == 'delete' || k == 'xóa' || k == 'xoa') {
        mapped.add('delete');
      } else if (k == 'share' || k == 'chia sẻ' || k == 'chia se') {
        mapped.add('share');
      } else if (k == 'view' || k == 'xem') {
        mapped.add('view');
      } else if (k.isNotEmpty) {
        mapped.add(k);
      }
    }

    return mapped.toList();
  }

  bool get canView => permissions.contains('view') || permissions.contains('all') || true;
  bool get canEdit => permissions.contains('edit') || permissions.contains('all');
  bool get canDelete => permissions.contains('delete') || permissions.contains('all');
  bool get canShare => permissions.contains('share') || permissions.contains('all');

  Map<String, dynamic> toMap() => {
    'id': id,
    'document_id': documentId,
    'user_id': userId,
    'user_email': userEmail,
    'user_name': userName,
    'permission_type': jsonEncode(permissions),
    'permissions': permissions,
    'granted_by': grantedBy,
    'created_at': createdAt.toIso8601String(),
  };

  factory DocumentPermission.fromMap(Map<String, dynamic> map) {
    final rawType = map['permission_type'] ?? map['permissions'];
    final parsed = parsePermissions(rawType);
    return DocumentPermission(
      id: map['id'] ?? '',
      documentId: map['document_id'] ?? '',
      userId: map['user_id'] ?? '',
      userEmail: map['user_email'] ?? '',
      userName: map['user_name'] ?? '',
      permissions: parsed,
      permissionType: _toEnum(parsed),
      grantedBy: map['granted_by'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory DocumentPermission.fromJson(String source) => DocumentPermission.fromMap(jsonDecode(source));
}
