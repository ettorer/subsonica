import 'package:flutter/foundation.dart';

import '../models/library.dart';

class RatingUpdates extends ChangeNotifier {
  final Map<String, int> _songs = {};
  final Map<String, int> _albums = {};

  int songRating(Song song) {
    return _songs[song.id] ?? _clamp(song.userRating);
  }

  int albumRating(String albumId, int fallback) {
    return _albums[albumId] ?? _clamp(fallback);
  }

  void setSong(String id, int rating) {
    _songs[id] = _clamp(rating);
    notifyListeners();
  }

  void setAlbum(String id, int rating) {
    _albums[id] = _clamp(rating);
    notifyListeners();
  }

  int _clamp(int rating) {
    if (rating < 0) return 0;
    if (rating > 5) return 5;
    return rating;
  }
}
