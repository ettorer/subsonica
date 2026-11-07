import 'library.dart';

enum DownloadStatus { queued, downloading, complete, failed }

class DownloadEntry {
  const DownloadEntry({
    required this.song,
    required this.status,
    this.filePath,
    this.byteSize = 0,
    this.received = 0,
    this.total,
    this.error,
  });

  final Song song;
  final DownloadStatus status;
  final String? filePath;
  final int byteSize;
  final int received;
  final int? total;
  final String? error;

  bool get isComplete => status == DownloadStatus.complete;

  DownloadEntry copyWith({
    DownloadStatus? status,
    String? filePath,
    int? byteSize,
    int? received,
    int? total,
    String? error,
    bool clearError = false,
  }) {
    return DownloadEntry(
      song: song,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      byteSize: byteSize ?? this.byteSize,
      received: received ?? this.received,
      total: total ?? this.total,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PendingScrobble {
  const PendingScrobble({
    required this.id,
    required this.songId,
    required this.submission,
    required this.atMs,
  });

  final int id;
  final String songId;
  final bool submission;
  final int atMs;
}
