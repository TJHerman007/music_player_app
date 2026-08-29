package com.example.music_player_app

import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceFragmentActivity() {
    private val channelName = "music_player/device_audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanAudio" -> scanAudio(result)
                    "resolveAudio" -> resolveAudio(call, result)
                    "readArtwork" -> readArtwork(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun scanAudio(result: MethodChannel.Result) {
        try {
            val songs = mutableListOf<Map<String, String>>()
            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DISPLAY_NAME,
                MediaStore.Audio.Media.TITLE,
            )
            val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

            contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                null,
                "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC",
            )?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val nameColumn = cursor.getColumnIndexOrThrow(
                    MediaStore.Audio.Media.DISPLAY_NAME,
                )
                val titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)

                while (cursor.moveToNext()) {
                    val title = cursor.getString(titleColumn) ?: "Unknown track"
                    val displayName = cursor.getString(nameColumn) ?: continue
                    val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                        .buildUpon()
                        .appendPath(cursor.getLong(idColumn).toString())
                        .build()
                    songs += mapOf(
                        "title" to title,
                        "path" to uri.toString(),
                        "displayName" to displayName,
                    )
                }
            }
            result.success(songs)
        } catch (_: SecurityException) {
            result.error("PERMISSION_DENIED", "Music permission was not granted.", null)
        } catch (_: Exception) {
            result.error("SCAN_FAILED", "Could not scan device music.", null)
        }
    }

    private fun resolveAudio(call: MethodCall, result: MethodChannel.Result) {
        val uri = parseUri(call, result) ?: return
        try {
            val id = uri.lastPathSegment
            if (id.isNullOrBlank()) {
                result.error("AUDIO_URI_INVALID", "Audio URI is invalid.", null)
                return
            }

            val target = File(cacheDir, "music_$id")
            if (!target.exists()) {
                val input = contentResolver.openInputStream(uri)
                if (input == null) {
                    result.error("AUDIO_UNAVAILABLE", "Audio file is unavailable.", null)
                    return
                }
                input.use { stream ->
                    target.outputStream().use { output -> stream.copyTo(output) }
                }
            }
            result.success(target.absolutePath)
        } catch (_: Exception) {
            result.error("AUDIO_RESOLVE_FAILED", "Could not open audio file.", null)
        }
    }

    private fun readArtwork(call: MethodCall, result: MethodChannel.Result) {
        val uri = parseUri(call, result) ?: return
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(this, uri)
            result.success(retriever.embeddedPicture)
        } catch (_: Exception) {
            result.success(null)
        } finally {
            retriever.release()
        }
    }

    private fun parseUri(call: MethodCall, result: MethodChannel.Result): Uri? {
        val value = call.argument<String>("uri")
        if (value.isNullOrBlank()) {
            result.error("AUDIO_URI_INVALID", "Audio URI is invalid.", null)
            return null
        }
        return Uri.parse(value)
    }
}
