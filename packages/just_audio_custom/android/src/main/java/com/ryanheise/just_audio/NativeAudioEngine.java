package com.ryanheise.just_audio;

import java.nio.ByteBuffer;

public final class NativeAudioEngine {

    static {
        System.loadLibrary("music_player_audio_engine");
    }

    private NativeAudioEngine() {}

    public static native void process(
            ByteBuffer input,
            ByteBuffer output,
            int frames,
            int channels,
            int sampleRate
    );
}
