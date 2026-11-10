import '../models/library.dart';

List<Artist> artistsFromAlbums(Iterable<Album> albums) {
  final grouped = <String, List<Album>>{};
  final names = <String, String>{};
  for (final album in albums) {
    final name = album.artist.trim().isEmpty
        ? 'Unknown artist'
        : album.artist.trim();
    final key = name.toLowerCase();
    names.putIfAbsent(key, () => name);
    grouped.putIfAbsent(key, () => []).add(album);
  }
  final artists = <Artist>[];
  for (final entry in grouped.entries) {
    final list = [...entry.value]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    artists.add(
      Artist(
        id: 'local-artist:${entry.key}',
        name: names[entry.key]!,
        albumCount: list.length,
        coverArt: list.first.coverArt,
        albums: list,
      ),
    );
  }
  artists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return artists;
}

List<ArtistSection> artistSections(Iterable<Artist> artists) {
  final grouped = <String, List<Artist>>{};
  for (final artist in artists) {
    grouped.putIfAbsent(artistLetter(artist.name), () => []).add(artist);
  }
  final letters = grouped.keys.toList()
    ..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
  return [
    for (final letter in letters)
      ArtistSection(letter: letter, artists: grouped[letter]!),
  ];
}

String artistLetter(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '#';
  final first = String.fromCharCode(trimmed.runes.first).toUpperCase();
  if (RegExp(r'^\p{L}', unicode: true).hasMatch(first)) return first;
  return '#';
}
