import 'package:flutter_test/flutter_test.dart';
import 'package:subsonica/models/library.dart';
import 'package:subsonica/util/music_only.dart';

void main() {
  test('a music-only mp3 is hidden and points back at the vocal file', () {
    const vocal = 'Porcupine Tree/Deadwing/Halo.mp3';
    const music = 'Porcupine Tree/Deadwing/Halo-music.mp3';
    expect(isMusicOnlyPath(vocal), isFalse);
    expect(isMusicOnlyPath(music), isTrue);
    expect(isMusicOnlyPath(r'C:\Music\Halo-Music.mp3'), isTrue);
    expect(musicOnlySiblingPath(vocal), music);
    expect(musicOnlySiblingPath(music), 'Porcupine Tree/Deadwing/Halo.mp3');
    expect(musicOnlySiblingPath('Halo.flac'), isNull);
    expect(isHiddenTrackPath('Deadwing/Halo-vocals.mp3'), isTrue);
    expect(musicOnlySiblingPath('Deadwing/Halo-vocals.mp3'), isNull);
  });

  test('album and search lists drop the music-only file', () {
    const vocal = Song(
      id: 'vocal',
      title: 'Halo',
      artist: 'Porcupine Tree',
      album: 'Deadwing',
      path: 'Deadwing/Halo.mp3',
    );
    const music = Song(
      id: 'music',
      title: 'Halo',
      artist: 'Porcupine Tree',
      album: 'Deadwing',
      path: 'Deadwing/Halo-music.mp3',
    );
    const stems = Song(
      id: 'stems',
      title: 'Halo',
      artist: 'Porcupine Tree',
      album: 'Deadwing',
      path: 'Deadwing/Halo-vocals.mp3',
    );
    final visible = withoutMusicOnly(const [vocal, music, stems]);
    expect(visible.map((song) => song.id), ['vocal']);
    expect(
      songWithPath(const [vocal, music], 'deadwing/halo-music.mp3')?.id,
      'music',
    );
  });
}
