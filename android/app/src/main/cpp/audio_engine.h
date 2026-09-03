#pragma once

#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>

namespace music_player {

class AudioEngine {
 public:
  AudioEngine();

  void setPitchSemitones(float semitones);
  void setSpeed(float speed);
  void setEq(const std::array<float, 10>& bandsDb);
  void setKaraoke(float amount);
  void setSpatial(bool enabled, float depth);

  // Processes interleaved PCM16 in-place.
  void process(int16_t* samples, std::size_t frames, int channels,
               int sampleRate = 44100);

 private:
  std::atomic<float> pitchSemitones_;
  std::atomic<float> speed_;
  std::atomic<float> karaoke_;
  std::atomic<bool> spatialEnabled_;
  std::atomic<float> spatialDepth_;
  std::array<std::atomic<float>, 10> eqDb_;

  float previousLeft_;
  float previousRight_;

  struct FilterState {
    float z1L = 0.0f;
    float z2L = 0.0f;
    float z1R = 0.0f;
    float z2R = 0.0f;
  };

  std::array<FilterState, 10> eqState_;
};

}  // namespace music_player
