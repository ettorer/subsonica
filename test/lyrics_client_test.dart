import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:subsonica/models/library.dart';
import 'package:subsonica/services/lyrics_client.dart';

void main() {
  test('plain lyrics leave the opening free and stay evenly spaced', () {
    final lrc = plainToLrc('First line\n\nSecond line\nThird', 30);
    expect(
      lrc,
      '[00:03.00]First line\n[00:11.33]Second line\n[00:19.66]Third\n',
    );
  });

  test('a long track waits longer before the first line', () {
    expect(plainToLrc('One\nTwo', 600), startsWith('[01:06.00]One\n'));
  });

  test('search prefers the synced line with the closest duration', () {
    const distant = LyricCandidate(
      trackName: 'Deadwing',
      artistName: 'Porcupine Tree',
      duration: 400,
      instrumental: false,
      syncedLyrics: '[00:00.00]far',
    );
    const plain = LyricCandidate(
      trackName: 'Deadwing',
      artistName: 'Porcupine Tree',
      duration: 590,
      instrumental: false,
      plainLyrics: 'plain',
    );
    const synced = LyricCandidate(
      trackName: 'Deadwing',
      artistName: 'Porcupine Tree',
      duration: 588,
      instrumental: false,
      syncedLyrics: '[00:01.00]near',
    );
    final picked = pickLyric(
      title: 'Deadwing',
      artist: 'Porcupine Tree',
      durationSeconds: 589,
      candidates: const [distant, plain, synced],
    );
    expect(picked?.syncedLyrics, '[00:01.00]near');
  });

  test('a saved lyric file keeps sync and the words', () {
    const match = LyricMatch(
      lrc: '[00:12.00]Halo',
      plain: '',
      source: 'LRCLIB',
      synced: true,
      instrumental: false,
    );
    final restored = LyricMatch.fromJson(match.toJson());
    expect(restored.synced, isTrue);
    expect(restored.lrc, '[00:12.00]Halo');
    expect(restored.source, 'LRCLIB');
  });

  test('search ignores a different artist when the duration is far', () {
    final picked = pickLyric(
      title: 'Halo',
      artist: 'Porcupine Tree',
      durationSeconds: 340,
      candidates: const [
        LyricCandidate(
          trackName: 'Halo',
          artistName: 'Someone Else',
          duration: 180,
          instrumental: false,
          syncedLyrics: '[00:00.00]no',
        ),
      ],
    );
    expect(picked, isNull);
  });

  test('structured lyrics keep the lrc offset and a one-line object', () {
    final parsed = parseStructuredLyrics({
      'structuredLyrics': {
        'synced': true,
        'offset': -100,
        'line': [
          {'start': 0, 'value': "It's bugging me"},
          {'start': 2100, 'value': 'Grating me'},
        ],
      },
    });
    expect(parsed?.lrc, "[00:00.00]It's bugging me\n[00:02.00]Grating me");
    expect(parsed?.plain, isEmpty);
  });

  test('a synced entry is kept when an earlier entry is plain text', () {
    final parsed = parseStructuredLyrics({
      'structuredLyrics': [
        {
          'synced': false,
          'line': {'value': 'plain only'},
        },
        {
          'synced': true,
          'line': {'start': 1500, 'value': 'timed'},
        },
      ],
    });
    expect(parsed?.lrc, '[00:01.50]timed');
    expect(parsed?.plain, 'plain only');
  });

  test('an empty lyrics list is not a match', () {
    expect(parseStructuredLyrics({'structuredLyrics': const []}), isNull);
    expect(parseStructuredLyrics(null), isNull);
  });

  test(
    'synced server lyrics are used without calling another source',
    () async {
      final client = LyricsClient(httpClient: _ThrowingClient());
      addTearDown(client.close);
      final match = await client.find(
        const Song(
          id: 'server-synced',
          title: 'Halo',
          artist: 'Porcupine Tree',
          album: 'Deadwing',
          duration: 279,
        ),
        serverLyrics: () async => {
          'structuredLyrics': {
            'synced': true,
            'line': {'start': 1000, 'value': 'God is in my fingers'},
          },
        },
      );
      expect(match.source, 'Navidrome');
      expect(match.synced, isTrue);
      expect(match.lrc, '[00:01.00]God is in my fingers');
    },
  );

  test(
    'plain server lyrics are kept when the other sources have none',
    () async {
      final client = LyricsClient(httpClient: _NotFoundClient());
      addTearDown(client.close);
      final match = await client.find(
        const Song(
          id: 'server-plain',
          title: 'Deadwing',
          artist: 'Porcupine Tree',
          album: 'Deadwing',
          duration: 589,
        ),
        serverLyrics: () async => {
          'structuredLyrics': {
            'synced': false,
            'line': [
              {'value': 'first'},
              {'value': 'second'},
            ],
          },
        },
      );
      expect(match.source, 'Navidrome');
      expect(match.synced, isFalse);
      expect(match.plain, 'first\nsecond');
    },
  );

  test(
    'a tango with no lyrics searches LRCLIB by title for plain text',
    () async {
      final httpClient = _TangoClient(plain: 'quién al oír');
      final client = LyricsClient(httpClient: httpClient);
      addTearDown(client.close);
      final match = await client.find(
        const Song(
          id: 'vals-tango',
          title: 'El vals soñador',
          artist: 'Miguel Caló',
          album: 'Tango Popular',
          duration: 207,
          genre: 'TANGO',
        ),
      );
      expect(match.source, 'LRCLIB');
      expect(match.synced, isFalse);
      expect(match.lrc, isEmpty);
      expect(match.plain, 'quién al oír');
      final titleOnly = httpClient.urls.where(
        (uri) =>
            uri.path == '/api/search' &&
            uri.queryParameters.length == 1 &&
            uri.queryParameters['q'] == 'El vals soñador Tango',
      );
      expect(titleOnly, hasLength(1));
    },
  );

  test('an unaccented title matches the accented LRCLIB name', () {
    final picked = pickPlainTitle(
      title: 'Tus Besos Fueron Mios',
      candidates: const [
        LyricCandidate(
          trackName: 'Tus Besos Fueron Míos',
          artistName: 'Alfredo De Angelis',
          duration: 174,
          instrumental: false,
          plainLyrics: 'Hoy pasas a mi lado',
        ),
      ],
    );
    expect(picked?.plainLyrics, 'Hoy pasas a mi lado');
  });

  test('Tus Besos Fueron Mios matches the accented plain lyric', () async {
    final httpClient = _MiosClient();
    final client = LyricsClient(httpClient: httpClient);
    addTearDown(client.close);
    final match = await client.find(
      const Song(
        id: 'tus-besos',
        title: 'Tus Besos Fueron Mios',
        artist: 'Alfredo De Angelis',
        album: 'Yo Soy El Tango',
        duration: 174,
        genre: 'Tango',
      ),
    );
    expect(match.synced, isFalse);
    expect(match.lrc, isEmpty);
    expect(match.plain, startsWith('Hoy pasas a mi lado'));
  });

  test('synced-only tango results are not used', () async {
    final client = LyricsClient(httpClient: _TangoClient());
    addTearDown(client.close);
    final match = await client.find(
      const Song(
        id: 'vals-synced-only',
        title: 'El vals soñador',
        artist: 'Miguel Caló',
        album: 'Tango Popular',
        duration: 207,
        genre: 'tango',
      ),
    );
    expect(match.found, isFalse);
  });

  test('another genre does not add Tango to the title search', () async {
    final httpClient = _TangoClient(plain: 'should not be used');
    final client = LyricsClient(httpClient: httpClient);
    addTearDown(client.close);
    final match = await client.find(
      const Song(
        id: 'halo-jazz',
        title: 'Halo',
        artist: 'Porcupine Tree',
        album: 'Deadwing',
        duration: 279,
        genre: 'Rock',
      ),
    );
    expect(match.found, isFalse);
    expect(
      httpClient.urls.where(
        (uri) => uri.queryParameters['q']?.endsWith(' Tango') ?? false,
      ),
      isEmpty,
    );
  });
}

