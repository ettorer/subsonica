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
}

class _ThrowingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw StateError('should not request ${request.url}');
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
