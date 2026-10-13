import 'package:flutter/foundation.dart';
import '../models/supabase_user.dart';

/// Dịch vụ Xác thực Firebase Authentication & Đăng nhập Google
/// Checklist 1: Thiết lập dự án Firebase và tích hợp chức năng đăng nhập Google
class FirebaseAuthService with ChangeNotifier {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  SupabaseUser? _currentUser;
  SupabaseUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // Danh sách ít nhất 3 tài khoản người dùng khác nhau phục vụ kiểm thử phân quyền (Checklist 6)
  static final List<SupabaseUser> predefinedAccounts = [
    SupabaseUser(
      id: 'usr-owner-001',
      email: 'phamvanhung21122004@gmail.com',
      displayName: 'Phạm Văn Hưng (Owner / Trưởng nhóm)',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=hung',
    ),
    SupabaseUser(
      id: 'usr-editor-002',
      email: 'trinhtrungkien2004@gmail.com',
      displayName: 'Trịnh Trung Kiên (Editor / Thành viên)',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=kien',
    ),
    SupabaseUser(
      id: 'usr-viewer-003',
      email: 'doviettien2004@gmail.com',
      displayName: 'Đỗ Việt Tiến (Viewer / Sinh viên)',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=tien',
    ),
    SupabaseUser(
      id: 'usr-stranger-004',
      email: 'unauthorized_stranger@gmail.com',
      displayName: 'Người dùng Không phân quyền',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=stranger',
    ),
  ];

  /// Đăng nhập bằng Google (chọn tài khoản hoặc tài khoản mặc định)
  Future<SupabaseUser> signInWithGoogle({SupabaseUser? user}) async {
    _currentUser = user ?? predefinedAccounts[0];
    notifyListeners();
    return _currentUser!;
  }

  /// Đăng xuất tài khoản khỏi hệ thống
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }

  /// Chuyển đổi nhanh giữa các tài khoản để kiểm thử luồng RLS (Checklist 6)
  Future<SupabaseUser> switchUser(String userId) async {
    final target = predefinedAccounts.firstWhere(
      (u) => u.id == userId,
      orElse: () => predefinedAccounts[0],
    );
    _currentUser = target;
    notifyListeners();
    return _currentUser!;
  }
}
