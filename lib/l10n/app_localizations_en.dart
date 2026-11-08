// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get localeAutomatic => 'Automatic';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get logOut => 'Log out';

  @override
  String get offlineLabel => 'Offline';

  @override
  String get offlineMode => 'Offline mode';

  @override
  String get offlineModeDetail => 'Play music saved on this phone';

  @override
  String get karaoke => 'Karaoke';

  @override
  String get karaokeDetail =>
      'Show the playing lyrics in a browser on this network.';

  @override
  String get karaokeOpen => 'Open this address in the browser.';

  @override
  String get karaokeNoAddress =>
      'Connect this phone to Wi-Fi, then turn Karaoke off and on.';

  @override
  String get karaokeFailed => 'The karaoke server could not start.';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String onThisPhone(String size) {
    return '$size on this phone';
  }

  @override
  String get connectionsTitle => 'Connections';

  @override
  String get addConnection => 'Add connection';

  @override
  String connectedProfile(String url) {
    return '$url · Connected';
  }

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try again';

  @override
  String get show => 'Show';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get musicOnly => 'Music only';

  @override
  String get withVocals => 'With vocals';

  @override
  String get playQueue => 'Play queue';

  @override
  String get options => 'Options';

  @override
  String get nothingPlaying => 'Nothing is playing';

  @override
  String get previousTrack => 'Previous track';

  @override
  String get nextTrack => 'Next track';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get shuffleOn => 'Shuffle on';

  @override
  String get loopOff => 'Loop off';

  @override
  String get loopAlbum => 'Loop album or playlist';

  @override
  String get loopTrack => 'Loop this track';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get speed => 'Speed';

  @override
  String get startRadio => 'Start radio';

  @override
  String get radioDetail => 'Similar songs play after this track';

  @override
  String get radioOffline => 'Unavailable while offline';

  @override
  String get radioEmpty => 'This server has no similar songs for this track.';

  @override
  String get radio => 'Radio';

  @override
  String get rating => 'Rating';

  @override
  String get connectToRate => 'Connect to set a rating.';

  @override
  String get listenOffline => 'Listen offline';

  @override
  String get connect => 'Connect';

  @override
  String get signIn => 'Sign in';

  @override
  String get connectionSaved => 'Connection saved';

  @override
  String get profileName => 'Profile name';

  @override
  String get profileNameHint => 'Home';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get newConnection => 'New connection';

  @override
  String get connection => 'Connection';

  @override
  String get deleteProfile => 'Delete profile';

  @override
  String get deleteProfileTitle => 'Delete profile?';

  @override
  String deleteProfileBody(String name) {
    return 'Delete $name? This phone will forget that server.';
  }

  @override
  String get enterProfileName => 'Enter a profile name.';

  @override
  String get enterServerAddress =>
      'Enter a server address like http://192.168.1.20:4533.';

  @override
  String get enterUsername => 'Enter the username.';

  @override
  String get serverAddressHelp =>
      'Use the address this phone can reach, such as https://subsonica.mydomain.org.';

  @override
  String get profileMissing => 'That profile is no longer saved.';

  @override
  String get profileLabel => 'Profile';

  @override
  String get playYourLibrary => 'Play your Navidrome library';

  @override
  String get search => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get serverConnection => 'Server connection';

  @override
  String get tabHome => 'Home';

  @override
  String get tabAlbum => 'Album';

  @override
  String get tabTrack => 'Track';

  @override
  String get tabArtist => 'Artist';

  @override
  String get tabGenre => 'Genre';

  @override
  String get tabPlaylist => 'Playlist';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get noDownloads => 'No downloads';

  @override
  String get noDownloadsDetail =>
      'Download a track or an album and it will be listed here.';

  @override
  String get playAll => 'Play all';

  @override
  String get randomPlay => 'Random play';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get deleteAllDownloadsTitle => 'Delete all downloads?';

  @override
  String get deleteAllDownloadsBody =>
      'Delete every download from this phone? The tracks stay in the library.';

  @override
  String get removeDownloadTitle => 'Remove download?';

  @override
  String removeDownloadBody(String title) {
    return 'Remove $title from this phone? The track stays in the library.';
  }

  @override
  String get removeDownload => 'Remove download';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get waiting => 'Waiting';

  @override
  String get noLyricsFound => 'No lyrics found';

  @override
  String get instrumental => 'This track is instrumental.';

  @override
  String get lyricsUnavailable => 'Lyrics are unavailable right now.';

  @override
  String get couldNotLoadTracks => 'Could not load tracks';

  @override
  String get noTracks => 'No tracks';

  @override
  String removedSong(String title) {
    return 'Removed $title';
  }

  @override
  String get albumAlreadyDownloaded => 'This album is already downloaded.';

  @override
  String get downloadWhenReachable =>
      'The download will start when the server is reachable.';

  @override
  String downloadingTracks(String count) {
    return 'Downloading $count';
  }

  @override
  String get connectToOpen => 'Connect to a server to open this.';

  @override
  String get downloadAlbum => 'Download album';

  @override
  String get removeAlbumDownloadBody =>
      'The tracks stay in the library. Only the copy on this phone is removed.';

  @override
  String get stop => 'Stop';

  @override
  String get random => 'Random';

  @override
  String get favoriteAlbum => 'Favorite album';

  @override
  String get unfavoriteAlbum => 'Remove album from favorites';

  @override
  String get favoritePlaylist => 'Favorite playlist';

  @override
  String get unfavoritePlaylist => 'Remove playlist from favorites';

  @override
  String get noAlbumPage => 'This track has no album page.';

  @override
  String get trackOptions => 'Track options';

  @override
  String get unfavorite => 'Remove from favorites';

  @override
  String get favorite => 'Favorite';

  @override
  String get addToQueue => 'Add to play queue';

  @override
  String get showAlbum => 'Show album page';

  @override
  String get cancelDownload => 'Cancel download';

  @override
  String get download => 'Download';

  @override
  String get connectToDownload => 'Connect to download tracks.';

  @override
  String get trackAlreadyDownloaded => 'This track is already downloaded.';

  @override
  String get downloading => 'Downloading';

  @override
  String get noDownloadedAlbums => 'No downloaded albums';

  @override
  String get noDownloadedAlbumsDetail =>
      'Albums you download appear here when the server is offline.';

  @override
  String get noDownloadedTracks => 'No downloaded tracks';

  @override
  String get noDownloadedTracksDetail =>
      'Tracks you download can play with the server disconnected.';

  @override
  String get artistNoTracks => 'This artist has no tracks.';

  @override
  String get loadingTracks => 'Loading tracks';

  @override
  String get artistOptions => 'Artist options';

  @override
  String get artistUnavailable => 'Artist unavailable';

  @override
  String get noAlbums => 'No albums';

  @override
  String get noRecentAlbums => 'No recent albums';

  @override
  String get noRecentAlbumsDetail => 'Albums show up here after you play them.';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String addedToName(String name) {
    return 'Added to $name';
  }

  @override
  String addedTracksToName(int count, String name) {
    return 'Added $count tracks to $name';
  }

  @override
  String playlistOwnerOnly(String owner) {
    return 'Only $owner can add tracks to this playlist.';
  }

  @override
  String get playlistReadOnly =>
      'Navidrome is not allowing changes to this playlist. Smart playlists and auto-imported lists stay read-only.';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get create => 'Create';

  @override
  String get createPlaylist => 'Create new playlist';

  @override
  String get queueEmpty => 'The play queue is empty';

  @override
  String get addedToQueue => 'Added to the play queue';

  @override
  String addedTracksToQueue(int count) {
    return 'Added $count tracks to the play queue';
  }

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get noResults => 'No results';

  @override
  String get artists => 'Artists';

  @override
  String get albums => 'Albums';

  @override
  String get tracks => 'Tracks';

  @override
  String discNumber(int number) {
    return 'Disc $number';
  }

  @override
  String get genresUnavailable => 'Genres unavailable';

  @override
  String get noGenres => 'No genres';

  @override
  String get noGenreTags => 'Tracks in this library have no genre tags yet.';

  @override
  String get artistsUnavailable => 'Artists unavailable';

  @override
  String get noArtists => 'No artists';

  @override
  String get noArtistsYet => 'This library does not have any artists yet.';

  @override
  String get albumsUnavailable => 'Albums unavailable';

  @override
  String get noAlbumsYet => 'This library does not have any albums yet.';

  @override
  String get tracksUnavailable => 'Tracks unavailable';

  @override
  String get tracksSample =>
      'A sample from the library. Search to find a specific track.';

  @override
  String get noSongsYet => 'This library does not have any songs yet.';

  @override
  String get favoritesUnavailable => 'Favorites unavailable';

  @override
  String get noFavorites => 'No favorites';

  @override
  String get noFavoritesDetail =>
      'Albums, artists, and tracks you mark with a heart in Navidrome show up here.';

  @override
  String get playlistsUnavailable => 'Playlists unavailable';

  @override
  String get noPlaylists => 'No playlists';

  @override
  String get noPlaylistsDetail =>
      'Playlists you create on Navidrome show up here.';

  @override
  String get rename => 'Rename';

  @override
  String createdPlaylist(String name) {
    return 'Created $name';
  }

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String renamedPlaylist(String name) {
    return 'Renamed to $name';
  }

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String deletePlaylistBody(String name) {
    return 'Delete $name? The tracks stay in the library.';
  }

  @override
  String deletedPlaylist(String name) {
    return 'Deleted $name';
  }

  @override
  String get playlistName => 'Playlist name';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get serverTimeout => 'The server took too long to respond.';

  @override
  String get secureConnectionFailed => 'The secure connection failed.';

  @override
  String get cannotReachServer => 'Cannot reach the server. Check the address.';

  @override
  String get notSubsonic =>
      'The server did not return a Subsonic response. Check the address.';

  @override
  String get somethingWentWrong => 'Something went wrong. Try again.';

  @override
  String get serverRejected => 'The server rejected the request.';

  @override
  String get albumNotFound => 'Album not found.';

  @override
  String get artistNotFound => 'Artist not found.';

  @override
  String get playlistNotFound => 'Playlist not found.';

  @override
  String get serverNoFile => 'The server did not return the file.';

  @override
  String serverHttp(int code) {
    return 'The server returned HTTP $code.';
  }

  @override
  String get noTracksToPlay => 'There are no tracks to play.';

  @override
  String get downloadToPlayOffline =>
      'Download these tracks to play them offline.';

  @override
  String get playbackFailed =>
      'Playback failed. Check the server and the track file.';

  @override
  String get downloadedFileMissing => 'The downloaded file is missing.';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String get untitledPlaylist => 'Untitled playlist';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }
}
