import 'dart:js_interop';

import '../models/server_config.dart';
import 'settings_records.dart';

export 'settings_records.dart';

@JS('localStorage')
external _WebStorage get _webStorage;

extension type _WebStorage(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
  external void removeItem(JSString key);
}

/// Browser settings. The page is served over plain HTTP, where the secure
/// storage plugin refuses to run. The password is not written here.
class SettingsStore {
  static const _urlKey = 'subsonica.server_url';
  static const _localeKey = 'subsonica.locale';

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

  Future<void> clear() async {
    _remove(_urlKey);
    _remove(_localeKey);
  }
}

String? _read(String key) => _webStorage.getItem(key.toJS)?.toDart;

void _write(String key, String value) {
  _webStorage.setItem(key.toJS, value.toJS);
}

void _remove(String key) {
  _webStorage.removeItem(key.toJS);
}
