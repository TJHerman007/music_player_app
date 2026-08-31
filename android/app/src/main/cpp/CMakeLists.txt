cmake_minimum_required(VERSION 3.22.1)

project(music_player_audio_engine)

add_library(
    music_player_audio_engine
    SHARED
    audio_engine.cpp
    karaoke_engine.cpp
    karaoke_jni.cpp
)

target_compile_features(
    music_player_audio_engine
    PRIVATE
    cxx_std_17
)

target_compile_options(
    music_player_audio_engine
    PRIVATE
    -O2
    -ffast-math
)

target_link_libraries(
    music_player_audio_engine
    android
    log
)
