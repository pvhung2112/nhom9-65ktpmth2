// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void saveLocalCache(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

String? getLocalCache(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}
