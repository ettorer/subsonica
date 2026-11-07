import 'package:flutter/foundation.dart';

import '../models/library.dart';

class FavoriteUpdates extends ChangeNotifier {
  var generation = 0;
  final Map<String, bool> _starred = {};

  bool starredFor(Song song) => _starred[song.id] ?? song.starred;

  void setStarred(String id, bool starred) {
    _starred[id] = starred;
    generation++;
    notifyListeners();
  }
}
