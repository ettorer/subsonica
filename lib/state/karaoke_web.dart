import 'package:flutter/foundation.dart';

import '../services/settings_store.dart';
import '../services/subsonic_api.dart';
import 'downloads.dart';
import 'player_controller.dart';

/// Browser build. The phone's karaoke server is not part of this app.
class KaraokeController extends ChangeNotifier {
  KaraokeController(
    SettingsStore _,
    PlayerController _,
    DownloadController _,
    SubsonicClient? Function() _,
  );

  bool enabled = false;
  bool busy = false;
  bool failed = false;
  String? url;
  String? secureUrl;

  bool get active => false;

  Future<void> restore() async {}

  Future<void> setEnabled(bool value) async {}
}
