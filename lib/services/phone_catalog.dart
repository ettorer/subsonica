import '../models/library.dart';
import '../util/music_only.dart';

class PhoneTrack {
  const PhoneTrack({
    required this.song,
    required this.playUri,
    this.lyricsJson,
  });

  final Song song;
  final String playUri;
  final String? lyricsJson;
}

List<Album> albumsFromPhoneTracks(Iterable<PhoneTrack> tracks) {
  final grouped = <String, List<Song>>{};
  for (final item in tracks) {
    final song = item.song;
    if (isHiddenTrackPath(song.path)) continue;
    final albumId = song.albumId;
    if (albumId == null || albumId.isEmpty) continue;
    grouped.putIfAbsent(albumId, () => []).add(song);
  }
  final albums = <Album>[];
  for (final songs in grouped.values) {
    songs.sort((a, b) {
      final disc = (a.disc ?? 1).compareTo(b.disc ?? 1);
      if (disc != 0) return disc;
      return (a.track ?? 0).compareTo(b.track ?? 0);
    });
    final song = songs.first;
    albums.add(
      Album(
        id: song.albumId!,
        name: song.album.isEmpty ? 'Unknown album' : song.album,
        artist: song.artist,
        coverArt: song.coverArt ?? song.albumId,
        songCount: songs.length,
        songs: songs,
      ),
    );
  }
  albums.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return albums;
}

List<Song> visiblePhoneTracks(Iterable<PhoneTrack> tracks) {
  final songs = [
    for (final item in tracks)
      if (!isHiddenTrackPath(item.song.path)) item.song,
  ];
  songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  return songs;
}
