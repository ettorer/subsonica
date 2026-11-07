import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/library.dart';
import '../services/subsonic_api.dart';
import 'local_tracks.dart';

class PlayerController extends ChangeNotifier {
  PlayerController() {
    _playing = _player.playing;
    _processing = _player.processingState;
    _loopMode = _player.loopMode;
    _shuffleEnabled = _player.shuffleModeEnabled;
    _speed = _player.speed;
    _stateSub = _player.playerStateStream.listen(_onPlayerState);
    _indexSub = _player.currentIndexStream.listen(_onIndex);
    _loopSub = _player.loopModeStream.listen(_onLoop);
    _shuffleSub = _player.shuffleModeEnabledStream.listen(_onShuffle);
    _speedSub = _player.speedStream.listen(_onSpeed);
    _positionSub = _player
        .createPositionStream(
          steps: 400,
          minPeriod: const Duration(milliseconds: 80),
          maxPeriod: const Duration(milliseconds: 160),
        )
        .listen(_onPosition);
    _durationSub = _player.durationStream.listen((value) {
      durationListenable.value = value ?? Duration.zero;
    });
    _errorSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace _) {
        if (error is PlayerInterruptedException) return;
        _setError(_playbackMessage(error));
      },
    );
  }

  final AudioPlayer _player = AudioPlayer();
  final positionListenable = ValueNotifier<Duration>(Duration.zero);
  final durationListenable = ValueNotifier<Duration>(Duration.zero);

  SubsonicClient? _client;
  LocalTracks? _library;
  List<Song> _queue = const [];
  String _queueTitle = '';
  Song? _current;
  int? _currentIndex;
  var _playGeneration = 0;
  var _playing = false;
  var _shuffleEnabled = false;
  var _processing = ProcessingState.idle;
  var _loopMode = LoopMode.off;
  var _speed = 1.0;
  var _disposed = false;
  var _errorId = 0;
  String? _error;
  String? _announcedKey;
  String? _scrobbledKey;
  Duration _lastPosition = Duration.zero;
  Duration? _seekTarget;
  DateTime? _seekHold;
  var _speedTicket = 0;
  Future<void>? _speedChain;

  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<int?> _indexSub;
  late final StreamSubscription<LoopMode> _loopSub;
  late final StreamSubscription<bool> _shuffleSub;
  late final StreamSubscription<double> _speedSub;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration?> _durationSub;
  late final StreamSubscription<PlaybackEvent> _errorSub;

  bool get hasTrack => _current != null;
  Song? get current => _current;
  int? get index => _currentIndex;
  String get queueTitle => _queueTitle;
  bool get playing => _playing;
  bool get shuffleEnabled => _shuffleEnabled;
  LoopMode get loopMode => _loopMode;
  double get speed => _speed;
  String? get error => _error;
  int get errorId => _errorId;

  bool get buffering =>
      _processing == ProcessingState.loading ||
      _processing == ProcessingState.buffering;

  void bindLibrary(LocalTracks library) {
    _library = library;
  }

  void attach(SubsonicClient? client) {
    if (identical(_client, client)) return;
    final replacePlayback = _client != null;
    _client = client;
    if (!replacePlayback) return;
    _playGeneration++;
    _queue = const [];
    _queueTitle = '';
    _current = null;
    _currentIndex = null;
    _announcedKey = null;
    _scrobbledKey = null;
    positionListenable.value = Duration.zero;
    durationListenable.value = Duration.zero;
    _notify();
    _player.stop();
  }

  List<Song> get queue => List.unmodifiable(_queue);

  bool matchesQueue(List<Song> songs) {
    if (songs.length != _queue.length) return false;
    for (var i = 0; i < songs.length; i++) {
      if (songs[i].id != _queue[i].id) return false;
    }
    return true;
  }

  Future<void> playSongs(
    List<Song> songs, {
    required int startIndex,
    required bool shuffle,
    required String queueTitle,
  }) async {
    if (songs.isEmpty) {
      _setError('There are no tracks to play.');
      return;
    }
    if (!_canPlay(songs)) return;
    final generation = ++_playGeneration;
    final safeIndex = startIndex.clamp(0, songs.length - 1);
    final sameQueue = matchesQueue(songs);
    _error = null;
    if (sameQueue && !shuffle && !_player.shuffleModeEnabled) {
      _queueTitle = queueTitle;
      _currentIndex = safeIndex;
      _current = songs[safeIndex];
      positionListenable.value = Duration.zero;
      _notify();
      await _guard(generation, () async {
        await _player.seek(Duration.zero, index: safeIndex);
        await _player.play();
      });
      return;
    }

    _queue = List<Song>.from(songs);
    _queueTitle = queueTitle;
    _currentIndex = safeIndex;
    _current = songs[safeIndex];
    positionListenable.value = Duration.zero;
    durationListenable.value = Duration(seconds: songs[safeIndex].duration);
    _notify();

    final sources = <AudioSource>[
      for (var i = 0; i < songs.length; i++) _mediaSource(songs[i], i, generation),
    ];

    await _guard(generation, () async {
      await _player.setAudioSources(
        sources,
        initialIndex: safeIndex,
        initialPosition: Duration.zero,
      );
      if (generation != _playGeneration) return;
      await _player.setShuffleModeEnabled(shuffle);
      if (shuffle && songs.length > 1) {
        await _player.shuffle();
        final pick = Random().nextInt(songs.length);
        await _player.seek(Duration.zero, index: pick);
        if (generation != _playGeneration) return;
        _currentIndex = pick;
        _current = songs[pick];
        durationListenable.value = Duration(seconds: songs[pick].duration);
        _notify();
      }
      await _player.play();
    });
  }

  /// Keeps the current track where it is and plays [songs] after it.
  /// The list is the one returned by the server. It is not a saved playlist.
  Future<bool> startRadio(List<Song> songs) async {
    final current = _current;
    final index = _currentIndex;
    final upcoming = [
      for (final song in songs)
        if (current == null || song.id != current.id) song,
    ];
    if (upcoming.isEmpty) return false;
    if (current == null || index == null || _queue.isEmpty) {
      await playSongs(
        upcoming,
        startIndex: 0,
        shuffle: false,
        queueTitle: 'Radio',
      );
      return _error == null;
    }
    if (!_canPlay(upcoming)) return false;
    final generation = _playGeneration;
    try {
      if (_player.shuffleModeEnabled) {
        await _player.setShuffleModeEnabled(false);
      }
      if (generation != _playGeneration) return false;
      if (index + 1 < _queue.length) {
        await _player.removeAudioSourceRange(index + 1, _queue.length);
        if (generation != _playGeneration) return false;
        _queue = _queue.sublist(0, index + 1);
      }
      final start = _queue.length;
      final sources = <AudioSource>[
        for (var i = 0; i < upcoming.length; i++)
          _mediaSource(upcoming[i], start + i, generation),
      ];
      await _player.addAudioSources(sources);
      if (generation != _playGeneration) return false;
      _queue = [..._queue, ...upcoming];
      _queueTitle = 'Radio';
      _error = null;
      _notify();
      if (!_player.playing) await _player.play();
      return true;
    } on PlayerInterruptedException {
      return false;
    } catch (error) {
      if (generation != _playGeneration) return false;
      _setError(_playbackMessage(error));
      return false;
    }
  }

  Future<void> appendSongs(List<Song> songs) async {
    if (songs.isEmpty) return;
    if (_queue.isEmpty) {
      await playSongs(
        songs,
        startIndex: 0,
        shuffle: false,
        queueTitle: 'Play queue',
      );
      return;
    }
    if (!_canPlay(songs)) return;
    final generation = _playGeneration;
    final start = _queue.length;
    final sources = <AudioSource>[
      for (var i = 0; i < songs.length; i++)
        _mediaSource(songs[i], start + i, generation),
    ];
    try {
      await _player.addAudioSources(sources);
    } on PlayerInterruptedException {
      return;
    } catch (error) {
      if (generation != _playGeneration) return;
      _setError(_playbackMessage(error));
      return;
    }
    if (generation != _playGeneration) return;
    _queue = [..._queue, ...songs];
    _notify();
  }

  bool _canPlay(List<Song> songs) {
    final needsServer = songs.any(
      (song) => _library?.audioPath(song.id) == null,
    );
    if (!needsServer) return true;
    if (_client == null || _library?.playFromDownloadsOnly == true) {
      _setError('Download these tracks to play them offline.');
      return false;
    }
    return true;
  }

  AudioSource _mediaSource(Song song, int index, int generation) {
    final coverPath = _library?.coverFile(song.artworkId);
    final artUri = coverPath != null
        ? Uri.file(coverPath)
        : _client?.coverUri(song.artworkId, size: 512);
    final tag = MediaItem(
      id: '${song.id}#$index#$generation',
      title: song.title,
      album: song.album.isEmpty ? null : song.album,
      artist: song.artist,
      artUri: artUri,
      duration: Duration(seconds: song.duration),
    );
    final local = _library?.audioPath(song.id);
    if (local != null) return AudioSource.file(local, tag: tag);
    return AudioSource.uri(_client!.streamUri(song.id), tag: tag);
  }

  Future<void> togglePlayPause() {
    return _guard(_playGeneration, () async {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    });
  }

  Future<void> stop() {
    positionListenable.value = Duration.zero;
    return _guard(_playGeneration, () async {
      await _player.pause();
      final index = _player.currentIndex;
      if (index != null) {
        await _player.seek(Duration.zero, index: index);
      }
    });
  }

  Future<void> seek(Duration position) {
    _seekTarget = position;
    _seekHold = DateTime.now().add(const Duration(milliseconds: 1500));
    positionListenable.value = position;
    return _guard(_playGeneration, () => _player.seek(position));
  }

  Future<void> previous() {
    return _guard(_playGeneration, () async {
      if (_player.position > const Duration(seconds: 3)) {
        positionListenable.value = Duration.zero;
        await _player.seek(Duration.zero);
        return;
      }
      if (_player.hasPrevious) {
        positionListenable.value = Duration.zero;
        await _player.seekToPrevious();
      } else {
        positionListenable.value = Duration.zero;
        await _player.seek(Duration.zero);
      }
    });
  }

  Future<void> next() {
    if (!_player.hasNext) return Future.value();
    positionListenable.value = Duration.zero;
    return _guard(_playGeneration, _player.seekToNext);
  }

  Future<void> toggleShuffle() {
    final enabled = !_shuffleEnabled;
    return _guard(_playGeneration, () async {
      await _player.setShuffleModeEnabled(enabled);
      if (enabled) await _player.shuffle();
    });
  }

  Future<void> setSpeed(double speed) {
    final next = speed.clamp(0.5, 2.0);
    final ticket = ++_speedTicket;
    final previous = _speedChain;
    final current = _guard(_playGeneration, () async {
      if (previous != null) await previous;
      if (_disposed || ticket != _speedTicket) return;
      await _player.setSpeed(next);
    });
    _speedChain = current;
    return current;
  }

  Future<void> cycleLoop() {
    final next = switch (_loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    return _guard(_playGeneration, () => _player.setLoopMode(next));
  }

  Future<void> _guard(int generation, Future<void> Function() action) async {
    try {
      await action();
    } on PlayerInterruptedException {
      return;
    } catch (error) {
      if (generation != _playGeneration) return;
      _setError(_playbackMessage(error));
    }
  }

  void _onPlayerState(PlayerState state) {
    if (state.playing == _playing && state.processingState == _processing) {
      return;
    }
    _playing = state.playing;
    _processing = state.processingState;
    _notify();
  }

  void _onIndex(int? index) {
    if (index == null || index < 0 || index >= _queue.length) return;
    final song = _queue[index];
    final changed = index != _currentIndex || _current?.id != song.id;
    _currentIndex = index;
    _current = song;
    _markNowPlaying(song);
    if (changed) _notify();
  }

  void _onLoop(LoopMode mode) {
    if (mode == _loopMode) return;
    _loopMode = mode;
    _notify();
  }

  void _onShuffle(bool enabled) {
    if (enabled == _shuffleEnabled) return;
    _shuffleEnabled = enabled;
    _notify();
  }

  void _onSpeed(double speed) {
    if (speed == _speed) return;
    _speed = speed;
    _notify();
  }

  void _onPosition(Duration position) {
    final hold = _seekHold;
    final target = _seekTarget;
    if (hold != null && target != null && DateTime.now().isBefore(hold)) {
      if ((position - target).inMilliseconds.abs() > 1500) return;
      _seekHold = null;
      _seekTarget = null;
    }
    if (position + const Duration(seconds: 2) < _lastPosition &&
        position < const Duration(seconds: 2)) {
      _scrobbledKey = null;
    }
    _lastPosition = position;
    positionListenable.value = position;
    final song = _current;
    if (song == null || !_playing) return;
    final key = '$_playGeneration:${song.id}';
    if (_scrobbledKey == key || song.duration <= 0) return;
    final threshold = min(30, max(5, song.duration ~/ 2));
    if (position.inSeconds >= threshold) {
      _scrobbledKey = key;
      _scrobble(song.id, submission: true);
    }
  }

  void _markNowPlaying(Song song) {
    final key = '$_playGeneration:${song.id}';
    if (_announcedKey == key) return;
    _announcedKey = key;
    _scrobbledKey = null;
    _scrobble(song.id, submission: false);
  }

  void _scrobble(String id, {required bool submission}) {
    if (_client == null || _library?.playFromDownloadsOnly == true) {
      _library?.queueScrobble(id, submission: submission);
      return;
    }
    _client?.scrobble(id, submission: submission);
  }

  void _setError(String message) {
    _error = message;
    _errorId++;
    _notify();
  }

  String _playbackMessage(Object error) {
    if (error is PlayerException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return 'Playback failed. Check the server and the track file.';
  }

  void _notify() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stateSub.cancel();
    _indexSub.cancel();
    _loopSub.cancel();
    _shuffleSub.cancel();
    _speedSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    _errorSub.cancel();
    positionListenable.dispose();
    durationListenable.dispose();
    _player.dispose();
    super.dispose();
  }
}
