// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

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

void openUrlInNewTab(String url) {
  try {
    html.window.open(url, '_blank');
  } catch (_) {}
}

final Set<String> _registeredViews = {};

void registerMapIframe(String viewType, String url) {
  if (_registeredViews.contains(viewType)) return;
  _registeredViews.add(viewType);
  try {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      },
    );
  } catch (_) {}
}
