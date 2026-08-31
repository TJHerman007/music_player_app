#include "karaoke_engine.h"
#include <algorithm>

namespace music_player {

void KaraokeEngine::process(
    int16_t* samples,
    std::size_t frames,
    int channels,
    float amount) {

    if (!samples || channels < 2) return;

    amount = std::clamp(amount, 0.0f, 1.0f);

    for (std::size_t i = 0; i < frames; ++i) {
        const float l = samples[i * channels] / 32768.0f;
        const float r = samples[i * channels + 1] / 32768.0f;

        // Center channel = (L + R) / 2.
        // Reduce it while retaining side information.
        const float mid = (l + r) * 0.5f;
        const float side = (l - r) * 0.5f;

        const float outL = mid * (1.0f - amount) + side;
        const float outR = mid * (1.0f - amount) - side;

        samples[i * channels] =
            static_cast<int16_t>(std::clamp(outL, -1.0f, 1.0f) * 32767.0f);
        samples[i * channels + 1] =
            static_cast<int16_t>(std::clamp(outR, -1.0f, 1.0f) * 32767.0f);
    }
}

} // namespace music_player
