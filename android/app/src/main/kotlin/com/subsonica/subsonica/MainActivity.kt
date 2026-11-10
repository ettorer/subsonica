package com.subsonica.subsonica

import android.Manifest
import android.content.ContentUris
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : AudioServiceActivity() {
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasAudioPermission())
                    "requestPermission" -> requestAudioPermission(result)
                    "querySongs" -> background(result) { querySongs() }
                    "artwork" -> {
                        val id = call.argument<Number>("id")?.toLong()
                        val albumId = call.argument<Number>("albumId")?.toLong()
                        background(result) { artwork(id, albumId) }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != permissionRequest) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        permissionResult?.success(granted)
        permissionResult = null
    }

    private fun requestAudioPermission(result: MethodChannel.Result) {
        if (hasAudioPermission()) {
            result.success(true)
            return
        }
        if (permissionResult != null) {
            result.success(false)
            return
        }
        permissionResult = result
        ActivityCompat.requestPermissions(this, arrayOf(audioPermission()), permissionRequest)
    }

    private fun hasAudioPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, audioPermission()) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun audioPermission(): String {
        return if (Build.VERSION.SDK_INT >= 33) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
    }

    private fun querySongs(): List<Map<String, Any?>> {
        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val modern = Build.VERSION.SDK_INT >= 29
        val projection = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.IS_MUSIC,
            MediaStore.Audio.Media.IS_ALARM,
            MediaStore.Audio.Media.IS_NOTIFICATION,
            MediaStore.Audio.Media.IS_RINGTONE,
            MediaStore.Audio.Media.IS_PODCAST,
            MediaStore.Audio.Media.DATA,
        )
        if (modern) projection.add(MediaStore.Audio.Media.RELATIVE_PATH)
        val songs = mutableListOf<Map<String, Any?>>()
        contentResolver.query(
            uri,
            projection.toTypedArray(),
            if (modern) {
                "${MediaStore.Audio.Media.RELATIVE_PATH} LIKE ? OR ${MediaStore.Audio.Media.DATA} LIKE ?"
            } else {
                "${MediaStore.Audio.Media.DATA} LIKE ?"
            },
            if (modern) arrayOf("Music/%", "%/Music/%") else arrayOf("%/Music/%"),
            null,
        )?.use { cursor ->
            val id = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val title = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artist = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val album = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val albumId = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val duration = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val track = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
            val display = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val music = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_MUSIC)
            val alarm = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_ALARM)
            val notification = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_NOTIFICATION)
            val ringtone = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_RINGTONE)
            val podcast = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_PODCAST)
            val data = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val relative = if (modern) {
                cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.RELATIVE_PATH)
            } else {
                -1
            }
            while (cursor.moveToNext()) {
                val mediaId = cursor.getLong(id)
                songs.add(
                    hashMapOf(
                        "id" to mediaId,
                        "title" to cursor.text(title),
                        "artist" to cursor.text(artist),
                        "album" to cursor.text(album),
                        "albumId" to if (cursor.isNull(albumId)) 0L else cursor.getLong(albumId),
                        "duration" to if (cursor.isNull(duration)) 0L else cursor.getLong(duration),
                        "track" to if (cursor.isNull(track)) null else cursor.getInt(track),
                        "displayName" to cursor.text(display),
                        "path" to cursor.text(data),
                        "relativePath" to if (relative < 0) null else cursor.text(relative),
                        "uri" to ContentUris.withAppendedId(uri, mediaId).toString(),
                        "isMusic" to cursor.flag(music),
                        "isAlarm" to cursor.flag(alarm),
                        "isNotification" to cursor.flag(notification),
                        "isRingtone" to cursor.flag(ringtone),
                        "isPodcast" to cursor.flag(podcast),
                    ),
                )
            }
        }
        return songs
    }

    private fun artwork(audioId: Long?, albumId: Long?): ByteArray? {
        if (albumId == null || albumId <= 0) return null
        val uri = ContentUris.withAppendedId(
            Uri.parse("content://media/external/audio/albumart"),
            albumId,
        )
        return try {
            contentResolver.openInputStream(uri)?.use { it.readBytes() }
        } catch (_: Exception) {
            null
        }
    }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        thread {
            try {
                val value = work()
                runOnUiThread { result.success(value) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("phone_music", error.message, null)
                }
            }
        }
    }

    private fun android.database.Cursor.text(index: Int): String? {
        if (isNull(index)) return null
        return getString(index)
    }

    private fun android.database.Cursor.flag(index: Int): Boolean {
        if (isNull(index)) return false
        return getInt(index) == 1
    }

    companion object {
        private const val channel = "com.subsonica.subsonica/phone_music"
        private const val permissionRequest = 8765
    }
}
