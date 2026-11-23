import 'package:flutter_test/flutter_test.dart';
import 'package:subsonica/models/library.dart';
import 'package:subsonica/models/playback_resume.dart';

Song _song(String id) {
  return Song(id: id, title: id, artist: 'Artist', album: 'Album');
}

void main() {
  test('a saved queue round-trips the current song and position', () {
    final resume = PlaybackResume(
      songs: [_song('a'), _song('b')],
      currentIndex: 1,
      position: const Duration(milliseconds: 3200),
      savedAt: DateTime.fromMillisecondsSinceEpoch(50),
      queueTitle: 'Abbey Road',
    );
    final decoded = PlaybackResume.decode(resume.encode());
    expect(decoded, isNotNull);
    expect(decoded!.songs.map((song) => song.id), ['a', 'b']);
    expect(decoded.current.id, 'b');
    expect(decoded.position, const Duration(milliseconds: 3200));
    expect(decoded.queueTitle, 'Abbey Road');
    expect(decoded.savedAt.millisecondsSinceEpoch, 50);
  });

  test('a clearly newer copy wins and a close one keeps the browser name', () {
    final browser = PlaybackResume(
      songs: [_song('browser')],
      currentIndex: 0,
      position: const Duration(seconds: 4),
      savedAt: DateTime.fromMillisecondsSinceEpoch(20000),
      queueTitle: 'Playlist',
    );
    final justAfter = PlaybackResume(
      songs: [_song('server')],
      currentIndex: 0,
      position: const Duration(seconds: 4),
      savedAt: DateTime.fromMillisecondsSinceEpoch(21000),
    );
    final muchLater = PlaybackResume(
      songs: [_song('server')],
      currentIndex: 0,
      position: const Duration(seconds: 9),
      savedAt: DateTime.fromMillisecondsSinceEpoch(30000),
    );
    expect(preferPlaybackResume(browser, justAfter)!.queueTitle, 'Playlist');
    expect(preferPlaybackResume(browser, muchLater)!.current.id, 'server');
    expect(preferPlaybackResume(browser, browser)!.queueTitle, 'Playlist');
    expect(preferPlaybackResume(null, muchLater)!.current.id, 'server');
  });
}
