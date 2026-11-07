class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumId,
    this.coverArt,
    this.track,
    this.disc,
    this.duration = 0,
    this.starred = false,
    this.userRating = 0,
    this.path,
    this.genre,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String? albumId;
  final String? coverArt;
  final int? track;
  final int? disc;
  final int duration;
  final bool starred;
  final int userRating;
  final String? path;
  final String? genre;

  String? get artworkId {
    final cover = coverArt;
    if (cover != null && cover.isNotEmpty) return cover;
    final albumCover = albumId;
    if (albumCover != null && albumCover.isNotEmpty) return albumCover;
    return null;
  }
}

class Album {
  const Album({
    required this.id,
    required this.name,
    required this.artist,
    this.artistId,
    this.coverArt,
    this.songCount = 0,
    this.year,
    this.songs = const [],
    this.userRating = 0,
  });

  final String id;
  final String name;
  final String artist;
  final String? artistId;
  final String? coverArt;
  final int songCount;
  final int? year;
  final List<Song> songs;
  final int userRating;

  String get artworkId {
    final cover = coverArt;
    if (cover != null && cover.isNotEmpty) return cover;
    return id;
  }

  String get subtitle {
    final release = year;
    if (release == null) return artist;
    return '$artist · $release';
  }
}

class Artist {
  const Artist({
    required this.id,
    required this.name,
    this.albumCount = 0,
    this.coverArt,
    this.albums = const [],
  });

  final String id;
  final String name;
  final int albumCount;
  final String? coverArt;
  final List<Album> albums;
}

class ArtistSection {
  const ArtistSection({required this.letter, required this.artists});

  final String letter;
  final List<Artist> artists;
}

class Genre {
  const Genre({required this.name, this.songCount = 0, this.albumCount = 0});

  final String name;
  final int songCount;
  final int albumCount;
}

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.coverArt,
    this.owner = '',
    this.songCount = 0,
    this.songs = const [],
  });

  final String id;
  final String name;
  final String? coverArt;
  final String owner;
  final int songCount;
  final List<Song> songs;

  String get artworkId {
    final cover = coverArt;
    if (cover != null && cover.isNotEmpty) return cover;
    return id;
  }
}

class Favorites {
  const Favorites({
    this.artists = const [],
    this.albums = const [],
    this.songs = const [],
  });

  final List<Artist> artists;
  final List<Album> albums;
  final List<Song> songs;

  bool get isEmpty => artists.isEmpty && albums.isEmpty && songs.isEmpty;
}

class SearchResult {
  const SearchResult({
    this.artists = const [],
    this.albums = const [],
    this.songs = const [],
  });

  final List<Artist> artists;
  final List<Album> albums;
  final List<Song> songs;

  bool get isEmpty => artists.isEmpty && albums.isEmpty && songs.isEmpty;
}
