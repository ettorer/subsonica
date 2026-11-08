import 'dart:convert';
import 'dart:io';

import 'subsonic_api.dart';

extension SubsonicFileDownload on SubsonicClient {
  Future<int> saveToFile(
    Uri uri,
    File destination, {
    void Function(int received, int? total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final response = await openBinary(uri);
    if (response.statusCode != 200) {
      throw SubsonicException(
        'The server returned HTTP ${response.statusCode}.',
      );
    }
    final type = response.headers['content-type']?.toLowerCase() ?? '';
    if (type.contains('json') ||
        type.contains('xml') ||
        type.contains('text/html')) {
      final body = await response.stream.bytesToString();
      throw SubsonicException(
        body.trim().isEmpty
            ? 'The server did not return the file.'
            : 'The server did not return the file.',
      );
    }
    final total = response.contentLength;
    final partial = File('${destination.path}.part');
    if (partial.existsSync()) await partial.delete();
    final sink = partial.openWrite();
    var received = 0;
    var first = true;
    var closed = false;
    try {
      await for (final chunk in response.stream) {
        if (isCancelled?.call() == true) throw const DownloadCancelled();
        if (first) {
          first = false;
          if (_looksLikeError(chunk)) {
            throw const SubsonicException(
              'The server did not return the file.',
            );
          }
        }
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
      await sink.close();
      closed = true;
    } catch (error) {
      if (!closed) await sink.close();
      if (partial.existsSync()) await partial.delete();
      rethrow;
    }
    if (destination.existsSync()) await destination.delete();
    await partial.rename(destination.path);
    return received;
  }
}

bool _looksLikeError(List<int> chunk) {
  if (chunk.isEmpty) return false;
  final head = utf8
      .decode(chunk.take(64).toList(), allowMalformed: true)
      .trimLeft();
  return head.startsWith('<') || head.startsWith('{');
}
