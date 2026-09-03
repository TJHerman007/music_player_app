import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio_effects.dart';
import 'audio_engine_bridge.dart';

/// Single public audio-effects state for the player.
///
/// This class owns the Flutter-side effect state and forwards
/// every change to the native audio engine.
class AudioEngine extends ChangeNotifier {
  AudioEngine({Future<void> Function(double speed)? onSpeedChanged})
    : _onSpeedChanged = onSpeedChanged;

  final AudioEffects effects = AudioEffects();
  final AudioEngineBridge _bridge = AudioEngineBridge();
  Future<void> Function(double speed)? _onSpeedChanged;

  void setPlaybackSpeedHandler(
    Future<void> Function(double speed)? handler,
  ) {
    _onSpeedChanged = handler;
  }

  void _send(
    Future<void> Function() operation,
    String label,
  ) {
    unawaited(
      operation().catchError((Object error, StackTrace stack) {
        debugPrint('AudioEngine $label failed: $error');
        debugPrintStack(stackTrace: stack);
      }),
    );
  }

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
    notifyListeners();
    _send(
      () => _bridge.setPitch(effects.pitchSemitones),
      'pitch',
    );
  }


  // ============================================================
  // SPEED
  // ============================================================

  Future<void> setSpeed(double value) async {
    effects.setSpeed(value);
    notifyListeners();

    final handler = _onSpeedChanged;
    if (handler != null) {
      unawaited(
        handler(effects.speed).catchError((Object error, StackTrace stack) {
          debugPrint('AudioEngine playback speed failed: $error');
          debugPrintStack(stackTrace: stack);
        }),
      );
    }

    _send(
      () => _bridge.setSpeed(effects.speed),
      'speed',
    );
  }

  // ============================================================
  // EQ
  // ============================================================

  Future<void> setEq(List<double> bands) async {
    effects.setEq(bands);
    notifyListeners();
    _send(() => _bridge.setEq(effects.eq), 'eq');
  }

  Future<void> setEqBand(int index, double value) async {
    effects.setEqBand(index, value);
    notifyListeners();
    _send(() => _bridge.setEq(effects.eq), 'eq');
  }

  // ============================================================
  // KARAOKE
  // ============================================================

  Future<void> setKaraokeEnabled(bool value) async {
    _karaokeEnabled = value;
    notifyListeners();
    _send(
      () => _bridge.setKaraoke(value ? 1.0 : 0.0),
      'karaoke',
    );
  }

  // ============================================================
  // SPATIAL AUDIO
  // ============================================================

  Future<void> setSpatial(bool enabled, double depth) async {
    _spatialEnabled = enabled;
    _spatialDepth = depth.clamp(0.0, 1.0);
    notifyListeners();
    _send(
      () => _bridge.setSpatial(_spatialEnabled, _spatialDepth),
      'spatial',
    );
  }

  Future<void> setSpatialEnabled(bool value) async {
    _spatialEnabled = value;
    notifyListeners();
    _send(
      () => _bridge.setSpatial(_spatialEnabled, _spatialDepth),
      'spatial',
    );
  }

  Future<void> setSpatialDepth(double value) async {
    _spatialDepth = value.clamp(0.0, 1.0);
    notifyListeners();
    if (_spatialEnabled) {
      _send(
        () => _bridge.setSpatial(true, _spatialDepth),
        'spatial depth',
      );
    }
  }

  // ============================================================
  // RESET
  // ============================================================

  Future<void> reset() async {
    effects.reset();
    _spatialEnabled = false;
    _spatialDepth = 0.70;
    _karaokeEnabled = false;

    notifyListeners();

    _send(() => _bridge.setPitch(0.0), 'reset pitch');
    _send(() => _bridge.setSpeed(1.0), 'reset speed');
    _send(
      () => _bridge.setEq(List<double>.filled(10, 0.0)),
      'reset eq',
    );
    _send(() => _bridge.setKaraoke(0.0), 'reset karaoke');
    _send(() => _bridge.setSpatial(false, 0.70), 'reset spatial');

    final handler = _onSpeedChanged;
    if (handler != null) {
      unawaited(
        handler(1.0).catchError((Object error, StackTrace stack) {
          debugPrint('AudioEngine reset playback speed failed: $error');
          debugPrintStack(stackTrace: stack);
        }),
      );
    }
  }

  @override
  void dispose() {
    effects.dispose();
    super.dispose();
  }
}
