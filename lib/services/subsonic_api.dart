import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/library.dart';
import '../models/server_config.dart';
import 'io_error.dart';

const subsonicApiVersion = '1.16.1';
const subsonicClientName = 'Subsonica';

class SubsonicException implements Exception {
  const SubsonicException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

class ServerAbout {
  const ServerAbout({this.type = '', this.version = ''});

  final String type;
  final String version;

  String get label {
    final raw = type.trim();
    final kind = raw.isEmpty
        ? 'Subsonic'
        : '${raw[0].toUpperCase()}${raw.substring(1)}';
    final release = version.trim();
    if (release.isEmpty) return kind;
    return '$kind $release';
  }
}

String serverStatusMessage(int statusCode) {
  if (statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504 ||
      statusCode == 530) {
    return 'Cannot reach the server. Check the address.';
  }
  return 'The server returned HTTP $statusCode.';
}

String describeError(Object error) {
  if (error is SubsonicException) return error.message;
  if (error is TimeoutException) {
    return 'The server took too long to respond.';
  }
  if (isTlsFailure(error)) {
    return 'The secure connection failed.';
  }
  if (isUnreachable(error)) {
    return 'Cannot reach the server. Check the address.';
  }
  if (error is FormatException) {
    return 'The server did not return a Subsonic response. Check the address.';
  }
  return 'Something went wrong. Try again.';
}

String subsonicToken(String password, String salt) {
  return md5.convert(utf8.encode('$password$salt')).toString();
}

String createSalt() {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random.secure();
  return List.generate(
    12,
    (_) => alphabet[random.nextInt(alphabet.length)],
  ).join();
}

Map<String, dynamic> unwrapSubsonic(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const SubsonicException(
      'The server did not return a Subsonic response. Check the address.',
    );
  }
  final response = decoded['subsonic-response'];
  if (response is! Map) {
    throw const SubsonicException(
      'The server did not return a Subsonic response. Check the address.',
    );
  }
  final map = Map<String, dynamic>.from(response);
  if (asString(map['status']) == 'failed') {
    final error = map['error'];
    final message = error is Map ? asString(error['message']).trim() : '';
    throw SubsonicException(
      message.isEmpty ? 'The server rejected the request.' : message,
    );
  }
  return map;
}

String asString(dynamic value) => value == null ? '' : value.toString();

int readUserRating(dynamic value) {
  final rating = asInt(value);
  if (rating < 0) return 0;
  if (rating > 5) return 5;
  return rating;
}

int asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? positiveInt(dynamic value) {
  final number = asInt(value);
  if (number <= 0) return null;
  return number;
}

