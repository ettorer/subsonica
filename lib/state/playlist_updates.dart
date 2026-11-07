import 'package:flutter/foundation.dart';

class PlaylistUpdates extends ChangeNotifier {
  var generation = 0;

  void notifyChanged() {
    generation++;
    notifyListeners();
  }
}
