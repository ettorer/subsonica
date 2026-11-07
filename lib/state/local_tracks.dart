abstract class LocalTracks {
  String? audioPath(String songId);

  String? coverFile(String? coverId);

  bool get playFromDownloadsOnly;

  void queueScrobble(String songId, {required bool submission});
}
