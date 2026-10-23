import '../database/web_storage.dart';
import '../database/database_helper.dart';
import '../models/tag_model.dart';
import '../models/storage_location_model.dart';
import '../struct/studyDocument.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/supabase_user.dart';
import '../models/supabase_document.dart';
import '../models/document_permission.dart';
import '../models/borrow_request.dart';
import 'firebase_auth_service.dart';

/// Dịch vụ Quản lý Cơ sở dữ liệu Supabase Cloud (PostgreSQL & RLS)
/// Hỗ trợ cả chế độ Online Realtime REST API và Cache Bộ nhớ cục bộ
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal() {
    _initDefaultData();
  }

  // Cấu hình kết nối Supabase Cloud Online (từ dashboard supabase.com)
  String? _supabaseUrl = 'https://tiosyakbmkcobgaobbbc.supabase.co';
  String? _supabaseAnonKey = 'sb_publishable_T4wqS-hOt5oAsLixtDS0sQ_dR4z2wDU';
  bool _isOnlineSyncing = false;
  String _connectionStatus = 'Đã kết nối Supabase Cloud Online (tiosyakbmkcobgaobbbc)';

  String? get supabaseUrl => _supabaseUrl;
  String? get supabaseAnonKey => _supabaseAnonKey;
  bool get isOnlineMode => _supabaseUrl != null && _supabaseUrl!.isNotEmpty && _supabaseAnonKey != null && _supabaseAnonKey!.isNotEmpty;
  bool get isOnlineSyncing => _isOnlineSyncing;
  String get connectionStatus => _connectionStatus;

  // Giả lập / Cache bảng dữ liệu PostgreSQL
  final Map<String, SupabaseDocument> _documentsTable = {};
  final Map<String, SupabaseUser> _usersTable = {};
  final Map<String, DocumentPermission> _permissionsTable = {};
  final Map<String, BorrowRequest> _borrowRequestsTable = {};

  final StreamController<List<SupabaseDocument>> _docsStreamController =
      StreamController<List<SupabaseDocument>>.broadcast();

  Stream<List<SupabaseDocument>> watchDocuments() => _docsStreamController.stream;

  void _notify() {
    final currentUserId = FirebaseAuthService().currentUser?.id;
    if (currentUserId != null) {
      _docsStreamController.add(getAccessibleDocuments(currentUserId));
    } else {
      _docsStreamController.add([]);
    }
  }

  void _saveBorrowRequestsCache() {
    try {
      final list = _borrowRequestsTable.values.map((r) => r.toMap()).toList();
      saveLocalCache('cached_borrow_requests', jsonEncode(list));
    } catch (_) {}
  }

  void _loadBorrowRequestsFromCache() {
    try {
      final cached = getLocalCache('cached_borrow_requests');
      if (cached != null && cached.isNotEmpty) {
        final list = jsonDecode(cached) as List<dynamic>;
        for (var item in list) {
          final req = BorrowRequest.fromMap(Map<String, dynamic>.from(item));
          _borrowRequestsTable[req.id] = req;
        }
      }
    } catch (_) {}
  }

  void _initDefaultData() {
    for (var u in FirebaseAuthService.predefinedAccounts) {
      _usersTable[u.id] = u;
    }
    _loadBorrowRequestsFromCache();
  }

  /// Cấu hình thông số kết nối Supabase Cloud Online từ Dashboard Supabase
  void configureOnline({required String url, required String anonKey}) {
    var cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    _supabaseUrl = cleanUrl;
    _supabaseAnonKey = anonKey.trim();
    _connectionStatus = isOnlineMode ? 'Đã cấu hình Supabase Cloud' : 'Chế độ Local Cache';
  }

  /// Kiểm tra kết nối tới Supabase Cloud qua REST API
  Future<bool> testConnection() async {
    if (!isOnlineMode) {
      _connectionStatus = 'Chưa điền URL hoặc Anon Key';
      return false;
    }

    try {
      _isOnlineSyncing = true;
      final uri = Uri.parse('$_supabaseUrl/rest/v1/documents?select=id&limit=1');
      final response = await http.get(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _connectionStatus = 'Kết nối Supabase Cloud Online thành công (HTTP ${response.statusCode})';
        _isOnlineSyncing = false;
        await fetchOnlineDocuments();
        return true;
      } else {
        _connectionStatus = 'Lỗi kết nối HTTP ${response.statusCode}: ${response.body}';
        _isOnlineSyncing = false;
        return false;
      }
    } catch (e) {
      _connectionStatus = 'Không thể kết nối đến máy chủ Supabase: $e';
      _isOnlineSyncing = false;
      return false;
    }
  }

  /// Tải dữ liệu tài liệu trực tiếp từ Supabase Cloud Online về ứng dụng
  Future<List<SupabaseDocument>> fetchOnlineDocuments() async {
    if (!isOnlineMode) return _documentsTable.values.toList();

    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/documents?select=*');
      final response = await http.get(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> list = jsonDecode(response.body);
        _documentsTable.clear();
        for (var item in list) {
          final doc = SupabaseDocument.fromMap(Map<String, dynamic>.from(item));
          _documentsTable[doc.id] = doc;
        }
        _notify();
      }
    } catch (e) {
      // Giữ nguyên cache cục bộ nếu gặp sự cố mạng
    }
    return _documentsTable.values.toList();
  }

  // ==========================================
  // BẢNG 1: USERS (Người dùng)
  // ==========================================
  Future<void> upsertUser(SupabaseUser user) async {
    _usersTable[user.id] = user;

    if (isOnlineMode) {
      try {
        final uri = Uri.parse('$_supabaseUrl/rest/v1/users?on_conflict=id');
        final res = await http.post(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode(user.toMap()),
        ).timeout(const Duration(seconds: 6));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          debugPrint('✅ Supabase Cloud: Đã lưu user vào bảng users: ${user.email}');
        } else if (res.statusCode == 409) {
          // Email đã tồn tại với ID khác -> Cập nhật thông tin theo email
          final patchUri = Uri.parse('$_supabaseUrl/rest/v1/users?email=eq.${user.email}');
          final patchMap = Map<String, dynamic>.from(user.toMap())..remove('id');
          await http.patch(
            patchUri,
            headers: {
              'apikey': _supabaseAnonKey!,
              'Authorization': 'Bearer $_supabaseAnonKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(patchMap),
          ).timeout(const Duration(seconds: 4));
          debugPrint('✅ Supabase Cloud: Đã cập nhật user theo email: ${user.email}');
        } else {
          debugPrint('❌ Supabase Cloud lỗi lưu user: ${res.statusCode} ${res.body}');
        }
      } catch (e) {
        debugPrint('Supabase upsertUser error: $e');
      }
    }
  }

  SupabaseUser? getUserById(String userId) => _usersTable[userId];
  List<SupabaseUser> getAllUsers() => _usersTable.values.toList();

  // ==========================================
  // BẢNG 2: DOCUMENTS (Tài liệu) & RLS CHECKS
  // ==========================================

  /// [RLS Policy 1 - SELECT]: Người dùng chỉ được xem tài liệu nếu là Owner
  /// HOẶC được cấp quyền 'view' / 'edit' trong bảng document_permissions
  List<SupabaseDocument> getAccessibleDocuments(String currentUserId) {
    return _documentsTable.values.where((doc) {
      if (doc.ownerId == currentUserId) return true;
      return hasPermission(doc.id, currentUserId, PermissionType.view) ||
             hasPermission(doc.id, currentUserId, PermissionType.edit);
    }).toList();
  }

  /// [RLS Policy 2 - INSERT]: Chỉ người dùng đã đăng nhập mới được tạo tài liệu mới
  /// và trường owner_id bắt buộc phải trùng khớp với auth.uid()
  Future<SupabaseDocument> insertDocument({
    required String title,
    required String description,
    String? courseCode,
    String? storageLocationId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required SupabaseUser currentUser,
    List<String> tags = const [],
    List<String> tagIds = const [],
    String physicalLocation = 'Thư viện Trung tâm - Tòa H1',
    String shelfLocation = 'Kệ A3 - Ngăn 02',
    double latitude = 10.8700,
    double longitude = 106.8030,
    bool isPinned = false,
  }) async {
    // Đảm bảo user đã được lưu vào bảng users trước để thỏa mãn Foreign Key
    await upsertUser(currentUser);

    // Lấy id thực tế của user từ Supabase Cloud để luôn thỏa mãn Foreign Key
    String effectiveOwnerId = currentUser.id;
    if (isOnlineMode) {
      try {
        final checkUri = Uri.parse('$_supabaseUrl/rest/v1/users?email=eq.${currentUser.email}&select=id');
        final checkRes = await http.get(
          checkUri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
          },
        ).timeout(const Duration(seconds: 4));
        if (checkRes.statusCode == 200) {
          final List<dynamic> list = jsonDecode(checkRes.body);
          if (list.isNotEmpty && list[0]['id'] != null) {
            effectiveOwnerId = list[0]['id'] as String;
          }
        }
      } catch (_) {}
    }

    // Đóng gói metadata để lưu an toàn vào DB ngay cả khi schema chưa cập nhật cột mới
    final metaJson = jsonEncode({
      'tags': tags,
      'loc': physicalLocation,
      'shelf': shelfLocation,
      'lat': latitude,
      'lng': longitude,
      'pinned': isPinned,
    });
    final enrichedDesc = description.isNotEmpty ? '$description\n<!--META:$metaJson-->' : '<!--META:$metaJson-->';

    final docId = const Uuid().v4();
    final newDoc = SupabaseDocument(
      id: docId,
      title: title,
      description: enrichedDesc,
      storageLocationId: storageLocationId,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      ownerId: currentUser.id,
      ownerEmail: currentUser.email,
      ownerName: currentUser.displayName,
    );

    _documentsTable[newDoc.id] = newDoc;
    _notify();

    // Đồng bộ trực tiếp lên Supabase Cloud (Không gửi course_code vì đã bỏ cột này)
    if (isOnlineMode) {
      try {
        final uri = Uri.parse('$_supabaseUrl/rest/v1/documents');
        final payload = newDoc.toMap()
          ..['owner_id'] = effectiveOwnerId
          ..remove('course_code');
        if (storageLocationId != null && storageLocationId.isNotEmpty) {
          payload['storage_location_id'] = storageLocationId;
        }

        final res = await http.post(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation',
          },
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 6));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          debugPrint('✅ Supabase Cloud: Đã thêm tài liệu thành công: ${newDoc.title}');

          // Đồng bộ các tag vào bảng trung gian document_tags
          final listToSync = tagIds.isNotEmpty ? tagIds : tags;
          for (final tid in listToSync) {
            try {
              final tagUri = Uri.parse('$_supabaseUrl/rest/v1/document_tags');
              await http.post(
                tagUri,
                headers: {
                  'apikey': _supabaseAnonKey!,
                  'Authorization': 'Bearer $_supabaseAnonKey',
                  'Content-Type': 'application/json',
                  'Prefer': 'return=minimal',
                },
                body: jsonEncode({
                  'document_id': docId,
                  'tag_id': tid,
                }),
              ).timeout(const Duration(seconds: 3));
            } catch (_) {}
          }
        } else {
          debugPrint('❌ Supabase Cloud lỗi thêm tài liệu: ${res.statusCode} ${res.body}');
        }
      } catch (e) {
        debugPrint('Supabase insert error: $e');
      }
    }

    return newDoc;
  }

  /// [RLS Policy 3 - UPDATE]: Chỉ Owner HOẶC người dùng có quyền 'edit' mới được sửa
  Future<bool> updateDocument({
    required String documentId,
    required String newTitle,
    required String newDescription,
    String? newCourseCode,
    String? storageLocationId,
    String? newFileUrl,
    required String currentUserId,
    List<String>? tags,
    String? physicalLocation,
    String? shelfLocation,
    double? latitude,
    double? longitude,
    bool? isPinned,
  }) async {
    final doc = _documentsTable[documentId];
    if (doc != null) {
      // RLS Enforcement: Kiểm tra quyền sở hữu hoặc quyền Edit
      final isOwner = doc.ownerId == currentUserId;
      final isEditor = hasPermission(documentId, currentUserId, PermissionType.edit);

      if (!isOwner && !isEditor) {
        throw Exception('RLS VIOLATION: Người dùng ' + currentUserId + ' không có quyền chỉnh sửa tài liệu ' + documentId);
      }

      final updated = doc.copyWith(
        title: newTitle,
        description: newDescription,
        updatedAt: DateTime.now(),
      );

      _documentsTable[documentId] = updated;
      _notify();
    }

    // LUÔN LUÔN gửi HTTP PATCH lên Supabase Cloud REST API để cập nhật cơ sở dữ liệu thật!
    bool cloudSuccess = false;
    final Map<String, dynamic> metaMap = {};
    if (tags != null) metaMap['tags'] = tags;
    if (physicalLocation != null) metaMap['loc'] = physicalLocation;
    if (shelfLocation != null) metaMap['shelf'] = shelfLocation;
    if (latitude != null) metaMap['lat'] = latitude;
    if (longitude != null) metaMap['lng'] = longitude;
    if (isPinned != null) metaMap['pinned'] = isPinned;
    final metaJson = jsonEncode(metaMap);
    final enrichedDesc = newDescription.isNotEmpty ? '$newDescription\n<!--META:$metaJson-->' : '<!--META:$metaJson-->';

    if (isOnlineMode) {
      try {
        final uri = Uri.parse('$_supabaseUrl/rest/v1/documents?id=eq.$documentId');
        final Map<String, dynamic> patchBody = {
          'title': newTitle,
          'description': enrichedDesc,
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (storageLocationId != null && storageLocationId.isNotEmpty) {
          patchBody['storage_location_id'] = storageLocationId;
        }
        if (newCourseCode != null && newCourseCode.isNotEmpty) {
          patchBody['course_code'] = newCourseCode;
        }
        if (newFileUrl != null && newFileUrl.isNotEmpty) {
          patchBody['file_url'] = newFileUrl;
        }

        final res = await http.patch(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode(patchBody),
        ).timeout(const Duration(seconds: 6));

        if (res.statusCode >= 200 && res.statusCode < 300) {
          cloudSuccess = true;
          debugPrint('✅ Supabase Cloud: Đã PATCH cập nhật tài liệu $documentId thành công');
        } else {
          debugPrint('❌ Supabase Cloud PATCH thất bại: ${res.statusCode} ${res.body}');
        }
      } catch (e) {
        debugPrint('Lỗi HTTP updateDocument Supabase: $e');
      }
    }

    return cloudSuccess || doc != null;
  }

  /// [RLS Policy 4 - DELETE]: CHỈ DUY NHẤT Owner mới có quyền xóa tài liệu
  Future<bool> deleteDocument({
    required String documentId,
    required String currentUserId,
  }) async {
    final doc = _documentsTable[documentId];
    if (doc != null) {
      // RLS Enforcement: Owner HOẶC người được cấp quyền delete/all mới được xóa
      final isOwner = doc.ownerId == currentUserId;
      final canDelete = hasPermission(documentId, currentUserId, PermissionType.delete) || isOwner;
      if (!isOwner && !canDelete) {
        throw Exception('RLS VIOLATION: Bạn không có quyền xóa tài liệu này');
      }

      // Cascade delete permissions liên quan
      _permissionsTable.removeWhere((_, p) => p.documentId == documentId);
      _documentsTable.remove(documentId);
      _notify();
    }

    // LUÔN LUÔN gửi HTTP DELETE lên Supabase Cloud REST API!
    bool cloudSuccess = false;
    if (isOnlineMode) {
      try {
        final uri = Uri.parse('$_supabaseUrl/rest/v1/documents?id=eq.$documentId');
        final res = await http.delete(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
          },
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode >= 200 && res.statusCode < 300) {
          cloudSuccess = true;
          debugPrint('✅ Supabase Cloud: Đã DELETE tài liệu $documentId thành công');
        }
      } catch (e) {
        debugPrint('Lỗi HTTP deleteDocument Supabase: $e');
      }
    }

    return cloudSuccess || doc != null;
  }

  // ==========================================
  // BẢNG 3: PERMISSIONS (Quyền chia sẻ) & RLS
  // ==========================================

  /// [RLS Policy 5 - PERMISSION MANAGEMENT]: Chỉ Owner mới được quyền chia sẻ hoặc thu hồi quyền
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetUserId,
    required PermissionType permissionType,
    required SupabaseUser currentUser,
  }) async {
    final doc = _documentsTable[documentId];
    if (doc == null) throw Exception('Tài liệu không tồn tại');

    // RLS Enforcement: Owner HOẶC người được cấp quyền share/all mới được quyền chia sẻ
    final isOwner = doc.ownerId == currentUser.id;
    final canShare = hasPermission(documentId, currentUser.id, PermissionType.share) || isOwner;
    if (!isOwner && !canShare) {
      throw Exception('RLS VIOLATION: Bạn không có quyền chia sẻ tài liệu này');
    }

    final targetUser = _usersTable[targetUserId];
    if (targetUser == null) throw Exception('Người dùng được chia sẻ không tồn tại');

    final permId = 'perm-' + documentId + '-' + targetUserId;
    final permission = DocumentPermission(
      id: permId,
      documentId: documentId,
      userId: targetUserId,
      userEmail: targetUser.email,
      userName: targetUser.displayName,
      permissionType: permissionType,
      grantedBy: currentUser.id,
    );

    _permissionsTable[permId] = permission;
    _notify();
    return permission;
  }

  /// Thu hồi quyền truy cập (Revoke permission)
  Future<bool> revokePermission({
    required String documentId,
    required String targetUserId,
    required String currentUserId,
  }) async {
    final doc = _documentsTable[documentId];
    if (doc == null || doc.ownerId != currentUserId) {
      throw Exception('RLS VIOLATION: Chỉ chủ sở hữu mới có quyền thu hồi quyền chia sẻ');
    }

    final permId = 'perm-' + documentId + '-' + targetUserId;
    _permissionsTable.remove(permId);
    _notify();
    return true;
  }

  /// Kiểm tra quyền hạn cụ thể của người dùng đối với tài liệu
  bool hasPermission(String documentId, String userId, PermissionType type) {
    final permId = 'perm-' + documentId + '-' + userId;
    final perm = _permissionsTable[permId];
    if (perm == null) return false;
    if (type == PermissionType.view) {
      return true; // Mặc định luôn luôn có quyền xem
    }
    if (type == PermissionType.edit) {
      return perm.canEdit;
    }
    if (type == PermissionType.delete) {
      return perm.canDelete;
    }
    if (type == PermissionType.share) {
      return perm.canShare;
    }
    return perm.permissionType == PermissionType.all || perm.permissions.contains('all');
  }

  List<DocumentPermission> getPermissionsForDocument(String documentId) {
    return _permissionsTable.values.where((p) => p.documentId == documentId).toList();
  }

  // ==========================================
  // CHECKLIST 4: TÌM KIẾM TÀI LIỆU TOÀN VĂN
  // ==========================================
  List<SupabaseDocument> searchDocuments({
    required String query,
    required String currentUserId,
    String? courseCode,
    bool onlySharedWithMe = false,
  }) {
    var accessible = getAccessibleDocuments(currentUserId);

    if (onlySharedWithMe) {
      accessible = accessible.where((d) => d.ownerId != currentUserId).toList();
    }

    if (courseCode != null && courseCode.isNotEmpty && courseCode != 'all') {
      accessible = accessible.where((d) => d.courseCode.toLowerCase() == courseCode.toLowerCase()).toList();
    }

    if (query.trim().isEmpty) return accessible;

    final q = query.trim().toLowerCase();
    return accessible.where((d) {
      return d.title.toLowerCase().contains(q) ||
             d.description.toLowerCase().contains(q) ||
             d.fileName.toLowerCase().contains(q) ||
             d.courseCode.toLowerCase().contains(q) ||
             d.ownerName.toLowerCase().contains(q);
    }).toList();
  }

  /// [RLS ENFORCEMENT]: Tải danh sách tài liệu mà người dùng HIỆN TẠI có quyền truy cập
  Future<List<StudyDocument>> fetchAccessibleStudyDocuments(SupabaseUser currentUser) async {
    final List<StudyDocument> accessibleDocs = [];

    try {
      // 1. Kéo toàn bộ tài liệu từ Supabase Cloud
      final docUri = Uri.parse('$_supabaseUrl/rest/v1/documents?select=*&order=created_at.desc');
      final docRes = await http.get(
        docUri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 6));

      if (docRes.statusCode < 200 || docRes.statusCode >= 300) {
        return [];
      }

      final List<dynamic> rawDocs = jsonDecode(docRes.body);
      _documentsTable.clear();
      _permissionsTable.clear();

      // 2. Kéo toàn bộ quyền chia sẻ từ bảng document_permissions
      final permUri = Uri.parse('$_supabaseUrl/rest/v1/document_permissions?select=*');
      final permRes = await http.get(
        permUri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 6));

      final List<dynamic> rawPerms = (permRes.statusCode >= 200 && permRes.statusCode < 300)
          ? jsonDecode(permRes.body)
          : [];

      // Đồng bộ toàn bộ quyền từ Supabase vào bảng in-memory _permissionsTable
      for (var p in rawPerms) {
        final pDocId = p['document_id']?.toString() ?? '';
        final pUserId = p['user_id']?.toString() ?? '';
        final pUserEmail = p['user_email']?.toString() ?? '';
        final pUserName = p['user_name']?.toString() ?? '';
        final pType = p['permission_type']?.toString() ?? 'view';
        final pGrantedBy = p['granted_by']?.toString() ?? '';
        final permId = 'perm-$pDocId-$pUserId';
        _permissionsTable[permId] = DocumentPermission(
          id: p['id']?.toString() ?? permId,
          documentId: pDocId,
          userId: pUserId,
          userEmail: pUserEmail,
          userName: pUserName,
          permissions: DocumentPermission.parsePermissions(pType),
          permissionType: PermissionType.fromString(pType),
          grantedBy: pGrantedBy,
        );
      }

      for (var item in rawDocs) {
        final map = Map<String, dynamic>.from(item);
        final docId = map['id']?.toString() ?? '';
        final itemOwnerId = map['owner_id']?.toString() ?? '';
        final itemOwnerEmail = (map['owner_email']?.toString() ?? '').toLowerCase().trim();
        final itemOwnerName = map['owner_name']?.toString() ?? itemOwnerEmail;

        // Đồng bộ vào _documentsTable
        _documentsTable[docId] = SupabaseDocument(
          id: docId,
          title: map['title']?.toString() ?? 'Tài liệu không tên',
          description: map['description']?.toString() ?? '',
          courseCode: map['course_code']?.toString() ?? 'SE301',
          fileUrl: map['file_url']?.toString() ?? '',
          fileName: map['file_name']?.toString() ?? '',
          fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
          ownerId: itemOwnerId,
          ownerEmail: itemOwnerEmail,
          ownerName: itemOwnerName,
          createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
        );
        final ownerId = map['owner_id']?.toString() ?? '';
        final ownerEmail = (map['owner_email']?.toString() ?? '').toLowerCase().trim();
        final ownerName = map['owner_name']?.toString() ?? ownerEmail;
        final currentEmail = currentUser.email.toLowerCase().trim();

        // Giải mã metadata (Tags, Vị trí vật lý, GPS, Đã ghim) từ Description hoặc Cột
        final rawDesc = map['description']?.toString() ?? '';
        String cleanDesc = rawDesc;
        List<String> parsedTags = [];
        String physicalLoc = map['physical_location']?.toString() ?? 'Thư viện Trung tâm - Tòa H1';
        String shelfLoc = map['shelf_location']?.toString() ?? 'Kệ A3 - Ngăn 02';
        double lat = (map['latitude'] as num?)?.toDouble() ?? 10.8700;
        double lon = (map['longitude'] as num?)?.toDouble() ?? 106.8030;
        bool pinned = map['is_pinned'] == true || map['is_pinned']?.toString() == 'true';
        String borrowStat = map['borrow_status']?.toString() ?? 'available';

        if (rawDesc.contains('<!--META:') && rawDesc.contains('-->')) {
          final start = rawDesc.indexOf('<!--META:') + 9;
          final end = rawDesc.indexOf('-->', start);
          if (end > start) {
            final metaStr = rawDesc.substring(start, end);
            cleanDesc = rawDesc.substring(0, rawDesc.indexOf('<!--META:')).trim();
            try {
              final metaMap = jsonDecode(metaStr) as Map<String, dynamic>;
              if (metaMap['tags'] is List) {
                parsedTags = (metaMap['tags'] as List).map((e) => e.toString()).toList();
              }
              if (metaMap['loc'] != null) physicalLoc = metaMap['loc'].toString();
              if (metaMap['shelf'] != null) shelfLoc = metaMap['shelf'].toString();
              if (metaMap['lat'] != null) lat = (metaMap['lat'] as num).toDouble();
              if (metaMap['lng'] != null) lon = (metaMap['lng'] as num).toDouble();
              if (metaMap['pinned'] != null) pinned = metaMap['pinned'] == true;
              if (metaMap['borrow'] != null) borrowStat = metaMap['borrow'].toString();
            } catch (_) {}
          }
        }

        // Kiểm tra xem có phải chủ sở hữu tài liệu không
        final isOwner = (ownerEmail == currentEmail) || (ownerId == currentUser.id);

        if (isOwner) {
          accessibleDocs.add(StudyDocument(
            id: docId,
            title: map['title']?.toString() ?? 'Tài liệu không tên',
            description: cleanDesc,
            courseId: '',
            type: DocumentType.lecture,
            fileUrl: map['file_url']?.toString() ?? '',
            tags: parsedTags,
            physicalLocation: physicalLoc,
            shelfLocation: shelfLoc,
            latitude: lat,
            longitude: lon,
            isPinned: pinned,
            borrowStatus: borrowStat,
            ownerId: ownerId,
            ownerEmail: ownerEmail,
            ownerName: ownerName,
            sharedPermission: 'owner',
            isSynced: true,
          ));
          continue;
        }

        // Kiểm tra xem có được ai chia sẻ quyền xem/sửa không
        dynamic matchedPerm;
        for (var p in rawPerms) {
          final pDocId = p['document_id']?.toString() ?? '';
          final pUserEmail = (p['user_email']?.toString() ?? '').toLowerCase().trim();
          final pUserId = p['user_id']?.toString() ?? '';

          if (pDocId == docId && (pUserEmail == currentEmail || pUserId == currentUser.id)) {
            matchedPerm = p;
            break;
          }
        }

        if (matchedPerm != null) {
          final rawUserName = matchedPerm['user_name']?.toString() ?? '';
          final rawPermType = matchedPerm['permission_type']?.toString() ?? 'view';

          List<String> parsedPerms;
          if (rawUserName.contains('#perms:')) {
            final permPart = rawUserName.split('#perms:').last;
            parsedPerms = DocumentPermission.parsePermissions(permPart);
          } else {
            parsedPerms = DocumentPermission.parsePermissions(rawPermType);
          }

          accessibleDocs.add(StudyDocument(
            id: docId,
            title: map['title']?.toString() ?? 'Tài liệu không tên',
            description: cleanDesc,
            courseId: '',
            type: DocumentType.lecture,
            fileUrl: map['file_url']?.toString() ?? '',
            tags: parsedTags,
            physicalLocation: physicalLoc,
            shelfLocation: shelfLoc,
            latitude: lat,
            longitude: lon,
            isPinned: pinned,
            borrowStatus: borrowStat,
            ownerId: ownerId,
            ownerEmail: ownerEmail,
            ownerName: ownerName,
            sharedPermission: rawPermType,
            permissions: parsedPerms,
            sharedByEmail: ownerEmail,
            isSynced: true,
          ));
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetchAccessibleStudyDocuments: $e');
    }

    return accessibleDocs;
  }

  /// Tìm kiếm danh sách người dùng trong bảng users trên Supabase
  Future<List<SupabaseUser>> searchUsersOnline(String query) async {
    final List<SupabaseUser> results = [];
    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/users?select=*');
      final res = await http.get(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> list = jsonDecode(res.body);
        final q = query.toLowerCase().trim();
        for (var item in list) {
          final u = SupabaseUser.fromMap(Map<String, dynamic>.from(item));
          if (q.isEmpty || u.email.toLowerCase().contains(q) || u.displayName.toLowerCase().contains(q)) {
            results.add(u);
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi searchUsersOnline: $e');
    }
    return results;
  }

  /// Chia sẻ quyền truy cập tài liệu lên Supabase Cloud (bảng document_permissions)
  Future<bool> shareDocumentOnline({
    required String documentId,
    required SupabaseUser targetUser,
    PermissionType? permissionType,
    List<String>? permissions,
    required SupabaseUser currentUser,
  }) async {
    try {
      final List<String> perms = permissions ?? (permissionType != null ? [permissionType.name] : ['view']);
      final pType = permissionType ?? (perms.contains('all') ? PermissionType.all : (perms.contains('edit') ? PermissionType.edit : (perms.contains('share') ? PermissionType.share : PermissionType.view)));

      final uri = Uri.parse('$_supabaseUrl/rest/v1/document_permissions');
      // Lưu dưới dạng mảng JSON: '["view","edit","share"]'
      final jsonArrayStr = jsonEncode(perms);

      final permJoined = perms.join(',');
      final encodedUserName = '${targetUser.displayName}#perms:$permJoined';

      final body = {
        'document_id': documentId,
        'user_id': targetUser.id,
        'user_email': targetUser.email,
        'user_name': encodedUserName,
        'permission_type': jsonArrayStr,
        'granted_by': currentUser.id,
      };

      var res = await http.post(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));

      // Nếu Supabase chưa gỡ CHECK constraint, thử dạng 'view,edit,share'
      if (res.statusCode == 400 && res.body.contains('check constraint')) {
        body['permission_type'] = perms.join(',');
        res = await http.post(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 6));
      }

      // Nếu vẫn bị constraint cũ IN ('view', 'edit'), fallback về 'edit' hoặc 'view' và nhắc nhở
      if (res.statusCode == 400 && res.body.contains('check constraint')) {
        debugPrint('⚠️ Supabase đang có CHECK constraint cũ: fallback lưu');
        body['permission_type'] = perms.contains('edit') ? 'edit' : 'view';
        res = await http.post(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 6));
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        debugPrint('✅ Đã chia sẻ mảng quyền $perms cho ${targetUser.email} trên Supabase');
        shareDocument(
          documentId: documentId,
          targetUserId: targetUser.id,
          permissionType: pType,
          currentUser: currentUser,
        );
        return true;
      } else {
        debugPrint('❌ Lỗi chia sẻ Supabase: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Lỗi shareDocumentOnline: $e');
    }
    return false;
  }

  /// Lấy danh sách những người đã được chia sẻ của một tài liệu
  Future<List<DocumentPermission>> fetchPermissionsForDocOnline(String documentId) async {
    final List<DocumentPermission> list = [];
    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/document_permissions?document_id=eq.$documentId&select=*');
      final res = await http.get(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> data = jsonDecode(res.body);
        for (var item in data) {
          list.add(DocumentPermission.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    } catch (_) {}
    return list;
  }

  /// Thu hồi quyền chia sẻ trên Supabase Cloud
  Future<bool> revokePermissionOnline(String documentId, String targetUserId) async {
    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/document_permissions?document_id=eq.$documentId&user_id=eq.$targetUserId');
      final res = await http.delete(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 5));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Tải toàn bộ tài liệu học tập của TẤT CẢ người dùng trong cộng đồng để hiển thị trong Nơi mượn tài liệu
  Future<List<StudyDocument>> fetchAllCommunityStudyDocuments() async {
    final List<StudyDocument> list = [];
    if (isOnlineMode) {
      try {
        final docUri = Uri.parse('$_supabaseUrl/rest/v1/documents?select=*&order=created_at.desc');
        final docRes = await http.get(
          docUri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
          },
        ).timeout(const Duration(seconds: 6));

        if (docRes.statusCode >= 200 && docRes.statusCode < 300) {
          final List<dynamic> rawDocs = jsonDecode(docRes.body);
          for (var item in rawDocs) {
            final map = Map<String, dynamic>.from(item);
            final docId = map['id']?.toString() ?? '';
            final ownerId = map['owner_id']?.toString() ?? '';
            final ownerEmail = map['owner_email']?.toString() ?? '';
            final ownerName = map['owner_name']?.toString() ?? ownerEmail;
            final rawDesc = map['description']?.toString() ?? '';

            String cleanDesc = rawDesc;
            List<String> parsedTags = [];
            String physicalLoc = map['physical_location']?.toString() ?? 'Thư viện Trung tâm - Tòa H1';
            String shelfLoc = map['shelf_location']?.toString() ?? 'Kệ A3 - Ngăn 02';
            double lat = (map['latitude'] as num?)?.toDouble() ?? 21.00699;
            double lon = (map['longitude'] as num?)?.toDouble() ?? 105.8251;
            bool pinned = map['is_pinned'] == true || map['is_pinned']?.toString() == 'true';
            String borrowStat = map['borrow_status']?.toString() ?? 'available';

            if (rawDesc.contains('<!--META:') && rawDesc.contains('-->')) {
              final start = rawDesc.indexOf('<!--META:') + 9;
              final end = rawDesc.indexOf('-->', start);
              if (end > start) {
                final metaStr = rawDesc.substring(start, end);
                cleanDesc = rawDesc.substring(0, rawDesc.indexOf('<!--META:')).trim();
                try {
                  final metaMap = jsonDecode(metaStr) as Map<String, dynamic>;
                  if (metaMap['tags'] is List) {
                    parsedTags = (metaMap['tags'] as List).map((e) => e.toString()).toList();
                  }
                  if (metaMap['loc'] != null && metaMap['loc'].toString().isNotEmpty) {
                    physicalLoc = metaMap['loc'].toString();
                  }
                  if (metaMap['shelf'] != null) shelfLoc = metaMap['shelf'].toString();
                  if (metaMap['lat'] != null) lat = (metaMap['lat'] as num).toDouble();
                  if (metaMap['lng'] != null) lon = (metaMap['lng'] as num).toDouble();
                  if (metaMap['pinned'] != null) pinned = metaMap['pinned'] == true;
                  if (metaMap['borrow'] != null) borrowStat = metaMap['borrow'].toString();
                } catch (_) {}
              }
            }

            // Đồng bộ vị trí kho chuẩn nếu có id
            final storageLocId = map['storage_location_id']?.toString();
            if (storageLocId != null && storageLocId.isNotEmpty) {
              final loc = AppDatabase().getStorageLocation(storageLocId);
              if (loc != null) {
                if (physicalLoc == 'Thư viện Trung tâm - Tòa H1' || physicalLoc.isEmpty) {
                  physicalLoc = loc.name;
                  shelfLoc = loc.shelfDetail;
                }
                if (lat == 10.8700 || lat == 0.0) {
                  lat = loc.latitude;
                  lon = loc.longitude;
                }
              }
            }

            list.add(StudyDocument(
              id: docId,
              title: map['title']?.toString() ?? 'Tài liệu không tên',
              description: cleanDesc,
              courseId: '',
              type: DocumentType.lecture,
              fileUrl: map['file_url']?.toString() ?? '',
              tags: parsedTags,
              physicalLocation: physicalLoc,
              shelfLocation: shelfLoc,
              latitude: lat,
              longitude: lon,
              isPinned: pinned,
              borrowStatus: borrowStat,
              ownerId: ownerId,
              ownerEmail: ownerEmail,
              ownerName: ownerName,
              isSynced: true,
            ));
          }
        }
      } catch (e) {
        debugPrint('Lỗi fetchAllCommunityStudyDocuments: $e');
      }
    }

    if (list.isEmpty) {
      list.addAll(AppDatabase().getAllDocuments());
    }
    return list;
  }

  // ================= TH2: QUẢN LÝ MƯỢN / TRẢ TÀI LIỆU =================
  Future<bool> createBorrowRequest(BorrowRequest request) async {
    _borrowRequestsTable[request.id] = request;
    _saveBorrowRequestsCache();

    if (isOnlineMode) {
      try {
        final uri = Uri.parse('$_supabaseUrl/rest/v1/borrow_requests?on_conflict=id');
        final res = await http.post(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode(request.toMap()),
        ).timeout(const Duration(seconds: 5));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          debugPrint('✅ Supabase Cloud: Đã lưu yêu cầu mượn ${request.id} vào CSDL thật');
          return true;
        } else {
          debugPrint('⚠️ Supabase Cloud createBorrowRequest trả về mã: ${res.statusCode} ${res.body}');
        }
        return res.statusCode >= 200 && res.statusCode < 300;
      } catch (e) {
        debugPrint('Lỗi createBorrowRequest Supabase: $e');
      }
    }
    return true;
  }

  Future<List<BorrowRequest>> fetchBorrowRequests({String? borrowerEmail, String? ownerEmail}) async {
    final List<BorrowRequest> results = [];

    if (isOnlineMode) {
      try {
        String url = '$_supabaseUrl/rest/v1/borrow_requests?select=*&order=request_date.desc';
        if (borrowerEmail != null && borrowerEmail.isNotEmpty) {
          url += '&borrower_email=eq.${borrowerEmail.trim()}';
        } else if (ownerEmail != null && ownerEmail.isNotEmpty) {
          url += '&owner_email=eq.${ownerEmail.trim()}';
        }
        final uri = Uri.parse(url);
        final res = await http.get(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
          },
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode >= 200 && res.statusCode < 300) {
          final List<dynamic> list = jsonDecode(res.body);
          for (var item in list) {
            final req = BorrowRequest.fromMap(Map<String, dynamic>.from(item));
            _borrowRequestsTable[req.id] = req;
            results.add(req);
          }
          _saveBorrowRequestsCache();
          results.sort((a, b) => b.requestDate.compareTo(a.requestDate));
          return results;
        }
      } catch (e) {
        debugPrint('Lỗi fetchBorrowRequests Supabase: $e');
      }
    }

    _loadBorrowRequestsFromCache();

    // Lọc theo borrower hoặc owner
    for (var req in _borrowRequestsTable.values) {
      if (borrowerEmail != null && req.borrowerEmail.toLowerCase() == borrowerEmail.toLowerCase()) {
        results.add(req);
      } else if (ownerEmail != null && req.ownerEmail.toLowerCase() == ownerEmail.toLowerCase()) {
        results.add(req);
      } else if (borrowerEmail == null && ownerEmail == null) {
        results.add(req);
      }
    }

    results.sort((a, b) => b.requestDate.compareTo(a.requestDate));
    return results;
  }

  Future<bool> updateBorrowRequestStatus(String requestId, BorrowStatus newStatus) async {
    if (_borrowRequestsTable.containsKey(requestId)) {
      final old = _borrowRequestsTable[requestId]!;
      _borrowRequestsTable[requestId] = old.copyWith(
        status: newStatus,
        returnDate: newStatus == BorrowStatus.returned ? DateTime.now() : null,
      );
      _saveBorrowRequestsCache();
    }

    if (isOnlineMode) {
      try {
        final uri = Uri.parse('$_supabaseUrl/rest/v1/borrow_requests?id=eq.$requestId');
        final res = await http.patch(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode({
            'status': newStatus.name,
            if (newStatus == BorrowStatus.returned) 'return_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 5));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          debugPrint('✅ Supabase Cloud: Đã PATCH cập nhật trạng thái mượn ${newStatus.name} cho yêu cầu $requestId');
          return true;
        } else {
          debugPrint('⚠️ Supabase Cloud PATCH updateBorrowRequestStatus lỗi: ${res.statusCode} ${res.body}');
        }
      } catch (e) {
        debugPrint('Lỗi updateBorrowRequestStatus: $e');
      }
    }
    return true;
  }

  // ================= QUẢN LÝ THẺ TAG TRÊN SUPABASE (TABLE: tags) =================
  Future<List<DocumentTag>> fetchTags() => fetchTagsOnline();
  Future<List<StorageLocationItem>> fetchStorageLocations() => fetchStorageLocationsOnline();

  Future<List<DocumentTag>> fetchTagsOnline() async {
    final List<DocumentTag> tags = [];
    if (!isOnlineMode) return tags;
    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/tags?select=*&order=created_at.desc');
      final res = await http.get(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> list = jsonDecode(res.body);
        for (var item in list) {
          tags.add(DocumentTag.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    } catch (_) {}
    return tags;
  }

  Future<bool> insertTagOnline(DocumentTag tag) async {
    if (!isOnlineMode) return false;
    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/tags');
      final res = await http.post(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(tag.toMap()),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTagOnline(String id) async {
    if (!isOnlineMode) return false;
    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/tags?id=eq.$id');
      final res = await http.delete(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 4));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ================= QUẢN LÝ KHO LƯU TRỮ TRÊN SUPABASE (TABLE: storage_locations) =================
  Future<List<StorageLocationItem>> fetchStorageLocationsOnline() async {
    final List<StorageLocationItem> locations = [];
    if (!isOnlineMode) return locations;
    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/storage_locations?select=*&order=created_at.desc');
      final res = await http.get(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> list = jsonDecode(res.body);
        for (var item in list) {
          locations.add(StorageLocationItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    } catch (_) {}
    return locations;
  }

  Future<bool> insertStorageLocationOnline(StorageLocationItem loc) async {
    if (!isOnlineMode) return false;
    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/storage_locations');
      final res = await http.post(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(loc.toMap()),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteStorageLocationOnline(String id) async {
    if (!isOnlineMode) return false;
    try {
      final uri = Uri.parse('$_supabaseUrl/rest/v1/storage_locations?id=eq.$id');
      final res = await http.delete(
        uri,
        headers: {
          'apikey': _supabaseAnonKey!,
          'Authorization': 'Bearer $_supabaseAnonKey',
        },
      ).timeout(const Duration(seconds: 4));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

}
