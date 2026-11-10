import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../util/music_only.dart';
import 'local_tracks.dart';

class PlayerController extends ChangeNotifier {
  PlayerController() {
    _playing = _player.playing;
    _processing = _player.processingState;
    _loopMode = _player.loopMode;
    _shuffleEnabled = _player.shuffleModeEnabled;
    _speed = _player.speed;
    _bindPlayer();
  }

  AudioPlayer _player = AudioPlayer();
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
  var _offerPhoneScan = false;
  String? _announcedKey;
  String? _scrobbledKey;
  Duration _lastPosition = Duration.zero;
  Duration? _seekTarget;
  DateTime? _seekHold;
  var _speedTicket = 0;
  Future<void>? _speedChain;
  final Map<String, Song?> _siblings = {};
  Song? _counterpart;
  var _switchingMusic = false;
  var _musicOnly = false;
  var _holdingIndex = false;
  var _siblingTicket = 0;
  var _webPlayerUsed = false;

  late StreamSubscription<PlayerState> _stateSub;
  late StreamSubscription<int?> _indexSub;
  late StreamSubscription<LoopMode> _loopSub;
  late StreamSubscription<bool> _shuffleSub;
  late StreamSubscription<double> _speedSub;
  late StreamSubscription<Duration> _positionSub;
  late StreamSubscription<Duration?> _durationSub;
  late StreamSubscription<PlaybackEvent> _errorSub;

