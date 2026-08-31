import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Android bridge for the native audio engine.
///
/// The channel is deliberately small. Existing AudioLibraryController
/// playback/library logic does not need to be rewritten.
class AudioEngineBridge {
  static const MethodChannel _channel = MethodChannel(
    'music_player_app/audio_engine',
  );

  Future<bool> prepare(String path) async {
    return await _channel.invokeMethod<bool>('prepare', {'path': path}) ??
        false;
  }

  Future<void> setPitch(double semitones) {
    return _channel.invokeMethod<void>('setPitch', {'semitones': semitones});
  }

  Future<void> setSpeed(double speed) {
    return _channel.invokeMethod<void>('setSpeed', {'speed': speed});
  }

  Future<void> setEq(List<double> bands) {
    return _channel.invokeMethod<void>('setEq', {'bands': bands});
  }

  Future<void> setKaraoke(double amount) {
    return _channel.invokeMethod<void>('setKaraoke', {'amount': amount});
  }

  Future<void> setSpatial(bool enabled, double depth) {
    return _channel.invokeMethod<void>('setSpatial', {
      'enabled': enabled,
      'depth': depth,
    });
  }

  Future<void> release() {
    return _channel.invokeMethod<void>('release');
  }

  Future<Uint8List?> renderPreview({
    required String path,
    int milliseconds = 1000,
  }) async {
    return _channel.invokeMethod<Uint8List>('renderPreview', {
      'path': path,
      'milliseconds': milliseconds,
    });
  }
}
