import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:media_metadata/media_metadata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic>? _decodeState(String rawState) {
  final decoded = jsonDecode(rawState);
  if (decoded is! Map) return null;
  return Map<String, dynamic>.from(decoded);
}

class AudioTrack {
  const AudioTrack({required this.name, required this.path});

  final String name;
  final String path;
}

class AudioPlaylist {
  const AudioPlaylist({
    required this.id,
    required this.name,
    required this.trackPaths,
  });

  final String id;
  final String name;
  final List<String> trackPaths;

  AudioPlaylist copyWith({String? name, List<String>? trackPaths}) {
    return AudioPlaylist(
      id: id,
      name: name ?? this.name,
      trackPaths: trackPaths ?? this.trackPaths,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trackPaths': trackPaths,
  };

  factory AudioPlaylist.fromJson(Map<String, dynamic> json) {
    return AudioPlaylist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled playlist',
      trackPaths: (json['trackPaths'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

enum TrackSource { library, likedSongs, playlist, allSongs }

enum AudioRepeatMode { off, all, one }

class AudioLibraryController extends ChangeNotifier {
  AudioLibraryController({this._preferences, Future<void>? backgroundReady})
    : _backgroundReady = backgroundReady ?? Future<void>.value() {
    unawaited(_backgroundReady);
    unawaited(ready);
    unawaited(_restorePlaylists());
    unawaited(_restoreHomeImage());
    unawaited(player.setShuffleModeEnabled(shuffleEnabled));
    unawaited(player.setLoopMode(_loopModeFor(repeatMode)));
  }

  static const _stateKey = 'audio_library_state';
  static const _playlistStateKey = 'audio_library_playlists';
  static const int maxPlaylists = 50;

  final AudioPlayer player = AudioPlayer();
  final SharedPreferences? _preferences;
  final Future<void> _backgroundReady;
  Future<void> _persistenceQueue = Future<void>.value();
  Timer? _persistDebounce;
  final Map<String, Future<Uint8List?>> _artworkRequests = {};
  Map<String, List<ArtistGroup>>? _artistCategoryCache;
  static const MethodChannel _deviceAudioChannel = MethodChannel(
    'music_player/device_audio',
  );
  final List<AudioTrack> tracks = [];
  final Set<String> _favoritePaths = <String>{};
  final Set<String> excludedExtensions = <String>{};
  final Set<String> _removedPaths = <String>{};
  List<AudioPlaylist> _playlists = <AudioPlaylist>[];
  static const int maxRecentlyPlayed = 20;
  final List<String> _recentlyPlayedPaths = <String>[];

  AudioTrack? currentTrack;
  TrackSource currentSource = TrackSource.library;
  bool isBusy = false;
  bool isRestoring = true;
  bool shuffleEnabled = false;
  AudioRepeatMode repeatMode = AudioRepeatMode.off;
  bool excludeHiddenFiles = true;
  Uint8List? homeImageBytes;
  ui.Color? nowPlayingAccent;
  String? errorMessage;

  Future<void> get ready => _restoreFuture;
  List<AudioPlaylist> get playlists => List.unmodifiable(_playlists);
  late final Future<void> _restoreFuture = _restoreState();

  /// Most-recently played tracks first. Entries whose file has since been
  /// removed from the library are skipped.
  List<AudioTrack> get recentlyPlayed {
    final byPath = {for (final track in tracks) track.path: track};
    return _recentlyPlayedPaths
        .map((path) => byPath[path])
        .whereType<AudioTrack>()
        .toList(growable: false);
  }

  void _recordRecentlyPlayed(AudioTrack track) {
    _recentlyPlayedPaths.remove(track.path);
    _recentlyPlayedPaths.insert(0, track.path);
    while (_recentlyPlayedPaths.length > maxRecentlyPlayed) {
      _recentlyPlayedPaths.removeLast();
    }
  }

  bool get isPlaying => player.playing;
  bool get nowPlaying => player.playing && currentTrack != null;

  bool isFavorite(AudioTrack track) => _favoritePaths.contains(track.path);

  void toggleFavorite(AudioTrack track) {
    if (isFavorite(track)) {
      _favoritePaths.remove(track.path);
    } else {
      _favoritePaths.add(track.path);
    }
    _notifyAndPersist();
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
    for (var index = 0; index < _playlists.length; index++) {
      final playlist = _playlists[index];
      if (playlist.trackPaths.contains(track.path)) {
        _playlists[index] = playlist.copyWith(
          trackPaths: playlist.trackPaths
              .where((path) => path != track.path)
              .toList(growable: false),
        );
      }
    }
    _artistCategoryCache = null;
    if (currentTrack?.path == track.path) {
      player.stop();
      currentTrack = null;
    }
    _notifyAndPersist();
  }

  Future<void> createPlaylist(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || _playlists.length >= maxPlaylists) return;
    _playlists = [
      ..._playlists,
      AudioPlaylist(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: trimmedName,
        trackPaths: const [],
      ),
    ];
    await _persistPlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(AudioPlaylist playlist) async {
    _playlists = _playlists.where((item) => item.id != playlist.id).toList();
    await _persistPlaylists();
    notifyListeners();
  }

  Future<void> addToPlaylist(AudioTrack track, AudioPlaylist playlist) async {
    if (playlist.trackPaths.contains(track.path)) return;
    final updated = playlist.copyWith(
      trackPaths: [...playlist.trackPaths, track.path],
    );
    _replacePlaylist(updated);
    await _persistPlaylists();
    notifyListeners();
  }

  Future<void> removeFromPlaylist(
    AudioTrack track,
    AudioPlaylist playlist,
  ) async {
    final updated = playlist.copyWith(
      trackPaths: playlist.trackPaths
          .where((path) => path != track.path)
          .toList(growable: false),
    );
    _replacePlaylist(updated);
    await _persistPlaylists();
    notifyListeners();
  }

  AudioPlaylist? playlistForId(String id) {
    for (final playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  List<AudioTrack> tracksForPlaylist(AudioPlaylist playlist) {
    final tracksByPath = {for (final track in tracks) track.path: track};
    return playlist.trackPaths
        .map((path) => tracksByPath[path])
        .whereType<AudioTrack>()
        .toList(growable: false);
  }

  void _replacePlaylist(AudioPlaylist updated) {
    _playlists = _playlists
        .map((playlist) => playlist.id == updated.id ? updated : playlist)
        .toList(growable: false);
  }

  Future<void> _restorePlaylists() async {
    final raw = _preferences?.getString(_playlistStateKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _playlists = decoded
          .whereType<Map>()
          .map(
            (item) => AudioPlaylist.fromJson(Map<String, dynamic>.from(item)),
          )
          .where(
            (playlist) => playlist.id.isNotEmpty && playlist.name.isNotEmpty,
          )
          .take(maxPlaylists)
          .toList(growable: true);
      notifyListeners();
    } catch (_) {
      _playlists = <AudioPlaylist>[];
    }
  }

  Future<void> _persistPlaylists() async {
    final preferences = _preferences;
    if (preferences == null) return;
    await preferences.setString(
      _playlistStateKey,
      jsonEncode(_playlists.map((playlist) => playlist.toJson()).toList()),
    );
  }

  Future<void> toggleShuffle(bool enabled) async {
    shuffleEnabled = enabled;
    await player.setShuffleModeEnabled(enabled);
    _notifyAndPersist();
  }

  Future<void> toggleRepeat(bool enabled) async {
    await setRepeatMode(enabled ? AudioRepeatMode.one : AudioRepeatMode.off);
  }

  Future<void> setRepeatMode(AudioRepeatMode mode) async {
    repeatMode = mode;
    await player.setLoopMode(_loopModeFor(mode));
    _notifyAndPersist();
  }

  Future<void> cycleRepeatMode() async {
    final nextMode = switch (repeatMode) {
      AudioRepeatMode.off => AudioRepeatMode.all,
      AudioRepeatMode.all => AudioRepeatMode.one,
      AudioRepeatMode.one => AudioRepeatMode.off,
    };
    await setRepeatMode(nextMode);
  }

  /// Scans the device for newly added music.
  ///
  /// The existing library is restored from SharedPreferences at startup, so
  /// this scan only needs to be run when the user explicitly refreshes the
  /// library (or when the app wants to discover newly added files).
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

      // The native query itself is awaited, so Flutter isn't blocked while
      // waiting for Android. The Android side should also keep this query off
      // the main/UI thread for very large libraries.
      final songs = await _deviceAudioChannel.invokeMethod<List<dynamic>>(
        'scanAudio',
      );

      final existingPaths = <String>{...tracks.map((track) => track.path)};
      final pending = <AudioTrack>[];

      const batchSize = 32;
      final result = songs ?? const <dynamic>[];
      _artistCategoryCache = null;

      for (var i = 0; i < result.length; i++) {
        final item = result[i];

        if (item is Map) {
          final song = Map<String, dynamic>.from(item);
          final path = song['path'] as String?;
          final title = song['title'] as String? ?? 'Unknown track';

          if (path != null &&
              path.isNotEmpty &&
              _isAllowedAudio(path) &&
              !_removedPaths.contains(path) &&
              existingPaths.add(path)) {
            final oldPathIndex = path.startsWith('content://')
                ? tracks.indexWhere(
                    (track) =>
                        track.name == title &&
                        !track.path.startsWith('content://'),
                  )
                : -1;
            if (oldPathIndex >= 0) {
              tracks[oldPathIndex] = AudioTrack(name: title, path: path);
            } else {
              pending.add(AudioTrack(name: title, path: path));
            }
          }
        }

        if (pending.length >= batchSize || i == result.length - 1) {
          if (pending.isNotEmpty) {
            tracks.addAll(pending);
            pending.clear();

            // Only one rebuild per batch. Yield immediately afterward so
            // Flutter can paint, animate and process scrolling/navigation.
            notifyListeners();
            await Future<void>.delayed(Duration.zero);
          }
        }
      }

      _schedulePersist();
      return true;
    } catch (_) {
      errorMessage = 'Could not scan music on this phone.';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// Removes entries whose files no longer exist.
  ///
  /// This is intentionally separate from startup so opening the app stays fast.
  Future<void> removeMissingTracks() async {
    final missing = <String>{};

    for (final track in tracks) {
      if (!track.path.startsWith('content://') &&
          !await File(track.path).exists()) {
        missing.add(track.path);
      }
    }

    if (missing.isEmpty) return;

    tracks.removeWhere((track) => missing.contains(track.path));
    _favoritePaths.removeWhere(missing.contains);
    _removedPaths.addAll(missing);

    if (currentTrack != null && missing.contains(currentTrack!.path)) {
      await player.stop();
      currentTrack = null;
    }

    _notifyAndPersist();
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
      _artistCategoryCache = null;
      _schedulePersist();
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
      final directory = await getApplicationSupportDirectory();
      final artworkFile = File(
        '${directory.path}${Platform.pathSeparator}home_artwork',
      );
      await artworkFile.writeAsBytes(bytes, flush: true);
      homeImageBytes = bytes;
      _notifyAndPersist();
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
        final mediaItem = MediaItem(id: track.path, title: track.name);
        if (track.path.startsWith('content://')) {
          try {
            final cachedPath = await _deviceAudioChannel.invokeMethod<String>(
              'resolveAudio',
              {'uri': track.path},
            );
            if (cachedPath == null || cachedPath.isEmpty) {
              throw StateError('Audio file could not be resolved.');
            }
            await player.setFilePath(cachedPath, tag: mediaItem);
          } on MissingPluginException {
            // Allow hot-reloaded older APKs to play before native code is rebuilt.
            await player.setAudioSource(
              AudioSource.uri(Uri.parse(track.path), tag: mediaItem),
            );
          }
        } else {
          await player.setFilePath(track.path, tag: mediaItem);
        }
        currentTrack = track;
        unawaited(_updateNowPlayingAccent(track));
      }
      currentSource = source;
      _recordRecentlyPlayed(track);
      await player.play();
      _notifyAndPersist();
    } catch (error) {
      debugPrint('Could not play ${track.path}: $error');
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
    if (path.startsWith('content://')) return true;
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
    _artistCategoryCache = null;
    if (currentTrack != null && !_isAllowedAudio(currentTrack!.path)) {
      player.stop();
      currentTrack = null;
    }
    _notifyAndPersist();
  }

  static LoopMode _loopModeFor(AudioRepeatMode mode) => switch (mode) {
    AudioRepeatMode.off => LoopMode.off,
    AudioRepeatMode.all => LoopMode.all,
    AudioRepeatMode.one => LoopMode.one,
  };

  Future<void> _restoreState() async {
    final rawState = _preferences?.getString(_stateKey);
    if (rawState == null) {
      isRestoring = false;
      return;
    }
    try {
      final decodedState = await compute(_decodeState, rawState);
      if (decodedState == null) return;
      final state = decodedState;
      final savedTracks = (state['tracks'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((track) => Map<String, dynamic>.from(track))
          .map(
            (track) => AudioTrack(
              name: track['name'] as String? ?? 'Unknown track',
              path: track['path'] as String? ?? '',
            ),
          )
          .where((track) => track.path.isNotEmpty)
          .toList();
      // Restore the previously scanned library immediately. We intentionally
      // do not scan the device here; the saved paths are the startup library.
      tracks.addAll(savedTracks.where((track) => _isAllowedAudio(track.path)));

      _favoritePaths.addAll(
        (state['favoritePaths'] as List<dynamic>? ?? const [])
            .whereType<String>(),
      );
      excludedExtensions.addAll(
        (state['excludedExtensions'] as List<dynamic>? ?? const [])
            .whereType<String>(),
      );
      _removedPaths.addAll(
        (state['removedPaths'] as List<dynamic>? ?? const [])
            .whereType<String>(),
      );
      shuffleEnabled = state['shuffleEnabled'] as bool? ?? false;
      excludeHiddenFiles = state['excludeHiddenFiles'] as bool? ?? true;
      repeatMode = switch (state['repeatMode']) {
        'all' => AudioRepeatMode.all,
        'one' => AudioRepeatMode.one,
        _ => AudioRepeatMode.off,
      };
      _recentlyPlayedPaths.addAll(
        (state['recentlyPlayedPaths'] as List<dynamic>? ?? const [])
            .whereType<String>(),
      );
    } catch (_) {
      // Ignore malformed older data and start with an empty library.
    } finally {
      isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> _restoreHomeImage() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final artworkFile = File(
        '${directory.path}${Platform.pathSeparator}home_artwork',
      );
      if (!await artworkFile.exists()) return;
      final bytes = await artworkFile.readAsBytes();
      if (bytes.isEmpty) return;
      homeImageBytes = bytes;
      notifyListeners();
    } catch (_) {
      // Artwork is optional, so a missing or unreadable file is harmless.
    }
  }

  void _notifyAndPersist() {
    notifyListeners();
    _schedulePersist();
  }

  /// Coalesces rapid state changes into one SharedPreferences write.
  /// This prevents repeated JSON encoding/writes from contributing to UI lag.
  void _schedulePersist() {
    if (_preferences == null) return;

    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 300), _persistState);
  }

  void _persistState() {
    if (_preferences == null) return;

    final snapshot = jsonEncode({
      'tracks': tracks
          .map((track) => {'name': track.name, 'path': track.path})
          .toList(growable: false),
      'favoritePaths': _favoritePaths.toList(growable: false),
      'excludedExtensions': excludedExtensions.toList(growable: false),
      'removedPaths': _removedPaths.toList(growable: false),
      'shuffleEnabled': shuffleEnabled,
      'repeatMode': repeatMode.name,
      'excludeHiddenFiles': excludeHiddenFiles,
      'recentlyPlayedPaths': _recentlyPlayedPaths,
    });

    _persistenceQueue = _persistenceQueue.then(
      (_) => _preferences.setString(_stateKey, snapshot),
    );
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    _persistState();
    player.dispose();
    super.dispose();
  }

  /// Reads the embedded cover image (ID3 APIC / MP4 covr / FLAC picture) from
  /// the actual audio file. The Future is cached so each file is parsed once.
  Future<Uint8List?> artworkFor(AudioTrack track) {
    return _artworkRequests.putIfAbsent(track.path, () async {
      try {
        final bytes = track.path.startsWith('content://')
            ? await _deviceAudioChannel.invokeMethod<Uint8List>('readArtwork', {
                'uri': track.path,
              })
            : (await MediaMetadata.read(track.path))?.imageMetadata?.data;
        return bytes != null && bytes.isNotEmpty ? bytes : null;
      } catch (_) {
        return null;
      }
    });
  }

  Future<void> _updateNowPlayingAccent(AudioTrack track) async {
    final artwork = await artworkFor(track);
    if (currentTrack?.path != track.path) return;
    if (artwork == null) {
      nowPlayingAccent = null;
      notifyListeners();
      return;
    }
    try {
      final codec = await ui.instantiateImageCodec(
        artwork,
        targetWidth: 24,
        targetHeight: 24,
      );
      final frame = await codec.getNextFrame();
      final bytes = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      frame.image.dispose();
      if (bytes == null || currentTrack?.path != track.path) return;
      final pixels = bytes.buffer.asUint8List();
      var red = 0;
      var green = 0;
      var blue = 0;
      var samples = 0;
      for (var index = 0; index < pixels.length; index += 16) {
        final r = pixels[index];
        final g = pixels[index + 1];
        final b = pixels[index + 2];
        if (r + g + b < 50 || r + g + b > 710) continue;
        red += r;
        green += g;
        blue += b;
        samples++;
      }
      nowPlayingAccent = samples == 0
          ? null
          : ui.Color.fromARGB(
              255,
              red ~/ samples,
              green ~/ samples,
              blue ~/ samples,
            );
      notifyListeners();
    } catch (_) {
      // A cover that cannot be decoded simply leaves the theme unchanged.
    }
  }
}

/// Extended data class representing an artist group
class ArtistGroup {
  const ArtistGroup({required this.artistName, required this.tracks});

  final String artistName;
  final List<AudioTrack> tracks;

  int get trackCount => tracks.length;

  /// Returns the alphabetical header section (A-Z or #)
  String get sectionHeader {
    if (artistName.isEmpty) return '#';
    final char = artistName[0].toUpperCase();
    return RegExp(r'[A-Z]').hasMatch(char) ? char : '#';
  }
}

extension ArtistCategorization on AudioLibraryController {
  /// Extracts, groups, and categorizes tracks by artist alphabetically (A-Z, #)
  Map<String, List<ArtistGroup>> getCategorizedArtists() {
    final cached = _artistCategoryCache;
    if (cached != null) return cached;

    final Map<String, List<AudioTrack>> artistToTracks = {};

    for (final track in tracks) {
      // Infers artist name from file name or path if not explicit
      final artistName = _extractArtistName(track);
      artistToTracks.putIfAbsent(artistName, () => []).add(track);
    }

    final List<ArtistGroup> groups = artistToTracks.entries
        .map(
          (entry) => ArtistGroup(
            artistName: entry.key,
            tracks: List.unmodifiable(entry.value),
          ),
        )
        .toList();

    final Map<String, List<ArtistGroup>> categorized = {};

    for (final group in groups) {
      final header = group.sectionHeader;
      categorized.putIfAbsent(header, () => []).add(group);
    }

    // Sort categories (A-Z, with # placed at the end)
    final sortedKeys = categorized.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });

    final Map<String, List<ArtistGroup>> result = {};
    for (final key in sortedKeys) {
      final artistList = categorized[key]!;
      artistList.sort(
        (a, b) =>
            a.artistName.toLowerCase().compareTo(b.artistName.toLowerCase()),
      );
      result[key] = artistList;
    }

    final cachedResult = Map<String, List<ArtistGroup>>.unmodifiable(
      result.map(
        (key, value) => MapEntry(key, List<ArtistGroup>.unmodifiable(value)),
      ),
    );

    _artistCategoryCache = cachedResult;
    return cachedResult;
  }

  /// Helper method to extract artist names from "Artist - Title.mp3" formats
  String _extractArtistName(AudioTrack track) {
    if (track.name.contains(' - ')) {
      final parts = track.name.split(' - ');
      if (parts[0].trim().isNotEmpty) {
        return parts[0].trim();
      }
    }
    return 'Unknown Artist';
  }
}
