import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/library.dart';

class LyricsException implements Exception {
  const LyricsException(this.message);

  final String message;
}

class LyricMatch {
  const LyricMatch({
    required this.lrc,
    required this.source,
    required this.synced,
    required this.instrumental,
    this.plain = '',
  });

  static const missing = LyricMatch(
    lrc: '',
    source: '',
    synced: false,
    instrumental: false,
  );

  final String lrc;
  final String plain;
  final String source;
  final bool synced;
  final bool instrumental;

  bool get found =>
      instrumental || lrc.trim().isNotEmpty || plain.trim().isNotEmpty;

  Map<String, Object?> toJson() {
    return {
      'source': source,
      'synced': synced,
      'instrumental': instrumental,
      'lrc': lrc,
      'plain': plain,
    };
  }

  factory LyricMatch.fromJson(Map<String, Object?> json) {
    final lrc = json['lrc'];
    final plain = json['plain'];
    final source = json['source'];
    return LyricMatch(
      lrc: lrc is String ? lrc : '',
      plain: plain is String ? plain : '',
      source: source is String ? source : '',
      synced: json['synced'] == true,
      instrumental: json['instrumental'] == true,
    );
  }
}

class LyricCandidate {
  const LyricCandidate({
    required this.trackName,
    required this.artistName,
    required this.duration,
    required this.instrumental,
    this.plainLyrics,
    this.syncedLyrics,
  });

  final String trackName;
  final String artistName;
  final int duration;
  final bool instrumental;
  final String? plainLyrics;
  final String? syncedLyrics;
}

class LyricsClient {
  LyricsClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  static const _userAgent = 'Subsonica 1.0.0';
  static const _timeout = Duration(seconds: 12);
  static final _cache = <String, LyricMatch>{};

  final http.Client _http;
  var _answered = false;

  Future<LyricMatch> find(
    Song song, {
    Future<Object?> Function()? serverLyrics,
  }) async {
    final cached = _cache[song.id];
    if (cached != null) return cached;
    _answered = false;
    final server = parseStructuredLyrics(await _serverLyrics(serverLyrics));
    final synced = server?.lrc.trim() ?? '';
    if (synced.isNotEmpty) {
      final match = LyricMatch(
        lrc: synced,
        source: 'Navidrome',
        synced: true,
        instrumental: false,
      );
      _cache[song.id] = match;
      return match;
    }
    final LyricMatch external;
    try {
      external = await _search(song);
    } on LyricsException {
      final plain = _serverPlain(server);
      if (plain == null) rethrow;
      return _remember(song.id, plain);
    }
    if (external.synced) {
      _cache[song.id] = external;
      return external;
    }
    final plain = _serverPlain(server);
    if (plain != null) return _remember(song.id, plain);
    _cache[song.id] = external;
    return external;
  }

  LyricMatch _remember(String songId, LyricMatch match) {
    _cache[songId] = match;
    return match;
  }

  void close() {
    _http.close();
  }

  Future<LyricMatch> _search(Song song) async {
    final queries = _queries(song);
    for (final query in queries) {
      if (query.duration <= 0) continue;
      final exact = await _lrclibGet(query);
      final match = exact == null ? null : _fromCandidate(exact);
      if (match != null) return match;
    }
    for (final query in queries) {
      final picked = pickLyric(
        title: query.title,
        artist: query.artist,
        durationSeconds: query.duration,
        candidates: await _lrclibSearch(query),
      );
      final match = picked == null ? null : _fromCandidate(picked);
      if (match != null) return match;
    }
    for (final query in queries) {
      final plain = await _lyricsOvh(query);
      if (plain == null) continue;
      return LyricMatch(
        lrc: '',
        plain: plain,
        source: 'lyrics.ovh',
        synced: false,
        instrumental: false,
      );
    }
    if (!_answered) {
      throw const LyricsException('Lyrics are unavailable right now.');
    }
    return LyricMatch.missing;
  }

  Future<LyricCandidate?> _lrclibGet(_LyricQuery query) async {
    final response = await _send(
      Uri.https('lrclib.net', '/api/get', {
        'track_name': query.title,
        'artist_name': query.artist,
        'album_name': query.album,
        'duration': '${query.duration}',
      }),
    );
    if (response == null || response.statusCode == 404) return null;
    if (response.statusCode != 200) return null;
    final record = _record(response.body);
    return record;
  }

