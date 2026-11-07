import 'dart:async';

import 'package:flutter_lyric/flutter_lyric.dart';

import 'player_controller.dart';

class PlayerLyricProgress implements LyricProgressSource {
  PlayerLyricProgress(this._player) {
    _player.addListener(_emit);
    _player.positionListenable.addListener(_emit);
  }

  final PlayerController _player;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  var _closed = false;

  void _emit() {
    if (_closed) return;
    _changes.add(null);
  }

  @override
  Duration get position => _player.positionListenable.value;

  @override
  bool get isAdvancing => _player.playing && !_player.buffering;

  @override
  Stream<void> get changes => _changes.stream;

  void dispose() {
    if (_closed) return;
    _closed = true;
    _player.removeListener(_emit);
    _player.positionListenable.removeListener(_emit);
    _changes.close();
  }
}
