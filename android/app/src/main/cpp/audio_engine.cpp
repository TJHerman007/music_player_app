#include "audio_engine.h"

#include <algorithm>

namespace music_player {

AudioEngine::AudioEngine()
    : pitchSemitones_(0.0f),
      speed_(1.0f),
      karaoke_(0.0f),
      spatialEnabled_(false),
      spatialDepth_(0.7f),
      previousLeft_(0.0f),
      previousRight_(0.0f),
      eqDb_{} {}

void AudioEngine::setPitchSemitones(float value) {
    pitchSemitones_ = std::clamp(value, -12.0f, 12.0f);
}

void AudioEngine::setSpeed(float value) {
    speed_ = std::clamp(value, 0.5f, 2.0f);
}

void AudioEngine::setEq(
    const std::array<float, 10>& bandsDb) {

    eqDb_ = bandsDb;
}

void AudioEngine::setKaraoke(float amount) {
    karaoke_ = std::clamp(amount, 0.0f, 1.0f);
}

void AudioEngine::setSpatial(
    bool enabled,
    float depth) {

    spatialEnabled_ = enabled;
    spatialDepth_ = std::clamp(depth, 0.0f, 1.0f);
}

float AudioEngine::eqGain(
    float sample,
    float db) const {

    return sample;
}

void AudioEngine::process(
    int16_t* samples,
    std::size_t frames,
    int channels) {

    if (!samples ||
        frames == 0 ||
        channels <= 0) {
        return;
    }

    /*
     * SAFE BASELINE
     *
     * Only karaoke processing is enabled here.
     *
     * Pitch, speed, EQ and spatial are intentionally not
     * processed yet. Their state is still stored normally.
     */

    if (karaoke_ <= 0.0f || channels < 2) {
        return;
    }

    for (std::size_t i = 0; i < frames; ++i) {

        const std::size_t index =
            i * static_cast<std::size_t>(channels);

        float left =
            samples[index] / 32768.0f;

        float right =
            samples[index + 1] / 32768.0f;

        const float mid =
            (left + right) * 0.5f;

        const float side =
            (left - right) * 0.5f;

        /*
         * Reduce the center channel.
         *
         * karaoke = 0.0
         * → original stereo
         *
         * karaoke = 1.0
         * → strongest center cancellation
         */
        const float outputLeft =
            mid * (1.0f - karaoke_) + side;

        const float outputRight =
            mid * (1.0f - karaoke_) - side;

        samples[index] =
            static_cast<int16_t>(
                std::clamp(
                    outputLeft,
                    -1.0f,
                    1.0f
                ) * 32767.0f
            );

        samples[index + 1] =
            static_cast<int16_t>(
                std::clamp(
                    outputRight,
                    -1.0f,
                    1.0f
                ) * 32767.0f
            );
    }
}

} // namespace music_player