  Future<List<LyricCandidate>> _lrclibSearch(_LyricQuery query) async {
    final response = await _send(
      Uri.https('lrclib.net', '/api/search', {
        'track_name': query.title,
        'artist_name': query.artist,
        if (query.album.isNotEmpty) 'album_name': query.album,
      }),
    );
    if (response == null || response.statusCode != 200) return const [];
    final decoded = _decode(response.body);
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (item is Map) _candidate(Map<String, dynamic>.from(item)),
    ].whereType<LyricCandidate>().toList();
  }

  Future<String?> _lyricsOvh(_LyricQuery query) async {
    if (query.artist.isEmpty || query.title.isEmpty) return null;
    final response = await _send(
      Uri(
        scheme: 'https',
        host: 'api.lyrics.ovh',
        pathSegments: ['v1', query.artist, query.title],
      ),
    );
    if (response == null || response.statusCode == 404) return null;
    if (response.statusCode != 200) return null;
    final decoded = _decode(response.body);
    if (decoded is! Map) return null;
    final lyrics = decoded['lyrics'];
    if (lyrics is! String) return null;
    final text = lyrics.trim();
    return text.isEmpty ? null : text;
  }

  Future<http.Response?> _send(Uri uri) async {
    try {
      final response = await _http
          .get(
            uri,
            headers: const {
              'User-Agent': _userAgent,
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);
      if (response.statusCode == 429 || response.statusCode >= 500) {
        return null;
      }
      _answered = true;
      return response;
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } on http.ClientException {
      return null;
    }
  }
}

Future<Object?> _serverLyrics(Future<Object?> Function()? read) async {
  if (read == null) return null;
  try {
    return await read();
  } catch (_) {
    return null;
  }
}

LyricMatch? _serverPlain(({String lrc, String plain})? server) {
  final plain = server?.plain.trim() ?? '';
  if (plain.isEmpty) return null;
  return LyricMatch(
    lrc: '',
    plain: plain,
    source: 'Navidrome',
    synced: false,
    instrumental: false,
  );
}

({String lrc, String plain})? parseStructuredLyrics(Object? lyricsList) {
  if (lyricsList is! Map) return null;
  final entries = _maps(lyricsList['structuredLyrics']);
  String? synced;
  String? plain;
  for (final entry in entries) {
    final offset = _int(entry['offset']);
    final timed = entry['synced'] == true || entry['synced'] == 'true';
    final lines = _maps(entry['line']);
    final texts = <String>[];
    final stamps = <({int start, String text})>[];
    for (final line in lines) {
      final text = _string(line['value']);
      if (text.isEmpty) continue;
      texts.add(text);
      if (!timed) continue;
      final start = _int(line['start']) + offset;
      stamps.add((start: start < 0 ? 0 : start, text: text));
    }
    if (timed && stamps.isNotEmpty && synced == null) {
      stamps.sort((a, b) => a.start.compareTo(b.start));
      final buffer = StringBuffer();
      for (final line in stamps) {
        buffer.writeln(
          '${formatLrcStamp(Duration(milliseconds: line.start))}${line.text}',
        );
      }
      synced = buffer.toString().trimRight();
    } else if (!timed && texts.isNotEmpty && plain == null) {
      plain = texts.join('\n');
    }
  }
  if ((synced == null || synced.isEmpty) && (plain == null || plain.isEmpty)) {
    return null;
  }
  return (lrc: synced ?? '', plain: plain ?? '');
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is List) {
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
  if (value is Map) return [Map<String, dynamic>.from(value)];
  return const [];
}

LyricMatch? _fromCandidate(LyricCandidate candidate) {
  final synced = candidate.syncedLyrics?.trim();
  if (synced != null && synced.isNotEmpty) {
    return LyricMatch(
      lrc: synced,
      source: 'LRCLIB',
      synced: true,
      instrumental: false,
    );
  }
  final plain = candidate.plainLyrics?.trim();
  if (plain != null && plain.isNotEmpty) {
    return LyricMatch(
      lrc: '',
      plain: plain,
      source: 'LRCLIB',
      synced: false,
      instrumental: false,
    );
  }
  if (candidate.instrumental) {
    return const LyricMatch(
      lrc: '',
      source: 'LRCLIB',
      synced: false,
      instrumental: true,
    );
  }
  return null;
}

LyricCandidate? _candidate(Map<String, dynamic> json) {
  final title = _string(json['trackName']);
  if (title.isEmpty) return null;
  return LyricCandidate(
    trackName: title,
    artistName: _string(json['artistName']),
    duration: _int(json['duration']),
    instrumental: json['instrumental'] == true,
    plainLyrics: _optional(json['plainLyrics']),
    syncedLyrics: _optional(json['syncedLyrics']),
  );
}

LyricCandidate? _record(String body) {
  final decoded = _decode(body);
  if (decoded is! Map) return null;
  return _candidate(Map<String, dynamic>.from(decoded));
}

Object? _decode(String body) {
  try {
    return jsonDecode(body);
  } on FormatException {
    return null;
  }
}

String _string(Object? value) => value is String ? value.trim() : '';

