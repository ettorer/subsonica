import 'dart:convert';
import 'dart:typed_data';

import '../remote/lrc.dart';

class EmbeddedLyrics {
  const EmbeddedLyrics({required this.text, required this.synced});

  final String text;
  final bool synced;
}

/// Reads ID3v2.3 and ID3v2.4 `SYLT` and `USLT` frames from the start of an
/// audio file. Synced lyrics are returned as LRC when the timestamps are
/// milliseconds.
EmbeddedLyrics? embeddedLyrics(Uint8List bytes) {
  if (bytes.length < 10) return null;
  if (bytes[0] != 0x49 || bytes[1] != 0x44 || bytes[2] != 0x33) return null;
  final major = bytes[3];
  if (major != 3 && major != 4) return null;
  final flags = bytes[5];
  final tagSize = _synchsafe(bytes, 6);
  var start = 10;
  if (flags & 0x40 != 0) {
    if (bytes.length < 14) return null;
    if (major == 4) {
      start += _synchsafe(bytes, 10);
    } else {
      start += 4 + _int32(bytes, 10);
    }
  }
  final end = (10 + tagSize).clamp(0, bytes.length);
  if (start >= end) return null;
  var body = Uint8List.sublistView(bytes, start, end);
  if (flags & 0x80 != 0) body = _deunsync(body);

  EmbeddedLyrics? plain;
  var offset = 0;
  while (offset + 10 <= body.length) {
    final idBytes = body.sublist(offset, offset + 4);
    if (idBytes.every((byte) => byte == 0)) break;
    if (!_frameId(idBytes)) break;
    final id = latin1.decode(idBytes);
    final frameSize = major == 4
        ? _synchsafe(body, offset + 4)
        : _int32(body, offset + 4);
    final frameFlags = _int16(body, offset + 8);
    offset += 10;
    if (frameSize <= 0 || offset + frameSize > body.length) break;
    var frame = Uint8List.sublistView(body, offset, offset + frameSize);
    offset += frameSize;
    if (_compressed(major, frameFlags)) continue;
    if (major == 4 && frameFlags & 0x0002 != 0) frame = _deunsync(frame);
    if (major == 4 && frameFlags & 0x0001 != 0 && frame.length >= 4) {
      frame = Uint8List.sublistView(frame, 4);
    }
    if (id == 'SYLT') {
      final synced = _sylt(frame);
      if (synced != null) return synced;
    } else if (id == 'USLT' && plain == null) {
      plain = _uslt(frame);
    }
  }
  return plain;
}

bool _frameId(List<int> bytes) {
  for (final byte in bytes) {
    final letter = byte >= 0x41 && byte <= 0x5a;
    final digit = byte >= 0x30 && byte <= 0x39;
    if (!letter && !digit) return false;
  }
  return true;
}

bool _compressed(int major, int flags) {
  if (major == 4) return flags & 0x0008 != 0;
  return flags & 0x0080 != 0;
}

EmbeddedLyrics? _uslt(Uint8List frame) {
  if (frame.length < 5) return null;
  final encoding = frame[0];
  final (_, next) = _terminated(frame, 4, encoding);
  if (next > frame.length) return null;
  final text = _decode(encoding, Uint8List.sublistView(frame, next)).trim();
  if (text.isEmpty) return null;
  return _asLyrics(text);
}

EmbeddedLyrics? _sylt(Uint8List frame) {
  if (frame.length < 6) return null;
  final encoding = frame[0];
  final format = frame[4];
  if (format != 2) return null;
  final (_, next) = _terminated(frame, 6, encoding);
  final lines = <({int ms, String text})>[];
  var offset = next;
  while (offset + 4 < frame.length) {
    final (text, after) = _terminated(frame, offset, encoding);
    if (after + 4 > frame.length) break;
    final ms = _int32(frame, after);
    offset = after + 4;
    final trimmed = text.trim();
    if (trimmed.isEmpty) continue;
    lines.add((ms: ms, text: trimmed));
  }
  if (lines.isEmpty) return null;
  lines.sort((a, b) => a.ms.compareTo(b.ms));
  final lrc = [for (final line in lines) '${_stamp(line.ms)}${line.text}']
      .join('\n');
  return EmbeddedLyrics(text: lrc, synced: true);
}

EmbeddedLyrics _asLyrics(String text) {
  if (parseLrc(text).isNotEmpty) {
    return EmbeddedLyrics(text: text, synced: true);
  }
  return EmbeddedLyrics(text: text, synced: false);
}

String _stamp(int ms) {
  if (ms < 0) ms = 0;
  final minutes = ms ~/ 60000;
  final seconds = (ms % 60000) ~/ 1000;
  final hundredths = (ms % 1000) ~/ 10;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  final ff = hundredths.toString().padLeft(2, '0');
  return '[$mm:$ss.$ff]';
}

(String, int) _terminated(Uint8List data, int offset, int encoding) {
  if (offset > data.length) return ('', data.length);
  if (encoding == 1 || encoding == 2) {
    var index = offset;
    while (index + 1 < data.length) {
      if (data[index] == 0 && data[index + 1] == 0) {
        final text = _decode(
          encoding,
          Uint8List.sublistView(data, offset, index),
        );
        return (text, index + 2);
      }
      index += 2;
    }
    return (
      _decode(encoding, Uint8List.sublistView(data, offset)),
      data.length,
    );
  }
  var index = offset;
  while (index < data.length && data[index] != 0) {
    index++;
  }
  final text = _decode(encoding, Uint8List.sublistView(data, offset, index));
  return (text, index < data.length ? index + 1 : index);
}

String _decode(int encoding, Uint8List data) {
  if (data.isEmpty) return '';
  switch (encoding) {
    case 1:
      return _utf16(data);
    case 2:
      return String.fromCharCodes(_units16(data, little: false));
    case 3:
      return utf8.decode(data, allowMalformed: true);
    default:
      return latin1.decode(data, allowInvalid: true);
  }
}

String _utf16(Uint8List data) {
  if (data.length >= 2 && data[0] == 0xFF && data[1] == 0xFE) {
    return String.fromCharCodes(
      _units16(Uint8List.sublistView(data, 2), little: true),
    );
  }
  if (data.length >= 2 && data[0] == 0xFE && data[1] == 0xFF) {
    return String.fromCharCodes(
      _units16(Uint8List.sublistView(data, 2), little: false),
    );
  }
  return String.fromCharCodes(_units16(data, little: true));
}

List<int> _units16(Uint8List data, {required bool little}) {
  final units = <int>[];
  for (var index = 0; index + 1 < data.length; index += 2) {
    final unit = little
        ? data[index] | (data[index + 1] << 8)
        : (data[index] << 8) | data[index + 1];
    units.add(unit);
  }
  return units;
}

Uint8List _deunsync(Uint8List data) {
  final out = <int>[];
  for (var index = 0; index < data.length; index++) {
    out.add(data[index]);
    if (data[index] == 0xFF &&
        index + 1 < data.length &&
        data[index + 1] == 0x00) {
      index++;
    }
  }
  return Uint8List.fromList(out);
}

int _synchsafe(Uint8List bytes, int offset) {
  return (bytes[offset] & 0x7f) << 21 |
      (bytes[offset + 1] & 0x7f) << 14 |
      (bytes[offset + 2] & 0x7f) << 7 |
      (bytes[offset + 3] & 0x7f);
}

int _int32(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

int _int16(Uint8List bytes, int offset) {
  return (bytes[offset] << 8) | bytes[offset + 1];
}
