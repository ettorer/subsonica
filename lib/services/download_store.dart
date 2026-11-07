import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/download.dart';
import '../models/library.dart';

class DownloadStore {
  Database? _database;
  late Directory audioDirectory;
  late Directory coverDirectory;
  late Directory lyricsDirectory;

  Future<void> open() async {
    final root = await getApplicationSupportDirectory();
    final base = Directory(p.join(root.path, 'offline'));
    audioDirectory = Directory(p.join(base.path, 'audio'));
    coverDirectory = Directory(p.join(base.path, 'covers'));
    lyricsDirectory = Directory(p.join(base.path, 'lyrics'));
    await audioDirectory.create(recursive: true);
    await coverDirectory.create(recursive: true);
    await lyricsDirectory.create(recursive: true);
    _database = await openDatabase(
      p.join(base.path, 'downloads.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE downloads (
            song_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            album TEXT NOT NULL,
            album_id TEXT,
            cover_art TEXT,
            track INTEGER,
            disc INTEGER,
            duration INTEGER NOT NULL,
            starred INTEGER NOT NULL,
            status TEXT NOT NULL,
            file_path TEXT,
            byte_size INTEGER NOT NULL,
            error TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE covers (
            cover_id TEXT PRIMARY KEY,
            file_path TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE scrobbles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            song_id TEXT NOT NULL,
            submission INTEGER NOT NULL,
            at_ms INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Database get _db {
    final database = _database;
    if (database == null) {
      throw StateError('The download store is not open.');
    }
    return database;
  }

  File audioFile(String songId) {
    return File(p.join(audioDirectory.path, safeFileId(songId)));
  }

  File coverFile(String coverId) {
    return File(p.join(coverDirectory.path, safeFileId(coverId)));
  }

  File lyricsFile(String songId) {
    return File(p.join(lyricsDirectory.path, '${safeFileId(songId)}.json'));
  }

  Future<void> writeLyrics(String songId, String json) {
    return lyricsFile(songId).writeAsString(json);
  }

  Future<String?> readLyrics(String songId) async {
    final file = lyricsFile(songId);
    if (!file.existsSync()) return null;
    return file.readAsString();
  }

  Future<void> deleteLyrics(String songId) async {
    final file = lyricsFile(songId);
    if (file.existsSync()) await file.delete();
  }

  Future<List<DownloadEntry>> loadDownloads() async {
    final rows = await _db.query('downloads');
    return [for (final row in rows) _entry(row)];
  }

  Future<Map<String, String>> loadCovers() async {
    final rows = await _db.query('covers');
    return {
      for (final row in rows)
        row['cover_id']! as String: row['file_path']! as String,
    };
  }

  Future<void> upsert(DownloadEntry entry) {
    return _db.insert('downloads', {
      'song_id': entry.song.id,
      'title': entry.song.title,
      'artist': entry.song.artist,
      'album': entry.song.album,
      'album_id': entry.song.albumId,
      'cover_art': entry.song.coverArt,
      'track': entry.song.track,
      'disc': entry.song.disc,
      'duration': entry.song.duration,
      'starred': entry.song.starred ? 1 : 0,
      'status': entry.status.name,
      'file_path': entry.filePath,
      'byte_size': entry.byteSize,
      'error': entry.error,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSong(String songId) {
    return _db.delete('downloads', where: 'song_id = ?', whereArgs: [songId]);
  }

  Future<void> upsertCover(String coverId, String filePath) {
    return _db.insert('covers', {
      'cover_id': coverId,
      'file_path': filePath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCover(String coverId) {
    return _db.delete('covers', where: 'cover_id = ?', whereArgs: [coverId]);
  }

  Future<void> addScrobble(
    String songId, {
    required bool submission,
    required int atMs,
  }) {
    return _db.insert('scrobbles', {
      'song_id': songId,
      'submission': submission ? 1 : 0,
      'at_ms': atMs,
    });
  }

  Future<List<PendingScrobble>> loadScrobbles() async {
    final rows = await _db.query('scrobbles', orderBy: 'id');
    return [
      for (final row in rows)
        PendingScrobble(
          id: row['id']! as int,
          songId: row['song_id']! as String,
          submission: row['submission'] == 1,
          atMs: row['at_ms']! as int,
        ),
    ];
  }

  Future<void> deleteScrobble(int id) {
    return _db.delete('scrobbles', where: 'id = ?', whereArgs: [id]);
  }

  DownloadEntry _entry(Map<String, Object?> row) {
    return DownloadEntry(
      song: Song(
        id: row['song_id']! as String,
        title: row['title']! as String,
        artist: row['artist']! as String,
        album: row['album']! as String,
        albumId: row['album_id'] as String?,
        coverArt: row['cover_art'] as String?,
        track: row['track'] as int?,
        disc: row['disc'] as int?,
        duration: row['duration']! as int,
        starred: row['starred'] == 1,
      ),
      status: DownloadStatus.values.byName(row['status']! as String),
      filePath: row['file_path'] as String?,
      byteSize: row['byte_size']! as int,
      error: row['error'] as String?,
    );
  }
}

String safeFileId(String id) => id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
