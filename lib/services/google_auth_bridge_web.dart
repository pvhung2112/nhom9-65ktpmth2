// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

const String googleAuthUrl = 'https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=344574429469-nmbnnl4piuqo6seljr1t2u6v248n6nbo.apps.googleusercontent.com&redirect_uri=https://study-document-cloud.firebaseapp.com/__/auth/handler&scope=openid+email+profile';

Future<Map<String, dynamic>?> triggerWebGoogleSignIn() async {
  try {
    // Mở trực tiếp cửa sổ xác thực accounts.google.com chính thức
    html.window.open(googleAuthUrl, 'google_signin_popup', 'width=520,height=650,menubar=no,status=no');
  } catch (e) {
    html.window.open(googleAuthUrl, '_blank');
  }
  return null;
}

void openGoogleAccountsUrl() {
  html.window.open(googleAuthUrl, '_blank');
}
