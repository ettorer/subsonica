import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/server_config.dart';
import 'settings_records.dart';

export 'settings_records.dart';

class SettingsStore {
  SettingsStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _urlKey = 'server_url';
  static const _usernameKey = 'username';
  static const _passwordKey = 'password';
  static const _profilesKey = 'connection_profiles';
  static const _activeKey = 'active_profile_id';
  static const _offlineKey = 'offline_mode';
  static const _localeKey = 'locale';
  static const _karaokeKey = 'karaoke';

  final FlutterSecureStorage _storage;

  String get browserUserAgent => '';
  bool get isTeslaBrowser => false;
  String get browserDiagnostics => '';

  Future<StoredConnections> loadConnections() async {
    try {
      final raw = await _storage.read(key: _profilesKey);
      if (raw != null && raw.isNotEmpty) {
        final profiles = decodeProfiles(jsonDecode(raw));
        final activeId = await _storage.read(key: _activeKey);
        return StoredConnections(
          profiles: profiles,
          activeId: profiles.any((profile) => profile.id == activeId)
              ? activeId
              : null,
        );
      }
      final legacy = await _loadLegacy();
      if (legacy == null) return const StoredConnections(profiles: []);
      await saveConnections([legacy], legacy.id);
      return StoredConnections(profiles: [legacy], activeId: legacy.id);
    } catch (_) {
      return const StoredConnections(profiles: []);
    }
  }

  Future<void> saveConnections(
    List<ServerConfig> profiles,
    String? activeId,
  ) async {
    await _storage.write(
      key: _profilesKey,
      value: jsonEncode([for (final profile in profiles) profile.toJson()]),
    );
    if (activeId == null || activeId.isEmpty) {
      await _storage.delete(key: _activeKey);
    } else {
      await _storage.write(key: _activeKey, value: activeId);
    }
    await _storage.delete(key: _urlKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
    await _deleteCloudflareKeys();
  }

  Future<ServerConfig?> _loadLegacy() async {
    final url = await _storage.read(key: _urlKey);
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    if (url == null || username == null || password == null) return null;
    final baseUrl = normalizeServerUrl(url);
    if (baseUrl == null || username.isEmpty) return null;
    return ServerConfig(
      id: newProfileId(),
      name: profileNameFromUrl(baseUrl),
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
  }

  Future<bool> loadOffline() async {
    try {
      return await _storage.read(key: _offlineKey) == '1';
    } catch (_) {
      return false;
    }
  }

  Future<void> saveOffline(bool enabled) {
    return _storage.write(key: _offlineKey, value: enabled ? '1' : '0');
  }

  Future<String> loadLocale() async {
    try {
      final value = await _storage.read(key: _localeKey);
      return switch (value) {
        'en' => 'en',
        'it' => 'it',
        _ => 'auto',
      };
    } catch (_) {
      return 'auto';
    }
  }

  Future<bool> loadKaraoke() async {
    try {
      return await _storage.read(key: _karaokeKey) == '1';
    } catch (_) {
      return false;
    }
  }

  Future<void> saveKaraoke(bool enabled) {
    return _storage.write(key: _karaokeKey, value: enabled ? '1' : '0');
  }

  Future<void> saveLocale(String preference) {
    if (preference == 'auto') return _storage.delete(key: _localeKey);
    return _storage.write(key: _localeKey, value: preference);
  }

  Future<String?> loadWebServerUrl() async {
    try {
      final url = await _storage.read(key: _urlKey);
      if (url == null || url.isEmpty) return null;
      return normalizeServerUrl(url);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWebServerUrl(String url) {
    return _storage.write(key: _urlKey, value: url);
  }

  Future<({String username, String password})?> loadWebCredentials() async {
    return null;
  }

  Future<void> saveWebCredentials({
    required String username,
    required String password,
  }) async {}

  Future<void> clearWebCredentials() async {}

  Future<void> clear() async {
    await _storage.delete(key: _urlKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _profilesKey);
    await _storage.delete(key: _activeKey);
    await _deleteCloudflareKeys();
  }

  Future<void> _deleteCloudflareKeys() async {
    await _storage.delete(key: 'cf_access_client_id');
    await _storage.delete(key: 'cf_access_client_secret');
    await _storage.delete(key: 'cf_access_token');
  }
}
