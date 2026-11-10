import 'package:flutter/widgets.dart';

import '../services/phone_scan_result.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String localizeMessage(AppLocalizations l10n, String message) {
  final http = RegExp(r'^The server returned HTTP (\d+)\.$')
      .firstMatch(message);
  if (http != null) {
    return l10n.serverHttp(int.parse(http.group(1)!));
  }
  return switch (message) {
    'The server took too long to respond.' => l10n.serverTimeout,
    'The secure connection failed.' => l10n.secureConnectionFailed,
    'Cannot reach the server. Check the address.' => l10n.cannotReachServer,
    'The server did not return a Subsonic response. Check the address.' =>
      l10n.notSubsonic,
    'Something went wrong. Try again.' => l10n.somethingWentWrong,
    'The server rejected the request.' => l10n.serverRejected,
    'Album not found.' => l10n.albumNotFound,
    'Artist not found.' => l10n.artistNotFound,
    'Playlist not found.' => l10n.playlistNotFound,
    'The server did not return the file.' => l10n.serverNoFile,
    'There are no tracks to play.' => l10n.noTracksToPlay,
    'Download these tracks to play them offline.' => l10n.downloadToPlayOffline,
    'Playback failed. Check the server and the track file.' =>
      l10n.playbackFailed,
    'The downloaded file is missing.' => l10n.downloadedFileMissing,
    'Enter a profile name.' => l10n.enterProfileName,
    'Enter a server address like http://192.168.1.20:4533.' =>
      l10n.enterServerAddress,
    'Enter the username.' => l10n.enterUsername,
    'That profile is no longer saved.' => l10n.profileMissing,
    'Lyrics are unavailable right now.' => l10n.lyricsUnavailable,
    'No lyrics found' => l10n.noLyricsFound,
    'This track is instrumental.' => l10n.instrumental,
    'Download failed' => l10n.downloadFailed,
    'Waiting' => l10n.waiting,
    _ => message,
  };
}

String phoneScanStatusMessage(AppLocalizations l10n, PhoneScanResult result) {
  return switch (result.status) {
    PhoneScanStatus.found => l10n.phoneMusicFound(result.tracks),
    PhoneScanStatus.empty => l10n.phoneMusicEmpty,
    PhoneScanStatus.denied => l10n.phoneMusicDenied,
    PhoneScanStatus.failed => l10n.phoneMusicFailed,
  };
}

String queueLabel(AppLocalizations l10n, String title) {
  return switch (title) {
    '' || 'Play queue' => l10n.playQueue,
    'Downloads' => l10n.downloadsTitle,
    'Favorites' => l10n.tabFavorites,
    'Tracks' => l10n.tracks,
    'Search' => l10n.search,
    'Radio' => l10n.radio,
    _ => title,
  };
}

String displayName(AppLocalizations l10n, String value) {
  return switch (value) {
    'Unknown artist' => l10n.unknownArtist,
    'Unknown album' => l10n.unknownAlbum,
    'Untitled playlist' => l10n.untitledPlaylist,
    _ => value,
  };
}
