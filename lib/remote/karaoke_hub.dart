import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/library.dart';
import '../services/lyrics_client.dart';
import '../services/subsonic_api.dart';
import '../state/download_controller.dart';
import '../state/player_controller.dart';
import 'karaoke_page.dart';
import 'karaoke_tls.dart';
import 'lrc.dart';

class KaraokeHub {
  KaraokeHub._(this._player, this._downloads, this._readClient) {
    _socket = webSocketHandler((channel, _) => _accept(channel));
  }

  static const port = 8765;
  static const securePort = 8766;

  final PlayerController _player;
  final DownloadController _downloads;
  final SubsonicClient? Function() _readClient;
  final LyricsClient _lyrics = LyricsClient();
  final Set<WebSocketChannel> _clients = {};

  HttpServer? _server;
  HttpServer? _secureServer;
  late final Handler _socket;
  String? url;
  String? secureUrl;
  String? _songId;
  Map<String, Object?>? _document;
  String? _cachedCoverId;
  Uint8List? _cachedCover;
  String _cachedCoverType = 'image/jpeg';
  Future<({Uint8List bytes, String? contentType})?>? _loadingCover;
  String? _loadingCoverId;
  var _lyricTicket = 0;
  var _closed = false;
  DateTime? _lastProgress;

  static Future<KaraokeHub> start({
    required PlayerController player,
    required DownloadController downloads,
    required SubsonicClient? Function() readClient,
  }) async {
    final hub = KaraokeHub._(player, downloads, readClient);
    hub._server = await shelf_io.serve(
      hub._handle,
      InternetAddress.anyIPv4,
      port,
    );
    final context = await loadKaraokeSecurityContext();
    if (context != null) {
      try {
        hub._secureServer = await shelf_io.serve(
          hub._handle,
          InternetAddress.anyIPv4,
          securePort,
          securityContext: context,
        );
      } catch (_) {
        hub._secureServer = null;
      }
    }
    final song = hub._player.current;
    hub._songId = song?.id;
    hub._player.addListener(hub._onPlayer);
    hub._player.positionListenable.addListener(hub._onPosition);
    final address = await _lanAddress();
    if (address != null) {
      hub.url = 'http://$address:$port/';
      if (hub._secureServer != null) {
        hub.secureUrl = 'https://$address:$securePort/';
      }
    }
    if (song != null) unawaited(hub._loadLyrics(song));
    return hub;
  }

  Future<Response> _handle(Request request) async {
    final path = request.url.path;
    if (path == 'ws') return _socket(request);
    if (path.isEmpty || path == 'index.html') {
      return Response.found('/karaoke');
    }
    if (path == 'karaoke') {
      return Response.ok(
        karaokePageHtml,
        headers: const {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'no-store',
        },
      );
    }
    if (path == 'cover') return _cover(request);
    return Response.notFound('Not found');
  }

  Future<Response> _cover(Request request) async {
    final song = _player.current;
    final id = song?.artworkId;
    if (song == null || id == null || id.isEmpty) {
      return Response.notFound('Not found');
    }
    final asked = request.url.queryParameters['id'];
    if (asked != null && asked != id) return Response.notFound('Not found');
    final image = await _loadCover(id);
    if (image == null || _player.current?.artworkId != id) {
      return Response.notFound('Not found');
    }
    return Response.ok(
      image.bytes,
      headers: {
        'content-type': image.contentType,
        'cache-control': 'private, max-age=86400',
      },
    );
  }

  Future<({Uint8List bytes, String contentType})?> _loadCover(String id) async {
    if (_cachedCoverId == id && _cachedCover != null) {
      return (bytes: _cachedCover!, contentType: _cachedCoverType);
    }
    final local = _downloads.coverFile(id);
    if (local != null) {
      try {
        final bytes = await File(local).readAsBytes();
        if (bytes.isEmpty) return null;
        final type = _imageType(bytes, null);
        _storeCover(id, bytes, type);
        return (bytes: bytes, contentType: type);
      } catch (_) {
        return null;
      }
    }
    final client = _readClient();
    if (client == null) return null;
    final Future<({Uint8List bytes, String? contentType})?> pending;
    if (_loadingCover != null && _loadingCoverId == id) {
      pending = _loadingCover!;
    } else {
      _loadingCoverId = id;
      pending = client.fetchCover(id, size: 600);
      _loadingCover = pending;
    }
    final loaded = await pending;
    if (identical(_loadingCover, pending)) _loadingCover = null;
    if (loaded == null || loaded.bytes.isEmpty) return null;
    if (_player.current?.artworkId != id) return null;
    final type = _imageType(loaded.bytes, loaded.contentType);
    _storeCover(id, loaded.bytes, type);
    return (bytes: loaded.bytes, contentType: type);
  }

  void _storeCover(String id, Uint8List bytes, String type) {
    _cachedCoverId = id;
    _cachedCover = bytes;
    _cachedCoverType = type;
  }

  void _accept(WebSocketChannel channel) {
    if (_closed) {
      channel.sink.close();
      return;
    }
    _clients.add(channel);
    _send(channel, 'playback.state', _state());
    final document = _document;
    if (document != null) _send(channel, 'lyrics.document', document);
    channel.stream.listen(
      (_) {},
      onDone: () => _clients.remove(channel),
      onError: (Object _, StackTrace _) => _clients.remove(channel),
    );
  }

  void _onPlayer() {
    if (_closed) return;
    final song = _player.lyricsTrack;
    final id = song?.id;
    if (id != _songId) {
      _songId = id;
      unawaited(_loadLyrics(song));
    }
    _broadcast('playback.state', _state());
    _broadcastProgress();
  }

