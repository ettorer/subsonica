import 'dart:async';

import 'package:flutter/foundation.dart';

import '../remote/karaoke_hub.dart';
import '../services/settings_store.dart';
import '../services/subsonic_api.dart';
import 'download_controller.dart';
import 'player_controller.dart';

class KaraokeController extends ChangeNotifier {
  KaraokeController(
    this._settings,
    this._player,
    this._downloads,
    this._readClient,
  );

  final SettingsStore _settings;
  final PlayerController _player;
  final DownloadController _downloads;
  final SubsonicClient? Function() _readClient;

  var enabled = false;
  var busy = false;
  var failed = false;
  String? url;
  String? secureUrl;
  var _ticket = 0;
  KaraokeHub? _hub;

  bool get active => enabled && _hub != null;

  Future<void> restore() async {
    if (await _settings.loadKaraoke()) await setEnabled(true);
  }

  Future<void> setEnabled(bool value) async {
    final ticket = ++_ticket;
    busy = true;
    notifyListeners();
    await _settings.saveKaraoke(value);
    if (!value) {
      final hub = _hub;
      _hub = null;
      await hub?.close();
      if (ticket != _ticket) return;
      enabled = false;
      url = null;
      secureUrl = null;
      failed = false;
      busy = false;
      notifyListeners();
      return;
    }
    try {
      final hub = await KaraokeHub.start(
        player: _player,
        downloads: _downloads,
        readClient: _readClient,
      );
      if (ticket != _ticket) {
        await hub.close();
        return;
      }
      _hub = hub;
      enabled = true;
      url = hub.url;
      secureUrl = hub.secureUrl;
      failed = false;
    } catch (_) {
      if (ticket != _ticket) return;
      enabled = false;
      url = null;
      secureUrl = null;
      failed = true;
      await _settings.saveKaraoke(false);
    }
    if (ticket != _ticket) return;
    busy = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticket++;
    final hub = _hub;
    _hub = null;
    unawaited(hub?.close());
    super.dispose();
  }
}
