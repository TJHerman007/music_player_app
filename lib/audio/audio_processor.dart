import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_effects.dart';
import 'audio_karaoke.dart';
import 'audio_spatial.dart';

/// Single entry point for all audio processing.
///
/// The AudioPlayer is supplied by AudioLibraryController. This class does
/// NOT create another player.
class AudioProcessor extends ChangeNotifier {
  AudioProcessor({
    required AudioPlayer player,
  })  : _player = player,
        effects = AudioEffects(player: player),
        spatial = AudioSpatial(player: player),
        karaoke = const AudioKaraoke() {
    effects.addListener(_childChanged);
    spatial.addListener(_childChanged);
  }

  final AudioPlayer _player;

  final AudioEffects effects;
  final AudioSpatial spatial;
  final AudioKaraoke karaoke;

  bool _karaokeEnabled = false;
  String? _karaokePath;

  AudioPlayer get player => _player;
  bool get karaokeEnabled => _karaokeEnabled;
  String? get karaokePath => _karaokePath;

  void _childChanged() {
    notifyListeners();
  }

  Future<bool> enableKaraoke({
    required String originalResolvedPath,
    String? cacheKey,
  }) async {
    final processedPath = await karaoke.process(
      inputPath: originalResolvedPath,
      cacheKey: cacheKey,
    );

    if (processedPath == null) return false;

    final applied = await karaoke.applyToPlayer(
      player: _player,
      processedPath: processedPath,
    );

    if (!applied) return false;

    _karaokeEnabled = true;
    _karaokePath = processedPath;

    notifyListeners();
    return true;
  }

  Future<bool> disableKaraoke({
    required String originalResolvedPath,
  }) async {
    final position = _player.position;
    final playing = _player.playing;

    try {
      await _player.setFilePath(originalResolvedPath);
      await _player.seek(position);

      if (playing) {
        await _player.play();
      }

      _karaokeEnabled = false;
      _karaokePath = null;

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reset() async {
    await effects.reset();

    if (spatial.enabled) {
      await spatial.setEnabled(false);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    effects.removeListener(_childChanged);
    spatial.removeListener(_childChanged);

    effects.dispose();
    spatial.dispose();

    super.dispose();
  }
}
