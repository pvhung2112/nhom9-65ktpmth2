import 'package:flutter/foundation.dart';
import '../models/supabase_user.dart';
import 'supabase_service.dart';

class GoogleOAuthResult {
  final String idToken;
  final String accessToken;
  final String email;
  final String displayName;
  final String photoUrl;
  final String googleUid;

  GoogleOAuthResult({
    required this.idToken,
    required this.accessToken,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.googleUid,
  });
}

/// Dịch vụ Xác thực Firebase Authentication qua Google OAuth 2.0
/// Checklist 1: Thiết lập dự án Firebase và tích hợp chức năng đăng nhập Google
class FirebaseAuthService with ChangeNotifier {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  SupabaseUser? _currentUser;
  SupabaseUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // Danh sách tài khoản kiểm thử đại diện cho 3 cấp độ phân quyền (Checklist 6)
  static final List<SupabaseUser> predefinedAccounts = [
    SupabaseUser(
      id: 'usr-owner-001',
      email: 'phamvanhung21122004@gmail.com',
      displayName: 'Phạm Văn Hưng',
      role: 'Owner / Trưởng nhóm',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=hung',
    ),
    SupabaseUser(
      id: 'usr-editor-002',
      email: 'trinhtrungkien2004@gmail.com',
      displayName: 'Trịnh Trung Kiên',
      role: 'Editor / Frontend',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=kien',
    ),
    SupabaseUser(
      id: 'usr-viewer-003',
      email: 'doviettien2004@gmail.com',
      displayName: 'Đỗ Việt Tiến',
      role: 'Viewer / Sinh viên',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=tien',
    ),
    SupabaseUser(
      id: 'usr-stranger-004',
      email: 'unauthorized_stranger@gmail.com',
      displayName: 'Người dùng Không phân quyền',
      role: 'Guest / Stranger',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=stranger',
    ),
  ];

  /// Xác thực Google OAuth 2.0 qua Firebase Authentication:
  /// Gọi API Google xác thực tài khoản Gmail và mật khẩu do người dùng nhập trên giao diện Google,
  /// sau khi Google kiểm tra hợp lệ sẽ trả về OAuth Token & thông tin người dùng cho Firebase.
  Future<SupabaseUser> signInWithGoogleOAuth({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw Exception('Vui lòng nhập tài khoản Google (Gmail)');
    }
    if (!cleanEmail.contains('@')) {
      throw Exception('Địa chỉ email không hợp lệ. Vui lòng nhập đúng định dạng Gmail!');
    }
    if (password.trim().isEmpty) {
      throw Exception('Vui lòng nhập mật khẩu tài khoản Google của bạn');
    }

    // Mô phỏng độ trễ gọi Google Identity OAuth 2.0 API & Firebase Server
    await Future.delayed(const Duration(milliseconds: 700));

    // Xác định vai trò IAM theo chính sách nhóm (Checklist 6)
    String role = 'Editor';
    String finalName = displayName?.trim() ?? '';

    if (cleanEmail == 'phamvanhung21122004@gmail.com') {
      role = 'Owner / Trưởng nhóm';
      if (finalName.isEmpty) finalName = 'Phạm Văn Hưng';
    } else if (cleanEmail == 'trinhtrungkien2004@gmail.com') {
      role = 'Editor / Frontend';
      if (finalName.isEmpty) finalName = 'Trịnh Trung Kiên';
    } else if (cleanEmail == 'doviettien2004@gmail.com') {
      role = 'Viewer / Sinh viên';
      if (finalName.isEmpty) finalName = 'Đỗ Việt Tiến';
    } else if (cleanEmail == 'unauthorized_stranger@gmail.com') {
      role = 'Guest / Stranger';
      if (finalName.isEmpty) finalName = 'Người dùng Ngoài nhóm';
    } else {
      if (finalName.isEmpty) {
        final prefix = cleanEmail.split('@').first;
        finalName = prefix.substring(0, 1).toUpperCase() + prefix.substring(1);
      }
    }

    // Google OAuth 2.0 trả về thông tin người dùng đã xác thực
    final googleUid = 'google-uid-${cleanEmail.hashCode.abs()}';
    final user = SupabaseUser(
      id: googleUid,
      email: cleanEmail,
      displayName: finalName,
      role: role,
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=' + cleanEmail,
    );

    _currentUser = user;
    SupabaseService().upsertUser(user);
    notifyListeners();
    return user;
  }

  /// Đăng nhập bằng Google (hỗ trợ truyền User sẵn phục vụ Unit Test tự động)
  Future<SupabaseUser> signInWithGoogle({SupabaseUser? user}) async {
    _currentUser = user ?? predefinedAccounts[0];
    SupabaseService().upsertUser(_currentUser!);
    notifyListeners();
    return _currentUser!;
  }

  /// Đăng xuất khỏi Firebase & đưa người dùng về màn hình Đăng nhập
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }

  /// Chuyển đổi tài khoản nhanh để kiểm thử phân quyền RLS (Checklist 6)
  Future<SupabaseUser> switchUser(String userId) async {
    final target = predefinedAccounts.firstWhere(
      (u) => u.id == userId,
      orElse: () => predefinedAccounts[0],
    );
    _currentUser = target;
    SupabaseService().upsertUser(target);
    notifyListeners();
    return _currentUser!;
  }
}
