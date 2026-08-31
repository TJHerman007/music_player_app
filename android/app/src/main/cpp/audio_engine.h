#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace music_player {

class AudioEngine {
public:
    AudioEngine();

    void setPitchSemitones(float semitones);
    void setSpeed(float speed);
    void setEq(const std::array<float, 10>& bandsDb);
    void setKaraoke(float amount);
    void setSpatial(bool enabled, float depth);

    // Processes interleaved stereo PCM16 in-place.
    void process(int16_t* samples, std::size_t frames, int channels);

private:
    float pitchSemitones_;
    float speed_;
    float karaoke_;
    bool spatialEnabled_;
    float spatialDepth_;
    std::array<float, 10> eqDb_;

    float previousLeft_;
    float previousRight_;

    float eqGain(float sample, float db) const;
};

} // namespace music_player
