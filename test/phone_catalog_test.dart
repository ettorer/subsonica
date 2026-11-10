import 'package:flutter_test/flutter_test.dart';

import 'package:subsonica/models/library.dart';
import 'package:subsonica/services/phone_catalog.dart';

void main() {
  test('groups phone tracks and hides the music-only file', () {
    final tracks = [
      _track('phone:1', 'Halo', '/Music/Halo/Halo.mp3', 1),
      _track('phone:2', 'Halo', '/Music/Halo/Halo-music.mp3', 2),
      _track('phone:3', 'Other', '/Music/Halo/Other.mp3', 3),
    ];
    final albums = albumsFromPhoneTracks(tracks);
    expect(albums, hasLength(1));
    expect(albums.single.songCount, 2);
    expect(albums.single.songs.map((song) => song.id), ['phone:1', 'phone:3']);
    expect(visiblePhoneTracks(tracks).map((song) => song.id), [
      'phone:1',
      'phone:3',
    ]);
  });
}

PhoneTrack _track(String id, String album, String path, int track) {
  return PhoneTrack(
    playUri: 'content://media/external/audio/media/$track',
    song: Song(
      id: id,
      title: path.split('/').last,
      artist: 'Artist',
      album: album,
      albumId: 'phone-album:9',
      track: track,
      duration: 10,
      path: path,
    ),
  );
}
