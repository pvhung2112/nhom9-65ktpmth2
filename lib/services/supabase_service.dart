import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/supabase_user.dart';
import '../models/supabase_document.dart';
import '../models/document_permission.dart';
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
  String? _supabaseUrl;
  String? _supabaseAnonKey;
  bool _isOnlineSyncing = false;
  String _connectionStatus = 'Chế độ Local Cache';

  String? get supabaseUrl => _supabaseUrl;
  String? get supabaseAnonKey => _supabaseAnonKey;
  bool get isOnlineMode => _supabaseUrl != null && _supabaseUrl!.isNotEmpty && _supabaseAnonKey != null && _supabaseAnonKey!.isNotEmpty;
  bool get isOnlineSyncing => _isOnlineSyncing;
  String get connectionStatus => _connectionStatus;

  // Giả lập / Cache bảng dữ liệu PostgreSQL
  final Map<String, SupabaseDocument> _documentsTable = {};
  final Map<String, SupabaseUser> _usersTable = {};
  final Map<String, DocumentPermission> _permissionsTable = {};

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

  void _initDefaultData() {
    for (var u in FirebaseAuthService.predefinedAccounts) {
      _usersTable[u.id] = u;
    }
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
        final uri = Uri.parse('$_supabaseUrl/rest/v1/users');
        await http.post(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode(user.toMap()),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
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
    required String courseCode,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required SupabaseUser currentUser,
  }) async {
    final docId = 'doc-${DateTime.now().millisecondsSinceEpoch}';
    final newDoc = SupabaseDocument(
      id: docId,
      title: title,
      description: description,
      courseCode: courseCode,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      ownerId: currentUser.id,
      ownerEmail: currentUser.email,
      ownerName: currentUser.displayName,
    );

    _documentsTable[newDoc.id] = newDoc;
    _notify();

    // Đồng bộ trực tiếp lên Cloud nếu đã cấu hình
    if (isOnlineMode) {
      try {
        final uri = Uri.parse('$_supabaseUrl/rest/v1/documents');
        await http.post(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode(newDoc.toMap()),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    return newDoc;
  }

  /// [RLS Policy 3 - UPDATE]: Chỉ Owner HOẶC người dùng có quyền 'edit' mới được sửa
  Future<bool> updateDocument({
    required String documentId,
    required String newTitle,
    required String newDescription,
    required String currentUserId,
  }) async {
    final doc = _documentsTable[documentId];
    if (doc == null) return false;

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

    if (isOnlineMode) {
      try {
        final uri = Uri.parse('$_supabaseUrl/rest/v1/documents?id=eq.$documentId');
        await http.patch(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'title': newTitle,
            'description': newDescription,
            'updated_at': DateTime.now().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    return true;
  }

  /// [RLS Policy 4 - DELETE]: CHỈ DUY NHẤT Owner mới có quyền xóa tài liệu
  Future<bool> deleteDocument({
    required String documentId,
    required String currentUserId,
  }) async {
    final doc = _documentsTable[documentId];
    if (doc == null) return false;

    // RLS Enforcement: Chỉ Owner mới được xóa
    if (doc.ownerId != currentUserId) {
      throw Exception('RLS VIOLATION: Chỉ có chủ sở hữu (Owner: ' + doc.ownerId + ') mới được phép xóa tài liệu');
    }

    // Cascade delete permissions liên quan
    _permissionsTable.removeWhere((_, p) => p.documentId == documentId);
    _documentsTable.remove(documentId);
    _notify();

    if (isOnlineMode) {
      try {
        final uri = Uri.parse('$_supabaseUrl/rest/v1/documents?id=eq.$documentId');
        await http.delete(
          uri,
          headers: {
            'apikey': _supabaseAnonKey!,
            'Authorization': 'Bearer $_supabaseAnonKey',
          },
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    return true;
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

    // Chỉ Owner mới được quyền chia sẻ
    if (doc.ownerId != currentUser.id) {
      throw Exception('RLS VIOLATION: Chỉ chủ sở hữu tài liệu mới có quyền chia sẻ cho người khác');
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
      return perm.permissionType == PermissionType.view || perm.permissionType == PermissionType.edit;
    }
    return perm.permissionType == PermissionType.edit;
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
}
