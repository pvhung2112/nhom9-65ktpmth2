// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

Future<Map<String, dynamic>?> triggerWebGoogleSignIn() async {
  final completer = Completer<Map<String, dynamic>?>();

  late html.EventListener listener;
  listener = (html.Event event) {
    try {
      final customEvent = event as html.CustomEvent;
      final detail = customEvent.detail;
      if (detail != null) {
        final data = jsonDecode(detail.toString()) as Map<String, dynamic>;
        completer.complete(data);
      } else {
        completer.complete(null);
      }
    } catch (_) {
      completer.complete(null);
    }
    html.window.removeEventListener('google_signin_completed', listener);
  };

  html.window.addEventListener('google_signin_completed', listener);
  html.window.dispatchEvent(html.CustomEvent('start_google_signin'));

  return await completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () {
      html.window.removeEventListener('google_signin_completed', listener);
      return null;
    },
  );
}

void openGoogleAccountsUrl() {
  const url = 'https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=344574429469-nmbnnl4piuqo6seljr1t2u6v248n6nbo.apps.googleusercontent.com&redirect_uri=https://study-document-cloud.firebaseapp.com/__/auth/handler&scope=openid+email+profile';
  html.window.open(url, '_blank');
}
