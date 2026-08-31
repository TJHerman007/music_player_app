import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class AudioSpatial extends ChangeNotifier {
  AudioSpatial({required AudioPlayer player}) : _player = player {
    _sessionSubscription = _player.androidAudioSessionIdStream.listen((
      sessionId,
    ) {
      _sessionId = sessionId;

      if (_enabled && sessionId != null) {
        _apply();
      }
    });
  }

  static const MethodChannel _channel = MethodChannel(
    'music_player/audio_spatial',
  );

  final AudioPlayer _player;
  StreamSubscription<int?>? _sessionSubscription;

  int? _sessionId;
  bool _enabled = false;
  double _strength = 0.70;

  bool get enabled => _enabled;
  double get strength => _strength;

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    notifyListeners();
    await _apply();
  }

  Future<void> setStrength(double strength) async {
    _strength = strength.clamp(0.0, 1.0).toDouble();
    notifyListeners();

    if (_enabled) {
      await _apply();
    }
  }

  Future<void> _apply() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final sessionId = _sessionId;
    if (sessionId == null) return;

    try {
      await _channel.invokeMethod<void>('setSpatialEnabled', <String, dynamic>{
        'enabled': _enabled,
        'sessionId': sessionId,
        'strength': (_strength * 1000).round(),
      });
    } on PlatformException {
      // Native spatial support is optional.
    } on MissingPluginException {
      // Native code has not been rebuilt yet.
    }
  }

  Future<void> reapply() => _apply();

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
