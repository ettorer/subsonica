import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:subsonica/services/id3_lyrics.dart';

void main() {
  test('reads plain USLT lyrics from an ID3v2.3 tag', () {
    final lyrics = embeddedLyrics(_tag(3, _uslt('Line one\nLine two')));
    expect(lyrics?.synced, isFalse);
    expect(lyrics?.text, 'Line one\nLine two');
  });

  test('reads millisecond SYLT lyrics as LRC', () {
    final lyrics = embeddedLyrics(_tag(4, _sylt()));
    expect(lyrics?.synced, isTrue);
    expect(lyrics?.text, contains('[00:01.50]Halo'));
    expect(lyrics?.text, contains('[00:04.00]World'));
  });

  test('prefers synced lyrics over a plain frame', () {
    final lyrics = embeddedLyrics(_tag(3, [..._uslt('plain'), ..._sylt()]));
    expect(lyrics?.synced, isTrue);
    expect(lyrics?.text, contains('Halo'));
  });
}

Uint8List _tag(int major, List<int> frames) {
  return Uint8List.fromList([
    ...'ID3'.codeUnits,
    major,
    0,
    0,
    ..._synchsafe(frames.length),
    ...frames,
  ]);
}

List<int> _uslt(String text) {
  final body = [3, 0x65, 0x6e, 0x67, 0, ...utf8.encode(text)];
  return [...'USLT'.codeUnits, ..._size(body.length), 0, 0, ...body];
}

List<int> _sylt() {
  final body = <int>[3, 0x65, 0x6e, 0x67, 2, 1, 0];
  _line(body, 'Halo', 1500);
  _line(body, 'World', 4000);
  return [...'SYLT'.codeUnits, ..._size(body.length), 0, 0, ...body];
}

void _line(List<int> body, String text, int ms) {
  body
    ..addAll(utf8.encode(text))
    ..add(0)
    ..add((ms >> 24) & 0xff)
    ..add((ms >> 16) & 0xff)
    ..add((ms >> 8) & 0xff)
    ..add(ms & 0xff);
}

List<int> _size(int value) {
  return [
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  ];
}

List<int> _synchsafe(int value) {
  return [
    (value >> 21) & 0x7f,
    (value >> 14) & 0x7f,
    (value >> 7) & 0x7f,
    value & 0x7f,
  ];
}
