#pragma once

#include <cstddef>
#include <cstdint>

namespace music_player {

class KaraokeEngine {
public:
    static void process(
        int16_t* samples,
        std::size_t frames,
        int channels,
        float amount);
};

} // namespace music_player
