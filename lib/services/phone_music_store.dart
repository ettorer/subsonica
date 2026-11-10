import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/library.dart';
import 'download_store.dart';
import 'phone_catalog.dart';

class PhoneMusicStore {
  Database? _database;
  late Directory coverDirectory;

  Future<void> open() async {
    final root = await getApplicationSupportDirectory();
    final base = Directory(p.join(root.path, 'offline'));
    coverDirectory = Directory(p.join(base.path, 'phone_covers'));
    await base.create(recursive: true);
    await coverDirectory.create(recursive: true);
    _database = await openDatabase(
      p.join(base.path, 'phone_music.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tracks (
            song_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            album TEXT NOT NULL,
            album_id TEXT,
            cover_art TEXT,
            track INTEGER,
            disc INTEGER,
            duration INTEGER NOT NULL,
            path TEXT,
            play_uri TEXT NOT NULL,
            genre TEXT,
            lyrics_json TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE covers (
            cover_id TEXT PRIMARY KEY,
            file_path TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<PhoneTrack>> loadTracks() async {
    final rows = await _db.query('tracks');
    return [
      for (final row in rows)
        PhoneTrack(
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
            path: row['path'] as String?,
            genre: row['genre'] as String?,
          ),
          playUri: row['play_uri']! as String,
          lyricsJson: row['lyrics_json'] as String?,
        ),
    ];
  }

  Future<Map<String, String>> loadCovers() async {
    final rows = await _db.query('covers');
    return {
      for (final row in rows)
        row['cover_id']! as String: row['file_path']! as String,
    };
  }

  Future<void> replace(
    List<PhoneTrack> tracks,
    Map<String, Uint8List> covers,
  ) async {
    final previous = await loadCovers();
    for (final path in previous.values) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
    final db = _db;
    await db.transaction((txn) async {
      await txn.delete('tracks');
      await txn.delete('covers');
      for (final item in tracks) {
        final song = item.song;
        await txn.insert('tracks', {
          'song_id': song.id,
          'title': song.title,
          'artist': song.artist,
          'album': song.album,
          'album_id': song.albumId,
          'cover_art': song.coverArt,
          'track': song.track,
          'disc': song.disc,
          'duration': song.duration,
          'path': song.path,
          'play_uri': item.playUri,
          'genre': song.genre,
          'lyrics_json': item.lyricsJson,
        });
      }
    });
    final saved = <String, String>{};
    for (final entry in covers.entries) {
      if (entry.value.isEmpty) continue;
      final file = File(p.join(coverDirectory.path, safeFileId(entry.key)));
      await file.writeAsBytes(entry.value, flush: true);
      saved[entry.key] = file.path;
      await db.insert('covers', {
        'cover_id': entry.key,
        'file_path': file.path,
      });
    }
  }

  Future<void> writeLyrics(String songId, String json) async {
    await _db.update(
      'tracks',
      {'lyrics_json': json},
      where: 'song_id = ?',
      whereArgs: [songId],
    );
  }

  Database get _db {
    final database = _database;
    if (database == null) {
      throw StateError('The phone music store is not open.');
    }
    return database;
  }
}
