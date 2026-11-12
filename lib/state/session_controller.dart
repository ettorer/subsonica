import 'package:flutter/foundation.dart';

import '../models/server_config.dart';
import '../services/settings_store.dart';
import '../services/subsonic_api.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._store);

  final SettingsStore _store;

  final List<ServerConfig> _profiles = [];
  String? _activeId;
  ServerConfig? _config;
  ServerConfig? _draft;
  SubsonicClient? _client;
  ServerAbout? _server;
  String? _connectionError;
  String? _webServerUrl;
  String? _webUsername;
  String? _webPassword;
  bool _booting = true;
  bool _connecting = false;
  bool _holdAtConnection = false;

  bool get booting => _booting;
  bool get connecting => _connecting;
  bool get isConnected => _client != null;
  bool get holdAtConnection => _holdAtConnection;
  List<ServerConfig> get profiles => List.unmodifiable(_profiles);
  String? get activeId => _activeId;
  ServerConfig? get config => _config;
  ServerConfig? get draft => _draft ?? _config;
  SubsonicClient? get client => _client;
  ServerAbout? get server => _server;
  String? get connectionError => _connectionError;
  String? get webServerUrl => _webServerUrl;
  String? get webUsername => _webUsername;
  String? get webPassword => _webPassword;
  String get browserUserAgent => _store.browserUserAgent;
  bool get isTeslaBrowser => _store.isTeslaBrowser;
  String get browserDiagnostics => _store.browserDiagnostics;

  Future<void> bootstrap() async {
    if (kIsWeb) {
      _webServerUrl = await _store.loadWebServerUrl();
      final saved = await _store.loadWebCredentials();
      _webUsername = saved?.username;
      _webPassword = saved?.password;
      final url = _webServerUrl;
      if (url != null && saved != null) {
        await signIn(
          baseUrl: url,
          username: saved.username,
          password: saved.password,
        );
      }
      _booting = false;
      notifyListeners();
      return;
    }
    final stored = await _store.loadConnections();
    _profiles
      ..clear()
      ..addAll(stored.profiles);
    _activeId = stored.activeId;
    final active = _find(_activeId);
    if (active == null) {
      _booting = false;
      notifyListeners();
      return;
    }
    _draft = active;
    await _establish(active, remember: false);
    _booting = false;
    notifyListeners();
  }

  Future<String?> connect(ServerConfig config) async {
    final name = config.name.trim();
    if (name.isEmpty) return 'Enter a profile name.';
    final profile = ServerConfig(
      id: config.id.isEmpty ? newProfileId() : config.id,
      name: name,
      baseUrl: config.baseUrl,
      username: config.username,
      password: config.password,
    );
    _draft = profile;
    return _establish(profile, remember: true);
  }

  Future<String?> signIn({
    required String baseUrl,
    required String username,
    required String password,
  }) {
    final name = username.trim();
    if (name.isEmpty) return Future.value('Enter the username.');
    return _establish(
      ServerConfig(
        id: 'web',
        name: profileNameFromUrl(baseUrl),
        baseUrl: baseUrl,
        username: name,
        password: password,
      ),
      remember: false,
    ).then((error) async {
      if (error != null) return error;
      _webServerUrl = baseUrl;
      _webUsername = name;
      _webPassword = password;
      await _store.saveWebServerUrl(baseUrl);
      await _store.saveWebCredentials(username: name, password: password);
      return null;
    });
  }

  Future<String?> updateWebServerUrl(String raw) async {
    final baseUrl = normalizeServerUrl(raw);
    if (baseUrl == null) {
      return 'Enter a server address like http://192.168.1.20:4533.';
    }
    await _store.saveWebServerUrl(baseUrl);
    final changed = _config != null && _config!.baseUrl != baseUrl;
    if (_webServerUrl != null && _webServerUrl != baseUrl) {
      _webUsername = null;
      _webPassword = null;
      await _store.clearWebCredentials();
    }
    _webServerUrl = baseUrl;
    if (changed) {
      _client?.close();
      _client = null;
      _config = null;
      _server = null;
      _connectionError = null;
    }
    notifyListeners();
    return null;
  }

  Future<String?> useProfile(String id) {
    final profile = _find(id);
    if (profile == null) {
      return Future.value('That profile is no longer saved.');
    }
    _draft = profile;
    return _establish(profile, remember: true);
  }

  Future<String?> _establish(
    ServerConfig profile, {
    required bool remember,
  }) async {
    _connecting = true;
    _connectionError = null;
    notifyListeners();
    final client = SubsonicClient(profile);
    try {
      final about = await client.ping();
      if (remember) {
        _upsert(profile);
        _activeId = profile.id;
        await _store.saveConnections(_profiles, _activeId);
      }
      final previous = _config;
      final changed = previous == null || !previous.sameServerAs(profile);
      if (changed || _client == null) {
        _client?.close();
        _client = client;
      } else {
        client.close();
      }
      _config = profile;
      _draft = profile;
      _activeId = profile.id;
      _server = about;
      _connecting = false;
      _connectionError = null;
      _holdAtConnection = false;
      notifyListeners();
      return null;
    } catch (error) {
      client.close();
      final message = describeError(error);
      _connecting = false;
      _connectionError = message;
      notifyListeners();
      return message;
    }
  }

  Future<void> deleteProfile(String id) async {
    final removed = _find(id);
    if (removed == null) return;
    _profiles.removeWhere((profile) => profile.id == id);
    if (_activeId == id || _config?.id == id) {
      _client?.close();
      _client = null;
      _config = null;
      _server = null;
      _activeId = null;
      _draft = _profiles.isEmpty ? null : _profiles.first;
      _connectionError = null;
    }
    await _store.saveConnections(_profiles, _activeId);
    notifyListeners();
  }

  Future<void> signOut() async {
    _client?.close();
    _client = null;
    _config = null;
    _server = null;
    _connectionError = null;
    _connecting = false;
    _webUsername = null;
    _webPassword = null;
    await _store.clearWebCredentials();
    notifyListeners();
  }

  void openConnection() {
    _holdAtConnection = true;
    notifyListeners();
  }

  void closeConnection() {
    if (!_holdAtConnection) return;
    _holdAtConnection = false;
    notifyListeners();
  }

  ServerConfig? _find(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final profile in _profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  void _upsert(ServerConfig profile) {
    final index = _profiles.indexWhere((item) => item.id == profile.id);
    if (index < 0) {
      _profiles.add(profile);
    } else {
      _profiles[index] = profile;
    }
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }
}
