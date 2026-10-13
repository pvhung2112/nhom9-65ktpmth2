import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final bool _isLoading = false;

  void _openGoogleSignInModal({String? initialEmail}) {
    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (ctx) => _GoogleSignInDialog(
        initialEmail: initialEmail,
        onSuccess: () {
          // ListenableBuilder in AuthGate automatically switches to MainLayoutScreen
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7D8DF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Color(0xFFD81B60),
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Cashew Study',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Hệ thống Quản lý Tài liệu Học tập Cloud',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF7D8DF)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFFD81B60)),
                          SizedBox(width: 6),
                          Text(
                            'Firebase Auth (Google OAuth 2.0)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD81B60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Google Authentication Card Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Yêu cầu Xác thực Tài khoản Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF202124),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nhấn nút bên dưới để gọi Google OAuth 2.0 API. Google sẽ mở giao diện xác thực để bạn nhập tài khoản Gmail và mật khẩu Google.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Official Google Sign-In Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF3C4043),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onPressed: () => _openGoogleSignInModal(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                                width: 22,
                                height: 22,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.g_mobiledata_rounded,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Đăng nhập bằng tài khoản Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'KIỂM THỬ PHÂN QUYỀN (CHECKLIST 6)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Hoặc mở nhanh giao diện Google với tài khoản trong dự án:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),

                  const SizedBox(height: 12),

                  // Predefined Account Cards for instant test
                  ...FirebaseAuthService.predefinedAccounts.take(3).map((account) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openGoogleSignInModal(initialEmail: account.email),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: const Color(0xFFF7D8DF),
                                child: Text(
                                  account.displayName[0],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD81B60),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.displayName,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${account.email} • ${account.role}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal Giao diện Đăng nhập Google Accounts (accounts.google.com)
/// Google yêu cầu người dùng nhập Gmail và Mật khẩu, sau đó gọi Google OAuth 2.0 API
class _GoogleSignInDialog extends StatefulWidget {
  final String? initialEmail;
  final VoidCallback onSuccess;

  const _GoogleSignInDialog({this.initialEmail, required this.onSuccess});

  @override
  State<_GoogleSignInDialog> createState() => _GoogleSignInDialogState();
}

class _GoogleSignInDialogState extends State<_GoogleSignInDialog> {
  int _step = 1; // 1: Email, 2: Password, 3: Verifying with Google API
  late TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _passwordController.text = '123456';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToPasswordStep() {
    setState(() => _errorMessage = null);
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập địa chỉ email hoặc số điện thoại');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Địa chỉ email không hợp lệ (cần có ký tự @)');
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _submitGoogleOAuth() async {
    setState(() => _errorMessage = null);
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu tài khoản Google của bạn');
      return;
    }

    setState(() => _step = 3); // Gọi Google OAuth 2.0 API

    try {
      final email = _emailController.text.trim();
      final auth = FirebaseAuthService();
      await auth.signInWithGoogleOAuth(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = 2;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Google 4-Color Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.network(
                    'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.g_mobiledata_rounded,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'accounts.google.com',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // BƯỚC 1: GOOGLE YÊU CẦU NHẬP EMAIL
              if (_step == 1) ...[
                const Text(
                  'Đăng nhập bằng Google',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'tiếp tục tới Cashew Study (Firebase Auth)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5F6368),
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email hoặc số điện thoại',
                    hintText: 'ví dụ: yourname@gmail.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _goToPasswordStep(),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 10),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () {},
                  child: const Text(
                    'Bạn quên địa chỉ email?',
                    style: TextStyle(color: Color(0xFF1A73E8), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'Không phải máy tính của bạn? Hãy sử dụng chế độ Khách để đăng nhập một cách riêng tư.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy', style: TextStyle(color: Color(0xFF1A73E8))),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _goToPasswordStep,
                      child: const Text('Tiếp theo', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],

              // BƯỚC 2: GOOGLE YÊU CẦU NHẬP MẬT KHẨU
              if (_step == 2) ...[
                // Account chip with back arrow
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _step = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_circle_rounded, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          _emailController.text.trim(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chào mừng',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nhập mật khẩu Google của bạn để tiếp tục',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _passwordController,
                  autofocus: true,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Nhập mật khẩu của bạn',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onSubmitted: (_) => _submitGoogleOAuth(),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: !_obscurePassword,
                      onChanged: (val) => setState(() => _obscurePassword = !(val ?? false)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      activeColor: const Color(0xFF1A73E8),
                    ),
                    const Text('Hiện mật khẩu', style: TextStyle(fontSize: 13)),
                  ],
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _step = 1),
                      child: const Text('Quay lại', style: TextStyle(color: Color(0xFF1A73E8))),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _submitGoogleOAuth,
                      child: const Text('Tiếp theo', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],

              // BƯỚC 3: GOOGLE OAUTH 2.0 API ĐANG XÁC THỰC
              if (_step == 3) ...[
                const SizedBox(height: 20),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF1A73E8)),
                      SizedBox(height: 24),
                      Text(
                        'Đang gọi Google OAuth 2.0 API...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Google đang xác thực thông tin tài khoản và trả về mã định danh cho Firebase Authentication...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