class _ThrowingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw StateError('should not request ${request.url}');
  }
}

class _TangoClient extends http.BaseClient {
  _TangoClient({this.plain});

  final String? plain;
  final urls = <Uri>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    urls.add(uri);
    final titleOnly =
        uri.path == '/api/search' &&
        uri.queryParameters.length == 1 &&
        uri.queryParameters.containsKey('q');
    if (!titleOnly) {
      return http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode('{}')),
        404,
      );
    }
    final query = uri.queryParameters['q'] ?? '';
    const suffix = ' Tango';
    final trackName = query.endsWith(suffix)
        ? query.substring(0, query.length - suffix.length)
        : query;
    final record = <String, Object?>{
      'trackName': trackName,
      'artistName': 'Orquesta',
      'duration': 180,
      'instrumental': false,
      'syncedLyrics': '[00:01.00]timed line',
    };
    final text = plain;
    if (text != null) record['plainLyrics'] = text;
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(jsonEncode([record]))),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}

class _MiosClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final query = request.url.queryParameters['q'];
    if (query == 'Tus Besos Fueron Mios Tango') {
      final body = jsonEncode([
        {
          'trackName': 'Tus Besos Fueron Míos',
          'artistName': 'Alfredo De Angelis',
          'duration': 174,
          'instrumental': false,
          'plainLyrics': 'Hoy pasas a mi lado con fría indiferencia;',
          'syncedLyrics': null,
        },
        {
          'trackName': 'Tus besos fueron míos',
          'artistName': 'Francisco Canaro',
          'duration': 162,
          'instrumental': true,
          'plainLyrics': null,
          'syncedLyrics': null,
        },
      ]);
      return http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode(body)),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{}')),
      404,
    );
  }
}

class _NotFoundClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{}')),
      404,
    );
  }
}
