package com.example.music_player_app

import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "music_player/device_audio"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				if (call.method != "scanAudio") {
					result.notImplemented()
					return@setMethodCallHandler
				}

				try {
					val songs = mutableListOf<Map<String, String>>()
					val projection = arrayOf(
						MediaStore.Audio.Media.TITLE,
						MediaStore.Audio.Media.DATA,
					)
					val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

					contentResolver.query(
						MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
						projection,
						selection,
						null,
						"${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC",
					)?.use { cursor ->
						val titleIndex = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
						val pathIndex = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
						while (cursor.moveToNext()) {
							val title = cursor.getString(titleIndex) ?: "Unknown track"
							val path = cursor.getString(pathIndex) ?: continue
							songs.add(mapOf("title" to title, "path" to path))
						}
					}
					result.success(songs)
				} catch (error: SecurityException) {
					result.error("PERMISSION_DENIED", "Music permission was not granted.", null)
				} catch (error: Exception) {
					result.error("SCAN_FAILED", "Could not scan device music.", null)
				}
			}
	}
}
