import 'dart:js_interop';

import '../models/server_config.dart';
import 'settings_records.dart';

export 'settings_records.dart';

@JS('localStorage')
external _WebStorage get _webStorage;

@JS('navigator.userAgent')
external JSString get _browserUserAgent;

extension type _WebStorage(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
  external void removeItem(JSString key);
}

/// Browser settings. The page is served over plain HTTP, where the secure
/// storage plugin refuses to run. A browser whose user agent contains
/// "Tesla", "X11", "Linux", and "x86_64" keeps the username and password
/// for the next visit.
class SettingsStore {
  static const _urlKey = 'subsonica.server_url';
  static const _localeKey = 'subsonica.locale';
  static const _usernameKey = 'subsonica.username';
  static const _passwordKey = 'subsonica.password';

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
    if (!_teslaBrowser) {
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
    if (!_teslaBrowser) return;
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

bool get _teslaBrowser {
  final agent = _browserUserAgent.toDart.toLowerCase();
  return agent.contains('tesla') &&
      agent.contains('x11') &&
      agent.contains('linux') &&
      agent.contains('x86_64');
}

String? _read(String key) => _webStorage.getItem(key.toJS)?.toDart;

void _write(String key, String value) {
  _webStorage.setItem(key.toJS, value.toJS);
}

void _remove(String key) {
  _webStorage.removeItem(key.toJS);
}
