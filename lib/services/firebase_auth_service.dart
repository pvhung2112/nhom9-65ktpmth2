import 'package:flutter/foundation.dart';
import '../models/supabase_user.dart';
import 'supabase_service.dart';

class _RegisteredUserData {
  final SupabaseUser user;
  final String password;

  _RegisteredUserData({required this.user, required this.password});
}

/// Dịch vụ Xác thực Firebase Authentication & Đăng nhập Google
/// Hỗ trợ cả đăng nhập/đăng ký tài khoản thủ công (Email/Password) và Google Sign-In
class FirebaseAuthService with ChangeNotifier {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal() {
    _initPredefined();
  }

  SupabaseUser? _currentUser;
  SupabaseUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  final Map<String, _RegisteredUserData> _registeredUsers = {};

  // Danh sách tài khoản kiểm thử đại diện cho các cấp độ phân quyền (Checklist 6)
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

  void _initPredefined() {
    for (var u in predefinedAccounts) {
      _registeredUsers[u.email.toLowerCase()] = _RegisteredUserData(user: u, password: '123456');
    }
  }

  /// Đăng nhập bằng Email & Password do người dùng tự nhập
  Future<SupabaseUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw Exception('Vui lòng nhập địa chỉ Email hoặc Gmail');
    }
    if (password.trim().isEmpty) {
      throw Exception('Vui lòng nhập mật khẩu');
    }

    final entry = _registeredUsers[cleanEmail];
    if (entry != null) {
      if (entry.password != password) {
        throw Exception('Mật khẩu không chính xác. Vui lòng kiểm tra lại!');
      }
      _currentUser = entry.user;
    } else {
      // Nếu là email mới chưa từng đăng ký, tự động cấp tài khoản trải nghiệm
      final name = cleanEmail.split('@').first;
      final newUser = SupabaseUser(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        email: cleanEmail,
        displayName: name,
        role: 'Editor',
        avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=$name',
      );
      _registeredUsers[cleanEmail] = _RegisteredUserData(user: newUser, password: password);
      _currentUser = newUser;
      SupabaseService().upsertUser(newUser);
    }

    notifyListeners();
    return _currentUser!;
  }

  /// Đăng ký tài khoản mới bằng Email, Mật khẩu và Họ tên
  Future<SupabaseUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Vui lòng nhập địa chỉ Email hợp lệ (vd: yourname@gmail.com)');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu phải chứa ít nhất 6 ký tự');
    }

    if (_registeredUsers.containsKey(cleanEmail)) {
      throw Exception('Email $cleanEmail đã tồn tại trong hệ thống. Vui lòng Đăng nhập!');
    }

    final name = displayName.trim().isNotEmpty ? displayName.trim() : cleanEmail.split('@').first;
    final newUser = SupabaseUser(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      displayName: name,
      role: 'Editor',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=$name',
    );

    _registeredUsers[cleanEmail] = _RegisteredUserData(user: newUser, password: password);
    _currentUser = newUser;
    SupabaseService().upsertUser(newUser);

    notifyListeners();
    return _currentUser!;
  }

  /// Đăng nhập bằng Google Account (nhập Gmail hoặc tự chọn)
  Future<SupabaseUser> signInWithGoogleAccount({
    required String email,
    String? displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Vui lòng nhập địa chỉ Google Gmail hợp lệ');
    }

    final existing = _registeredUsers[cleanEmail];
    if (existing != null) {
      _currentUser = existing.user;
    } else {
      final name = (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : cleanEmail.split('@').first;
      final newUser = SupabaseUser(
        id: 'usr-google-${DateTime.now().millisecondsSinceEpoch}',
        email: cleanEmail,
        displayName: name,
        role: 'Editor',
        avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=$name',
      );
      _registeredUsers[cleanEmail] = _RegisteredUserData(user: newUser, password: 'google_oauth_token');
      _currentUser = newUser;
      SupabaseService().upsertUser(newUser);
    }

    notifyListeners();
    return _currentUser!;
  }

  /// Đăng nhập bằng Google (hỗ trợ truyền User sẵn hoặc mặc định cho Test Suite)
  Future<SupabaseUser> signInWithGoogle({SupabaseUser? user}) async {
    _currentUser = user ?? predefinedAccounts[0];
    SupabaseService().upsertUser(_currentUser!);
    notifyListeners();
    return _currentUser!;
  }

  /// Đăng xuất tài khoản khỏi hệ thống Firebase & đưa về màn hình Đăng nhập
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }

  /// Chuyển đổi nhanh tài khoản phục vụ kiểm thử phân quyền RLS (Checklist 6)
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
