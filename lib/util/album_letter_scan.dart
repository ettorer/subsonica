import '../models/library.dart';
import 'library_letter.dart';

/// Albums loaded in alphabetical order, from the start of the library.
class AlbumLetterScan {
  final loaded = <Album>[];
  var complete = false;

  /// True when every album for [letter] is already in [loaded].
  bool covers(String letter) {
    if (complete) return true;
    if (loaded.isEmpty) return false;
    final last = libraryLetterRank(libraryLetter(loaded.last.name));
    return last > libraryLetterRank(letter);
  }

  List<Album> matching(String letter) {
    return [
      for (final album in loaded)
        if (libraryLetter(album.name) == letter) album,
    ];
  }

  void add(List<Album> page, {required int pageSize}) {
    loaded.addAll(page);
    if (page.length < pageSize) complete = true;
  }
}
