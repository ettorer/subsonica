import 'package:flutter_test/flutter_test.dart';
import 'package:subsonica/models/server_config.dart';
import 'package:subsonica/services/subsonic_api.dart';

void main() {
  test('token matches the Subsonic API example', () {
    expect(
      subsonicToken('sesame', 'c19b2d'),
      '26719a1196d2a940705a59634eb18eab',
    );
  });

  test('server addresses are normalized', () {
    expect(
      normalizeServerUrl('http://192.168.1.20:4533/'),
      'http://192.168.1.20:4533',
    );
    expect(
      normalizeServerUrl('http://192.168.1.20:4533/rest/ping.view'),
      'http://192.168.1.20:4533',
    );
    expect(normalizeServerUrl('192.168.1.20:4533'), 'http://192.168.1.20:4533');
    expect(
      normalizeServerUrl('https://music.example.com/navidrome'),
      'https://music.example.com/navidrome',
    );
    expect(normalizeServerUrl('ftp://example.com'), isNull);
    expect(normalizeServerUrl('   '), isNull);
  });

  test('stream url carries the token and not the password', () {
    final client = SubsonicClient(
      const ServerConfig(
        baseUrl: 'http://192.168.1.20:4533',
        username: 'joe',
        password: 'sesame',
      ),
      salt: 'c19b2d',
    );
    addTearDown(client.close);
    final uri = client.streamUri('song 1');
    expect(uri.scheme, 'http');
    expect(uri.host, '192.168.1.20');
    expect(uri.port, 4533);
    expect(uri.path, '/rest/stream.view');
    expect(uri.queryParameters['u'], 'joe');
    expect(uri.queryParameters['t'], '26719a1196d2a940705a59634eb18eab');
    expect(uri.queryParameters['s'], 'c19b2d');
    expect(uri.queryParameters['id'], 'song 1');
    expect(uri.queryParameters.containsKey('p'), isFalse);
    expect(uri.queryParameters.containsKey('f'), isFalse);
    expect(uri.toString().contains('sesame'), isFalse);
  });

  test('a song keeps a string genre or the first genre name', () {
    expect(
      tryParseSong({
        'id': 's1',
        'title': 'El vals soñador',
        'artist': 'Miguel Caló',
        'genre': 'Tango',
      })?.genre,
      'Tango',
    );
    expect(
      tryParseSong({
        'id': 's2',
        'title': 'El vals soñador',
        'artist': 'Miguel Caló',
        'genres': [
          {'name': 'Tango'},
        ],
      })?.genre,
      'Tango',
    );
  });

  test('user rating is clamped to 0 through 5', () {
    final album = parseAlbums({
      'album': {
        'id': 'a1',
        'name': 'Blue',
        'artist': 'Miles',
        'userRating': 4,
        'song': {
          'id': 's1',
          'title': 'So What',
          'artist': 'Miles',
          'duration': 562,
          'userRating': 9,
        },
      },
    }).single;
    expect(album.userRating, 4);
    expect(album.songs.single.userRating, 5);
    expect(readUserRating(null), 0);
    expect(readUserRating(-2), 0);
  });

  test('album list accepts one album object or many', () {
    final many = parseAlbums({
      'album': [
        {
          'id': 'a1',
          'name': 'Kind of Blue',
          'artist': 'Miles Davis',
          'year': 1959,
          'songCount': 5,
        },
      ],
    });
    expect(many.single.name, 'Kind of Blue');
    expect(many.single.year, 1959);

    final one = parseAlbums({
      'album': {
        'id': 'a2',
        'name': 'Blue',
        'song': {
          'id': 's1',
          'title': 'So What',
          'artist': 'Miles',
          'duration': 562,
        },
      },
    });
    expect(one.single.songs.single.title, 'So What');
    expect(one.single.songs.single.duration, 562);
  });

  test('failed responses surface the server message', () {
    expect(
      () => unwrapSubsonic(
        '{"subsonic-response":{"status":"failed","error":{"code":40,"message":"Wrong username or password"}}}',
      ),
      throwsA(
        isA<SubsonicException>().having(
          (error) => error.message,
          'message',
          'Wrong username or password',
        ),
      ),
    );
  });

  test('genres, playlists, and artist indexes parse Navidrome json', () {
    final genres = parseGenres({
      'genre': {'value': 'Jazz', 'songCount': 12, 'albumCount': 3},
    });
    expect(genres.single.name, 'Jazz');
    expect(genres.single.songCount, 12);

    final playlists = parsePlaylists({
      'playlist': {
        'id': 'p1',
        'name': 'Road trip',
        'songCount': 1,
        'coverArt': 'pl-p1',
        'entry': {'id': 's9', 'title': 'Night', 'artist': 'Ada'},
      },
    });
    expect(playlists.single.songs.single.title, 'Night');
    expect(playlists.single.artworkId, 'pl-p1');
    final favorites = parseFavorites({
      'album': {'id': 'a1', 'name': 'Kind of Blue', 'artist': 'Miles Davis'},
      'song': {
        'id': 's1',
        'title': 'So What',
        'artist': 'Miles Davis',
        'starred': '2026-01-01T00:00:00Z',
      },
    });
    expect(favorites.albums.single.name, 'Kind of Blue');
    expect(favorites.songs.single.title, 'So What');
    expect(favorites.songs.single.starred, isTrue);
    expect(tryParsePlaylist({'id': 'p2', 'name': 'No art'})?.artworkId, 'p2');

    final artists = parseArtistIndex({
      'index': {
        'name': 'M',
        'artist': {'id': 'ar1', 'name': 'Miles Davis', 'albumCount': 4},
      },
    });
    expect(artists.single.artists.single.name, 'Miles Davis');
    expect(artists.single.artists.single.albumCount, 4);
  });
}
