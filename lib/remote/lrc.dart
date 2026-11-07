class LyricLine {
  const LyricLine(this.timeMs, this.text);

  final int timeMs;
  final String text;
}

final _stamp = RegExp(r'\[(\d+):(\d{1,2})(?:[.:](\d{1,3}))?\]');

List<LyricLine> parseLrc(String lrc) {
  final lines = <LyricLine>[];
  for (final raw in lrc.split(RegExp(r'\r?\n'))) {
    final stamps = _stamp.allMatches(raw).toList();
    if (stamps.isEmpty) continue;
    final text = raw.substring(stamps.last.end).trim();
    if (text.isEmpty) continue;
    for (final stamp in stamps) {
      final minutes = int.parse(stamp.group(1)!);
      final seconds = int.parse(stamp.group(2)!);
      lines.add(LyricLine(_timeMs(minutes, seconds, stamp.group(3)), text));
    }
  }
  lines.sort((a, b) => a.timeMs.compareTo(b.timeMs));
  return lines;
}

int _timeMs(int minutes, int seconds, String? fraction) {
  return ((minutes * 60) + seconds) * 1000 + _fractionMs(fraction);
}

int _fractionMs(String? fraction) {
  if (fraction == null || fraction.isEmpty) return 0;
  if (fraction.length == 1) return int.parse(fraction) * 100;
  if (fraction.length == 2) return int.parse(fraction) * 10;
  return int.parse(fraction.substring(0, 3));
}
