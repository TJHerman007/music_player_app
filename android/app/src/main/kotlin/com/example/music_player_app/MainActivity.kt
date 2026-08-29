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

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "scanAudio" -> {
                    scanAudio(result)
                }

                "resolveAudio" -> {
                    resolveAudio(call, result)
                }

                "readArtwork" -> {
                    readArtwork(call, result)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // =========================================================================
    // SCAN AUDIO
    // =========================================================================

    private fun scanAudio(
        result: MethodChannel.Result
    ) {
        try {

            val songs =
                mutableListOf<Map<String, String>>()

            /*
             * IMPORTANT:
             *
             * Artist, album artist and album are obtained directly from
             * Android MediaStore.
             *
             * This means we DON'T need to open every MP3 with
             * MediaMetadataRetriever.
             *
             * Therefore the normal library scan remains fast.
             */

            val projection = arrayOf(

                MediaStore.Audio.Media._ID,

                MediaStore.Audio.Media.DISPLAY_NAME,

                MediaStore.Audio.Media.TITLE,

                MediaStore.Audio.Media.ARTIST,

                MediaStore.Audio.Media.ALBUM_ARTIST,

                MediaStore.Audio.Media.ALBUM
            )

            val selection =
                "${MediaStore.Audio.Media.IS_MUSIC} != 0"

            contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                null,
                "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"
            )?.use { cursor ->

                val idColumn =
                    cursor.getColumnIndexOrThrow(
                        MediaStore.Audio.Media._ID
                    )

                val nameColumn =
                    cursor.getColumnIndexOrThrow(
                        MediaStore.Audio.Media.DISPLAY_NAME
                    )

                val titleColumn =
                    cursor.getColumnIndexOrThrow(
                        MediaStore.Audio.Media.TITLE
                    )

                val artistColumn =
                    cursor.getColumnIndexOrThrow(
                        MediaStore.Audio.Media.ARTIST
                    )

                val albumArtistColumn =
                    cursor.getColumnIndexOrThrow(
                        MediaStore.Audio.Media.ALBUM_ARTIST
                    )

                val albumColumn =
                    cursor.getColumnIndexOrThrow(
                        MediaStore.Audio.Media.ALBUM
                    )

                while (cursor.moveToNext()) {

                    // ---------------------------------------------------------
                    // BASIC INFORMATION
                    // ---------------------------------------------------------

                    val title =
                        cursor.getString(titleColumn)
                            ?.trim()
                            ?.takeIf {
                                it.isNotEmpty()
                            }
                            ?: "Unknown track"

                    val displayName =
                        cursor.getString(nameColumn)
                            ?.trim()
                            ?.takeIf {
                                it.isNotEmpty()
                            }
                            ?: continue

                    // ---------------------------------------------------------
                    // ARTIST
                    // ---------------------------------------------------------

                    val rawArtist =
                        cursor.getString(artistColumn)
                            ?.trim()

                    val rawAlbumArtist =
                        cursor.getString(
                            albumArtistColumn
                        )?.trim()

                    /*
                     * Priority:
                     *
                     * Artist
                     * ↓
                     * Album Artist
                     * ↓
                     * Unknown
                     */

                    val artist =
                        if (
                            !rawArtist.isNullOrEmpty() &&
                            !rawArtist.equals(
                                "<unknown>",
                                ignoreCase = true
                            )
                        ) {
                            rawArtist
                        } else if (
                            !rawAlbumArtist.isNullOrEmpty() &&
                            !rawAlbumArtist.equals(
                                "<unknown>",
                                ignoreCase = true
                            )
                        ) {
                            rawAlbumArtist
                        } else {
                            "Unknown"
                        }

                    // ---------------------------------------------------------
                    // ALBUM
                    // ---------------------------------------------------------

                    val rawAlbum =
                        cursor.getString(albumColumn)
                            ?.trim()

                    val album =
                        if (
                            !rawAlbum.isNullOrEmpty() &&
                            !rawAlbum.equals(
                                "<unknown>",
                                ignoreCase = true
                            )
                        ) {
                            rawAlbum
                        } else {
                            "Unknown album"
                        }

                    // ---------------------------------------------------------
                    // MEDIASTORE URI
                    // ---------------------------------------------------------

                    val uri =
                        MediaStore.Audio.Media
                            .EXTERNAL_CONTENT_URI
                            .buildUpon()
                            .appendPath(
                                cursor
                                    .getLong(idColumn)
                                    .toString()
                            )
                            .build()

                    // ---------------------------------------------------------
                    // SEND EVERYTHING TO FLUTTER
                    // ---------------------------------------------------------

                    songs += mapOf(

                        "title" to title,

                        "path" to uri.toString(),

                        "displayName" to displayName,

                        "artist" to artist,

                        "albumArtist" to (
                            rawAlbumArtist
                                ?.takeIf {
                                    it.isNotEmpty() &&
                                    !it.equals(
                                        "<unknown>",
                                        ignoreCase = true
                                    )
                                }
                                ?: "Unknown"
                        ),

                        "album" to album
                    )
                }
            }

            result.success(songs)

        } catch (
            _: SecurityException
        ) {

            result.error(
                "PERMISSION_DENIED",
                "Music permission was not granted.",
                null
            )

        } catch (
            _: Exception
        ) {

            result.error(
                "SCAN_FAILED",
                "Could not scan device music.",
                null
            )
        }
    }

    // =========================================================================
    // RESOLVE AUDIO
    // =========================================================================

    private fun resolveAudio(
        call: MethodCall,
        result: MethodChannel.Result
    ) {

        val uri =
            parseUri(
                call,
                result
            ) ?: return

        try {

            val id =
                uri.lastPathSegment

            if (id.isNullOrBlank()) {

                result.error(
                    "AUDIO_URI_INVALID",
                    "Audio URI is invalid.",
                    null
                )

                return
            }

            val target =
                File(
                    cacheDir,
                    "music_$id"
                )

            if (!target.exists()) {

                val input =
                    contentResolver.openInputStream(
                        uri
                    )

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

                        stream.copyTo(
                            output
                        )
                    }
                }
            }

            result.success(
                target.absolutePath
            )

        } catch (
            _: Exception
        ) {

            result.error(
                "AUDIO_RESOLVE_FAILED",
                "Could not open audio file.",
                null
            )
        }
    }

    // =========================================================================
    // READ ARTWORK
    // =========================================================================

    private fun readArtwork(
        call: MethodCall,
        result: MethodChannel.Result
    ) {

        val uri =
            parseUri(
                call,
                result
            ) ?: return

        val retriever =
            MediaMetadataRetriever()

        try {

            retriever.setDataSource(
                this,
                uri
            )

            result.success(
                retriever.embeddedPicture
            )

        } catch (
            _: Exception
        ) {

            result.success(
                null
            )

        } finally {

            retriever.release()
        }
    }

    // =========================================================================
    // URI PARSER
    // =========================================================================

    private fun parseUri(
        call: MethodCall,
        result: MethodChannel.Result
    ): Uri? {

        val value =
            call.argument<String>(
                "uri"
            )

        if (value.isNullOrBlank()) {

            result.error(
                "AUDIO_URI_INVALID",
                "Audio URI is invalid.",
                null
            )

            return null
        }

        return Uri.parse(
            value
        )
    }
}