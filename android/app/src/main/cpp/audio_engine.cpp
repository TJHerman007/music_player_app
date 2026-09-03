#include "audio_engine.h"

#include <algorithm>
#include <array>
#include <cmath>

namespace music_player {

namespace {
constexpr std::array<float, 10> kFrequencies = {
    60.0f, 120.0f, 250.0f, 500.0f, 1000.0f,
    2000.0f, 4000.0f, 8000.0f, 12000.0f, 16000.0f};

struct Biquad {
  float b0 = 1.0f;
  float b1 = 0.0f;
  float b2 = 0.0f;
  float a1 = 0.0f;
  float a2 = 0.0f;
  float z1L = 0.0f;
  float z2L = 0.0f;
  float z1R = 0.0f;
  float z2R = 0.0f;

  float processLeft(float x) {
    const float y = b0 * x + z1L;
    z1L = b1 * x - a1 * y + z2L;
    z2L = b2 * x - a2 * y;
    return y;
  }

  float processRight(float x) {
    const float y = b0 * x + z1R;
    z1R = b1 * x - a1 * y + z2R;
    z2R = b2 * x - a2 * y;
    return y;
  }
};

Biquad makePeaking(float frequency, float sampleRate, float gainDb) {
  Biquad q;
  if (sampleRate <= 0.0f || frequency >= sampleRate * 0.48f ||
      std::abs(gainDb) < 0.001f) {
    return q;
  }

  constexpr float kQ = 1.0f;
  constexpr float kPi = 3.14159265358979323846f;

  const float A = std::pow(10.0f, gainDb / 40.0f);
  const float w0 = 2.0f * kPi * frequency / sampleRate;
  const float alpha = std::sin(w0) / (2.0f * kQ);
  const float cosW0 = std::cos(w0);

  const float b0 = 1.0f + alpha * A;
  const float b1 = -2.0f * cosW0;
  const float b2 = 1.0f - alpha * A;
  const float a0 = 1.0f + alpha / A;
  const float a1 = -2.0f * cosW0;
  const float a2 = 1.0f - alpha / A;

  q.b0 = b0 / a0;
  q.b1 = b1 / a0;
  q.b2 = b2 / a0;
  q.a1 = a1 / a0;
  q.a2 = a2 / a0;
  return q;
}

inline float clampSample(float value) {
  return std::clamp(value, -1.0f, 1.0f);
}

}  // namespace

AudioEngine::AudioEngine()
    : pitchSemitones_(0.0f),
      speed_(1.0f),
      karaoke_(0.0f),
      spatialEnabled_(false),
      spatialDepth_(0.7f),
      previousLeft_(0.0f),
      previousRight_(0.0f) {
  for (auto& band : eqDb_) {
    band.store(0.0f);
  }
}

void AudioEngine::setPitchSemitones(float value) {
  pitchSemitones_.store(std::clamp(value, -12.0f, 12.0f));
}

void AudioEngine::setSpeed(float value) {
  speed_.store(std::clamp(value, 0.5f, 2.0f));
}

void AudioEngine::setEq(const std::array<float, 10>& bandsDb) {
  for (std::size_t i = 0; i < eqDb_.size(); ++i) {
    eqDb_[i].store(std::clamp(bandsDb[i], -12.0f, 12.0f));
  }
}

void AudioEngine::setKaraoke(float amount) {
  karaoke_.store(std::clamp(amount, 0.0f, 1.0f));
}

void AudioEngine::setSpatial(bool enabled, float depth) {
  spatialEnabled_.store(enabled);
  spatialDepth_.store(std::clamp(depth, 0.0f, 1.0f));
}

void AudioEngine::process(
    int16_t* samples,
    std::size_t frames,
    int channels,
    int sampleRate) {
  if (!samples || frames == 0 || channels <= 0) return;

  const float karaoke = karaoke_.load();
  const bool spatial = spatialEnabled_.load();
  const float depth = spatialDepth_.load();

  std::array<Biquad, 10> eq{};
  bool anyEq = false;
  if (channels >= 2 && sampleRate > 0) {
    for (std::size_t band = 0; band < eqDb_.size(); ++band) {
      const float gain = eqDb_[band].load();
      if (std::abs(gain) >= 0.001f) {
        eq[band] = makePeaking(
            kFrequencies[band],
            static_cast<float>(sampleRate),
            gain);
        anyEq = true;
        eq[band].z1L = eqState_[band].z1L;
        eq[band].z2L = eqState_[band].z2L;
        eq[band].z1R = eqState_[band].z1R;
        eq[band].z2R = eqState_[band].z2R;
      }
    }
  }

  for (std::size_t frame = 0; frame < frames; ++frame) {
    const std::size_t index =
        frame * static_cast<std::size_t>(channels);

    float left = samples[index] / 32768.0f;
    float right = channels >= 2
        ? samples[index + 1] / 32768.0f
        : left;

    // 10-band peaking EQ. Only non-flat bands do work.
    if (anyEq && channels >= 2) {
      for (std::size_t band = 0; band < eq.size(); ++band) {
        if (std::abs(eqDb_[band].load()) < 0.001f) continue;
        left = eq[band].processLeft(left);
        right = eq[band].processRight(right);
        eqState_[band].z1L = eq[band].z1L;
        eqState_[band].z2L = eq[band].z2L;
        eqState_[band].z1R = eq[band].z1R;
        eqState_[band].z2R = eq[band].z2R;
      }
    }

    // Center-channel reduction for karaoke.
    if (karaoke > 0.0f && channels >= 2) {
      const float mid = (left + right) * 0.5f;
      const float side = (left - right) * 0.5f;
      left = mid * (1.0f - karaoke) + side;
      right = mid * (1.0f - karaoke) - side;
    }

    // Mid/side stereo widening.
    if (spatial && channels >= 2 && depth > 0.0f) {
      const float mid = (left + right) * 0.5f;
      const float side = (left - right) * 0.5f;
      const float width = 1.0f + depth * 0.85f;
      left = mid + side * width;
      right = mid - side * width;
    }

    samples[index] =
        static_cast<int16_t>(clampSample(left) * 32767.0f);

    if (channels >= 2) {
      samples[index + 1] =
          static_cast<int16_t>(clampSample(right) * 32767.0f);
    }

    // Preserve state fields for future stateful pitch/time-stretch stages.
    previousLeft_ = left;
    previousRight_ = right;
  }

  // Speed is applied by just_audio's real playback clock from Dart.
  // Pitch is stored and bridged, but independent pitch-preserving time
  // stretching requires a dedicated phase-vocoder/granular stage.
  (void)speed_.load();
  (void)pitchSemitones_.load();
}

}  // namespace music_player
