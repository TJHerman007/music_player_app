package com.example.music_player_app

object KaraokeNative {
    init {
        System.loadLibrary("music_player_audio_engine")
    }

    external fun nativeSetPitch(semitones: Float)
    external fun nativeSetSpeed(speed: Float)
    external fun nativeSetKaraoke(amount: Float)
    external fun nativeSetSpatial(enabled: Boolean, depth: Float)
    external fun nativeSetEq(bands: FloatArray)
}
