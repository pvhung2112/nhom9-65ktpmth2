import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../services/google_auth_bridge.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLoading = false;
  bool _showManualEntry = false;
  final TextEditingController _gmailController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _gmailController.dispose();
    super.dispose();
  }

  /// Kích hoạt Google Sign-In chính thức (mở trang accounts.google.com)
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await triggerWebGoogleSignIn();
      if (res != null && res['success'] == true) {
        final email = res['email'] as String? ?? 'user@gmail.com';
        final displayName = res['displayName'] as String? ?? email.split('@')[0];

        await FirebaseAuthService().signInWithGoogleOAuth(
          email: email,
          password: 'google_oauth_token',
          displayName: displayName,
          isGoogleProvider: true,
        );
      } else {
        if (mounted) {
          setState(() {
            _showManualEntry = true;
            final errorStr = (res != null && (res['error'] != null || res['message'] != null))
                ? (res['error'] ?? res['message']).toString()
                : '';
            
            if (errorStr.contains('FIREBASE') || errorStr.contains('Firebase')) {
              _errorMessage = errorStr;
            } else if (errorStr.contains('origin_mismatch')) {
              _errorMessage = 'Google chặn do cổng ${Uri.base.origin} chưa được khai báo trong Google Cloud Console (Error 400: origin_mismatch).\n👉 Bạn có thể nhập nhanh địa chỉ Gmail của mình bên dưới để đăng nhập Firebase ngay!';
            } else if (errorStr.isNotEmpty && !errorStr.contains('closed-by-user')) {
              _errorMessage = errorStr;
            } else {
              _errorMessage = 'Bạn có thể nhập trực tiếp địa chỉ Gmail của bạn bên dưới để đăng nhập Firebase.';
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _showManualEntry = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Đăng nhập bằng Gmail tự nhập (không có tài khoản fix cứng)
  Future<void> _handleManualGmailSubmit() async {
    final email = _gmailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập địa chỉ Gmail của bạn');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Địa chỉ email không hợp lệ (cần có @)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuthService().signInWithGoogleOAuth(
        email: email,
        password: 'google_direct_auth',
        isGoogleProvider: false,
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
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

                  const SizedBox(height: 34),

                  // Error notification
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Main Google Sign-In Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Xác thực Tài khoản Google',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF202124),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bấm nút bên dưới để mở trang đăng nhập Google (accounts.google.com). Google sẽ xác thực tài khoản và chuyển kết quả về Firebase.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Official Google Sign-In Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF3C4043),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A73E8)),
                                )
                              : Row(
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

                  const SizedBox(height: 22),

                  // Manual Gmail input section toggle
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      icon: Icon(
                        _showManualEntry ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                      ),
                      label: Text(_showManualEntry ? 'Thu gọn' : 'Hoặc tự nhập tài khoản Gmail bất kỳ'),
                      onPressed: () => setState(() => _showManualEntry = !_showManualEntry),
                    ),
                  ),

                  if (_showManualEntry) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _gmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Địa chỉ Gmail của bạn',
                              hintText: 'ví dụ: yourname@gmail.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onSubmitted: (_) => _handleManualGmailSubmit(),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD81B60),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _isLoading ? null : _handleManualGmailSubmit,
                            child: const Text('Xác thực Gmail với Firebase', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
