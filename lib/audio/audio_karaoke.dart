import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Local karaoke processing.
///
/// This first implementation uses center-channel cancellation. It is not
/// AI stem separation. The class is isolated so a future stem-separation
/// engine can replace the processing algorithm without changing the UI.
class AudioKaraoke {
  const AudioKaraoke();

  Future<String?> process({
    required String inputPath,
    String? cacheKey,
  }) async {
    final source = File(inputPath);

    if (!await source.exists()) return null;

    final directory = await getTemporaryDirectory();

    final safeKey = (cacheKey ?? inputPath.hashCode.toString())
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    final outputPath =
        '${directory.path}${Platform.pathSeparator}'
        'music_player_karaoke_$safeKey.m4a';

    final output = File(outputPath);

    if (await output.exists() && await output.length() > 0) {
      return outputPath;
    }

    try {
      final session = await FFmpegKit.executeWithArguments([
        '-y',
        '-i',
        inputPath,
        '-vn',
        '-af',
        'pan=stereo|FL=0.5*c0-0.5*c1|FR=0.5*c1-0.5*c0',
        '-c:a',
        'aac',
        '-b:a',
        '256k',
        outputPath,
      ]);

      final code = await session.getReturnCode();

      if (ReturnCode.isSuccess(code) &&
          await output.exists() &&
          await output.length() > 0) {
        return outputPath;
      }
    } catch (_) {
      // Processing failure should never crash playback.
    }

    if (await output.exists()) {
      try {
        await output.delete();
      } catch (_) {}
    }

    return null;
  }

  Future<bool> applyToPlayer({
    required AudioPlayer player,
    required String processedPath,
  }) async {
    final position = player.position;
    final playing = player.playing;

    try {
      await player.setFilePath(processedPath);
      await player.seek(position);

      if (playing) {
        await player.play();
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearCache() async {
    final directory = await getTemporaryDirectory();

    if (!await directory.exists()) return;

    await for (final entity in directory.list()) {
      if (entity is File &&
          entity.path.contains(
            '${Platform.pathSeparator}music_player_karaoke_',
          )) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }
}
