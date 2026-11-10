import 'package:flutter_test/flutter_test.dart';

import 'package:subsonica/models/library.dart';
import 'package:subsonica/services/local_artists.dart';

void main() {
  test('groups saved albums by artist and letter', () {
    final artists = artistsFromAlbums([
      _album('b', 'Halo', 'Artist'),
      _album('a', 'Other', 'artist'),
      _album('c', 'Live', 'Second'),
      _album('d', '12', '2 Live Crew'),
    ]);
    expect(artists.map((artist) => artist.name), [
      '2 Live Crew',
      'Artist',
      'Second',
    ]);
    expect(artists[1].albumCount, 2);
    expect(artists[1].albums.map((album) => album.name), ['Halo', 'Other']);
    expect(artists[1].id, 'local-artist:artist');

    final sections = artistSections(artists);
    expect(sections.map((section) => section.letter), ['A', 'S', '#']);
    expect(sections.last.artists.single.name, '2 Live Crew');
  });
}

Album _album(String id, String name, String artist) {
  return Album(id: id, name: name, artist: artist, songCount: 1);
}
