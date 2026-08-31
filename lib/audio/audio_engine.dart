import 'package:flutter/foundation.dart';

import 'audio_effects.dart';
import 'audio_engine_bridge.dart';

/// Single public audio-effects state for the player.
///
/// This class owns the Flutter-side effect state and forwards
/// every change to the native audio engine.
class AudioEngine extends ChangeNotifier {
  AudioEngine();

  final AudioEffects effects = AudioEffects();
  final AudioEngineBridge _bridge = AudioEngineBridge();

  bool _spatialEnabled = false;
  double _spatialDepth = 0.70;
  bool _karaokeEnabled = false;

  bool get spatialEnabled => _spatialEnabled;
  double get spatialDepth => _spatialDepth;
  bool get karaokeEnabled => _karaokeEnabled;

  // ============================================================
  // PITCH
  // ============================================================

  Future<void> setPitch(double value) async {
    effects.setPitch(value);

    await _bridge.setPitch(effects.pitchSemitones);

    notifyListeners();
  }

  // ============================================================
  // SPEED
  // ============================================================

  Future<void> setSpeed(double value) async {
    effects.setSpeed(value);

    await _bridge.setSpeed(effects.speed);

    notifyListeners();
  }

  // ============================================================
  // EQ
  // ============================================================

  Future<void> setEq(List<double> bands) async {
    effects.setEq(bands);

    await _bridge.setEq(effects.eq);

    notifyListeners();
  }

  Future<void> setEqBand(int index, double value) async {
    effects.setEqBand(index, value);

    await _bridge.setEq(effects.eq);

    notifyListeners();
  }

  // ============================================================
  // KARAOKE
  // ============================================================

  Future<void> setKaraokeEnabled(bool value) async {
    _karaokeEnabled = value;

    await _bridge.setKaraoke(value ? 1.0 : 0.0);

    notifyListeners();
  }

  // ============================================================
  // SPATIAL AUDIO
  // ============================================================

  Future<void> setSpatial(bool enabled, double depth) async {
    _spatialEnabled = enabled;
    _spatialDepth = depth.clamp(0.0, 1.0);

    await _bridge.setSpatial(_spatialEnabled, _spatialDepth);

    notifyListeners();
  }

  Future<void> setSpatialEnabled(bool value) async {
    _spatialEnabled = value;

    await _bridge.setSpatial(_spatialEnabled, _spatialDepth);

    notifyListeners();
  }

  Future<void> setSpatialDepth(double value) async {
    _spatialDepth = value.clamp(0.0, 1.0);

    if (_spatialEnabled) {
      await _bridge.setSpatial(true, _spatialDepth);
    }

    notifyListeners();
  }

  // ============================================================
  // RESET
  // ============================================================

  Future<void> reset() async {
    effects.reset();

    _spatialEnabled = false;
    _spatialDepth = 0.70;
    _karaokeEnabled = false;

    // Reset native pitch.
    await _bridge.setPitch(0.0);

    // Reset native speed.
    await _bridge.setSpeed(1.0);

    // Reset all 10 EQ bands.
    await _bridge.setEq(List<double>.filled(10, 0.0));

    // Disable karaoke.
    await _bridge.setKaraoke(0.0);

    // Disable spatial audio.
    await _bridge.setSpatial(false, 0.70);

    notifyListeners();
  }
}
