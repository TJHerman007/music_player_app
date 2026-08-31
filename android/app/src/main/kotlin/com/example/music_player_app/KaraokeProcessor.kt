package com.example.music_player_app

/**
 * Compatibility facade for the existing karaoke feature.
 *
 * Existing Flutter code can migrate to AudioEngineChannel gradually.
 */
object KaraokeProcessor {
    fun setAmount(amount: Float) {
        KaraokeNative.nativeSetKaraoke(amount.coerceIn(0f, 1f))
    }
}
