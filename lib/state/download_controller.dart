import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/download.dart';
import '../models/library.dart';
import '../services/download_store.dart';
import '../services/file_download.dart';
import '../services/lyrics_client.dart';
import '../services/settings_store.dart';
import '../services/subsonic_api.dart';
import 'local_tracks.dart';

class DownloadController extends ChangeNotifier implements LocalTracks {
  DownloadController(this._settings);

  final SettingsStore _settings;
  final DownloadStore _store = DownloadStore();

  final Map<String, DownloadEntry> _entries = {};
  final Map<String, String> _covers = {};

  SubsonicClient? _client;
  var _ready = false;
  var _preferOffline = false;
  var _working = false;
  var _clientSeen = false;
  String? _cancelSongId;
  DateTime _lastProgress = DateTime.fromMillisecondsSinceEpoch(0);

  bool get ready => _ready;
  bool get preferOffline => _preferOffline;
  bool get hasCompleted => _entries.values.any((entry) => entry.isComplete);

  int get byteCount {
    var total = 0;
    for (final entry in _entries.values) {
      if (entry.isComplete) total += entry.byteSize;
    }
    return total;
  }

  List<DownloadEntry> get entries {
    final list = _entries.values.toList();
    list.sort((a, b) {
      final rank = _rank(a.status).compareTo(_rank(b.status));
      if (rank != 0) return rank;
      return a.song.title.toLowerCase().compareTo(b.song.title.toLowerCase());
    });
    return list;
  }

  List<Album> get albums {
    final grouped = <String, List<DownloadEntry>>{};
    for (final entry in _entries.values) {
      if (!entry.isComplete) continue;
      final albumId = entry.song.albumId;
      if (albumId == null || albumId.isEmpty) continue;
      grouped.putIfAbsent(albumId, () => []).add(entry);
    }
    final albums = <Album>[];
    for (final group in grouped.values) {
      group.sort((a, b) {
        final disc = (a.song.disc ?? 1).compareTo(b.song.disc ?? 1);
        if (disc != 0) return disc;
        return (a.song.track ?? 0).compareTo(b.song.track ?? 0);
      });
      final song = group.first.song;
      albums.add(
        Album(
          id: song.albumId!,
          name: song.album.isEmpty ? 'Album' : song.album,
          artist: song.artist,
          coverArt: song.coverArt ?? song.albumId,
          songCount: group.length,
          songs: [for (final entry in group) entry.song],
        ),
      );
    }
    albums.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return albums;
  }

  List<Song> get tracks {
    final songs = [
      for (final entry in _entries.values)
        if (entry.isComplete) entry.song,
    ];
    songs.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return songs;
  }

  List<Song> songsForAlbum(String albumId) {
    for (final album in albums) {
      if (album.id == albumId) return album.songs;
    }
    return const [];
  }

  DownloadEntry? entryFor(String songId) => _entries[songId];

