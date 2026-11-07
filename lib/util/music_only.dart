import '../models/library.dart';

const _musicSuffix = '-music.mp3';
const _vocalsSuffix = '-vocals.mp3';

bool isMusicOnlyPath(String? path) {
  final name = _fileName(path);
  if (name == null) return false;
  return name.toLowerCase().endsWith(_musicSuffix);
}

bool isHiddenTrackPath(String? path) {
  final name = _fileName(path)?.toLowerCase();
  if (name == null) return false;
  return name.endsWith(_musicSuffix) || name.endsWith(_vocalsSuffix);
}

String? musicOnlySiblingPath(String? path) {
  final name = _fileName(path);
  if (name == null) return null;
  final lower = name.toLowerCase();
  if (!lower.endsWith('.mp3') || lower.endsWith(_vocalsSuffix)) return null;
  final folder = _folder(path!);
  final stem = name.substring(0, name.length - 4);
  if (lower.endsWith(_musicSuffix)) {
    final vocal = stem.substring(0, stem.length - '-music'.length);
    if (vocal.isEmpty) return null;
    return '$folder$vocal.mp3';
  }
  return '$folder$stem$_musicSuffix';
}

List<Song> withoutMusicOnly(Iterable<Song> songs) {
  return [
    for (final song in songs)
      if (!isHiddenTrackPath(song.path)) song,
  ];
}

Song? songWithPath(Iterable<Song> songs, String path) {
  final wanted = path.toLowerCase();
  for (final song in songs) {
    final file = song.path;
    if (file != null && file.toLowerCase() == wanted) return song;
  }
  return null;
}

String? _fileName(String? path) {
  if (path == null) return null;
  final trimmed = path.trim();
  if (trimmed.isEmpty) return null;
  final slash = trimmed.lastIndexOf(RegExp(r'[\\/]'));
  final name = slash < 0 ? trimmed : trimmed.substring(slash + 1);
  return name.isEmpty ? null : name;
}

String _folder(String path) {
  final slash = path.lastIndexOf(RegExp(r'[\\/]'));
  if (slash < 0) return '';
  return path.substring(0, slash + 1);
}
