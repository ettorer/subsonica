import 'package:flutter/foundation.dart';

import '../models/library.dart';
import '../models/download.dart';
import '../services/lyrics_client.dart';
import '../services/phone_scan_result.dart';
import '../services/settings_store.dart';
import '../services/subsonic_api.dart';
import 'local_tracks.dart';

/// Browser build. Nothing is stored on the device.
class DownloadController extends ChangeNotifier implements LocalTracks {
  DownloadController(SettingsStore _);

  var _ready = false;

  bool get ready => _ready;
  bool get preferOffline => false;
  bool get scanningPhoneMusic => false;
  bool get hasCompleted => false;
  int get byteCount => 0;
  List<DownloadEntry> get entries => const [];
  List<Album> get albums => const [];
  List<Song> get tracks => const [];
  List<Album> get libraryAlbums => const [];
  List<Song> get libraryTracks => const [];
  List<Artist> get libraryArtists => const [];

  Artist? artistById(String id) => null;

  List<Song> songsForAlbum(String albumId) => const [];

  DownloadEntry? entryFor(String songId) => null;

  Future<LyricMatch?> savedLyrics(String songId) async => null;

  Future<void> saveLyrics(String songId, LyricMatch match) async {}

  @override
  bool get playFromDownloadsOnly => false;

  @override
  String? audioPath(String songId) => null;

  @override
  String? coverFile(String? coverId) => null;

  @override
  Song? songForPath(String path) => null;

  Future<void> init() async {
    _ready = true;
    notifyListeners();
  }

  void attach(SubsonicClient? client) {}

  Future<void> setPreferOffline(bool enabled) async {}

  Future<int> enqueue(List<Song> songs) async => 0;

  Future<void> retry(String songId) async {}

  Future<void> removeSong(String songId) async {}

  Future<void> removeAlbum(String albumId) async {}

  @override
  void queueScrobble(String songId, {required bool submission}) {}

  Future<void> flushScrobbles() async {}

  Future<PhoneScanResult> scanPhoneMusic() async {
    return const PhoneScanResult(PhoneScanStatus.failed);
  }
}