String? _optional(Object? value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

class _LyricQuery {
  const _LyricQuery(this.title, this.artist, this.album, this.duration);

  final String title;
  final String artist;
  final String album;
  final int duration;
}

List<_LyricQuery> _queries(Song song) {
  final primary = _LyricQuery(
    song.title.trim(),
    song.artist.trim(),
    song.album.trim(),
    song.duration,
  );
  final cleaned = _LyricQuery(
    _stripTags(primary.title),
    _stripTags(primary.artist),
    _stripTags(primary.album),
    song.duration,
  );
  if (cleaned.title.isEmpty || cleaned.artist.isEmpty) return [primary];
  if (cleaned.title == primary.title &&
      cleaned.artist == primary.artist &&
      cleaned.album == primary.album) {
    return [primary];
  }
  return [primary, cleaned];
}

String _stripTags(String value) {
  var text = value.replaceAll(
    RegExp(
      r'\s*[\(\[][^)\]]*(remaster|live|feat\.|featuring|ft\.)[^)\]]*[\)\]]',
      caseSensitive: false,
    ),
    '',
  );
  text = text.replaceAll(
    RegExp(r'\s+(feat\.|ft\.)\s+.*$', caseSensitive: false),
    '',
  );
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

LyricCandidate? pickLyric({
  required String title,
  required String artist,
  required int durationSeconds,
  required List<LyricCandidate> candidates,
}) {
  LyricCandidate? best;
  var bestScore = 0;
  for (final candidate in candidates) {
    final score = _score(
      title: title,
      artist: artist,
      durationSeconds: durationSeconds,
      candidate: candidate,
    );
    if (score > bestScore) {
      best = candidate;
      bestScore = score;
    }
  }
  return best;
}

int _score({
  required String title,
  required String artist,
  required int durationSeconds,
  required LyricCandidate candidate,
}) {
  final titleScore = _textScore(title, candidate.trackName);
  if (titleScore == 0) return 0;
  final artistScore = _textScore(artist, candidate.artistName);
  final durationDelta = durationSeconds > 0 && candidate.duration > 0
      ? (durationSeconds - candidate.duration).abs()
      : null;
  if (artistScore == 0 && (durationDelta == null || durationDelta > 3)) {
    return 0;
  }
  final hasSynced = candidate.syncedLyrics?.trim().isNotEmpty ?? false;
  final hasPlain = candidate.plainLyrics?.trim().isNotEmpty ?? false;
  if (!hasSynced && !hasPlain && !candidate.instrumental) return 0;
  var score = titleScore * 3 + artistScore * 2;
  if (hasSynced) {
    score += 40;
  } else if (hasPlain) {
    score += 10;
  } else {
    score += 4;
  }
  if (durationDelta != null) {
    if (durationDelta <= 2) {
      score += 30;
    } else if (durationDelta <= 5) {
      score += 15;
    } else if (durationDelta > 30) {
      score -= 25;
    }
  }
  return score;
}

int _textScore(String left, String right) {
  final a = _norm(left);
  final b = _norm(right);
  if (a.isEmpty || b.isEmpty) return 0;
  if (a == b) return 20;
  if (a.contains(b) || b.contains(a)) return 12;
  return 0;
}

String _norm(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

String plainToLrc(String plain, int durationSeconds) {
  final lines = plain
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return '';
  final introMs = _introMs(durationSeconds);
  final totalMs = durationSeconds <= 0
      ? lines.length * 4000
      : durationSeconds * 1000;
  final outroMs = durationSeconds <= 0 ? 0 : _outroMs(durationSeconds);
  final spanMs = totalMs - introMs - outroMs;
  final step = (spanMs < lines.length * 800 ? totalMs : spanMs) / lines.length;
  final buffer = StringBuffer();
  for (var index = 0; index < lines.length; index++) {
    final stamp = formatLrcStamp(
      Duration(milliseconds: introMs + (step * index).round()),
    );
    buffer.writeln('$stamp${lines[index]}');
  }
  return buffer.toString();
}

int _introMs(int durationSeconds) {
  if (durationSeconds <= 0) return 0;
  if (durationSeconds < 75) return 3000;
  final fraction = durationSeconds >= 500
      ? 0.11
      : durationSeconds >= 300
      ? 0.08
      : 0.055;
  final cap = durationSeconds >= 500 ? 70000 : 28000;
  final floor = durationSeconds >= 180 ? 8000 : 4000;
  return (durationSeconds * 1000 * fraction).round().clamp(floor, cap);
}

int _outroMs(int durationSeconds) {
  return (durationSeconds * 1000 * 0.05).round().clamp(2000, 20000);
}

String formatLrcStamp(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final centiseconds = (duration.inMilliseconds.remainder(1000) ~/ 10)
      .toString()
      .padLeft(2, '0');
  return '[$minutes:$seconds.$centiseconds]';
}
