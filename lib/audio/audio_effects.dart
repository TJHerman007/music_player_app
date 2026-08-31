import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_algorithms.dart';

/// Real-time playback effects.
///
/// This class never creates or disposes an AudioPlayer.
class AudioEffects extends ChangeNotifier {
  AudioEffects({
    required AudioPlayer player,
  }) : _player = player;

  final AudioPlayer _player;

  double _speed = 1.0;
  double _pitchSemitones = 0.0;

  double get speed => _speed;
  double get pitchSemitones => _pitchSemitones;
  double get pitchFactor =>
      AudioAlgorithms.semitonesToPitchFactor(_pitchSemitones);

  Future<void> setSpeed(double value) async {
    final next = value.clamp(0.5, 2.0).toDouble();

    await _player.setSpeed(next);
    _speed = next;
    notifyListeners();
  }

  Future<void> setPitch(double semitones) async {
    final next = semitones.clamp(-12.0, 12.0).toDouble();
    final factor = AudioAlgorithms.semitonesToPitchFactor(next);

    await _player.setPitch(factor);
    _pitchSemitones = next;
    notifyListeners();
  }

  Future<void> resetSpeed() => setSpeed(1.0);

  Future<void> resetPitch() => setPitch(0.0);

  Future<void> reset() async {
    await _player.setSpeed(1.0);
    await _player.setPitch(1.0);

    _speed = 1.0;
    _pitchSemitones = 0.0;

    notifyListeners();
  }
}
