import 'package:flutter/foundation.dart';

// Dịch vụ Xác thực Firebase & Đăng nhập Google (Google Sign-In)
// Phục vụ Checklist 6 & 7: Phương án tích hợp Cloud & Quản trị Phân quyền IAM

class MockFirebaseUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String role;
  final String msv;

  MockFirebaseUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.role = 'Editor',
    this.msv = '',
  });
}

class FirebaseAuthService with ChangeNotifier {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  MockFirebaseUser? _currentUser;
  MockFirebaseUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // Danh sách tài khoản thành viên nhóm có quyền IAM trong dự án Firebase
  static final List<MockFirebaseUser> teamMembers = [
    MockFirebaseUser(
      uid: 'user-hung-2351170598',
      email: 'phamvanhung21122004@gmail.com',
      displayName: 'Phạm Văn Hưng',
      role: 'Owner / Trưởng nhóm',
      msv: '2351170598',
    ),
    MockFirebaseUser(
      uid: 'user-kien-2251172396',
      email: 'trinhtrungkien2004@gmail.com',
      displayName: 'Trịnh Trung Kiên',
      role: 'Editor / Frontend',
      msv: '2251172396',
    ),
    MockFirebaseUser(
      uid: 'user-tien-2251243452',
      email: 'doviettien2004@gmail.com',
      displayName: 'Đỗ Việt Tiến',
      role: 'Editor / Frontend',
      msv: '2251243452',
    ),
    MockFirebaseUser(
      uid: 'user-dao-2351170581',
      email: 'caoducdao2004@gmail.com',
      displayName: 'Cao Đức Đạo',
      role: 'Editor / Backend',
      msv: '2351170581',
    ),
    MockFirebaseUser(
      uid: 'user-hai-2351170590',
      email: 'truongtuanhai2004@gmail.com',
      displayName: 'Trương Tuấn Hải',
      role: 'Editor / Cloud Research',
      msv: '2351170590',
    ),
  ];

  /// Đăng nhập bằng Google (Mặc định chọn Trưởng nhóm hoặc thành viên được chọn)
  Future<MockFirebaseUser> signInWithGoogle({MockFirebaseUser? user}) async {
    _currentUser = user ?? teamMembers[0];
    notifyListeners();
    return _currentUser!;
  }

  /// Đăng xuất khỏi hệ thống Google Firebase
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }
}
