import 'package:flutter/material.dart';

import '../audio/audio_library.dart';
import '../theme/theme_provider.dart';
import '../widgets/glass_surface.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.themeProvider,
    required this.audioLibrary,
    super.key,
  });

  final ThemeProvider themeProvider;
  final AudioLibraryController audioLibrary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: GlassBackground(
        child: ListenableBuilder(
          listenable: Listenable.merge([audioLibrary, themeProvider]),
          builder: (context, child) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              GlassSurface(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.palette_outlined),
                      title: Text('Theme'),
                      subtitle: Text('Choose how the app follows appearance'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_outlined),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {themeProvider.themeMode},
                        onSelectionChanged: (selection) =>
                            themeProvider.setThemeMode(selection.first),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.folder_open_rounded),
                      title: const Text('Add tracks'),
                      subtitle: const Text(
                        'Choose music files from your device',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _addTracks(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.image_outlined),
                      title: const Text('Home artwork'),
                      subtitle: const Text('Choose an image from your device'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _changeHomeImage(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Playback',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              GlassSurface(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.shuffle_rounded),
                      title: const Text('Shuffle'),
                      subtitle: const Text('Play songs in a random order'),
                      value: audioLibrary.shuffleEnabled,
                      onChanged: audioLibrary.toggleShuffle,
                    ),
                    const ListTile(
                      leading: Icon(Icons.repeat_rounded),
                      title: Text('Repeat'),
                      subtitle: Text('Choose off, all songs, or one song'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SegmentedButton<AudioRepeatMode>(
                        segments: const [
                          ButtonSegment(
                            value: AudioRepeatMode.off,
                            icon: Icon(Icons.repeat_rounded),
                            label: Text('Off'),
                          ),
                          ButtonSegment(
                            value: AudioRepeatMode.all,
                            icon: Icon(Icons.repeat_rounded),
                            label: Text('All'),
                          ),
                          ButtonSegment(
                            value: AudioRepeatMode.one,
                            icon: Icon(Icons.repeat_one_rounded),
                            label: Text('One'),
                          ),
                        ],
                        selected: {audioLibrary.repeatMode},
                        onSelectionChanged: (selection) =>
                            audioLibrary.setRepeatMode(selection.first),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Exclude from library',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              GlassSurface(
                child: Column(
                  children: [
                    _ExclusionSwitch(
                      extension: 'mp3',
                      controller: audioLibrary,
                    ),
                    _ExclusionSwitch(
                      extension: 'wav',
                      controller: audioLibrary,
                    ),
                    _ExclusionSwitch(
                      extension: 'flac',
                      controller: audioLibrary,
                    ),
                    _ExclusionSwitch(
                      extension: 'm4a',
                      controller: audioLibrary,
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.visibility_off_outlined),
                      title: const Text('Hidden files'),
                      subtitle: const Text('Hide files in dot folders'),
                      value: audioLibrary.excludeHiddenFiles,
                      onChanged: audioLibrary.setExcludeHiddenFiles,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Manage tracks',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (audioLibrary.tracks.isEmpty)
                const Text('No tracks added yet.')
              else
                GlassSurface(
                  child: Column(
                    children: audioLibrary.tracks
                        .map(
                          (track) => ListTile(
                            leading: const Icon(Icons.music_note_rounded),
                            title: Text(
                              track.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              tooltip: 'Remove track',
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () => audioLibrary.removeTrack(track),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addTracks(BuildContext context) async {
    final added = await audioLibrary.importAudioFiles();
    if (!context.mounted) return;
    final message =
        audioLibrary.errorMessage ??
        (added ? 'Tracks added to your library.' : 'No tracks selected.');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeHomeImage(BuildContext context) async {
    final changed = await audioLibrary.pickHomeImage();
    if (!context.mounted) return;
    final message =
        audioLibrary.errorMessage ??
        (changed ? 'Home artwork updated.' : 'No image was selected.');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ExclusionSwitch extends StatelessWidget {
  const _ExclusionSwitch({required this.extension, required this.controller});

  final String extension;
  final AudioLibraryController controller;

  @override
  Widget build(BuildContext context) {
    final excluded = controller.excludedExtensions.contains(extension);
    return SwitchListTile(
      secondary: const Icon(Icons.audio_file_outlined),
      title: Text('.$extension files'),
      value: excluded,
      onChanged: (value) => controller.setExtensionExcluded(extension, value),
    );
  }
}
