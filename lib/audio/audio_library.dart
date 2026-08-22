import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioTrack {
  const AudioTrack({required this.name, required this.path});

  final String name;
  final String path;
}

enum TrackSource { library, likedSongs, playlist }

enum AudioRepeatMode { off, all, one }

class AudioLibraryController extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  static const MethodChannel _deviceAudioChannel = MethodChannel(
    'music_player/device_audio',
  );
  final List<AudioTrack> tracks = [];
  final Set<String> _favoritePaths = <String>{};
  final Set<String> excludedExtensions = <String>{};
  final Set<String> _removedPaths = <String>{};

  AudioTrack? currentTrack;
  TrackSource currentSource = TrackSource.library;
  bool isBusy = false;
  bool shuffleEnabled = false;
  AudioRepeatMode repeatMode = AudioRepeatMode.off;
  bool excludeHiddenFiles = true;
  Uint8List? homeImageBytes;
  String? errorMessage;

  bool get isPlaying => player.playing;

  bool isFavorite(AudioTrack track) => _favoritePaths.contains(track.path);

  void toggleFavorite(AudioTrack track) {
    if (isFavorite(track)) {
      _favoritePaths.remove(track.path);
    } else {
      _favoritePaths.add(track.path);
    }
    notifyListeners();
  }

  void setExtensionExcluded(String extension, bool excluded) {
    if (excluded) {
      excludedExtensions.add(extension);
    } else {
      excludedExtensions.remove(extension);
    }
    _applyFilters();
  }

  void setExcludeHiddenFiles(bool excluded) {
    excludeHiddenFiles = excluded;
    _applyFilters();
  }

  void removeTrack(AudioTrack track) {
    _removedPaths.add(track.path);
    tracks.removeWhere((item) => item.path == track.path);
    if (currentTrack?.path == track.path) {
      player.stop();
      currentTrack = null;
    }
    notifyListeners();
  }

  Future<void> toggleShuffle(bool enabled) async {
    shuffleEnabled = enabled;
    await player.setShuffleModeEnabled(enabled);
    notifyListeners();
  }

  Future<void> toggleRepeat(bool enabled) async {
    await setRepeatMode(enabled ? AudioRepeatMode.one : AudioRepeatMode.off);
  }

  Future<void> setRepeatMode(AudioRepeatMode mode) async {
    repeatMode = mode;
    await player.setLoopMode(switch (mode) {
      AudioRepeatMode.off => LoopMode.off,
      AudioRepeatMode.all => LoopMode.all,
      AudioRepeatMode.one => LoopMode.one,
    });
    notifyListeners();
  }

  Future<void> cycleRepeatMode() async {
    final nextMode = switch (repeatMode) {
      AudioRepeatMode.off => AudioRepeatMode.all,
      AudioRepeatMode.all => AudioRepeatMode.one,
      AudioRepeatMode.one => AudioRepeatMode.off,
    };
    await setRepeatMode(nextMode);
  }

  Future<bool> scanDeviceMusic() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    if (isBusy) return false;

    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      final audioPermission = await Permission.audio.request();
      final storagePermission = await Permission.storage.request();
      if (!audioPermission.isGranted && !storagePermission.isGranted) {
        errorMessage = 'Music permission was not granted.';
        return false;
      }

      final songs = await _deviceAudioChannel.invokeMethod<List<dynamic>>(
        'scanAudio',
      );
      for (final item in songs ?? const <dynamic>[]) {
        final song = Map<String, dynamic>.from(item as Map);
        final path = song['path'] as String?;
        if (path == null) continue;
        if (!_isAllowedAudio(path)) continue;
        if (_isAllowedAudio(path) &&
            !_removedPaths.contains(path) &&
            tracks.every((track) => track.path != path)) {
          tracks.add(
            AudioTrack(
              name: song['title'] as String? ?? 'Unknown track',
              path: path,
            ),
          );
        }
      }
      return true;
    } catch (_) {
      errorMessage = 'Could not scan music on this phone.';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> importAudioFiles() async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // The system picker can grant access to selected files even when the
        // broader media permission is denied.
        await Permission.audio.request();
      }

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'flac', 'm4a'],
      );

      if (result.isEmpty) return false;
      for (final file in result) {
        final path = file.path;
        if (path == null || path.isEmpty) continue;
        if (!_removedPaths.contains(path) &&
            tracks.every((track) => track.path != path)) {
          tracks.add(AudioTrack(name: file.name, path: path));
        }
      }
      return true;
    } catch (_) {
      errorMessage = 'Could not access the selected music files.';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> pickHomeImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result.isEmpty) return false;
      final bytes = await result.first.readAsBytes();
      if (bytes.isEmpty) return false;
      homeImageBytes = bytes;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Could not load the selected image.';
      notifyListeners();
      return false;
    }
  }

  Future<void> playTrack(
    AudioTrack track, {
    TrackSource source = TrackSource.library,
  }) async {
    try {
      if (currentTrack?.path != track.path) {
        await player.setFilePath(track.path);
        currentTrack = track;
      }
      currentSource = source;
      await player.play();
      notifyListeners();
    } catch (_) {
      errorMessage = 'This audio file could not be played.';
      notifyListeners();
    }
  }

  Future<void> togglePlayback() async {
    if (currentTrack == null) return;
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
    notifyListeners();
  }

  Future<void> nextTrack() async {
    if (tracks.isEmpty) return;
    final currentIndex = currentTrack == null
        ? -1
        : tracks.indexWhere((track) => track.path == currentTrack!.path);
    final nextIndex = (currentIndex + 1) % tracks.length;
    await playTrack(tracks[nextIndex], source: currentSource);
  }

  Future<void> previousTrack() async {
    if (tracks.isEmpty) return;
    final currentIndex = currentTrack == null
        ? 0
        : tracks.indexWhere((track) => track.path == currentTrack!.path);
    final previousIndex = (currentIndex - 1 + tracks.length) % tracks.length;
    await playTrack(tracks[previousIndex], source: currentSource);
  }

  bool _isSupportedAudio(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mp3') ||
        lowerPath.endsWith('.wav') ||
        lowerPath.endsWith('.flac') ||
        lowerPath.endsWith('.m4a');
  }

  bool _isAllowedAudio(String path) {
    if (!_isSupportedAudio(path)) return false;
    final lowerPath = path.toLowerCase();
    if (excludeHiddenFiles &&
        lowerPath.split('/').any((part) => part.startsWith('.'))) {
      return false;
    }
    return excludedExtensions.every(
      (extension) => !lowerPath.endsWith('.$extension'),
    );
  }

  void _applyFilters() {
    tracks.removeWhere((track) => !_isAllowedAudio(track.path));
    if (currentTrack != null && !_isAllowedAudio(currentTrack!.path)) {
      player.stop();
      currentTrack = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
