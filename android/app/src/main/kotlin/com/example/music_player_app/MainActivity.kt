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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanAudio" -> scanAudio(result)
                "resolveAudio" -> resolveAudio(call, result)
                "readArtwork" -> readArtwork(call, result)
                "readMetadata" -> readMetadata(call, result)
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
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM
            )

            val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

            contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                null,
                "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"
            )?.use { cursor ->

                val idColumn = cursor.getColumnIndexOrThrow(
                    MediaStore.Audio.Media._ID
                )

                val nameColumn = cursor.getColumnIndexOrThrow(
                    MediaStore.Audio.Media.DISPLAY_NAME
                )

                val titleColumn = cursor.getColumnIndexOrThrow(
                    MediaStore.Audio.Media.TITLE
                )

                val artistColumn = cursor.getColumnIndexOrThrow(
                    MediaStore.Audio.Media.ARTIST
                )

                val albumColumn = cursor.getColumnIndexOrThrow(
                    MediaStore.Audio.Media.ALBUM
                )

                while (cursor.moveToNext()) {

                    val title = cursor.getString(titleColumn)
                        ?.trim()
                        ?.takeIf { it.isNotEmpty() }
                        ?: "Unknown track"

                    val displayName = cursor.getString(nameColumn)
                        ?.trim()
                        ?.takeIf { it.isNotEmpty() }
                        ?: continue

                    val artist = cleanMetadata(
                        cursor.getString(artistColumn),
                        "Unknown"
                    )

                    val albumFromMediaStore = cleanMetadata(
                        cursor.getString(albumColumn),
                        ""
                    )

                    val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                        .buildUpon()
                        .appendPath(
                            cursor.getLong(idColumn).toString()
                        )
                        .build()

                    /*
                     * MediaStore is the fast path.
                     *
                     * Some Android devices do not populate ALBUM even though
                     * the MP3 contains an embedded ID3 album tag. Only in that
                     * case do we inspect this individual file.
                     */
                    val album = if (albumFromMediaStore.isNotEmpty()) {
                        albumFromMediaStore
                    } else {
                        val embeddedAlbum = readAlbumFromFile(uri)

                        if (embeddedAlbum.isNotEmpty()) {
                            embeddedAlbum
                        } else {
                            "Unknown album"
                        }
                    }

                    songs.add(
                        mapOf(
                            "title" to title,
                            "path" to uri.toString(),
                            "displayName" to displayName,
                            "artist" to artist,
                            "albumArtist" to artist,
                            "album" to album
                        )
                    )
                }
            }

            result.success(songs)

        } catch (_: SecurityException) {
            result.error(
                "PERMISSION_DENIED",
                "Music permission was not granted.",
                null
            )
        } catch (_: Exception) {
            result.error(
                "SCAN_FAILED",
                "Could not scan device music.",
                null
            )
        }
    }

    private fun cleanMetadata(
        value: String?,
        fallback: String
    ): String {
        val cleaned = value?.trim()

        if (cleaned.isNullOrEmpty()) {
            return fallback
        }

        if (cleaned.equals("<unknown>", ignoreCase = true)) {
            return fallback
        }

        return cleaned
    }

    private fun readMetadata(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val uri = parseUri(call, result) ?: return

        val retriever = MediaMetadataRetriever()

        try {
            retriever.setDataSource(this, uri)

            val title = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_TITLE
            )

            val artist = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_ARTIST
            )

            val albumArtist = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_ALBUMARTIST
            )

            val album = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_ALBUM
            )

            result.success(
                mapOf(
                    "title" to (title?.trim() ?: ""),
                    "artist" to (artist?.trim() ?: ""),
                    "albumArtist" to (albumArtist?.trim() ?: ""),
                    "album" to (album?.trim() ?: "")
                )
            )

        } catch (_: Exception) {
            result.success(
                mapOf(
                    "title" to "",
                    "artist" to "",
                    "albumArtist" to "",
                    "album" to ""
                )
            )
        } finally {
            retriever.release()
        }
    }

    private fun readAlbumFromFile(
        uri: Uri
    ): String {
        val retriever = MediaMetadataRetriever()

        return try {
            retriever.setDataSource(
                this,
                uri
            )

            cleanMetadata(
                retriever.extractMetadata(
                    MediaMetadataRetriever.METADATA_KEY_ALBUM
                ),
                ""
            )
        } catch (_: Exception) {
            ""
        } finally {
            retriever.release()
        }
    }

    private fun resolveAudio(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val uri = parseUri(call, result) ?: return

        try {
            val id = uri.lastPathSegment

            if (id.isNullOrBlank()) {
                result.error(
                    "AUDIO_URI_INVALID",
                    "Audio URI is invalid.",
                    null
                )
                return
            }

            val target = File(
                cacheDir,
                "music_$id"
            )

            if (!target.exists()) {
                val input = contentResolver.openInputStream(uri)

                if (input == null) {
                    result.error(
                        "AUDIO_UNAVAILABLE",
                        "Audio file is unavailable.",
                        null
                    )
                    return
                }

                input.use { stream ->
                    target.outputStream().use { output ->
                        stream.copyTo(output)
                    }
                }
            }

            result.success(target.absolutePath)

        } catch (_: Exception) {
            result.error(
                "AUDIO_RESOLVE_FAILED",
                "Could not open audio file.",
                null
            )
        }
    }

    private fun readArtwork(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
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

    private fun parseUri(
        call: MethodCall,
        result: MethodChannel.Result
    ): Uri? {
        val value = call.argument<String>("uri")

        if (value.isNullOrBlank()) {
            result.error(
                "AUDIO_URI_INVALID",
                "Audio URI is invalid.",
                null
            )
            return null
        }

        return Uri.parse(value)
    }
}
