package com.example.music_player_app

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

object AudioEngineChannel {
    private const val CHANNEL = "music_player_app/audio_engine"

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "prepare" -> {
                        // Playback preparation remains owned by the existing
                        // AudioLibraryController/just_audio path.
                        result.success(true)
                    }

                    "setPitch" -> {
                        KaraokeNative.nativeSetPitch(
                            (call.argument<Double>("semitones") ?: 0.0).toFloat()
                        )
                        result.success(null)
                    }

                    "setSpeed" -> {
                        KaraokeNative.nativeSetSpeed(
                            (call.argument<Double>("speed") ?: 1.0).toFloat()
                        )
                        result.success(null)
                    }

                    "setKaraoke" -> {
                        KaraokeNative.nativeSetKaraoke(
                            (call.argument<Double>("amount") ?: 0.0).toFloat()
                        )
                        result.success(null)
                    }

                    "setSpatial" -> {
                        KaraokeNative.nativeSetSpatial(
                            call.argument<Boolean>("enabled") ?: false,
                            (call.argument<Double>("depth") ?: 0.7).toFloat()
                        )
                        result.success(null)
                    }

                    "setEq" -> {
                        val values = call.argument<List<Double>>("bands") ?: emptyList()
                        val bands = FloatArray(10)
                        for (i in 0 until minOf(10, values.size)) {
                            bands[i] = values[i].toFloat()
                        }
                        KaraokeNative.nativeSetEq(bands)
                        result.success(null)
                    }

                    "release" -> result.success(null)

                    else -> result.notImplemented()
                }
            } catch (t: Throwable) {
                result.error("AUDIO_ENGINE", t.message, null)
            }
        }
    }
}