  void _bindPlayer() {
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
      if (_switchingMusic && (value == null || value == Duration.zero)) return;
      durationListenable.value = value ?? Duration.zero;
    });
    _errorSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace _) {
        if (error is PlayerInterruptedException) return;
        _setError(
          _playbackMessage(error),
          offerPhoneScan: _isPhoneTrack(_playingSong()),
        );
      },
    );
  }

  /// The web player remembers the first playlist and will not replace it.
  /// A new player is the only way to load a different album.
  Future<void> _openWebPlaylist() async {
    if (!kIsWeb) return;
    if (!_webPlayerUsed) {
      _webPlayerUsed = true;
      return;
    }
    final speed = _speed;
    final loop = _loopMode;
    await _stateSub.cancel();
    await _indexSub.cancel();
    await _loopSub.cancel();
    await _shuffleSub.cancel();
    await _speedSub.cancel();
    await _positionSub.cancel();
    await _durationSub.cancel();
    await _errorSub.cancel();
    final old = _player;
    _player = AudioPlayer();
    _bindPlayer();
    try {
      await old.dispose();
    } catch (_) {}
    if (_disposed) return;
    if (speed != 1) await _player.setSpeed(speed);
    if (loop != LoopMode.off) await _player.setLoopMode(loop);
  }

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
  bool get offerPhoneScan => _offerPhoneScan;

  bool get buffering =>
      _processing == ProcessingState.loading ||
      _processing == ProcessingState.buffering;

  bool get musicOnly => _musicOnly;

  bool get canSwitchMusicOnly =>
      _counterpart != null && !isMusicOnlyPath(_current?.path);

  bool get switchingMusic => _switchingMusic;

  /// The vocal recording. Karaoke and the lyrics page stay on this song
  /// while the music-only file is playing.
  Song? get lyricsTrack {
    final song = _current;
    if (song == null || !isMusicOnlyPath(song.path)) return song;
    final vocal = _counterpart;
    if (vocal != null && !isMusicOnlyPath(vocal.path)) return vocal;
    return song;
  }

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
    _musicOnly = false;
    _counterpart = null;
    _siblings.clear();
    _siblingTicket++;
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
    final sameQueue = matchesQueue(songs) && !_musicOnly;
    _error = null;
    if (sameQueue && !shuffle && !_player.shuffleModeEnabled) {
      _queueTitle = queueTitle;
      _currentIndex = safeIndex;
      _current = songs[safeIndex];
      positionListenable.value = Duration.zero;
      unawaited(_resolveSibling(songs[safeIndex]));
      _notify();
      await _guard(generation, () async {
        await _player.seek(Duration.zero, index: safeIndex);
        await _player.play();
      }, played: songs[safeIndex]);
      return;
    }

    _queue = List<Song>.from(songs);
    _queueTitle = queueTitle;
    _currentIndex = safeIndex;
    _current = songs[safeIndex];
    _musicOnly = false;
    positionListenable.value = Duration.zero;
    durationListenable.value = Duration(seconds: songs[safeIndex].duration);
    unawaited(_resolveSibling(songs[safeIndex]));
    _notify();

    if (kIsWeb) {
      await _openWebPlaylist();
      if (_disposed || generation != _playGeneration) return;
    }

    final sources = <AudioSource>[
      for (var i = 0; i < songs.length; i++)
        _mediaSource(songs[i], i, generation),
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
        unawaited(_resolveSibling(songs[pick]));
        _notify();
      }
      await _player.play();
    }, played: songs[safeIndex]);
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
      _setError(
        _playbackMessage(error),
        offerPhoneScan: upcoming.any(_isPhoneTrack),
      );
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
      _setError(
        _playbackMessage(error),
        offerPhoneScan: songs.any(_isPhoneTrack),
      );
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

  AudioSource _mediaSource(
    Song song,
    int index,
    int generation, {
    Song? audio,
  }) {
    final played = audio ?? song;
    final coverPath = _library?.coverFile(song.artworkId);
    final artUri = coverPath != null
        ? Uri.file(coverPath)
        : _client?.coverUri(song.artworkId, size: 512);
    final tag = MediaItem(
      id: audio == null
          ? '${song.id}#$index#$generation'
          : '${song.id}#$index#$generation#music',
      title: song.title,
      album: song.album.isEmpty ? null : song.album,
      artist: song.artist,
      artUri: artUri,
      duration: Duration(seconds: song.duration),
    );
    final local = _library?.audioPath(played.id);
    if (local != null) {
      final source = local.startsWith('content:')
          ? AudioSource.uri(Uri.parse(local), tag: tag)
          : AudioSource.file(local, tag: tag);
      return source;
    }
    return AudioSource.uri(_client!.streamUri(played.id), tag: tag);
  }

  Future<void> toggleMusicOnly() async {
    final vocal = _current;
    final index = _currentIndex;
    final instrumental = _counterpart;
    if (vocal == null ||
        index == null ||
        instrumental == null ||
        _switchingMusic ||
        isMusicOnlyPath(vocal.path)) {
      return;
    }
    final playInstrumental = !_musicOnly;
    final audio = playInstrumental ? instrumental : vocal;
    if (!_canPlay([audio])) return;
    final position = positionListenable.value;
    final resume = _playing;
    final generation = _playGeneration;
    // The file change leaves a short silence. Start the new file this far
    // ahead so the music lines up with where it would have been.
    const lead = Duration(milliseconds: 200);
    final limit = Duration(
      seconds: audio.duration > 0 ? audio.duration : vocal.duration,
    );
    final ahead = resume ? position + lead : position;
    final seekTo = limit > Duration.zero && ahead > limit ? limit : ahead;
    _switchingMusic = true;
    _holdingIndex = true;
    _seekTarget = seekTo;
    _seekHold = DateTime.now().add(const Duration(seconds: 3));
    positionListenable.value = seekTo;
    var added = false;
    try {
      final inserted = index + 1;
      await _player.insertAudioSource(
        inserted,
        _mediaSource(
          vocal,
          index,
          generation,
          audio: playInstrumental ? instrumental : null,
        ),
      );
      added = true;
      if (generation != _playGeneration) return;
      await _player.seek(seekTo, index: inserted);
      if (generation != _playGeneration) return;
      await _player.removeAudioSourceAt(index);
      added = false;
      if (generation != _playGeneration) return;
      _musicOnly = playInstrumental;
      if (resume && !_player.playing) await _player.play();
    } on PlayerInterruptedException {
      // The swap is rolled back below when the extra source is still in place.
    } catch (error) {
      if (generation == _playGeneration) {
        _setError(
          _playbackMessage(error),
          offerPhoneScan: _isPhoneTrack(vocal) || _isPhoneTrack(audio),
        );
      }
    } finally {
      if (added && generation == _playGeneration) {
        try {
          if (_player.currentIndex != index) {
            await _player.seek(position, index: index);
          }
          await _player.removeAudioSourceAt(index + 1);
        } catch (_) {}
      }
      _holdingIndex = false;
      _switchingMusic = false;
      if (!_disposed) _notify();
    }
  }

  Future<void> togglePlayPause() {
    return _guard(_playGeneration, () async {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    }, played: _current);
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
    return _guard(
      _playGeneration,
      () => _player.seek(position),
      played: _current,
    );
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
    }, played: _current);
  }

  Future<void> next() {
    if (!_player.hasNext) return Future.value();
    positionListenable.value = Duration.zero;
    return _guard(_playGeneration, _player.seekToNext, played: _current);
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

  Future<void> _guard(
    int generation,
    Future<void> Function() action, {
    Song? played,
  }) async {
    try {
      await action();
    } on PlayerInterruptedException {
      return;
    } catch (error) {
      if (generation != _playGeneration) return;
      _setError(_playbackMessage(error), offerPhoneScan: _isPhoneTrack(played));
    }
  }

  Song? _playingSong() {
    final index = _player.currentIndex;
    if (index != null && index >= 0 && index < _queue.length) {
      return _queue[index];
    }
    return _current;
  }

  bool _isPhoneTrack(Song? song) =>
      song != null && song.id.startsWith('phone:');

  void _onPlayerState(PlayerState state) {
    if (state.playing == _playing && state.processingState == _processing) {
      return;
    }
    _playing = state.playing;
    _processing = state.processingState;
    _notify();
  }

  void _onIndex(int? index) {
    if (_holdingIndex) return;
    if (index == null || index < 0 || index >= _queue.length) return;
    final song = _queue[index];
    final changed = index != _currentIndex || _current?.id != song.id;
    _currentIndex = index;
    _current = song;
    _markNowPlaying(song);
    if (changed) {
      _musicOnly = false;
      unawaited(_resolveSibling(song));
      _notify();
    }
  }

  Future<void> _resolveSibling(Song song) async {
    final ticket = ++_siblingTicket;
    if (_siblings.containsKey(song.id)) {
      _counterpart = _siblings[song.id];
      if (ticket == _siblingTicket) _notify();
      return;
    }
    _counterpart = null;
    _notify();
    final found = await _findSibling(song);
    if (_disposed || ticket != _siblingTicket || _current?.id != song.id) {
      return;
    }
    _siblings[song.id] = found;
    if (found != null) _siblings[found.id] = song;
    _counterpart = found;
    _notify();
  }

  Future<Song?> _findSibling(Song song) async {
    final wanted = musicOnlySiblingPath(song.path);
    if (wanted == null) return null;
    final local = _library?.songForPath(wanted);
    if (local != null) return local;
    final client = _client;
    if (client == null) return null;
    final albumId = song.albumId;
    if (albumId != null && albumId.isNotEmpty) {
      try {
        final album = await client.getAlbum(albumId);
        final match = songWithPath(album.songs, wanted);
        if (match != null) return match;
      } on SubsonicException {
        // The album may be unreachable. The search below is the other look-up.
      }
    }
    final stem = _searchStem(wanted);
    if (stem.isEmpty) return null;
    try {
      final result = await client.search(stem);
      return songWithPath(result.songs, wanted);
    } on SubsonicException {
      return null;
    }
  }

  String _searchStem(String path) {
    final slash = path.lastIndexOf(RegExp(r'[\\/]'));
    final name = slash < 0 ? path : path.substring(slash + 1);
    final lower = name.toLowerCase();
    final stem = lower.endsWith('.mp3')
        ? name.substring(0, name.length - 4)
        : name;
    const marker = '-music';
    if (stem.toLowerCase().endsWith(marker)) {
      return stem.substring(0, stem.length - marker.length).trim();
    }
    return stem.trim();
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
    if (id.startsWith('phone:')) return;
    if (_client == null || _library?.playFromDownloadsOnly == true) {
      _library?.queueScrobble(id, submission: submission);
      return;
    }
    _client?.scrobble(id, submission: submission);
  }

  void _setError(String message, {bool offerPhoneScan = false}) {
    _error = message;
    _offerPhoneScan = offerPhoneScan;
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