List<Map<String, dynamic>> mapList(dynamic value) {
  if (value is List) {
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
  if (value is Map) return [Map<String, dynamic>.from(value)];
  return const [];
}

Song? tryParseSong(Map<String, dynamic> json) {
  if (json['isDir'] == true) return null;
  final id = asString(json['id']).trim();
  if (id.isEmpty) return null;
  final title = asString(json['title']).trim().isNotEmpty
      ? asString(json['title']).trim()
      : asString(json['name']).trim();
  final artist = asString(json['artist']).trim();
  return Song(
    id: id,
    title: title.isEmpty ? 'Untitled' : title,
    artist: artist.isEmpty ? 'Unknown artist' : artist,
    album: asString(json['album']).trim(),
    albumId: _optionalString(json['albumId']),
    coverArt: _optionalString(json['coverArt']),
    track: positiveInt(json['track']),
    disc: positiveInt(json['discNumber']),
    duration: asInt(json['duration']),
    starred: _isStarred(json['starred']),
    userRating: readUserRating(json['userRating']),
    path: _optionalString(json['path']),
    genre: _songGenre(json),
  );
}

Album? tryParseAlbum(Map<String, dynamic> json) {
  final id = asString(json['id']).trim();
  if (id.isEmpty) return null;
  final name = asString(json['name']).trim().isNotEmpty
      ? asString(json['name']).trim()
      : asString(json['title']).trim();
  final artist = asString(json['artist']).trim();
  final songs = parseSongList(json);
  final reported = asInt(json['songCount']);
  return Album(
    id: id,
    name: name.isEmpty ? 'Unknown album' : name,
    artist: artist.isEmpty ? 'Unknown artist' : artist,
    artistId: _optionalString(json['artistId']),
    coverArt: _optionalString(json['coverArt']),
    songCount: reported > 0 ? reported : songs.length,
    year: positiveInt(json['year']),
    songs: songs,
    userRating: readUserRating(json['userRating']),
  );
}

Artist? tryParseArtist(Map<String, dynamic> json) {
  final id = asString(json['id']).trim();
  if (id.isEmpty) return null;
  final name = asString(json['name']).trim();
  if (name.isEmpty) return null;
  final albums = [
    for (final album in mapList(json['album'])) ?tryParseAlbum(album),
  ];
  final reported = asInt(json['albumCount']);
  return Artist(
    id: id,
    name: name,
    albumCount: reported > 0 ? reported : albums.length,
    coverArt: _optionalString(json['coverArt']),
    albums: albums,
  );
}

Genre? tryParseGenre(Map<String, dynamic> json) {
  final fromValue = asString(json['value']).trim();
  final name = fromValue.isNotEmpty ? fromValue : asString(json['name']).trim();
  if (name.isEmpty) return null;
  return Genre(
    name: name,
    songCount: asInt(json['songCount']),
    albumCount: asInt(json['albumCount']),
  );
}

Playlist? tryParsePlaylist(Map<String, dynamic> json) {
  final id = asString(json['id']).trim();
  if (id.isEmpty) return null;
  final name = asString(json['name']).trim();
  final songs = parseSongList(json);
  final reported = asInt(json['songCount']);
  return Playlist(
    id: id,
    name: name.isEmpty ? 'Untitled playlist' : name,
    coverArt: _optionalString(json['coverArt']),
    owner: asString(json['owner']).trim(),
    songCount: reported > 0 ? reported : songs.length,
    songs: songs,
  );
}

List<Song> parseSongList(dynamic node) {
  final raw = node is Map ? (node['song'] ?? node['entry']) : node;
  return [for (final json in mapList(raw)) ?tryParseSong(json)];
}

List<Album> parseAlbums(dynamic node) {
  if (node is! Map) return const [];
  return [for (final json in mapList(node['album'])) ?tryParseAlbum(json)];
}

List<ArtistSection> parseArtistIndex(dynamic node) {
  if (node is! Map) return const [];
  return [
    for (final index in mapList(node['index']))
      ArtistSection(
        letter: asString(index['name']).trim().isEmpty
            ? '#'
            : asString(index['name']).trim(),
        artists: [
          for (final artist in mapList(index['artist']))
            ?tryParseArtist(artist),
        ],
      ),
  ].where((section) => section.artists.isNotEmpty).toList();
}

List<Genre> parseGenres(dynamic node) {
  if (node is! Map) return const [];
  final genres = [
    for (final json in mapList(node['genre'])) ?tryParseGenre(json),
  ];
  genres.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return genres;
}

List<Playlist> parsePlaylists(dynamic node) {
  if (node is! Map) return const [];
  final playlists = [
    for (final json in mapList(node['playlist'])) ?tryParsePlaylist(json),
  ];
  playlists.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  return playlists;
}

Favorites parseFavorites(dynamic node) {
  if (node is! Map) return const Favorites();
  return Favorites(
    artists: [
      for (final json in mapList(node['artist'])) ?tryParseArtist(json),
    ],
    albums: [for (final json in mapList(node['album'])) ?tryParseAlbum(json)],
    songs: parseSongList(node),
  );
}

SearchResult parseSearch(dynamic node) {
  if (node is! Map) return const SearchResult();
  return SearchResult(
    artists: [
      for (final json in mapList(node['artist'])) ?tryParseArtist(json),
    ],
    albums: [for (final json in mapList(node['album'])) ?tryParseAlbum(json)],
    songs: parseSongList(node),
  );
}

String? _songGenre(Map<String, dynamic> json) {
  final direct = _optionalString(json['genre']);
  if (direct != null) return direct;
  final raw = json['genres'];
  if (raw is! List || raw.isEmpty) return null;
  final first = raw.first;
  if (first is String) return _optionalString(first);
  if (first is Map) {
    return _optionalString(first['name'] ?? first['value']);
  }
  return null;
}

String? _optionalString(dynamic value) {
  final text = asString(value).trim();
  if (text.isEmpty) return null;
  return text;
}

bool _isStarred(dynamic value) {
  if (value == true) return true;
  return asString(value).trim().isNotEmpty;
}

class SubsonicClient {
  SubsonicClient(this.config, {String? salt, http.Client? httpClient})
    : salt = salt ?? createSalt(),
      _http = httpClient ?? http.Client() {
    token = subsonicToken(config.password, this.salt);
  }

  static const albumPageSize = 40;

  final ServerConfig config;
  final String salt;
  final http.Client _http;
  late final String token;

  Future<ServerAbout> ping() async {
    final data = await _request(
      'ping.view',
      const {},
      timeout: const Duration(seconds: 12),
    );
    return ServerAbout(
      type: asString(data['type']),
      version: asString(data['serverVersion']),
    );
  }

  Future<List<Album>> getAlbums({required int offset, int? size}) async {
    final data = await _request('getAlbumList2.view', {
      'type': 'alphabeticalByName',
      'size': '${size ?? albumPageSize}',
      'offset': '$offset',
    });
    return parseAlbums(data['albumList2']);
  }

  Future<List<Album>> getRecentAlbums({required int offset, int? size}) async {
    final data = await _request('getAlbumList2.view', {
      'type': 'recent',
      'size': '${size ?? albumPageSize}',
      'offset': '$offset',
    });
    return parseAlbums(data['albumList2']);
  }

  Future<Album> getAlbum(String id) async {
    final data = await _request('getAlbum.view', {'id': id});
    final album = data['album'];
    if (album is! Map) {
      throw const SubsonicException('Album not found.');
    }
    final parsed = tryParseAlbum(Map<String, dynamic>.from(album));
    if (parsed == null) throw const SubsonicException('Album not found.');
    final songs = List<Song>.from(parsed.songs);
    songs.sort((a, b) {
      final disc = (a.disc ?? 1).compareTo(b.disc ?? 1);
      if (disc != 0) return disc;
      final track = (a.track ?? 0).compareTo(b.track ?? 0);
      if (track != 0) return track;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return Album(
      id: parsed.id,
      name: parsed.name,
      artist: parsed.artist,
      artistId: parsed.artistId,
      coverArt: parsed.coverArt,
      songCount: parsed.songCount,
      year: parsed.year,
      songs: songs,
    );
  }

  Future<Object?> songLyrics(String songId) async {
    if (songId.isEmpty) return null;
    try {
      final data = await _request('getLyricsBySongId.view', {
        'id': songId,
      }, timeout: const Duration(seconds: 12));
      return data['lyricsList'];
    } on SubsonicException {
      return null;
    }
  }

  Future<List<Song>> getSimilarSongs(String id, {int count = 50}) async {
    final data = await _request('getSimilarSongs2.view', {
      'id': id,
      'count': '$count',
    });
    return parseSongList(data['similarSongs2']);
  }

  Future<List<Song>> getRandomSongs({int size = 80}) async {
    final data = await _request('getRandomSongs.view', {'size': '$size'});
    return parseSongList(data['randomSongs']);
  }

  Future<List<ArtistSection>> getArtists() async {
    final data = await _request('getArtists.view', const {});
    return parseArtistIndex(data['artists']);
  }

  Future<Artist> getArtist(String id) async {
    final data = await _request('getArtist.view', {'id': id});
    final artist = data['artist'];
    if (artist is! Map) {
      throw const SubsonicException('Artist not found.');
    }
    final parsed = tryParseArtist(Map<String, dynamic>.from(artist));
    if (parsed == null) throw const SubsonicException('Artist not found.');
    final albums = List<Album>.from(parsed.albums);
    albums.sort((a, b) {
      final byYear = (b.year ?? 0).compareTo(a.year ?? 0);
      if (byYear != 0) return byYear;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return Artist(
      id: parsed.id,
      name: parsed.name,
      albumCount: parsed.albumCount == 0 ? albums.length : parsed.albumCount,
      coverArt: parsed.coverArt,
      albums: albums,
    );
  }

  Future<List<Genre>> getGenres() async {
    final data = await _request('getGenres.view', const {});
    return parseGenres(data['genres']);
  }

  Future<List<Song>> getSongsByGenre(String genre, {int count = 200}) async {
    final data = await _request('getSongsByGenre.view', {
      'genre': genre,
      'count': '$count',
      'offset': '0',
    });
    return parseSongList(data['songsByGenre']);
  }

  Future<void> setStarred(String id, {required bool starred}) async {
    await _request(starred ? 'star.view' : 'unstar.view', {'id': id});
  }

  Future<void> setSongsStarred(
    List<String> ids, {
    required bool starred,
  }) async {
    final songIds = ids.where((id) => id.isNotEmpty).toList();
    if (songIds.isEmpty) return;
    await _requestRepeated(starred ? 'star.view' : 'unstar.view', {
      'id': songIds,
    });
  }

  Future<void> setAlbumStarred(String albumId, {required bool starred}) async {
    await _request(starred ? 'star.view' : 'unstar.view', {'albumId': albumId});
  }

  Future<void> setRating(String id, int rating) async {
    await _request('setRating.view', {
      'id': id,
      'rating': '${readUserRating(rating)}',
    });
  }

  Future<Favorites> getFavorites() async {
    final data = await _request('getStarred2.view', const {});
    return parseFavorites(data['starred2']);
  }

  Future<List<Playlist>> getPlaylists() async {
    final data = await _request('getPlaylists.view', const {});
    return parsePlaylists(data['playlists']);
  }

  Future<void> addToPlaylist(String playlistId, String songId) {
    return addSongsToPlaylist(playlistId, [songId]);
  }

  Future<void> addSongsToPlaylist(
    String playlistId,
    List<String> songIds,
  ) async {
    final ids = songIds.where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return;
    await _requestRepeated('updatePlaylist.view', {
      'playlistId': [playlistId],
      'songIdToAdd': ids,
    });
  }

  Future<void> createPlaylist(
    String name, {
    String? songId,
    List<String> songIds = const [],
  }) async {
    final ids = <String>[
      if (songId != null && songId.isNotEmpty) songId,
      ...songIds.where((id) => id.isNotEmpty),
    ];
    await _requestRepeated('createPlaylist.view', {
      'name': [name],
      if (ids.isNotEmpty) 'songId': ids,
    });
  }

  Future<void> removeFromPlaylist(String playlistId, int index) async {
    await _request('updatePlaylist.view', {
      'playlistId': playlistId,
      'songIndexToRemove': '$index',
    });
  }

  Future<void> renamePlaylist(String playlistId, String name) async {
    await _request('updatePlaylist.view', {
      'playlistId': playlistId,
      'name': name,
    });
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _request('deletePlaylist.view', {'id': playlistId});
  }

  Future<Playlist> getPlaylist(String id) async {
    final data = await _request('getPlaylist.view', {'id': id});
    final playlist = data['playlist'];
    if (playlist is! Map) {
      throw const SubsonicException('Playlist not found.');
    }
    final parsed = tryParsePlaylist(Map<String, dynamic>.from(playlist));
    if (parsed == null) {
      throw const SubsonicException('Playlist not found.');
    }
    return parsed;
  }

  Future<SearchResult> search(String query) async {
    final data = await _request('search3.view', {
      'query': query,
      'artistCount': '20',
      'albumCount': '30',
      'songCount': '40',
    });
    return parseSearch(data['searchResult3']);
  }

  Future<void> scrobble(String id, {required bool submission}) async {
    await submitScrobble(id, submission: submission);
  }

  Future<bool> submitScrobble(
    String id, {
    required bool submission,
    int? atMs,
  }) async {
    try {
      await _request('scrobble.view', {
        'id': id,
        'submission': submission ? 'true' : 'false',
        if (submission)
          'time': '${atMs ?? DateTime.now().millisecondsSinceEpoch}',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Uri streamUri(String id) {
    return _uri('stream.view', {'id': id}, json: false);
  }

  Uri downloadUri(String id) {
    return _uri('download.view', {'id': id}, json: false);
  }

  Future<http.StreamedResponse> openBinary(Uri uri) {
    final request = http.Request('GET', uri);
    return _http.send(request).timeout(const Duration(seconds: 30));
  }

  bool _looksLikeSubsonicError(List<int> chunk) {
    if (chunk.isEmpty) return false;
    final head = utf8
        .decode(chunk.take(64).toList(), allowMalformed: true)
        .trimLeft();
    return head.startsWith('<') || head.startsWith('{');
  }

  Uri? coverUri(String? id, {int size = 300}) {
    if (id == null || id.isEmpty) return null;
    return _uri('getCoverArt.view', {'id': id, 'size': '$size'}, json: false);
  }

  Future<({Uint8List bytes, String? contentType})?> fetchCover(
    String id, {
    int size = 600,
  }) async {
    final uri = coverUri(id, size: size);
    if (uri == null) return null;
    try {
      final response = await _http
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;
      final bytes = response.bodyBytes;
      if (bytes.isEmpty || _looksLikeSubsonicError(bytes)) return null;
      return (bytes: bytes, contentType: response.headers['content-type']);
    } catch (_) {
      return null;
    }
  }

  void close() => _http.close();

  Future<Map<String, dynamic>> _request(
    String view,
    Map<String, String> params, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final response = await _http
          .get(_uri(view, params, json: true))
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw SubsonicException(serverStatusMessage(response.statusCode));
      }
      return unwrapSubsonic(response.body);
    } on SubsonicException {
      rethrow;
    } on TimeoutException {
      throw const SubsonicException('The server took too long to respond.');
    } on FormatException {
      throw const SubsonicException(
        'The server did not return a Subsonic response. Check the address.',
      );
    } catch (error) {
      if (isUnreachable(error)) {
        throw const SubsonicException(
          'Cannot reach the server. Check the address.',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _requestRepeated(
    String view,
    Map<String, List<String>> params, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final response = await _http
          .get(_uriRepeated(view, params))
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw SubsonicException(serverStatusMessage(response.statusCode));
      }
      return unwrapSubsonic(response.body);
    } on SubsonicException {
      rethrow;
    } on TimeoutException {
      throw const SubsonicException('The server took too long to respond.');
    } on FormatException {
      throw const SubsonicException(
        'The server did not return a Subsonic response. Check the address.',
      );
    } catch (error) {
      if (isUnreachable(error)) {
        throw const SubsonicException(
          'Cannot reach the server. Check the address.',
        );
      }
      rethrow;
    }
  }

  Uri _uri(String view, Map<String, String> params, {required bool json}) {
    return Uri.parse('${config.baseUrl}/rest/$view').replace(
      queryParameters: {
        'u': config.username,
        't': token,
        's': salt,
        'v': subsonicApiVersion,
        'c': subsonicClientName,
        if (json) 'f': 'json',
        ...params,
      },
    );
  }

  Uri _uriRepeated(String view, Map<String, List<String>> params) {
    final query = [
      'u=${Uri.encodeQueryComponent(config.username)}',
      't=${Uri.encodeQueryComponent(token)}',
      's=${Uri.encodeQueryComponent(salt)}',
      'v=${Uri.encodeQueryComponent(subsonicApiVersion)}',
      'c=${Uri.encodeQueryComponent(subsonicClientName)}',
      'f=json',
      for (final entry in params.entries)
        for (final value in entry.value)
          '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value)}',
    ].join('&');
    return Uri.parse('${config.baseUrl}/rest/$view?$query');
  }
}
