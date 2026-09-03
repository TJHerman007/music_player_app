#include <jni.h>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>

#include "audio_engine.h"

static music_player::AudioEngine g_engine;

extern "C"
JNIEXPORT void JNICALL
Java_com_example_music_1player_app_KaraokeNative_nativeSetPitch(
    JNIEnv*,
    jobject,
    jfloat semitones) {

    g_engine.setPitchSemitones(semitones);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_music_1player_app_KaraokeNative_nativeSetSpeed(
    JNIEnv*,
    jobject,
    jfloat speed) {

    g_engine.setSpeed(speed);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_music_1player_app_KaraokeNative_nativeSetKaraoke(
    JNIEnv*,
    jobject,
    jfloat amount) {

    g_engine.setKaraoke(amount);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_music_1player_app_KaraokeNative_nativeSetSpatial(
    JNIEnv*,
    jobject,
    jboolean enabled,
    jfloat depth) {

    g_engine.setSpatial(
        enabled == JNI_TRUE,
        depth
    );
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_music_1player_app_KaraokeNative_nativeSetEq(
    JNIEnv* env,
    jobject,
    jfloatArray bands) {

    if (!env || !bands) {
        return;
    }

    std::array<float, 10> values{};

    const jsize count = env->GetArrayLength(bands);
    const jsize n = count < 10 ? count : 10;

    if (n > 0) {
        env->GetFloatArrayRegion(
            bands,
            0,
            n,
            values.data()
        );
    }

    g_engine.setEq(values);
}


/*
 * Native PCM bridge.
 *
 * This is the point where the decoded PCM from the custom just_audio
 * engine is passed through TIUS' native DSP chain.
 */
extern "C"
JNIEXPORT void JNICALL
Java_com_ryanheise_just_1audio_NativeAudioEngine_process(
    JNIEnv* env,
    jclass,
    jobject inputBuffer,
    jobject outputBuffer,
    jint frames,
    jint channels,
    jint sampleRate) {

    if (!env ||
        !inputBuffer ||
        !outputBuffer ||
        frames <= 0 ||
        channels <= 0) {
        return;
    }

    void* inputAddress =
        env->GetDirectBufferAddress(inputBuffer);

    void* outputAddress =
        env->GetDirectBufferAddress(outputBuffer);

    if (!inputAddress || !outputAddress) {
        return;
    }

    const std::size_t sampleCount =
        static_cast<std::size_t>(frames) *
        static_cast<std::size_t>(channels);

    const std::size_t byteCount =
        sampleCount * sizeof(int16_t);

    // Copy first so input and output buffers can safely alias or differ.
    if (inputAddress != outputAddress) {
        std::memcpy(outputAddress, inputAddress, byteCount);
    }

    g_engine.process(
        static_cast<int16_t*>(outputAddress),
        static_cast<std::size_t>(frames),
        static_cast<int>(channels),
        static_cast<int>(sampleRate));
}