  void _onPosition() {
    if (_closed || _clients.isEmpty) return;
    final now = DateTime.now();
    final last = _lastProgress;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 250)) {
      return;
    }
    _broadcastProgress();
  }

  Future<void> _loadLyrics(Song? song) async {
    final ticket = ++_lyricTicket;
    if (song == null) {
      _document = _emptyDocument(status: 'idle');
      _broadcast('lyrics.document', _document!);
      return;
    }
    _document = {
      'songId': song.id,
      'status': 'loading',
      'plain': '',
      'lines': const <Object>[],
    };
    _broadcast('lyrics.document', _document!);
    try {
      final saved = await _downloads.savedLyrics(song.id);
      if (ticket != _lyricTicket || _closed) return;
      final match =
          saved ??
          await _lyrics.find(
            song,
            serverLyrics: () {
              final client = _readClient();
              if (client == null) return Future<Object?>.value(null);
              return client.songLyrics(song.id);
            },
          );
      if (ticket != _lyricTicket || _closed) return;
      if (saved == null) await _downloads.saveLyrics(song.id, match);
      if (ticket != _lyricTicket || _closed) return;
      _document = _documentFor(song.id, match);
    } on LyricsException {
      if (ticket != _lyricTicket || _closed) return;
      _document = _emptyDocument(songId: song.id, status: 'unavailable');
    } catch (_) {
      if (ticket != _lyricTicket || _closed) return;
      _document = _emptyDocument(songId: song.id, status: 'unavailable');
    }
    _broadcast('lyrics.document', _document!);
    _broadcastProgress();
  }

  Map<String, Object?> _state() {
    final song = _player.lyricsTrack;
    return {
      'songId': song?.id ?? '',
      'title': song?.title ?? '',
      'artist': song?.artist ?? '',
      'coverId': song?.artworkId ?? '',
      'playing': _player.playing,
      'speed': _player.speed,
      'positionMs': _player.positionListenable.value.inMilliseconds,
      'durationMs': _player.durationListenable.value.inMilliseconds,
    };
  }

  void _broadcastProgress() {
    final song = _player.lyricsTrack;
    if (song == null || _clients.isEmpty) return;
    _lastProgress = DateTime.now();
    _broadcast('lyrics.progress', {
      'songId': song.id,
      'positionMs': _player.positionListenable.value.inMilliseconds,
      'playing': _player.playing,
      'speed': _player.speed,
    });
  }

  Map<String, Object?> _documentFor(String songId, LyricMatch match) {
    if (match.instrumental) {
      return _emptyDocument(songId: songId, status: 'instrumental');
    }
    if (match.synced && match.lrc.trim().isNotEmpty) {
      final lines = [
        for (final line in parseLrc(match.lrc))
          {'timeMs': line.timeMs, 'text': line.text},
      ];
      if (lines.isEmpty) {
        return _emptyDocument(songId: songId, status: 'missing');
      }
      return {
        'songId': songId,
        'status': 'synced',
        'plain': '',
        'lines': lines,
      };
    }
    final plain = match.plain.trim();
    if (plain.isNotEmpty) {
      return {
        'songId': songId,
        'status': 'plain',
        'plain': plain,
        'lines': const <Object>[],
      };
    }
    return _emptyDocument(songId: songId, status: 'missing');
  }

  Map<String, Object?> _emptyDocument({
    String songId = '',
    String status = 'idle',
  }) {
    return {
      'songId': songId,
      'status': status,
      'plain': '',
      'lines': const <Object>[],
    };
  }

  void _broadcast(String method, Map<String, Object?> params) {
    final text = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    });
    final gone = <WebSocketChannel>[];
    for (final channel in _clients) {
      try {
        channel.sink.add(text);
      } catch (_) {
        gone.add(channel);
      }
    }
    _clients.removeAll(gone);
  }

  void _send(
    WebSocketChannel channel,
    String method,
    Map<String, Object?> params,
  ) {
    channel.sink.add(
      jsonEncode({'jsonrpc': '2.0', 'method': method, 'params': params}),
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _lyricTicket++;
    _player.removeListener(_onPlayer);
    _player.positionListenable.removeListener(_onPosition);
    final channels = _clients.toList();
    _clients.clear();
    for (final channel in channels) {
      await channel.sink.close();
    }
    await _secureServer?.close(force: true);
    await _server?.close(force: true);
    _lyrics.close();
  }
}

String _imageType(List<int> bytes, String? header) {
  final declared = header?.split(';').first.trim().toLowerCase();
  if (declared != null && declared.startsWith('image/')) return declared;
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 6 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46) {
    return 'image/gif';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

Future<String?> _lanAddress() async {
  final faces = await NetworkInterface.list(
    includeLinkLocal: false,
    type: InternetAddressType.IPv4,
  );
  String? fallback;
  for (final face in faces) {
    final name = face.name.toLowerCase();
    if (_skipInterface(name)) continue;
    for (final addr in face.addresses) {
      if (addr.isLoopback) continue;
      final ip = addr.address;
      if (ip.startsWith('169.254.')) continue;
      if (_wifiName(name)) return ip;
      fallback ??= ip;
    }
  }
  return fallback;
}

bool _wifiName(String name) {
  return name.contains('wlan') ||
      name.contains('wifi') ||
      name.contains('swlan') ||
      name == 'ap0' ||
      name.contains('ap_');
}

bool _skipInterface(String name) {
  return name == 'lo' ||
      name.contains('dummy') ||
      name.contains('rmnet') ||
      name.contains('tun') ||
      name.contains('ccmni') ||
      name.contains('p2p') ||
      name.startsWith('ifb');
}
