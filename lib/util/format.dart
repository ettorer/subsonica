import '../l10n/app_localizations.dart';

String formatClock(Duration duration) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final hours = clamped.inHours;
  final minutes = clamped.inMinutes.remainder(60);
  final seconds = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}

String formatTrackCount(AppLocalizations l10n, int count) =>
    l10n.trackCount(count);

String formatAlbumCount(AppLocalizations l10n, int count) =>
    l10n.albumCount(count);

String formatByteSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value >= 10 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}
