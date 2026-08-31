package com.example.music_player_app

import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import android.os.Handler
import android.os.Looper
import android.database.ContentObserver
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceFragmentActivity() {

    private val channelName = "music_player/device_audio"
    private var flutterEngine: FlutterEngine? = null
    private var libraryObserver: ContentObserver? = null

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)
        this.flutterEngine = flutterEngine
        registerLibraryObserver()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "scanAudio" -> scanAudio(result)

                "scanNewAudio" -> {
                    val sinceSeconds = call.argument<Long>("sinceSeconds") ?: 0L
                    scanAudio(result, sinceSeconds)
                }

                "resolveAudio" ->
                    resolveAudio(call, result)

                "readArtwork" ->
                    readArtwork(call, result)

                else ->
                    result.notImplemented()
            }
        }
        AudioEngineChannel.register(flutterEngine.dartExecutor.binaryMessenger)
    }

    private fun registerLibraryObserver() {
        if (libraryObserver != null) return

        libraryObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                flutterEngine?.let { engine ->
                    MethodChannel(
                        engine.dartExecutor.binaryMessenger,
                        channelName
                    ).invokeMethod("audioLibraryChanged", null)
                }
            }
        }

        contentResolver.registerContentObserver(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            true,
            libraryObserver!!
        )
    }

    override fun onDestroy() {
        libraryObserver?.let { contentResolver.unregisterContentObserver(it) }
        libraryObserver = null
        flutterEngine = null
        super.onDestroy()
    }

    private fun scanAudio(
        result: MethodChannel.Result,
        sinceSeconds: Long? = null
    ) {
        try {

            val songs =
                mutableListOf<Map<String, String>>()

            /*
             * Keep the original MediaStore scan.
             *
             * ARTIST and ALBUM are standard MediaStore fields.
             *
             * album_artist is supplied as a string instead of using
             * MediaStore.Audio.Media.ALBUM_ARTIST so this file remains
             * compatible with older compile SDK configurations.
             */
            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DISPLAY_NAME,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                "album_artist"
            )

            val selection = if (sinceSeconds != null) {
                "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND " +
                    "${MediaStore.Audio.Media.DATE_ADDED} >= ?"
            } else {
                "${MediaStore.Audio.Media.IS_MUSIC} != 0"
            }

            val selectionArgs = if (sinceSeconds != null) {
                arrayOf(sinceSeconds.toString())
            } else {
                null
            }

            contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
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

                val albumColumn =
                    cursor.getColumnIndexOrThrow(
                        MediaStore.Audio.Media.ALBUM
                    )

                /*
                 * album_artist may not exist on some older Android
                 * MediaStore implementations.
                 *
                 * Therefore we don't use getColumnIndexOrThrow().
                 */
                val albumArtistColumn =
                    cursor.getColumnIndex(
                        "album_artist"
                    )

                while (cursor.moveToNext()) {

                    val title =
                        cursor.getString(titleColumn)
                            ?: "Unknown track"

                    val displayName =
                        cursor.getString(nameColumn)
                            ?: continue

                    // ---------------------------------------------------------
                    // ARTIST
                    // ---------------------------------------------------------

                    val artistValue =
                        cursor.getString(artistColumn)
                            ?.trim()

                    val albumArtistValue =
                        if (albumArtistColumn >= 0) {
                            cursor
                                .getString(
                                    albumArtistColumn
                                )
                                ?.trim()
                        } else {
                            null
                        }

                    /*
                     * Artist priority:
                     *
                     * 1. Artist
                     * 2. Album Artist
                     * 3. Unknown
                     */
                    val artist =
                        when {

                            !artistValue.isNullOrEmpty() &&
                                !artistValue.equals(
                                    "<unknown>",
                                    ignoreCase = true
                                ) ->
                                artistValue

                            !albumArtistValue.isNullOrEmpty() &&
                                !albumArtistValue.equals(
                                    "<unknown>",
                                    ignoreCase = true
                                ) ->
                                albumArtistValue

                            else ->
                                "Unknown"
                        }

                    // ---------------------------------------------------------
                    // ALBUM
                    // ---------------------------------------------------------

                    val albumValue =
                        cursor.getString(albumColumn)
                            ?.trim()

                    val album =
                        if (
                            !albumValue.isNullOrEmpty() &&
                            !albumValue.equals(
                                "<unknown>",
                                ignoreCase = true
                            )
                        ) {
                            albumValue
                        } else {
                            "Unknown album"
                        }

                    // ---------------------------------------------------------
                    // URI
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
                    // SEND RESULT TO FLUTTER
                    // ---------------------------------------------------------

                    songs.add(
                        mapOf(
                            "title" to title,
                            "path" to uri.toString(),
                            "displayName" to displayName,
                            "artist" to artist,
                            "albumArtist" to (
                                albumArtistValue
                                    ?: "Unknown"
                            ),
                            "album" to album
                        )
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
                    contentResolver
                        .openInputStream(uri)

                if (input == null) {

                    result.error(
                        "AUDIO_UNAVAILABLE",
                        "Audio file is unavailable.",
                        null
                    )

                    return
                }

                input.use { stream ->

                    target.outputStream()
                        .use { output ->

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

            result.success(null)

        } finally {

            retriever.release()
        }
    }

    private fun parseUri(
        call: MethodCall,
        result: MethodChannel.Result
    ): Uri? {

        val value =
            call.argument<String>("uri")

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