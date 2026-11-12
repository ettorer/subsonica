import 'dart:js_interop';

import 'package:tesla_browser_detector/tesla_browser_detector.dart'
    as tesla_detector;

import '../models/server_config.dart';
import 'settings_records.dart';

export 'settings_records.dart';

@JS('localStorage')
external _WebStorage get _webStorage;

@JS('navigator.userAgent')
external JSString get _browserUserAgent;

@JS('window')
external _BrowserWindow get _browserWindow;

@JS('navigator')
external _BrowserNavigator get _browserNavigator;

@JS('document.createElement')
external _WebGlCanvas _createCanvas(JSString tagName);

extension type _WebStorage(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
  external void removeItem(JSString key);
}

extension type _BrowserWindow(JSObject _) implements JSObject {
  external double get innerWidth;
  external double get innerHeight;
  external _BrowserScreen get screen;
}

extension type _BrowserScreen(JSObject _) implements JSObject {
  external double get width;
  external double get height;
}

extension type _BrowserNavigator(JSObject _) implements JSObject {
  external int get maxTouchPoints;
}

extension type _WebGlCanvas(JSObject _) implements JSObject {
  external _WebGlContext? getContext(JSString contextType);
}

extension type _WebGlContext(JSObject _) implements JSObject {
  external JSObject? getExtension(JSString name);
  external JSAny? getParameter(JSAny parameter);
}

/// Browser settings. The page is served over plain HTTP, where the secure
/// storage plugin refuses to run. Tesla's browser is identified by its Linux
/// user agent, touchscreen support, display size, and graphics renderer.
class SettingsStore {
  static const _urlKey = 'subsonica.server_url';
  static const _localeKey = 'subsonica.locale';
  static const _usernameKey = 'subsonica.username';
  static const _passwordKey = 'subsonica.password';

  String get browserUserAgent => _browserUserAgent.toDart;
  bool get isTeslaBrowser => tesla_detector.isTeslaBrowser;
  String get browserDiagnostics {
    final window = _browserWindow;
    return 'window.innerWidth: ${window.innerWidth}\n'
        'window.innerHeight: ${window.innerHeight}\n'
        'window.screen.width: ${window.screen.width}\n'
        'window.screen.height: ${window.screen.height}\n'
        'navigator.maxTouchPoints: ${_browserNavigator.maxTouchPoints}\n'
        'WEBGL_debug_renderer_info: ${_webGlRenderer()}';
  }

  Future<StoredConnections> loadConnections() async {
    return const StoredConnections(profiles: []);
  }

  Future<void> saveConnections(
    List<ServerConfig> profiles,
    String? activeId,
  ) async {}

  Future<bool> loadOffline() async => false;

  Future<void> saveOffline(bool enabled) async {}

  Future<String> loadLocale() async {
    return switch (_read(_localeKey)) {
      'en' => 'en',
      'it' => 'it',
      _ => 'auto',
    };
  }

  Future<bool> loadKaraoke() async => false;

  Future<void> saveKaraoke(bool enabled) async {}

  Future<void> saveLocale(String preference) async {
    if (preference == 'auto') {
      _remove(_localeKey);
      return;
    }
    _write(_localeKey, preference);
  }

  Future<String?> loadWebServerUrl() async {
    final url = _read(_urlKey);
    if (url == null || url.isEmpty) return null;
    return normalizeServerUrl(url);
  }

  Future<void> saveWebServerUrl(String url) async {
    _write(_urlKey, url);
  }

  Future<({String username, String password})?> loadWebCredentials() async {
    if (!isTeslaBrowser) {
      await clearWebCredentials();
      return null;
    }
    final username = _read(_usernameKey)?.trim() ?? '';
    final password = _read(_passwordKey);
    if (username.isEmpty || password == null || password.isEmpty) return null;
    return (username: username, password: password);
  }

  Future<void> saveWebCredentials({
    required String username,
    required String password,
  }) async {
    if (!isTeslaBrowser) return;
    _write(_usernameKey, username);
    _write(_passwordKey, password);
  }

  Future<void> clearWebCredentials() async {
    _remove(_usernameKey);
    _remove(_passwordKey);
  }

  Future<void> clear() async {
    _remove(_urlKey);
    _remove(_localeKey);
    _remove(_usernameKey);
    _remove(_passwordKey);
  }
}

String _webGlRenderer() {
  final canvas = _createCanvas('canvas'.toJS);
  final context =
      canvas.getContext('webgl'.toJS) ?? canvas.getContext('webgl2'.toJS);
  if (context == null) return 'unavailable (WebGL context not available)';
  if (context.getExtension('WEBGL_debug_renderer_info'.toJS) == null) {
    return 'unavailable (extension not supported)';
  }
  final renderer = context.getParameter(0x9246.toJS)?.dartify();
  return renderer is String ? renderer : 'unavailable';
}

String? _read(String key) => _webStorage.getItem(key.toJS)?.toDart;

void _write(String key, String value) {
  _webStorage.setItem(key.toJS, value.toJS);
}

void _remove(String key) {
  _webStorage.removeItem(key.toJS);
}
