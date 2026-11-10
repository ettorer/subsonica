import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';

import '../models/library.dart';
import '../remote/lrc.dart';
import 'id3_lyrics.dart';
import 'lyrics_client.dart';
import 'phone_catalog.dart';

const _phoneMusic = MethodChannel('com.subsonica.subsonica/phone_music');

class PhoneCatalogScan {
  const PhoneCatalogScan({required this.tracks, required this.covers});

  final List<PhoneTrack> tracks;
  final Map<String, Uint8List> covers;
}

/// Reads the Android music catalog. Returns null when permission is denied.
Future<PhoneCatalogScan?> readPhoneMusic() async {
  final allowed =
      await _phoneMusic.invokeMethod<bool>('hasPermission') == true ||
      await _phoneMusic.invokeMethod<bool>('requestPermission') == true;
  if (!allowed) return null;
  final raw = await _phoneMusic.invokeMethod<List<dynamic>>('querySongs');
  final rows = <_Row>[];
  for (final song in raw ?? const []) {
    try {
      if (song is! Map) continue;
      final row = _row(Map<Object?, Object?>.from(song));
      if (row != null) rows.add(row);
    } catch (_) {
      // One unreadable catalog row does not stop the scan.
    }
  }
  final covers = await _covers(rows);
  final paths = [for (final row in rows) row.song.path ?? ''];
  final lyrics = paths.isEmpty
      ? const <String?>[]
      : await Isolate.run(() => lyricsForPaths(paths));
  return PhoneCatalogScan(
    tracks: [
      for (var index = 0; index < rows.length; index++)
        PhoneTrack(
          song: Song(
            id: rows[index].song.id,
            title: rows[index].song.title,
            artist: rows[index].song.artist,
            album: rows[index].song.album,
            albumId: rows[index].song.albumId,
            coverArt: covers.containsKey(rows[index].coverId)
                ? rows[index].coverId
                : null,
            track: rows[index].song.track,
            disc: rows[index].song.disc,
            duration: rows[index].song.duration,
            path: rows[index].song.path,
            genre: rows[index].song.genre,
          ),
          playUri: rows[index].playUri,
          lyricsJson: lyrics[index],
        ),
    ],
    covers: covers,
  );
}

class _Row {
  const _Row({
    required this.song,
    required this.playUri,
    required this.coverId,
    required this.mediaId,
    this.albumMediaId,
    this.lyricsJson,
  });

  final Song song;
  final String playUri;
  final String coverId;
  final int mediaId;
  final int? albumMediaId;
  final String? lyricsJson;
}

_Row? _row(Map<Object?, Object?> info) {
  final data = info['path'];
  final relative = info['relativePath'];
  final display = info['displayName'];
  final path = _storedPath(
    data is String ? data : '',
    relative is String ? relative : '',
    display is String ? display : '',
  );
  if (!_musicFile(info, path)) return null;
  final albumMediaId = _int(info['albumId']);
  final albumId = _albumId(albumMediaId, path);
  final albumName = info['album'];
  final artistName = info['artist'];
  final track = _int(info['track']);
  final disc = track != null && track >= 1000 ? track ~/ 1000 : null;
  final number = track == null
      ? null
      : track >= 1000
      ? track % 1000
      : track;
  final durationMs = _int(info['duration']) ?? 0;
  final mediaId = _int(info['id']);
  if (mediaId == null) return null;
  final uri = info['uri'];
  return _Row(
    mediaId: mediaId,
    albumMediaId: albumMediaId,
    playUri: uri is String && uri.isNotEmpty
        ? uri
        : 'content://media/external/audio/media/$mediaId',
    coverId: 'phone-cover:$albumId',
    song: Song(
      id: 'phone:$mediaId',
      title: _title(info, path),
      artist: _named(
        artistName is String ? artistName : null,
        'Unknown artist',
      ),
      album: _albumName(albumName is String ? albumName : null, path),
      albumId: albumId,
      track: number == 0 ? null : number,
      disc: disc == 0 ? null : disc,
      duration: durationMs <= 0 ? 0 : (durationMs / 1000).round(),
      path: path,
    ),
  );
}

bool _musicFile(Map<Object?, Object?> info, String path) {
  if (info['isAlarm'] == true ||
      info['isNotification'] == true ||
      info['isRingtone'] == true ||
      info['isPodcast'] == true) {
    return false;
  }
  final relative = info['relativePath'];
  final folder = relative is String
      ? relative.replaceAll('\\', '/').toLowerCase()
      : '';
  final inMusic =
      folder == 'music' ||
      folder.startsWith('music/') ||
      path.replaceAll('\\', '/').toLowerCase().contains('/music/');
  if (!inMusic) return false;
  final normalized = '$folder ${path.replaceAll('\\', '/').toLowerCase()}';
  return !normalized.contains('/ringtones/') &&
      !normalized.contains('/notifications/') &&
      !normalized.contains('/alarms/');
}