  Future<LyricMatch?> savedLyrics(String songId) async {
    if (!_ready || audioPath(songId) == null) return null;
    final raw = await _store.readLyrics(songId);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return LyricMatch.fromJson(Map<String, Object?>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  Future<void> saveLyrics(String songId, LyricMatch match) async {
    if (!_ready || audioPath(songId) == null) return;
    await _store.writeLyrics(songId, jsonEncode(match.toJson()));
  }

  @override
  bool get playFromDownloadsOnly => _preferOffline;

  @override
  String? audioPath(String songId) {
    final entry = _entries[songId];
    final path = entry?.filePath;
    if (entry == null || !entry.isComplete || path == null) return null;
    if (!File(path).existsSync()) return null;
    return path;
  }

  @override
  String? coverFile(String? coverId) {
    if (coverId == null || coverId.isEmpty) return null;
    final path = _covers[coverId];
    if (path == null || !File(path).existsSync()) return null;
    return path;
  }

  Future<void> init() async {
    await _store.open();
    _preferOffline = await _settings.loadOffline();
    final saved = await _store.loadDownloads();
    for (final entry in saved) {
      if (entry.status == DownloadStatus.downloading) {
        final queued = entry.copyWith(status: DownloadStatus.queued);
        _entries[entry.song.id] = queued;
        await _store.upsert(queued);
      } else if (entry.isComplete &&
          (entry.filePath == null || !File(entry.filePath!).existsSync())) {
        final failed = entry.copyWith(
          status: DownloadStatus.failed,
          error: 'The downloaded file is missing.',
        );
        _entries[entry.song.id] = failed;
        await _store.upsert(failed);
      } else {
        _entries[entry.song.id] = entry;
      }
    }
    _covers.addAll(await _store.loadCovers());
    _ready = true;
    notifyListeners();
    if (_clientSeen) unawaited(_pump());
  }

  void attach(SubsonicClient? client) {
    _client = client;
    _clientSeen = true;
    if (!_ready) return;
    if (client != null && !_preferOffline) unawaited(flushScrobbles());
    unawaited(_pump());
  }

  Future<void> setPreferOffline(bool enabled) async {
    if (_preferOffline == enabled) return;
    _preferOffline = enabled;
    await _settings.saveOffline(enabled);
    notifyListeners();
    if (!enabled) await flushScrobbles();
  }

  Future<int> enqueue(List<Song> songs) async {
    if (!_ready) return 0;
    var added = 0;
    for (final song in songs) {
      final existing = _entries[song.id];
      if (existing != null && existing.status != DownloadStatus.failed) {
        continue;
      }
      final entry = DownloadEntry(song: song, status: DownloadStatus.queued);
      _entries[song.id] = entry;
      await _store.upsert(entry);
      added++;
    }
    if (added > 0) notifyListeners();
    unawaited(_pump());
    return added;
  }

  Future<void> retry(String songId) async {
    final entry = _entries[songId];
    if (entry == null || entry.status != DownloadStatus.failed) return;
    final queued = entry.copyWith(
      status: DownloadStatus.queued,
      clearError: true,
      received: 0,
    );
    _entries[songId] = queued;
    await _store.upsert(queued);
    notifyListeners();
    unawaited(_pump());
  }

  Future<void> removeSong(String songId) async {
    final downloading =
        _entries[songId]?.status == DownloadStatus.downloading;
    if (downloading) _cancelSongId = songId;
    final entry = _entries.remove(songId);
    await _store.deleteSong(songId);
    await _store.deleteLyrics(songId);
    final path = entry?.filePath;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
    await _dropUnusedCover(entry?.song.artworkId);
    if (!downloading && _cancelSongId == songId) _cancelSongId = null;
    notifyListeners();
  }

  Future<void> removeAlbum(String albumId) async {
    final ids = [
      for (final entry in _entries.values)
        if (entry.song.albumId == albumId) entry.song.id,
    ];
    for (final id in ids) {
      await removeSong(id);
    }
  }

  @override
  void queueScrobble(String songId, {required bool submission}) {
    if (!_ready) return;
    unawaited(
      _store.addScrobble(
        songId,
        submission: submission,
        atMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> flushScrobbles() async {
    final client = _client;
    if (!_ready || client == null || _preferOffline) return;
    final pending = await _store.loadScrobbles();
    for (final item in pending) {
      final sent = await client.submitScrobble(
        item.songId,
        submission: item.submission,
        atMs: item.atMs,
      );
      if (!sent) return;
      await _store.deleteScrobble(item.id);
    }
  }

  Future<void> _pump() async {
    if (_working || !_ready) return;
    _working = true;
    try {
      while (true) {
        final next = _entries.values
            .where((entry) => entry.status == DownloadStatus.queued)
            .cast<DownloadEntry?>()
            .firstOrNull;
        if (next == null || _client == null) break;
        await _download(next);
      }
    } finally {
      _working = false;
    }
  }

  Future<void> _download(DownloadEntry entry) async {
    final client = _client;
    if (client == null) return;
    final song = entry.song;
    final active = entry.copyWith(
      status: DownloadStatus.downloading,
      clearError: true,
      received: 0,
    );
    _entries[song.id] = active;
    await _store.upsert(active);
    notifyListeners();
    final file = _store.audioFile(song.id);
    try {
      final size = await client.saveToFile(
        client.downloadUri(song.id),
        file,
        isCancelled: () => _cancelSongId == song.id,
        onProgress: (received, total) {
          final current = _entries[song.id];
          if (current == null) return;
          _entries[song.id] = current.copyWith(
            received: received,
            total: total,
          );
          final now = DateTime.now();
          if (now.difference(_lastProgress) > const Duration(milliseconds: 250)) {
            _lastProgress = now;
            notifyListeners();
          }
        },
      );
      if (_cancelSongId == song.id || !_entries.containsKey(song.id)) {
        if (_cancelSongId == song.id) _cancelSongId = null;
        if (file.existsSync()) await file.delete();
        return;
      }
      await _saveCover(client, song);
      final complete = active.copyWith(
        status: DownloadStatus.complete,
        filePath: file.path,
        byteSize: size,
        received: size,
        clearError: true,
      );
      _entries[song.id] = complete;
      await _store.upsert(complete);
      notifyListeners();
    } on DownloadCancelled {
      if (_cancelSongId == song.id) _cancelSongId = null;
      if (file.existsSync()) await file.delete();
    } catch (error) {
      if (_cancelSongId == song.id || !_entries.containsKey(song.id)) {
        if (_cancelSongId == song.id) _cancelSongId = null;
        return;
      }
      final failed = active.copyWith(
        status: DownloadStatus.failed,
        error: describeError(error),
      );
      _entries[song.id] = failed;
      await _store.upsert(failed);
      notifyListeners();
    }
  }

  Future<void> _saveCover(SubsonicClient client, Song song) async {
    final coverId = song.artworkId;
    if (coverId == null || _covers.containsKey(coverId)) return;
    final uri = client.coverUri(coverId, size: 600);
    if (uri == null) return;
    final file = _store.coverFile(coverId);
    try {
      await client.saveToFile(uri, file);
      _covers[coverId] = file.path;
      await _store.upsertCover(coverId, file.path);
    } catch (_) {}
  }

  Future<void> _dropUnusedCover(String? coverId) async {
    if (coverId == null || coverId.isEmpty) return;
    final used = _entries.values.any(
      (entry) => entry.song.artworkId == coverId,
    );
    if (used) return;
    final path = _covers.remove(coverId);
    await _store.deleteCover(coverId);
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
  }

  int _rank(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.downloading => 0,
      DownloadStatus.queued => 1,
      DownloadStatus.failed => 2,
      DownloadStatus.complete => 3,
    };
  }
}
