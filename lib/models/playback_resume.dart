import 'dart:convert';

import 'library.dart';

class PlaybackResume {
  const PlaybackResume({
    required this.songs,
    required this.currentIndex,
    required this.position,
    required this.savedAt,
    this.queueTitle = '',
  });

  final List<Song> songs;
  final int currentIndex;
  final Duration position;
  final DateTime savedAt;
  final String queueTitle;

  Song get current => songs[currentIndex.clamp(0, songs.length - 1)];

  String encode() {
    return jsonEncode({
      'savedAt': savedAt.millisecondsSinceEpoch,
      'positionMs': position.inMilliseconds,
      'currentId': current.id,
      'queueTitle': queueTitle,
      'songs': [
        for (final song in songs)
          {
            'id': song.id,
            'title': song.title,
            'artist': song.artist,
            'album': song.album,
            'albumId': song.albumId,
            'artistId': song.artistId,
            'coverArt': song.coverArt,
            'duration': song.duration,
            'path': song.path,
          },
      ],
    });
  }

  static PlaybackResume? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      return fromParts(
        songs: [
          for (final item
              in json['songs'] is List ? json['songs'] as List : const [])
            if (item is Map) _song(Map<String, dynamic>.from(item)),
        ].whereType<Song>().toList(),
        currentId: '${json['currentId'] ?? ''}',
        positionMs: _millis(json['positionMs']),
        savedAt: DateTime.fromMillisecondsSinceEpoch(_millis(json['savedAt'])),
        queueTitle: '${json['queueTitle'] ?? ''}',
      );
    } catch (_) {
      return null;
    }
  }

  static PlaybackResume? fromParts({
    required List<Song> songs,
    required String currentId,
    required int positionMs,
    required DateTime savedAt,
    String queueTitle = '',
  }) {
    if (songs.isEmpty) return null;
    var index = songs.indexWhere((song) => song.id == currentId);
    if (index < 0) index = 0;
    final position = Duration(milliseconds: positionMs < 0 ? 0 : positionMs);
    return PlaybackResume(
      songs: songs,
      currentIndex: index,
      position: position,
      savedAt: savedAt,
      queueTitle: queueTitle,
    );
  }
}

/// The browser copy is written first, then Navidrome, so the server time is
/// usually a moment later for the same pause. Keep the browser copy unless
/// the server copy is clearly newer. The browser copy still has the album
/// or playlist name.
PlaybackResume? preferPlaybackResume(
  PlaybackResume? local,
  PlaybackResume? remote,
) {
  final localOk = local != null && local.songs.isNotEmpty;
  final remoteOk = remote != null && remote.songs.isNotEmpty;
  if (!localOk) return remoteOk ? remote : null;
  if (!remoteOk) return local;
  final remoteIsNewer = remote.savedAt.isAfter(
    local.savedAt.add(const Duration(seconds: 2)),
  );
  return remoteIsNewer ? remote : local;
}

Song? _song(Map<String, dynamic> json) {
  final id = '${json['id'] ?? ''}'.trim();
  if (id.isEmpty) return null;
  final title = '${json['title'] ?? ''}'.trim();
  final artist = '${json['artist'] ?? ''}'.trim();
  return Song(
    id: id,
    title: title.isEmpty ? 'Untitled' : title,
    artist: artist.isEmpty ? 'Unknown artist' : artist,
    album: '${json['album'] ?? ''}'.trim(),
    albumId: _optional(json['albumId']),
    artistId: _optional(json['artistId']),
    coverArt: _optional(json['coverArt']),
    duration: _millis(json['duration']),
    path: _optional(json['path']),
  );
}

String? _optional(Object? value) {
  final text = '$value'.trim();
  if (value == null || text.isEmpty || text == 'null') return null;
  return text;
}

int _millis(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}