String _storedPath(String data, String relative, String displayName) {
  if (data.trim().isNotEmpty) return data;
  if (relative.trim().isEmpty || displayName.trim().isEmpty) return '';
  final folder = relative.replaceAll('\\', '/');
  final slash = folder.endsWith('/') ? folder : '$folder/';
  return '/storage/emulated/0/$slash$displayName';
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

String _albumId(int? albumId, String path) {
  if (albumId != null && albumId > 0) return 'phone-album:$albumId';
  return 'phone-album:folder:${_folder(path).toLowerCase()}';
}

String _albumName(String? album, String path) {
  final named = _namedOrNull(album);
  if (named != null) return named;
  final folder = _folder(path);
  final slash = folder.lastIndexOf(RegExp(r'[\\/]'));
  final name = (slash < 0 ? folder : folder.substring(slash + 1)).trim();
  if (name.isEmpty || name.toLowerCase() == 'music') return 'Unknown album';
  return name;
}

String _title(Map<Object?, Object?> info, String path) {
  final title = info['title'];
  if (title is String && title.trim().isNotEmpty) return title.trim();
  final display = info['displayName'];
  if (display is String && display.trim().isNotEmpty) {
    final dot = display.lastIndexOf('.');
    final stem = dot <= 0 ? display : display.substring(0, dot);
    if (stem.trim().isNotEmpty) return stem.trim();
  }
  final slash = path.lastIndexOf(RegExp(r'[\\/]'));
  final name = slash < 0 ? path : path.substring(slash + 1);
  final dot = name.lastIndexOf('.');
  final stem = dot <= 0 ? name : name.substring(0, dot);
  return stem.trim().isEmpty ? 'Unknown album' : stem.trim();
}

String _folder(String path) {
  final slash = path.lastIndexOf(RegExp(r'[\\/]'));
  if (slash <= 0) return path;
  return path.substring(0, slash);
}

String _named(String? value, String fallback) =>
    _namedOrNull(value) ?? fallback;

String? _namedOrNull(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final lower = text.toLowerCase();
  if (lower == '<unknown>' || lower == 'unknown') return null;
  return text;
}

List<String?> lyricsForPaths(List<String> paths) {
  return [for (final path in paths) _lyricsJson(path)];
}

String? _lyricsJson(String path) {
  if (path.isEmpty) return null;
  final chosen = _prefer(_embedded(path), _sidecar(path));
  if (chosen == null) return null;
  return jsonEncode(
    LyricMatch(
      lrc: chosen.synced ? chosen.text : '',
      plain: chosen.synced ? '' : chosen.text,
      source: 'File',
      synced: chosen.synced,
      instrumental: false,
    ).toJson(),
  );
}

EmbeddedLyrics? _prefer(EmbeddedLyrics? embedded, EmbeddedLyrics? sidecar) {
  if (embedded != null && embedded.synced) return embedded;
  if (sidecar != null && sidecar.synced) return sidecar;
  return embedded ?? sidecar;
}

EmbeddedLyrics? _embedded(String path) {
  try {
    final bytes = _id3Bytes(path);
    if (bytes == null) return null;
    return embeddedLyrics(bytes);
  } catch (_) {
    return null;
  }
}

Uint8List? _id3Bytes(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  final handle = file.openSync();
  try {
    final header = handle.readSync(10);
    if (header.length < 10) return null;
    if (header[0] != 0x49 || header[1] != 0x44 || header[2] != 0x33) {
      return null;
    }
    final size =
        (header[6] & 0x7f) << 21 |
        (header[7] & 0x7f) << 14 |
        (header[8] & 0x7f) << 7 |
        (header[9] & 0x7f);
    final total = 10 + size;
    if (total <= 10 || total > 2 * 1024 * 1024) return null;
    handle.setPositionSync(0);
    final bytes = handle.readSync(total);
    if (bytes.length < total) return null;
    return bytes;
  } finally {
    handle.closeSync();
  }
}

EmbeddedLyrics? _sidecar(String path) {
  final dot = path.lastIndexOf('.');
  final slash = path.lastIndexOf(RegExp(r'[\\/]'));
  if (dot <= slash) return null;
  final file = File('${path.substring(0, dot)}.lrc');
  if (!file.existsSync()) return null;
  try {
    final text = file.readAsStringSync().trim();
    if (text.isEmpty) return null;
    if (parseLrc(text).isNotEmpty) {
      return EmbeddedLyrics(text: text, synced: true);
    }
    return EmbeddedLyrics(text: text, synced: false);
  } catch (_) {
    return null;
  }
}

Future<Map<String, Uint8List>> _covers(List<_Row> rows) async {
  final covers = <String, Uint8List>{};
  final seen = <String>{};
  for (final row in rows) {
    if (!seen.add(row.coverId)) continue;
    try {
      final bytes = await _phoneMusic.invokeMethod<Uint8List>('artwork', {
        'id': row.mediaId,
        'albumId': row.albumMediaId,
      });
      if (bytes != null && bytes.isNotEmpty) covers[row.coverId] = bytes;
    } catch (_) {
      // A missing picture still leaves the track in the catalog.
    }
  }
  return covers;
}
