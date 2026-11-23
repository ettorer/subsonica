import 'package:flutter_test/flutter_test.dart';
import 'package:subsonica/models/library.dart';
import 'package:subsonica/util/album_letter_scan.dart';
import 'package:subsonica/util/library_letter.dart';

Album _album(String name) {
  return Album(id: name, name: name, artist: 'Someone');
}

void main() {
  test('library letters keep A to Z and fold accents', () {
    expect(libraryLetter('Abbey Road'), 'A');
    expect(libraryLetter('  éclat'), 'E');
    expect(libraryLetter('1979'), '#');
    expect(libraryLetter(''), '#');
    expect(firstLibraryLetter(['10cc', 'Miles', 'Abbey Road']), '#');
    expect(firstLibraryLetter(['Miles', 'Abbey Road']), 'A');
    expect(libraryLetterRank('A'), 1);
    expect(libraryLetterRank('#'), 0);
  });

  test('an alphabetical scan stops once the letter is passed', () {
    final scan = AlbumLetterScan();
    scan.add([
      _album('10cc'),
      _album('Abbey Road'),
      _album('Animals'),
    ], pageSize: 3);
    expect(scan.covers('#'), isTrue);
    expect(scan.matching('#').map((album) => album.name), ['10cc']);
    expect(scan.covers('A'), isFalse);

    scan.add([_album('Arrival'), _album('Blue')], pageSize: 2);
    expect(scan.covers('A'), isTrue);
    expect(scan.matching('A').map((album) => album.name), [
      'Abbey Road',
      'Animals',
      'Arrival',
    ]);
    expect(scan.covers('B'), isFalse);

    scan.add([_album('Bridge')], pageSize: 2);
    expect(scan.complete, isTrue);
    expect(scan.covers('Z'), isTrue);
    expect(scan.matching('Z'), isEmpty);
  });
}
